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


##### **1. `_fifo_init_mm`**
**作用**：初始化页面管理器，将FIFO队列头节点`pra_list_head`与`mm_struct`的`sm_priv`字段关联。为页面替换算法提供基础结构，确保FIFO队列可以正确管理页面。


##### **2. `alloc_page`**
**作用**：分配一个空闲物理页面，为换入的页面提供存储空间。在页面换入时调用，是页面驻留内存的前提条件。

##### **3. `swapfs_read`**
**作用**：从交换空间读取页面内容并写入到分配的物理页面。实现页面内容的恢复，确保程序访问数据时能正确读取。


##### **4. `swap_in`**
**作用**：页面换入的主函数，负责调用`alloc_page`和`swapfs_read`完成页面加载，同时更新页表项。是页面换入流程的核心函数，处理从交换空间到内存的整体过程。


##### **5. `get_pte`**
**作用**：获取虚拟地址对应的页表项，用于检查和更新虚拟地址与物理页面的映射。页面换入换出都需要更新页表，确保内存访问的地址映射正确。


##### **6. `_fifo_map_swappable`**
**作用**：将新换入的页面加入FIFO队列的末尾，记录页面最近的访问顺序。维护FIFO队列，确保页面替换算法能够按照正确的顺序工作。


##### **7. `_fifo_swap_out_victim`**
**作用**：从FIFO队列中选择最早加入的页面（队列头部），并将其从队列中移除。实现页面换出的关键逻辑，是FIFO算法的核心体现。


##### **8. `swapfs_write`**
**作用**：将需要换出的页面内容写入到交换空间中，确保数据不丢失。页面换出的实际存储操作，是页面从内存移至外存的重要步骤。


##### **9. `free_page`**
**作用**：释放页面占用的物理内存。在页面成功换出后释放内存空间，为其他页面腾出空间。

##### **10. `tlb_invalidate`**
**作用**：刷新TLB（转换后备缓冲区），清除页面换出后旧的虚拟地址到物理地址映射，以避免旧映射导致错误，是换出页面后保持系统一致性的重要步骤。



##### **流程简述**
1. 页面换入：
   - 调用`swap_in`，分配内存（`alloc_page`），从交换空间加载数据（`swapfs_read`），更新页表（`get_pte`），并加入FIFO队列（`_fifo_map_swappable`）。
2. 页面换出：
   - 调用`_fifo_swap_out_victim`选择页面，写入交换空间（`swapfs_write`），释放内存（`free_page`），并刷新TLB（`tlb_invalidate`）。

这10个函数分别体现了页面换入换出过程的关键操作和管理机制，是FIFO页面置换算法的核心实现部分。

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

#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

##### CLOCK页面置换算法的整体设计思路

CLOCK算法是一种改进的FIFO算法，其基本思想是为每个页面维护一个访问标记（`visited`），并使用一个循环指针（`curr_ptr`）来遍历所有页面：
- 当需要换出页面时，算法从`curr_ptr`指针的位置开始检查页面。如果页面未被访问过，则选择该页面换出；如果页面被访问过，则将其访问标记清除并跳过，继续扫描下一个页面。
- 这样，频繁访问的页面会被“跳过”，保留在内存中，而不常用的页面将优先被换出，从而有效降低缺页率。

##### 代码实现及详细解析

###### 1. `_clock_init_mm`函数
`_clock_init_mm`函数是CLOCK算法初始化过程的一部分。它负责配置页面置换链表的基本结构，使`mm_struct`结构体能正确指向页面列表，并初始化`curr_ptr`以备后续使用。

```c
static int _clock_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head);    // 初始化 pra_list_head 为一个空链表，用于存放页面节点
    curr_ptr = &pra_list_head;    // 将 curr_ptr 指针初始化为指向链表头
    mm->sm_priv = &pra_list_head; // 将 mm->sm_priv 指向 pra_list_head，用于后续的页面替换操作
    return 0;
}
```

- **list_init(&pra_list_head)**：调用`list_init`将`pra_list_head`初始化为空链表，表示还没有页面进入链表。
- **curr_ptr = &pra_list_head**：初始化`curr_ptr`指针，使其指向`pra_list_head`。这是一个循环指针，会在页面置换过程中绕着链表循环移动。
- **mm->sm_priv = &pra_list_head**：将`mm_struct`结构的`sm_priv`指针指向`pra_list_head`，以便在其他函数中访问页面链表。

###### 2. `_clock_map_swappable`函数
当有新页面被加载到内存中时，调用`_clock_map_swappable`函数，它会将该页面插入到链表末尾，并设置其访问标记。这一步确保新加载的页面在下次被访问时不会被优先换出。

