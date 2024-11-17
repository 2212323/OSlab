#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

//pre define
struct mm_struct;

// the virtual continuous memory area(vma), [vm_start, vm_end), 
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end 
// 虚拟连续内存区域(vma)，[vm_start, vm_end)，地址属于一个vma意味着 vma.vm_start <= addr < vma.vm_end
struct vma_struct {//vma_struct 代表一个虚拟内存区域（VMA）
    struct mm_struct *vm_mm; // the set of vma using the same PDT // 使用相同PDT的一组vma
    uintptr_t vm_start;      // start addr of vma      // vma的起始地址
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself // vma的结束地址，不包括vm_end本身
    uint_t vm_flags;       // flags of vma // vma的标志
    list_entry_t list_link;  // linear list link which sorted by start addr of vma // 按vma起始地址排序的线性链表链接
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001 // 可读
#define VM_WRITE                0x00000002 // 可写
#define VM_EXEC                 0x00000004 // 可执行

// the control struct for a set of vma using the same PDT
// 使用相同PDT的一组vma的控制结构
struct mm_struct {
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma // 按vma起始地址排序的线性链表链接
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose // 当前访问的vma，用于加速
    pde_t *pgdir;                  // the PDT of these vma // 这些vma的PDT
    int map_count;                 // the count of these vma // 这些vma的数量
    void *sm_priv;                   // the private data for swap manager // 交换管理器的私有数据
    //sm_priv 是 mm_struct 结构体中的一个字段，用于存储与交换管理器（Swap Manager）相关的私有数据。
    //这个字段通常用于在内存管理结构中保存与页面交换（paging/swapping）相关的特定信息，以便在需要时能够快速访问和操作这些数据。
    //例如用于管理交换区的链表头、交换区的元数据等

};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr); // 查找包含指定地址的vma
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags); // 创建一个新的vma
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma); // 插入一个vma到mm_struct中

struct mm_struct *mm_create(void); // 创建一个新的mm_struct
void mm_destroy(struct mm_struct *mm); // 销毁一个mm_struct

void vmm_init(void); // 初始化虚拟内存管理

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr); // 处理页错误

extern volatile unsigned int pgfault_num; // 页错误计数
extern struct mm_struct *check_mm_struct; // 用于检查的mm_struct

#endif /* !__KERN_MM_VMM_H__ */
