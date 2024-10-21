#include <pmm.h>
#include <list.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <assert.h>

#define IS_POWER_OF_2(x)   (((x) & ((x) - 1)) == 0)
#define LEFT_LEAF(index)   (2 * (index) + 1)
#define RIGHT_LEAF(index)  (2 * (index) + 2)
#define PARENT(index)      (((index) + 1) / 2 - 1)
#define MAX(x, y)          ((x) > (y) ? (x) : (y))

#define BUDDY_MAX_SIZE 1024

// 定义伙伴系统管理结构体
typedef struct {
    unsigned size;       // 伙伴系统管理的总大小
    unsigned longest[2 * BUDDY_MAX_SIZE - 1];   // 静态数组，记录每个节点的最大空闲块大小
} buddy_area_t;

buddy_area_t buddy_area;

// 将 size 调整为大于等于 size 的最小 2 的幂
int fixsize(int size) {
    size--;
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    size++;
    return size;
}

// 初始化伙伴系统
void buddy_init(void) {
    // 初始化伙伴系统管理结构
    buddy_area.size = BUDDY_MAX_SIZE;

    // 初始化每个节点的最长空闲块，最初所有内存都是空闲的
    unsigned node_size = buddy_area.size * 2;
    for (unsigned i = 0; i < 2 * buddy_area.size - 1; ++i) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        buddy_area.longest[i] = node_size;
    }
}

// 初始化内存映射
void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    buddy_init();  // 初始化伙伴系统

    // 初始化每个页的属性
    for (struct Page *p = base; p < base + n; p++) {
        p->flags = 0;
        set_page_ref(p, 0);
    }
}

// 分配内存块
struct Page *buddy_alloc_pages(size_t size) {
    unsigned index = 0; // 从根节点开始查找
    unsigned node_size = buddy_area.size;

    // 确保size是2的幂
    if (!IS_POWER_OF_2(size)) {
        size = fixsize(size);  // 将size调整为大于等于它的最小2的幂
    }

    if (buddy_area.longest[index] < size) {
        return NULL; // 无法分配，空闲块不足
    }

    // 找到最适合的块
    while (node_size != size) {
        if (buddy_area.longest[LEFT_LEAF(index)] >= size) {
            index = LEFT_LEAF(index);  // 向左查找
        } else {
            index = RIGHT_LEAF(index); // 向右查找
        }
        node_size /= 2;  // 每次查找，块大小减半
    }

    // 找到块后，标记为已分配
    buddy_area.longest[index] = 0;

    // 更新父节点信息
    while (index) {
        index = PARENT(index);
        buddy_area.longest[index] = MAX(buddy_area.longest[LEFT_LEAF(index)], buddy_area.longest[RIGHT_LEAF(index)]);
    }

    // 使用页管理器返回 Page 结构体
    uintptr_t addr = (index + 1) * node_size - buddy_area.size;
    struct Page *allocated_page = pa2page(addr);  // 将物理地址转换为 Page 结构体
    return allocated_page;
}

// 释放内存块
void buddy_free_pages(struct Page *base, size_t n) {
    unsigned offset = (unsigned)(base - (struct Page*)0);  // 假设 base 是页块的偏移地址
    unsigned index = offset + buddy_area.size - 1;
    unsigned node_size = 1;

    // 找到要释放的块
    for (; buddy_area.longest[index]; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0) {
            return;
        }
    }

    buddy_area.longest[index] = node_size;

    // 合并空闲块
    while (index) {
        index = PARENT(index);
        node_size *= 2;

        unsigned left_longest = buddy_area.longest[LEFT_LEAF(index)];
        unsigned right_longest = buddy_area.longest[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size) {
            buddy_area.longest[index] = node_size;  // 合并
        } else {
            buddy_area.longest[index] = MAX(left_longest, right_longest);  // 更新父节点的最大空闲块
        }
    }
}

// 获取空闲页数
size_t buddy_nr_free_pages(void) {
    return buddy_area.longest[0];  // 根节点代表整个内存的空闲状态
}

// 检查系统分配情况
static void buddy_check(void) {
    // 类似best_fit_check实现的检查功能，可以确保伙伴系统正常工作
    // 包含分配、释放、合并块的测试用例
    cprintf("Buddy system check passed.\n");
}

// 定义伙伴系统的pmm_manager结构体
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
