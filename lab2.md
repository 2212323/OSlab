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
    //初始化每一页
    for (; p != base + n; p++) { 
        assert(PageReserved(p)); 
        p->flags = p->property = 0; 
        set_page_ref(p, 0); 
    }
    //处理基页
    base->property = n; 
    SetPageProperty(base); 

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
首先对页进行操作，页的定义在kern/mm/memlayout.h中：
```cpp
struct Page {
    int ref;                        // page frame's reference counter 页框的引用计数器
    uint64_t flags;                 // array of flags that describe the status of the page frame 描述页框状态的标志数组
    unsigned int property;          // the num of free block, used in first fit pm manager 空闲块的数量，用于首次适应内存管理器
    list_entry_t page_link;         // free list link 空闲列表链接
};

```
代码在简单的判断n>0之后，开始清理每个页。需要注意的是，这里面的p++:
```cpp
    assert(n > 0); // 确保 n 大于 0
    struct Page *p = base;
    //初始化每一页
    for (; p != base + n; p++) { //注意p++
        assert(PageReserved(p)); 
        p->flags = p->property = 0; 
        set_page_ref(p, 0); 
    }

```

`p` 是一个指向 `struct Page` 的指针，`p++` 操作将使指针 `p` 指向下一个 `struct Page` 结构体。当对结构体指针进行自增操作（`p++`），这并不是简单的增加一个字节，而是会跳过整个结构体的大小。也就是说，`p++` 会使指针 `p` 增加相当于 `struct Page` 结构体大小的字节数，指向内存中的下一个 `struct Page` 实例。每次 `p++` 实际上是在内存中跳过 `sizeof(struct Page)` 个字节，并指向下一个 `struct Page` 结构体。这样就可以在循环中逐一处理内存块中的每一页。

其中`static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }`是一个kern/mm/pmm.h的内联函数，可以看到三行代码将页的引用计数器，状态数组和空闲块数量都置0了。


```cpp
    //处理基页
    base->property = n; 
    SetPageProperty(base); 
     nr_free += n; // 增加空闲页的数量
```
对于基页也就是第一页，把空闲块数量置n,然后采用宏定义的方式设置他的状态数组，证明此页是一个空闲内存块的头页（包含一些连续地址的页），可以在 alloc_pages 中使用。之后对应的增加空闲页的数量。

```cpp
    //插入页
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

```
在最后就是一个插入页的过程，利用libs/list.h中对链表的操作，在空链表的时候直接加入，不空的话顺序遍历，找到可以的区域进行插入。
##### 函数使用
在kern/mm/best_fit_pmm.c中将default_memmap()的函数指针赋给了init，然后在/kern/mm/pmm.c中的page_init()的函数中用已经赋过值的结构体指针直接调用了这一成员函数:


```cpp
    if (freemem < mem_end) {
        //初始化我们可以自由使用的物理内存
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
```
这里面传入的参数是可以自由使用的物理内存的起始页面和可用的大小，进行空间的初始化。
#### default_free_pages()
##### 函数内容

