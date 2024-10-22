### 执行过程

启动在0x80000000，由bootloader到0x80200000

进入entry.S中的kern_entry代码段，
kern_entry 是内核的入口点，它的主要任务是设置三级页表并跳转到内核初始化函数 kern_init

具体来说：
1. **设置页表以启用虚拟内存：**这段代码设置了RISC-V处理器的三级页表来启用虚拟内存管理。具体而言，它使用了Sv39模式，这是RISC-V中一种支持39位虚拟地址空间的分页模式。

2. **计算并设置页表的物理地址：**代码通过加载三级页表的虚拟地址并减去虚实映射偏移量，计算出页表的物理地址。然后，将该物理地址转换为页号，并设置到RISC-V处理器的satp寄存器中。satp寄存器负责控制虚拟内存，包括指定页表的基地址和分页模式（Sv39模式）。

3. **刷新TLB（Translation Lookaside Buffer）：**在设置完页表后，代码通过执行sfence.vma指令刷新TLB，以确保处理器的地址翻译机制使用新的页表。

4. **设置内核栈指针：**代码接着在启用了虚拟内存空间后，将栈指针sp设置为一个虚拟地址，这个地址是在内核的虚拟地址空间中定义的。

5. **跳转到内核初始化函数kern_init：**完成页表设置和栈指针初始化后，代码跳转到内核的初始化函数kern_init，继续执行内核的其他初始化任务。


之后进入kern_init，进而执行到pmm_init()函数

**进入pmm_init函数  依次执行init_pmm_manager();----->page_init();----->check_alloc_page();**

**一、首先是init_pmm_manager()**，此处执行 
pmm_manager = &default_pmm_manager;(或best_fit_pmm_manager、buddy_pmm_manager)
pmm_manager->init();

**注：{**
 此处pmm_manager为  const struct pmm_manager *pmm_manager; 即一个指向结构体的指针。且pmm_manager 只是一个接口，具体的实现需要由特定的物理内存管理器（例如 default_pmm_manager 或 best_fit_pmm_manager）来完成。每个具体的内存管理器需要实现 pmm_manager 结构体中的所有方法，包括 init 方法。

在代码中，pmm_manager 结构体定义了一个物理内存管理器的接口。这个接口包含了一组函数指针，这些函数指针定义了内存管理器需要实现的所有方法。具体来说，pmm_manager 结构体包含以下方法：

+ init：初始化内存管理器的内部数据结构。
+ init_memmap：根据初始的空闲物理内存空间设置描述和管理数据结构。
+ alloc_pages：分配指定数量的连续物理页。
+ free_pages：释放指定数量的连续物理页。
+ nr_free_pages：返回当前空闲物理页的数量。
+ check：检查内存管理器的正确性。

**}**

之后执行default_pmm_manager中的init函数，则自然调用的是default_init函数（详情请见default_pmm.c最下面）

在default_init函数中调用list_init(&free_list); 来初始化空闲页链表

init_pmm_manager函数过程结束


**二、其次是page_init()**,此处执行了很多东西，并且调用了init_memmap函数
page_init() 是用于初始化物理内存管理系统的。它的主要任务是标记物理内存中哪些区域是内核专用的，哪些区域可以供其他程序使用。函数的主要功能是根据内存布局，设置物理内存页表，并初始化可以自由分配的物理内存。
它将物理内存划分为两部分：
内核使用的部分：由 SetPageReserved 标记，内核启动时占用的内存页。
可分配的自由内存：通过 init_memmap 初始化，供用户程序分配和使用。
（求内核所占页的多少，将内核所占的页全部标记为占用，之后初始化剩下的可以自由使用的内存）

**注：{**
Page是一个结构体，包含
int **ref**;                        //页框的引用计数器
uint64_t **flags**;                 //描述页框状态的标志数组
unsigned int **property**;          //空闲块的数量，用于首次适应内存管理器
list_entry_t **page_link**;         // 空闲列表链接

**}**

之后进入init_memmap函数
init_memmap函数只有一条语句pmm_manager->init_memmap(base, n); 即调用pmm_manager的init_memmap函数，即为default_pmm_manager及其default_init_memmap函数，

default_init_memmap函数用于初始化一个新的自由内存块，并将其添加到空闲页链表（free_list）中。作用是系统可以将这部分内存作为可分配的内存供使用。具体来说，它处理了**将内存页从“保留状态”转为“自由状态”**，并将其加入到系统的内存管理结构中。

至此page_init结束

**三、最后进入check_alloc_page();函数**
check_alloc_page函数使用 pmm->check 验证 pmm 中分配/释放函数的正确性

check_alloc_page函数只有一句话
pmm_manager->check();
自然，此时pmm_manager也应是defaultpmm_manager，并且check()也应是default_check()函数，都还在default_pmm.c中

default_check() 函数是用于验证和测试内存分配与回收的正确性。它通过模拟各种内存分配和释放的操作，确保内存管理系统能够正确地管理物理页。这是一种典型的单元测试函数，目的是通过断言验证各个操作的预期行为，确保内存管理模块的正确性

其中为了检查，其会调用basic_check函数，也会调用default_alloc_page函数、default_free_pages函数

**至此pmm_init函数中的函数调用全部结束，回到kern_init中，继续向下执行**

**总的来说，pmm_init初始化了虚拟内存，构建了页的空闲、保留、占用三种状态，并且实现了分配页面，释放页面等的算法，最后对实现进行了检查（注意：实际执行的只有初始化的代码，分配释放等并没有实际执行，而只是进行了检查，以便后续使用）。**


### 第二题

