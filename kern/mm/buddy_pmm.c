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
struct buddy {
    unsigned size;       // 伙伴系统管理的总大小
    unsigned longest[1]; // 记录每个节点的最大空闲块大小（变长数组）
};

// 创建新的伙伴系统，改用内核分配函数
struct buddy *buddy_new(int size) {
    struct buddy *self;
    unsigned node_size;
    int i;

    if (size < 1 || !IS_POWER_OF_2(size)) {
        return NULL;
    }

    // 改用内核分配物理页函数，alloc_pages 分配所需的内存空间
    self = (struct buddy *)alloc_pages(ROUNDUP(sizeof(struct buddy) + (2 * size - 1) * sizeof(unsigned), PGSIZE));
    if (self == NULL) {
        return NULL;
    }

    self->size = size;
    node_size = size * 2;

    for (i = 0; i < 2 * size - 1; ++i) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        self->longest[i] = node_size;
    }
    return self;
}

// 调整 size 为大于等于 size 的最小 2 的幂
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

// 分配内存块
int buddy_alloc(struct buddy *self, int size) {
    unsigned index = 0;
    unsigned node_size;
    unsigned offset = 0;

    if (self == NULL || size <= 0) {
        return -1;
    }

    if (!IS_POWER_OF_2(size)) {
        size = fixsize(size);
    }

    if (self->longest[index] < size) {
        return -1; // 无法分配，空闲块不足
    }

    // 找到最适合的块
    for (node_size = self->size; node_size != size; node_size /= 2) {
        if (self->longest[LEFT_LEAF(index)] >= size) {
            index = LEFT_LEAF(index);
        } else {
            index = RIGHT_LEAF(index);
        }
    }

    // 找到块后，标记为已分配
    self->longest[index] = 0;
    offset = (index + 1) * node_size - self->size;

    // 更新父节点信息
    while (index) {
        index = PARENT(index);
        self->longest[index] = MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]);
    }

    return offset;
}

// 释放内存块
void buddy_free(struct buddy *self, int offset) {
    unsigned node_size, index;
    unsigned left_longest, right_longest;

    assert(self && offset >= 0 && offset < self->size);

    node_size = 1;
    index = offset + self->size - 1;

    // 找到块并标记为已释放
    for (; self->longest[index]; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0) {
            return;
        }
    }

    self->longest[index] = node_size;

    // 合并空闲块
    while (index) {
        index = PARENT(index);
        node_size *= 2;

        left_longest = self->longest[LEFT_LEAF(index)];
        right_longest = self->longest[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size) {
            self->longest[index] = node_size; // 合并
        } else {
            self->longest[index] = MAX(left_longest, right_longest); // 更新父节点的最大空闲块
        }
    }
}

// 伙伴系统内存检查函数
static void buddy_check(struct buddy *self) {
    int total_free = 0;

    // 遍历所有节点，检查是否有空闲块
    for (int i = 0; i < 2 * self->size - 1; i++) {
        total_free += self->longest[i];
    }

    assert(total_free == self->longest[0]); // 检查根节点是否匹配所有空闲块的总和
    cprintf("buddy_check passed!\n");
}

// 定义伙伴系统的物理内存管理器
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = (void (*)(void))buddy_new,
    .init_memmap = NULL,  // 可以根据需要实现
    .alloc_pages = (struct Page *(*)(size_t))buddy_alloc,
    .free_pages = (void (*)(struct Page *, size_t))buddy_free,
    .nr_free_pages = NULL,  // 可以根据需要实现
    .check = (void (*)(void))buddy_check,
};