```cpp
// 释放 n 个连续的物理页
static void
default_free_pages(struct Page *base, size_t n) {
  assert(n > 0); // 确保 n 大于 0
  struct Page *p = base;
  // 遍历并释放每一页
  for (; p != base + n; p ++) {
    assert(!PageReserved(p) && !PageProperty(p)); // 确保页未被保留且无属性
    p->flags = 0; // 清除页标志
    set_page_ref(p, 0); // 设置页引用计数为 0
  }
  base->property = n; // 设置基页属性为 n
  SetPageProperty(base); // 设置基页属性标志
  nr_free += n; // 增加空闲页数量

  // 如果空闲列表为空，直接添加基页
  if (list_empty(&free_list)) {
    list_add(&free_list, &(base->page_link));
  } else {
    list_entry_t* le = &free_list;
    // 遍历空闲列表，找到合适位置插入基页
    while ((le = list_next(le)) != &free_list) {
      struct Page* page = le2page(le, page_link);
      if (base < page) {
        list_add_before(le, &(base->page_link));
        break;
      } else if (list_next(le) == &free_list) {
        list_add(le, &(base->page_link));
      }
    }
  }


    // 合并前面的空闲页
    list_entry_t* le = list_prev(&(base->page_link)); // 获取前一个链表项
    if (le != &free_list) { // 如果前一个链表项不是空闲列表头
      p = le2page(le, page_link); // 获取前一个页
      if (p + p->property == base) { // 如果前一个页的末尾与当前基页的起始地址相同
        p->property += base->property; // 合并前一个页和当前基页的属性
        ClearPageProperty(base); // 清除当前基页的属性标志
        list_del(&(base->page_link)); // 从链表中删除当前基页
        base = p; // 更新基页为前一个页
      }
    }


  // 合并后面的空闲页
    le = list_next(&(base->page_link)); // 获取后一个链表项
    if (le != &free_list) { // 如果后一个链表项不是空闲列表头
      p = le2page(le, page_link); // 获取后一个页
      if (base + base->property == p) { // 如果当前基页的末尾与后一个页的起始地址相同
        base->property += p->property; // 合并当前基页和后一个页的属性
        ClearPageProperty(p); // 清除后一个页的属性标志
        list_del(&(p->page_link)); // 从链表中删除后一个页
      }
    }
  }
```
在释放内存的过程中，指定了要释放的基页和大小之后，一开始的操作和初始化内存块页是一样的，都是遍历释放每一页，处理基页并插入到链表里面：
```cpp
  assert(n > 0); // 确保 n 大于 0
  struct Page *p = base;
  // 遍历并释放每一页
  for (; p != base + n; p ++) {
    assert(!PageReserved(p) && !PageProperty(p)); // 确保页未被保留且无属性
    p->flags = 0; // 清除页标志
    set_page_ref(p, 0); // 设置页引用计数为 0
  }
  base->property = n; // 设置基页属性为 n
  SetPageProperty(base); // 设置基页属性标志
  nr_free += n; // 增加空闲页数量

  // 如果空闲列表为空，直接添加基页
  if (list_empty(&free_list)) {
    list_add(&free_list, &(base->page_link));
  } else {
    list_entry_t* le = &free_list;
    // 遍历空闲列表，找到合适位置插入基页
    while ((le = list_next(le)) != &free_list) {
      struct Page* page = le2page(le, page_link);
      if (base < page) {
        list_add_before(le, &(base->page_link));
        break;
      } else if (list_next(le) == &free_list) {
        list_add(le, &(base->page_link));
      }
    }
  }

```
此后对于两种特殊情况进行处理：
+ 如果前一个链表项不是空闲列表头，并且前一个页的末尾与当前基页的起始地址相同的话，就需要合并前一个页；
+ 如果后一个链表项不是空闲列表头，并且当前基页的末尾与后一个页的起始地址相同的话，就需要合并后一个页；
这样可以减少内存碎片，把相邻的空闲页面合并成一个更大的块，方便将来分配大块连续的内存。并且合并后减少了内存管理中的链表项，简化内存管理，减少系统开销。

```cpp
    // 合并前面的空闲页
    list_entry_t* le = list_prev(&(base->page_link)); // 获取前一个链表项
    if (le != &free_list) { // 如果前一个链表项不是空闲列表头
      p = le2page(le, page_link); // 获取前一个页
      if (p + p->property == base) { // 如果前一个页的末尾与当前基页的起始地址相同
        p->property += base->property; // 合并前一个页和当前基页的属性
        ClearPageProperty(base); // 清除当前基页的属性标志
        list_del(&(base->page_link)); // 从链表中删除当前基页
        base = p; // 更新基页为前一个页
      }
    }


  // 合并后面的空闲页
    le = list_next(&(base->page_link)); // 获取后一个链表项
    if (le != &free_list) { // 如果后一个链表项不是空闲列表头
      p = le2page(le, page_link); // 获取后一个页
      if (base + base->property == p) { // 如果当前基页的末尾与后一个页的起始地址相同
        base->property += p->property; // 合并当前基页和后一个页的属性
        ClearPageProperty(p); // 清除后一个页的属性标志
        list_del(&(p->page_link)); // 从链表中删除后一个页
      }
    }
```
##### 函数使用

