## **练习1

### **1. `_fifo_init_mm`**
**作用**：初始化页面管理器，将FIFO队列头节点`pra_list_head`与`mm_struct`的`sm_priv`字段关联。为页面替换算法提供基础结构，确保FIFO队列可以正确管理页面。


### **2. `alloc_page`**
**作用**：分配一个空闲物理页面，为换入的页面提供存储空间。在页面换入时调用，是页面驻留内存的前提条件。

### **3. `swapfs_read`**
**作用**：从交换空间读取页面内容并写入到分配的物理页面。实现页面内容的恢复，确保程序访问数据时能正确读取。


### **4. `swap_in`**
**作用**：页面换入的主函数，负责调用`alloc_page`和`swapfs_read`完成页面加载，同时更新页表项。是页面换入流程的核心函数，处理从交换空间到内存的整体过程。


### **5. `get_pte`**
**作用**：获取虚拟地址对应的页表项，用于检查和更新虚拟地址与物理页面的映射。页面换入换出都需要更新页表，确保内存访问的地址映射正确。


### **6. `_fifo_map_swappable`**
**作用**：将新换入的页面加入FIFO队列的末尾，记录页面最近的访问顺序。维护FIFO队列，确保页面替换算法能够按照正确的顺序工作。


### **7. `_fifo_swap_out_victim`**
**作用**：从FIFO队列中选择最早加入的页面（队列头部），并将其从队列中移除。实现页面换出的关键逻辑，是FIFO算法的核心体现。


### **8. `swapfs_write`**
**作用**：将需要换出的页面内容写入到交换空间中，确保数据不丢失。页面换出的实际存储操作，是页面从内存移至外存的重要步骤。


### **9. `free_page`**
**作用**：释放页面占用的物理内存。在页面成功换出后释放内存空间，为其他页面腾出空间。

### **10. `tlb_invalidate`**
**作用**：刷新TLB（转换后备缓冲区），清除页面换出后旧的虚拟地址到物理地址映射，以避免旧映射导致错误，是换出页面后保持系统一致性的重要步骤。



### **流程简述**
1. 页面换入：
   - 调用`swap_in`，分配内存（`alloc_page`），从交换空间加载数据（`swapfs_read`），更新页表（`get_pte`），并加入FIFO队列（`_fifo_map_swappable`）。
2. 页面换出：
   - 调用`_fifo_swap_out_victim`选择页面，写入交换空间（`swapfs_write`），释放内存（`free_page`），并刷新TLB（`tlb_invalidate`）。

这10个函数分别体现了页面换入换出过程的关键操作和管理机制，是FIFO页面置换算法的核心实现部分。

## **练习4
### CLOCK页面置换算法的整体设计思路

CLOCK算法是一种改进的FIFO算法，其基本思想是为每个页面维护一个访问标记（`visited`），并使用一个循环指针（`curr_ptr`）来遍历所有页面：
- 当需要换出页面时，算法从`curr_ptr`指针的位置开始检查页面。如果页面未被访问过，则选择该页面换出；如果页面被访问过，则将其访问标记清除并跳过，继续扫描下一个页面。
- 这样，频繁访问的页面会被“跳过”，保留在内存中，而不常用的页面将优先被换出，从而有效降低缺页率。

### 代码实现及详细解析

#### 1. `_clock_init_mm`函数
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

#### 2. `_clock_map_swappable`函数
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

#### 3. `_clock_swap_out_victim`函数
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

### CLOCK算法与FIFO算法的不同

1. **页面选择机制**：
   - **FIFO算法**：仅按照页面进入内存的顺序决定换出，最早进入的页面总是最先被换出，不考虑页面的访问情况。这种方式简单但效率低，可能导致频繁换出正在使用的页面。
   - **CLOCK算法**：在FIFO基础上增加了页面访问标记的检查，通过`visited`标记决定是否跳过已访问页面，从而有效避免频繁访问的页面被过早换出。

2. **循环指针机制**：
   - **FIFO算法**：不需要循环指针，只需从队列前端顺序换出。
   - **CLOCK算法**：`curr_ptr`指针在链表中循环移动，构成“时钟”形状，通过环形扫描页面列表实现换出选择。

3. **性能优化**：
   - **FIFO算法**：性能一般，在某些场景下会导致频繁换页。
   - **CLOCK算法**：通过保留被访问过的页面，优化了换出频率和性能，降低了缺页次数，更适合实际应用。

### 总结

CLOCK算法通过访问标记和循环指针的结合，提升了页面置换效率。相比FIFO算法，CLOCK算法更加智能，能够适应更复杂的内存访问模式，减少了不必要的页面换出操作。