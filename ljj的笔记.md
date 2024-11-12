
## mm_struct和vma_struct的关系

一个 mm_struct 结构体包含多个 vma_struct 结构体。

vma_struct ：一个连续的虚拟内存区域，
mm_struct ：代表一个进程的所有虚拟内存区域。

链表结构：mm_struct 使用 mmap_list 字段将所有 vma_struct 结构体链接在一起，形成一个按起始地址排序的链表。每个 vma_struct 通过 list_link 字段链接到链表中。