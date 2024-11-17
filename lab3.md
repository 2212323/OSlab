### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

#### 练习2：深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
 - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

`kern/mm/pmm.c`中的`get_pte()`函数内容如下：

```c
/**
 * @brief      获取页表项并返回此页表项的内核虚拟地址
 *            如果包含此页表项的页表不存在，则为 PT 分配一个页面
 * @param      pgdir   页目录表的内核虚拟基地址
 * @param[in]  la      需要映射的线性地址
 * @param[in]  create  一个逻辑值，用于决定是否为 PT 分配一个页面,为0时不分配
 * @return     此页表项的内核虚拟地址
 * 
 * 
 */
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

```
*get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。*
在不同的分页机制中：
- sv32：使用两级页表，每级页表项大小为 4 字节，页表大小为 4 KB。
- sv39：使用三级页表，每级页表项大小为 8 字节，页表大小为 4 KB。
- sv48：使用四级页表，每级页表项大小为 8 字节，页表大小为 4 KB。

在这里使用的是sv39，具有三级页表的结构。在获取页表项并返回此页表项的内核虚拟地址的过程中体现了这一点，一共获取了三次，对应三级指针：
```c
    pde_t *pdep1 = &pgdir[PDX1(la)];
```
这里是第一级页表，这里使用的`PDX1(la)`的宏定义展开之后`#define PDX1(la) ((((uintptr_t)(la)) >> 30) & 0x1FF)`,右移30位并做掩码操作，获取了第一级页目录项索引之后在页目录表的内核虚拟基地址`pgdir`里面做偏移操作，找到第一级页目录项。

从第一级到第二级的过程中，需要做这样的操作：
```c
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }

```
逐步对于第一级的页表项进行判断：在有效的情况下，准备新建页。在短路逻辑的判断下，如果允许分配，就分配并作空值的异常处理；
之后进行新建的一系列操作：设置引用计数，获取分配页的物理地址，清除分配的页，最后新建新的页表项并设置权限。这样就完成了第一级页表项的安排。

之后进行第二级的页表项的指针

```c
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];

```
先从第一级页表项中提取物理地址，然后转成虚拟地址，并强制转换成页目录指针，其地址作为基址。然后用新的宏定义得到索引并计算偏移量，最后得到二级页表项的指针。

之后的操作和第一级相同：
```c
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }

```
同样的方式，与上面很相像，都是在确定了地址之后给他的内容赋值.

最后第第三级页表项：
```c
return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
```
与获取第二级的指针一样，只是改变了宏，偏移量改变了。

*目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？*

这种写法是可以的，没必要拆开。

首先函数的参数中包括bool值create，可以用来判断是否允许分配。这个值设置为0的时候 就是一个单纯的查找函数。

而且分配之前为了安全考虑都需要进行查找防止重复分配，给这两个放在一起可以让代码运行的更加安全。



#### 练习3：给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
 - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？


函数调用图：trap--> trap_dispatch-->pgfault_handler-->do_pgfault

在trapentry.S中，jal trap，然后trap-->exception_handle-->pgfault_handler-->do_pgfault

##### *设计实现过程*

1. swap_in(mm,addr,&page)函数
   作用：从磁盘加载页面到内存中。
   swap_in：根据 mm 和 addr，尝试将正确的磁盘页内容加载到内存中，并将其管理的页面指针返回。
2. page_insert 函数
  作用：将加载到内存中的页面插入到页表中，建立物理地址和虚拟地址的映射。
3. swap_map_swappable 函数
   作用：将页面标记为可交换的，并将其添加到交换管理器的管理中。


##### *请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。*

在
`memlayout.h`文件中PDE和PTE是这样被定义的
```cpp
typedef uintptr_t pte_t;//页表项
typedef uintptr_t pde_t;//页目录项
```

