#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <../sync/sync.h>
#include <riscv.h>

// pages指针保存的是第一个Page结构体所在的位置，也可以认为是Page结构体组成的数组的开头
// 由于C语言的特性，可以把pages作为数组名使用，pages[i]表示顺序排列的第i个结构体

// virtual address of physical page array
// 物理页数组的虚拟地址
// pages指针保存的是第一个Page结构体所在的位置，也可以认为是Page结构体组成的数组的开头
// 由于C语言的特性，可以把pages作为数组名使用，pages[i]表示顺序排列的第i个结构体

struct Page *pages;
// amount of physical memory (in pages)
// 物理内存的数量（以页为单位）
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
// 内核映像映射在 VA=KERNBASE 和 PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// 内存在 RISC-V 中从 0x80000000 开始
// DRAM_BASE defined in riscv.h as 0x80000000
// DRAM_BASE 在 riscv.h 中定义为 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;
//(npage - nbase)表示物理内存的页数
// virtual address of boot-time page directory
// 引导时页目录的虚拟地址
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
// 引导时页目录的物理地址
uintptr_t satp_physical;

// physical memory management
// 物理内存管理
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
// init_pmm_manager - 初始化一个 pmm_manager 实例
static void init_pmm_manager(void) {
    pmm_manager = &buddy_pmm_manager;  //初始默认为best，应改为default，因best还没有实现！！！！！！
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
// init_memmap - 调用 pmm->init_memmap 为空闲内存构建 Page 结构
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory
// alloc_pages - 调用 pmm->alloc_pages 分配连续的 n*PAGESIZE 内存
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

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
// free_pages - 调用 pmm->free_pages 释放连续的 n*PAGESIZE 内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) of current free memory
// nr_free_pages - 调用 pmm->nr_free_pages 获取当前空闲内存的大小 (nr*PAGESIZE)
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}


//初始化物理内存管理系统。它设置了内核和用户程序可以使用的物理内存区域，并将这些区域标记为可用
static void page_init(void) {
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;//这是设置虚拟地址到物理地址的偏移量。在启用虚拟内存的系统中，虚拟地址和物理地址之间有一个固定的偏移量，通常由系统定义。在我们的系统中，这个偏移量是0xFFFFFFFF40000000。

    uint64_t mem_begin = KERNEL_BEGIN_PADDR; //#define KERNEL_BEGIN_PADDR     0x80200000    应用程序的第一条指令   硬编码取代 sbi_query_memory()接口，内核的起始地址
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;//内核的大小
    uint64_t mem_end = PHYSICAL_MEMORY_END; //

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
            mem_end - 1);

    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
    //kernel在end[]结束, pages是剩下的页的开始
    // 内核在 end[] 结束，pages 是剩下的页的开始
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);//pages：指向内核结束后的第一个可用页面。通过 ROUNDUP 来确保对齐到页大小。
    //把pages指针指向内核所占内存空间结束后的第一页

    //一开始把所有页面都设置为保留给内核使用的，之后再设置哪些页面可以分配给其他程序

    for (size_t i = 0; i < npage - nbase; i++) {//npage - nbase表示物理内存的页数
        SetPageReserved(pages + i);//记得吗？在kern/mm/memlayout.h定义的
    }
    //从这个地方开始才是我们可以自由使用的物理内存
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); //这里是第一个可以分配的物理内存的地址
    //按照页面大小PGSIZE进行对齐, ROUNDUP, ROUNDDOWN是在libs/defs.h定义的
    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end) {
        cprintf("我们想知道自由使用的物理内存！！！！！%d\n",(mem_end - mem_begin) / PGSIZE);
   
        //cprintf((mem_end - mem_begin) / PGSIZE);
        //初始化我们可以自由使用的物理内存
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);

        cprintf("free physical memory: [0x%016lx, 0x%016lx).\n", mem_begin, mem_end);
    }
}

/* pmm_init - initialize the physical memory management */
// pmm_init - 初始化物理内存管理
void pmm_init(void) {

    
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // 我们需要分配/释放物理内存（粒度为 4KB 或其他大小）。
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // 因此在 pmm.h 中定义了一个物理内存管理器框架（struct pmm_manager）
    // First we should init a physical memory manager(pmm) based on the framework.
    // 首先我们应该基于该框架初始化一个物理内存管理器（pmm）。
    // Then pmm can alloc/free the physical memory.
    // 然后 pmm 可以分配/释放物理内存。
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    // 现在有 first_fit/best_fit/worst_fit/buddy_system pmm 可用。
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // 检测物理内存空间，保留已使用的内存，
    // then use pmm->init_memmap to create free page list
    // 然后使用 pmm->init_memmap 创建空闲页列表
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    // 使用 pmm->check 验证 pmm 中分配/释放函数的正确性
    check_alloc_page();

    extern char boot_page_table_sv39[];//我们把汇编里定义的页表所在位置的符号声明进来
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);//然后输出页表所在的地址
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    cprintf("check_alloc_page) succeeded!\n");
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
