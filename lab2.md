## 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

### 练习0：填写已有实验

本实验依赖实验1。请把你做的实验1的代码填入本实验中代码中有“LAB1”的注释相应部分并按照实验手册进行进一步的修改。具体来说，就是跟着实验手册的教程一步步做，然后完成教程后继续完成完成exercise部分的剩余练习。
```CPP
    /* (1) Where are the entry addrs of each Interrupt Service Routine (ISR)?
     *     All ISR's entry addrs are stored in __vectors. where is uintptr_t
     * __vectors[] ?
     *     __vectors[] is in kern/trap/vector.S which is produced by
     * tools/vector.c
     *     (try "make" command in lab1, then you will find vector.S in kern/trap
     * DIR)
     *     You can use  "extern uintptr_t __vectors[];" to define this extern
     * variable which will be used later.
     * (2) Now you should setup the entries of ISR in Interrupt Description
     * Table (IDT).
     *     Can you see idt[256] in this file? Yes, it's IDT! you can use SETGATE
     * macro to setup each item of IDT
     * (3) After setup the contents of IDT, you will let CPU know where is the
     * IDT by using 'lidt' instruction.
     *     You don't know the meaning of this instruction? just google it! and
     * check the libs/x86.h to know more.
     *     Notice: the argument of lidt is idt_pd. try to find it!
     */
        /* (1) 每个中断服务例程 (ISR) 的入口地址在哪里？
        *     所有 ISR 的入口地址都存储在 __vectors 中。uintptr_t __vectors[] 在哪里？
        *     __vectors[] 在 kern/trap/vector.S 中，它是由 tools/vector.c 生成的
        *     （在 lab1 中尝试使用 "make" 命令，然后你会在 kern/trap 目录中找到 vector.S）？？？根本没有vector.S文件！！！
        *     你可以使用 "extern uintptr_t __vectors[];" 来定义这个外部变量，它将在后面使用。
        * (2) 现在你应该在中断描述表 (IDT) 中设置 ISR 的条目。
        *     你能在这个文件中看到 idt[256] 吗？是的，那就是 IDT！你可以使用 SETGATE 宏来设置 IDT 的每一项。
        * (3) 在设置完 IDT 的内容后，你需要使用 'lidt' 指令让 CPU 知道 IDT 的位置。
        *     你不知道这条指令的含义？那就去谷歌一下吧！并查看 libs/x86.h 了解更多信息。
        *     注意：lidt 的参数是 idt_pd。试着找到它！
        */
```
**可是我现在找不到kern/trap/vector.S**wjj

### 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
- 你的first fit算法是否有进一步的改进空间？

#### default_init()

##### 函数内容
```cpp
//初始化 free_area 结构体
static void default_init(void) {
    //初始化自由内存块链表和自由内存块计数器：
    list_init(&free_list); //初始化空闲页链表
    nr_free = 0;       //空闲页数量为0
}

```
可以看到`default_init()`的内容就是在对`free_area_t`类型的对象`free_area_default`进行初始化，可以看到`free_area_t`结构体的内容如下：
```cpp
//kern/mm/memlayout.h
/* free_area_t - maintains a doubly linked list to record free (unused) pages 
    free_area_t - 维护一个双向链表来记录空闲（未使用的）页*/
typedef struct {
    list_entry_t free_list;         // the list header 列表头
    unsigned int nr_free;           // number of free pages in this free list 此空闲列表中的空闲页数
} free_area_t;

//kern/mm/default_pmm.c
#define free_list (free_area_default.free_list) 
#define nr_free (free_area_default.nr_free)

```
其中`list_init()`是libs/list.h中将头尾链表指针赋初值的初始化函数，将`free_area_default`的两个成员都初始化。
##### 函数使用

在kern/mm/best_fit_pmm.c中将default_init()的函数指针赋给了init，然后在/kern/mm/pmm.c中的init_pmm_manager()的函数中用已经赋过值的结构体指针直接调用了这一成员函数，就在给结构体赋值之后，起到了一个初始化物理内存管理器的作用。
#### default_init_memmap()
##### 函数内容
```cpp
// 初始化一个自由内存块，并将其添加到自由内存块链表中
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0); // 确保 n 大于 0
    struct Page *p = base;
    for (; p != base + n; p++) { // 初始化每一页
        assert(PageReserved(p)); // 确保页是保留的
        p->flags = p->property = 0; // 清除标志和属性
        set_page_ref(p, 0); // 设置页引用计数为 0
    }
    base->property = n; // 设置基页的属性为 n
    SetPageProperty(base); // 设置基页的属性标志
    nr_free += n; // 增加空闲页的数量
    if (list_empty(&free_list)) { // 如果空闲列表为空
        list_add(&free_list, &(base->page_link)); // 将基页添加到空闲列表
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) { // 遍历空闲列表
            struct Page* page = le2page(le, page_link);
            if (base < page) { // 找到合适的位置插入基页
                list_add_before(le, &(base->page_link)); // 在找到的位置之前插入基页
                break;
            } else if (list_next(le) == &free_list) { // 如果到达列表末尾
                list_add(le, &(base->page_link)); // 将基页添加到列表末尾
            }
        }
    }
}

```

这一部分的代码

![alt text](img/b11a8703d750fd858c7ee44f7fdc526.png)

### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？

### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。