而`uintptr_t`是在文件`defs.h`这样定义的，为一个无符号64位整数，即unsigned long long
```cpp
/* *
 * Pointers and addresses are 32 bits long.
 * We use pointer types to represent addresses,
 * uintptr_t to represent the numerical values of addresses.
 * */
typedef int64_t intptr_t;
typedef uint64_t uintptr_t;
```
+ 页目录项（PDE）
    组成部分：
  + P（Present）：表示该页目录项是否有效。如果为 0，表示该页目录项无效，访问该页会导致页错误。
  + R/W（Read/Write）：表示该页是否可写。如果为 0，表示只读。
  + U/S（User/Supervisor）：表示该页是否可以在用户模式下访问。如果为 0，表示只能在内核模式下访问。
  + 地址：指向页表的物理地址。

潜在的用处包括：
1. 页替换：当需要替换一个页时，可以通过 PDE 找到对应的页表，并在页表中找到需要替换的页表项。
2. 权限检查：在页替换过程中，可以通过 PDE 检查页的权限，确保替换后的页具有正确的访问权限，包括页面可读可写的权限检查，以及在何种模式（用户态/内核态）允许进行访问的检查

+ 页目录项（PDE）
    组成部分：
  + P（Present）：表示该页表项是否有效。如果为 0，表示该页表项无效，访问该页会导致页错误。
  + R/W（Read/Write）：表示该页是否可写。如果为 0，表示只读。
  + U/S（User/Supervisor）：表示该页是否可以在用户模式下访问。如果为 0，表示只能在内核模式下访问。
  + 地址：指向物理页的物理地址。


潜在的用处包括：
1. 页替换：当需要替换一个页时，可以通过 PTE 找到对应的物理页，并将其换出到磁盘或换入到内存。
2. 交换管理：PTE 可以用于标记页是否在交换区中，并在需要时从交换区加载页。
3. 权限检查：在页替换过程中，可以通过 PTE 检查页的权限，确保替换后的页具有正确的访问权限。


##### *如果 ucore 的缺页服务例程在执行过程中访问内存，出现了页访问异常，硬件要做哪些事情？*

再遇见访问异常时，在trapentry.S中，jal trap，然后trap-->exception_handle，之后在exception_handle中，进入case CAUSE_LOAD_PAGE_FAULT或CAUSE_STORE_PAGE_FAULT，之后调用函数pgfault_handler-->do_pgfault

1. 保存上下文：硬件会保存当前的 CPU 寄存器和状态，以便在处理完异常后能够恢复。
2. 保存当前异常原因，根据stvec的地址跳转到中断处理程序trap函数，此函数在trap.c中。
3. 之后如上面函数调用顺序，pgfault_handler-->do_pgfault，进入do_pgfault具体处理缺页异常。
4. 若处理成功，则返回异常前状态，继续执行，否则输出unhandled page fault

##### *数据结构 Page 的全局变量（其实是一个数组）的每一项与页表中的页目录项（PDE）和页表项（PTE）有无对应关系？如果有，其对应关系是啥？*

存在对应关系

三者的内容分别为：
+ Page 结构体：
  + struct Page：表示一个物理页，包含物理页的相关信息，如引用计数、物理地址等。
  + 全局变量：Page 结构体的全局变量是一个数组，每一项对应一个物理页。
+ 页表项（PTE）：
  + 物理地址：PTE 中的物理地址字段指向一个物理页。这个物理页在 Page 结构体的全局变量数组中有一个对应的 Page 结构体。
  + 映射关系：PTE 中的物理地址字段与 Page 结构体的物理地址字段相对应。
+ 页目录项（PDE）：
  + **页表地址：PDE 中的地址字段指向一个页表。页表中的每一个 PTE 都指向一个物理页，这些物理页在 Page 结构体的全局变量数组中有对应的 Page 结构体。**

简单来说，PDE中的地址字段-->页表，页表中包含的PTE的物理地址字段-->Page结构体
三者为逐步包含的关系


#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

好处和优势方面，可以减少页表项数量，使用较少的页表项来覆盖更大的地址空间，从而减少了页表的层级和页表项的数量，这可以显著减少页表的内存开销。而且还可以减少页表查找的层级，减少页表查找开销。


坏处和风险方面，如果只使用了大页的一小部分，其余部分将被浪费。并且使用大页可能会导致内存碎片化问题，特别是在频繁分配和释放内存的情况下。这样会降低内存利用率，影响系统性能。因为它要求内存分配必须是大页的整数倍，灵活性不足。对于需要精细内存管理的应用场景可能不太适用。

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。