```c
static int _clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link); // 获取页面的链表节点指针
    assert(entry != NULL && curr_ptr != NULL);    // 确保页面链表节点和 curr_ptr 非空

    list_add_before((list_entry_t*) mm->sm_priv, entry); // 将页面插入到链表尾部
    page->visited = 1;                                  // 将页面的访问标记设置为1，表示该页面已被访问
    return 0;
}
```

- **list_entry_t *entry = &(page->pra_page_link)**：获取页面的链表节点指针，便于将该页面加入链表。
- **list_add_before((list_entry_t*) mm->sm_priv, entry)**：将页面插入到`pra_list_head`链表的尾部，以符合FIFO的顺序。最新加载的页面总是被放在末尾。
- **page->visited = 1**：将页面的`visited`标记设为1，表示该页面已被访问。这样在下一次选择替换页面时，该页面将被“跳过”保留。

###### 3. `_clock_swap_out_victim`函数
`_clock_swap_out_victim`函数是CLOCK算法的核心部分，用于选择换出的页面。通过循环指针`curr_ptr`遍历链表，找到未被访问的页面，并将其换出。如果页面被访问过，清除访问标记并跳过该页面。

```c
static int _clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);

    while (1) {
        struct Page *page = le2page(curr_ptr, pra_page_link); // 获取 curr_ptr 指向的页面结构
        if (page->visited == 0) {  // 页面未被访问，选择为 victim
            *ptr_page = page;
            curr_ptr = list_next(curr_ptr);    // 指针移动到下一个位置
            list_del(&(page->pra_page_link));  // 将页面从链表中删除
            break;
        } else {
            page->visited = 0;  // 如果页面已被访问，清除访问标记
            curr_ptr = list_next(curr_ptr); // 指针移向下一个页面
            if (curr_ptr == &pra_list_head) { // 如果 curr_ptr 到达链表尾部，重新指向链表头
                curr_ptr = list_next(curr_ptr);
            }
        }
    }
    return 0;
}
```

- **struct Page *page = le2page(curr_ptr, pra_page_link)**：通过`curr_ptr`指针获取当前页面结构，以便检查其访问标记。
- **if (page->visited == 0)**：如果当前页面未被访问过，即`visited == 0`，则选择该页面作为换出页面。
  - **`*ptr_page = page`**：将要换出的页面指针赋值给`ptr_page`。
  - **`curr_ptr = list_next(curr_ptr)`**：移动`curr_ptr`到下一个页面，为后续页面选择做好准备。
  - **`list_del(&(page->pra_page_link))`**：将该页面从链表中移除，完成换出操作。
- **else**：如果页面被访问过，则清除其访问标记（`page->visited = 0`）并移动到下一个页面，继续检查。通过`curr_ptr = list_next(curr_ptr)`实现循环移动指针。
  - 如果`curr_ptr`到达链表尾部（即`curr_ptr == &pra_list_head`），则将`curr_ptr`指向链表头，形成循环。

##### CLOCK算法与FIFO算法的不同

1. **页面选择机制**：
   - **FIFO算法**：仅按照页面进入内存的顺序决定换出，最早进入的页面总是最先被换出，不考虑页面的访问情况。这种方式简单但效率低，可能导致频繁换出正在使用的页面。
   - **CLOCK算法**：在FIFO基础上增加了页面访问标记的检查，通过`visited`标记决定是否跳过已访问页面，从而有效避免频繁访问的页面被过早换出。

2. **循环指针机制**：
   - **FIFO算法**：不需要循环指针，只需从队列前端顺序换出。
   - **CLOCK算法**：`curr_ptr`指针在链表中循环移动，构成“时钟”形状，通过环形扫描页面列表实现换出选择。

3. **性能优化**：
   - **FIFO算法**：性能一般，在某些场景下会导致频繁换页。
   - **CLOCK算法**：通过保留被访问过的页面，优化了换出频率和性能，降低了缺页次数，更适合实际应用。

##### 总结

CLOCK算法通过访问标记和循环指针的结合，提升了页面置换效率。相比FIFO算法，CLOCK算法更加智能，能够适应更复杂的内存访问模式，减少了不必要的页面换出操作。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

好处和优势方面，可以减少页表项数量，使用较少的页表项来覆盖更大的地址空间，从而减少了页表的层级和页表项的数量，这可以显著减少页表的内存开销。而且还可以减少页表查找的层级，减少页表查找开销。


坏处和风险方面，如果只使用了大页的一小部分，其余部分将被浪费。并且使用大页可能会导致内存碎片化问题，特别是在频繁分配和释放内存的情况下。这样会降低内存利用率，影响系统性能。因为它要求内存分配必须是大页的整数倍，灵活性不足。对于需要精细内存管理的应用场景可能不太适用。

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。



