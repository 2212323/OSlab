#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <lru.h>
#include <list.h>

/*
 * LRU 页面替换算法
 * LRU 算法记录了每个页面的最近访问时间，将最近访问的页面放在链表的尾部，
 * 最久未访问的页面放在链表的头部。
 * 在页面链表 pra_list_head_lru 中，链表头代表最久未使用的页面，链表尾代表最近访问的页面。
 */

list_entry_t pra_list_head_lru;//页面链表

int list_find(list_entry_t *head, list_entry_t *entry) {
    list_entry_t *le = list_next(head);//获取链表头部
    while (le != head) {//遍历链表
        if (le == entry) {
            return 1;  // 找到该节点
        }
        le = list_next(le);
    }
    return 0;  // 未找到该节点
}

/*
 * 初始化 LRU 页面链表，指针 mm->sm_priv 指向 pra_list_head_lru
 */
static int
_lru_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head_lru);
    mm->sm_priv = &pra_list_head_lru;//指向页面链表
    return 0;
}

/*
 * 将页面插入链表末尾，表示最近使用
 */
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link);
    assert(entry != NULL);

    // 如果页面已在链表中，先将其移除
    if (list_find(&pra_list_head_lru, entry)) {
        list_del(entry);
    }

    // 将页面添加到链表尾部，表示最近使用
    list_add_before(&pra_list_head_lru, entry);
    return 0;
}

/*
 * 选择替换的页面：选择链表头部（最久未访问的页面）
 */
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;//获取页面链表
    assert(head != NULL && !list_empty(head));

    // 获取链表头部的页面，即最久未使用的页面
    list_entry_t *victim = list_next(head);//获取链表头部,把链表头换出

    // 获取对应的页面结构
    struct Page *page = le2page(victim, pra_page_link);

    // 将页面从链表中移除
    list_del(victim);

    // 返回该页面的地址以便进行替换
    *ptr_page = page;
    return 0;
}

static int
_lru_check_swap(void) {
#ifdef ucore_test
    int score = 0, totalscore = 5;
    cprintf("%d\n", &score);
    ++ score; cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    *(unsigned char *)0x2000 = 0x0b;
    ++ score; cprintf("grading %d/%d points", score, totalscore);
    assert(pgfault_num==4);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    ++ score; cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==5);
    ++ score; cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==5);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
    ++ score; cprintf("grading %d/%d points", score, totalscore);
#else 
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==5);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==5);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
#endif
    return 0;
}


static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{
    return 0;
}


struct swap_manager swap_manager_lru =
{
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};