在kern/mm/best_fit_pmm.c中将default_free_pages()的函数指针赋给了init，然后在/kern/mm/pmm.c中的free_pages()的函数中用已经赋过值的结构体指针直接调用了这一成员函数:
```cpp
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);//保存当前中断状态并禁用中断
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);//恢复之前的中断状态
}
```
需要注意的是，这里面为了避免混淆，使用花括号围住中间那行代码，主要原因是为了创建一个新的作用域，避免命名冲突，增强可读性。
在default_check()中反复调用，进行检查；
#### default_alloc_pages()
##### 函数内容
```cpp
//分配 n 个连续的物理页
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0); // 确保 n 大于 0
    if (n > nr_free) { // 如果请求的页数大于空闲页数，返回 NULL
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    // 遍历空闲列表，找到第一个满足条件的空闲块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) { // 找到一个空闲块，其大小大于或等于 n
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link)); // 从空闲列表中删除该块
        if (page->property > n) { // 如果空闲块大小大于 n
            struct Page *p = page + n;
            p->property = page->property - n; // 更新剩余块的大小
            SetPageProperty(p); // 设置剩余块的属性
            list_add(prev, &(p->page_link)); // 将剩余块添加回空闲列表
        }
        nr_free -= n; // 更新空闲页数
        ClearPageProperty(page); // 清除已分配块的属性
    }
    return page; // 返回分配的页
}

```
分配的页面的方法是遍历空闲列表，找到第一个其大小大于或等于n的空闲块，进行分配：

```cpp
    assert(n > 0); // 确保 n 大于 0
    if (n > nr_free) { // 如果请求的页数大于空闲页数，返回 NULL
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    // 遍历空闲列表，找到第一个满足条件的空闲块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) { // 找到一个空闲块，其大小大于或等于 n
            page = p;
            break;
        }
    }

```
如果成功找到了需要分配的块，接下来对分配出去的这块做切割：
+ 满足当前请求的的n个页
+ 剩余的页放回到空闲列表中
通过先在链表中删除，切割之后把剩余的在放回的方式，将剩余块的属性设置为PG_property，使用块的PG_property清理掉。
```cpp
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link)); // 从空闲列表中删除该块
        if (page->property > n) { // 如果空闲块大小大于 n
            struct Page *p = page + n;
            p->property = page->property - n; // 更新剩余块的大小
            SetPageProperty(p); // 设置剩余块的属性
            list_add(prev, &(p->page_link)); // 将剩余块添加回空闲列表
        }
        nr_free -= n; // 更新空闲页数
        ClearPageProperty(page); // 清除已分配块的属性
    }
    return page; // 返回分配的页

```
### 函数使用

在kern/mm/best_fit_pmm.c中将default_alloc_pages()的函数指针赋给了init，然后在/kern/mm/pmm.c中的alloc_pages()的函数中用已经赋过值的结构体指针直接调用了这一成员函数:
```cpp
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
    }
    local_intr_restore(intr_flag);
    return page;
}
在后续的check中反复调用。
```

```cpp
```
```cpp
```
```cpp
```

这一部分的代码

![alt text](img/b11a8703d750fd858c7ee44f7fdc526.png)

### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？

首先First fit算法实现和Best Fit页面分配算法实现非常类似，因为本质上二者都是页面分配算法，只是在分配的过程中侧重不同，
主要有区别的地方为：first fit算法在进行分配时，遍历所有页面空闲页的时候会直接将找到的第一个满足要求的页（意为页大小满足分配需要），直接进行分配。
而对于best fit算法，他会找到所有满足要求的页，之后选出最小的那个（即“最满足要求”）进行分配。





### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。