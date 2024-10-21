#ifndef __KERN_MM_PMM_H__
#define __KERN_MM_PMM_H__

#include <assert.h>
#include <atomic.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>

// pmm_manager is a physical memory management class. A special pmm manager -
// XXX_pmm_manager
// only needs to implement the methods in pmm_manager class, then
// XXX_pmm_manager can be used
// by ucore to manage the total physical memory space.
// pmm_manager 是一个物理内存管理类。一个特殊的 pmm 管理器 - XXX_pmm_manager
// 只需要实现 pmm_manager 类中的方法，然后 XXX_pmm_manager 就可以被 ucore 用来管理整个物理内存空间。
struct pmm_manager {
    const char *name;  // XXX_pmm_manager's name
                       // XXX_pmm_manager 的名字
    void (*init)(
        void);  // initialize internal description&management data structure
                // (free block list, number of free block) of XXX_pmm_manager
                // 初始化 XXX_pmm_manager 的内部描述和管理数据结构（空闲块列表，空闲块数量）
    void (*init_memmap)(
        struct Page *base,
        size_t n);  // setup description&management data structcure according to
                    // the initial free physical memory space
                    // 根据初始的空闲物理内存空间设置描述和管理数据结构
    struct Page *(*alloc_pages)(
        size_t n);  // allocate >=n pages, depend on the allocation algorithm
                    // 分配 >=n 页，取决于分配算法
    void (*free_pages)(struct Page *base, size_t n);  // free >=n pages with
                                                      // "base" addr of Page
                                                      // descriptor
                                                      // structures(memlayout.h)
                                                      // 释放 >=n 页，基于 Page 描述符结构（memlayout.h）的 "base" 地址
    size_t (*nr_free_pages)(void);  // return the number of free pages
                                    // 返回空闲页的数量
    void (*check)(void);            // check the correctness of XXX_pmm_manager
                                    // 检查 XXX_pmm_manager 的正确性
};

extern const struct pmm_manager *pmm_manager;

void pmm_init(void);

struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void); // number of free pages
                            // 空闲页的数量

#define alloc_page() alloc_pages(1)
#define free_page(page) free_pages(page, 1)


/* *
 * PADDR - takes a kernel virtual address (an address that points above
 * KERNBASE),
 * where the machine's maximum 256MB of physical memory is mapped and returns
 * the
 * corresponding physical address.  It panics if you pass it a non-kernel
 * virtual address.
 * PADDR - 获取一个内核虚拟地址（指向 KERNBASE 以上的地址），
 * 该地址映射了机器的最大 256MB 物理内存，并返回相应的物理地址。
 * 如果传递了一个非内核虚拟地址，它会触发 panic。
 * */
#define PADDR(kva)                                                 \
    ({                                                             \
        uintptr_t __m_kva = (uintptr_t)(kva);                      \
        if (__m_kva < KERNBASE) {                                  \
            panic("PADDR called with invalid kva %08lx", __m_kva); \
        }                                                          \
        __m_kva - va_pa_offset;                                    \
    })

/* *
 * KADDR - takes a physical address and returns the corresponding kernel virtual
 * address. It panics if you pass an invalid physical address.
 * KADDR - 获取一个物理地址并返回相应的内核虚拟地址。
 * 如果传递了一个无效的物理地址，它会触发 panic。
 * */
/*
#define KADDR(pa)                                                \
    ({                                                           \
        uintptr_t __m_pa = (pa);                                 \
        size_t __m_ppn = PPN(__m_pa);                            \
        if (__m_ppn >= npage) {                                  \
            panic("KADDR called with invalid pa %08lx", __m_pa); \
        }                                                        \
        (void *)(__m_pa + va_pa_offset);                         \
    })
*/
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }

static inline int page_ref_inc(struct Page *page) {
    page->ref += 1;
    return page->ref;
}

static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
}
static inline void flush_tlb() { asm volatile("sfence.vm"); }
extern char bootstack[], bootstacktop[]; // defined in entry.S
                                         // 在 entry.S 中定义

#endif /* !__KERN_MM_PMM_H__ */
