#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

struct buddy2 {// buddy系统结构
  unsigned size;// buddy系统大小
  unsigned longest[1]; // 最大可用块大小
};

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define ALLOC malloc
#define FREE free

// 修正大小为2的幂
static unsigned fixsize(unsigned size) {
  size |= size >> 1;
  size |= size >> 2;
  size |= size >> 4;
  size |= size >> 8;
  size |= size >> 16;
  return size+1;
}

// 创建一个新的buddy系统
// 参数: size - buddy系统的大小，必须是2的幂
// 返回值: 成功返回buddy系统的指针，失败返回NULL
struct buddy2* buddy2_new(int size) {
  struct buddy2* self;
  unsigned node_size;
  int i;

  if (size < 1 || !IS_POWER_OF_2(size))
    return NULL;

  self = (struct buddy2*)ALLOC(2 * size * sizeof(unsigned));
  self->size = size;
  node_size = size * 2;

  for (i = 0; i < 2 * size - 1; ++i) {
    if (IS_POWER_OF_2(i+1))
      node_size /= 2;
    self->longest[i] = node_size;
  }
  return self;
}

// 销毁buddy系统
// 参数: self - buddy系统的指针
void buddy2_destroy(struct buddy2* self) {
  FREE(self);
}

// 分配内存块
// 参数: self - buddy系统的指针, size - 要分配的内存块大小
// 返回值: 成功返回内存块的偏移量，失败返回-1
int buddy2_alloc(struct buddy2* self, int size) {
  unsigned index = 0; // 初始化索引为0
  unsigned node_size; // 节点大小
  unsigned offset = 0; // 偏移量

  if (self == NULL) // 如果buddy系统指针为空
    return -1; // 返回-1表示失败

  if (size <= 0) // 如果请求的大小小于等于0
    size = 1; // 将大小设为1
  else if (!IS_POWER_OF_2(size)) // 如果请求的大小不是2的幂
    size = fixsize(size); // 调整大小为2的幂

  if (self->longest[index] < size) // 如果根节点的最大可用块小于请求的大小
    return -1; // 返回-1表示失败

  // 遍历树找到合适的块
  for (node_size = self->size; node_size != size; node_size /= 2) {
    if (self->longest[LEFT_LEAF(index)] >= size) // 如果左子节点的最大可用块大于等于请求的大小
      index = LEFT_LEAF(index); // 选择左子节点
    else // 否则
      index = RIGHT_LEAF(index); // 选择右子节点
  }

  self->longest[index] = 0; // 将找到的块标记为已分配
  offset = (index + 1) * node_size - self->size; // 计算偏移量

  // 更新父节点的最大可用块大小
  while (index) {
    index = PARENT(index); // 获取父节点索引
    self->longest[index] =
      MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]); // 更新父节点的最大可用块大小
  }

  return offset; // 返回偏移量
}

// 释放内存块
// 参数: self - buddy系统的指针, offset - 要释放的内存块的偏移量
void buddy2_free(struct buddy2* self, int offset) {
  unsigned node_size, index = 0;
  unsigned left_longest, right_longest;

  assert(self && offset >= 0 && offset < self->size);

  node_size = 1;
  index = offset + self->size - 1;

  for (; self->longest[index]; index = PARENT(index)) {
    node_size *= 2;
    if (index == 0)
      return;
  }

  self->longest[index] = node_size;

  while (index) {
    index = PARENT(index);
    node_size *= 2;

    left_longest = self->longest[LEFT_LEAF(index)];
    right_longest = self->longest[RIGHT_LEAF(index)];

    if (left_longest + right_longest == node_size)
      self->longest[index] = node_size;
    else
      self->longest[index] = MAX(left_longest, right_longest);
  }
}

// 获取内存块大小
// 参数: self - buddy系统的指针, offset - 内存块的偏移量
// 返回值: 内存块的大小
int buddy2_size(struct buddy2* self, int offset) {
  unsigned node_size, index = 0;

  assert(self && offset >= 0 && offset < self->size);

  node_size = 1;
  for (index = offset + self->size - 1; self->longest[index]; index = PARENT(index))
    node_size *= 2;

  return node_size;
}

// 打印buddy系统状态
// 参数: self - buddy系统的指针
void buddy2_dump(struct buddy2* self) {
  char canvas[65];
  int i, j;
  unsigned node_size, offset;

  if (self == NULL) {
    printf("buddy2_dump: (struct buddy2*)self == NULL");
    return;
  }

  if (self->size > 64) {
    printf("buddy2_dump: (struct buddy2*)self is too big to dump");
    return;
  }

  memset(canvas, '_', sizeof(canvas));
  node_size = self->size * 2;

  for (i = 0; i < 2 * self->size - 1; ++i) {
    if (IS_POWER_OF_2(i + 1))
      node_size /= 2;

    if (self->longest[i] == 0) {
      if (i >= self->size - 1) {
        canvas[i - self->size + 1] = '*';
      } else if (self->longest[LEFT_LEAF(i)] && self->longest[RIGHT_LEAF(i)]) {
        offset = (i + 1) * node_size - self->size;

        for (j = offset; j < offset + node_size; ++j)
          canvas[j] = '*';
      }
    }
  }
  canvas[self->size] = '\0';
  puts(canvas);
}
