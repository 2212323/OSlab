#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
/* 在首次适应算法中，分配器维护一个空闲块列表（称为空闲列表），
   在收到内存请求时，沿着列表扫描第一个足够大的块来满足请求。
   如果选择的块明显大于请求的块，则通常会将其拆分，并将剩余部分作为另一个空闲块添加到列表中。
   请参阅严蔚敏的中文书《数据结构——C语言版》第196~198页，第8.2节
*/
// 你应该重写以下函数：default_init, default_init_memmap, default_alloc_pages, default_free_pages.
/*
 * FFMA 的详细信息
 * (1) 准备：为了实现首次适应内存分配（FFMA），我们应该使用一些列表来管理空闲内存块。
 *              struct free_area_t 用于管理空闲内存块。首先你应该熟悉 list.h 中的 struct list。
 *              struct list 是一个简单的双向链表实现。你应该知道如何使用：list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev。
 *              另一个巧妙的方法是将通用的 list 结构转换为特定的结构（例如 struct page）：
 *              你可以找到一些宏：le2page（在 memlayout.h 中），（在未来的实验中：le2vma（在 vmm.h 中），le2proc（在 proc.h 中）等）。
 * (2) default_init：你可以重用示例 default_init 函数来初始化 free_list 并将 nr_free 设置为 0。
 *              free_list 用于记录空闲内存块。nr_free 是空闲内存块的总数。
 * (3) default_init_memmap：调用图：kern_init --> pmm_init --> page_init --> init_memmap --> pmm_manager->init_memmap
 *              这个函数用于初始化一个空闲块（参数：addr_base, page_number）。
 *              首先你应该初始化这个空闲块中的每一页（在 memlayout.h 中），包括：
 *                  p->flags 应该设置 PG_property 位（表示此页有效。在 pmm_init 函数中（在 pmm.c 中），
 *                  PG_reserved 位已在 p->flags 中设置）
 *                  如果此页是空闲的且不是空闲块的第一页，p->property 应该设置为 0。
 *                  如果此页是空闲的且是空闲块的第一页，p->property 应该设置为块的总数。
 *                  p->ref 应该为 0，因为现在 p 是空闲的，没有引用。
 *                  我们可以使用 p->page_link 将此页链接到 free_list，（例如：list_add_before(&free_list, &(p->page_link));）
 *              最后，我们应该累加空闲内存块的数量：nr_free += n
 * (4) default_alloc_pages：在空闲列表中搜索第一个空闲块（块大小 >= n），调整空闲块的大小，返回分配块的地址。
 *              (4.1) 所以你应该像这样搜索空闲列表：
 *                       list_entry_t le = &free_list;
 *                       while((le = list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) 在 while 循环中，获取 struct page 并检查 p->property（记录空闲块的数量）是否 >= n？
 *                       struct Page *p = le2page(le, page_link);
 *                       if (p->property >= n) { ...
 *                 (4.1.2) 如果我们找到了这个 p，那么这意味着我们找到了一个空闲块（块大小 >= n），并且可以分配前 n 页。
 *                     这个页的一些标志位应该设置：PG_reserved = 1, PG_property = 0
 *                     从 free_list 中取消链接这些页
 *                     (4.1.2.1) 如果 (p->property > n)，我们应该重新计算这个空闲块剩余的数量，
 *                           （例如：le2page(le, page_link)->property = p->property - n;）
 *                 (4.1.3) 重新计算 nr_free（所有空闲块的剩余数量）
 *                 (4.1.4) 返回 p
 *               (4.2) 如果我们找不到一个空闲块（块大小 >= n），则返回 NULL
 * (5) default_free_pages：将页重新链接到空闲列表中，可能将小的空闲块合并成大的空闲块。
 *               (5.1) 根据撤回块的基地址，搜索空闲列表，找到正确的位置（从低地址到高地址），并插入这些页。（可以使用 list_next, le2page, list_add_before）
 *               (5.2) 重置页的字段，例如 p->ref, p->flags（PageProperty）
 *               (5.3) 尝试合并低地址或高地址块。注意：应该正确更改一些页的 p->property。
 */

free_area_t free_area_default;//定义一个全局变量 free_area，用于管理空闲页

//这些宏定义简化了对 free_area 结构体成员的访问
#define free_list (free_area_default.free_list) 
#define nr_free (free_area_default.nr_free)

//初始化 free_area 结构体
static void default_init(void) {
    //初始化自由内存块链表和自由内存块计数器：
    list_init(&free_list); //初始化空闲页链表
    nr_free = 0;       //空闲页数量为0
}

//初始化一个自由内存块，并将其添加到自由内存块链表中
static void
default_init_memmap(struct Page *base, size_t n) {
    
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
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
}


//分配 n 个连续的物理页
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

//释放 n 个连续的物理页
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
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

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}


//返回空闲页的数量
static size_t
default_nr_free_pages(void) {
    return nr_free;
}


//检查空闲页管理器的正确性
static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

