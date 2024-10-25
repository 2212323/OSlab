#include <pmm.h>
#include <list.h>
#include <buddy_pmm.h>
#include <stdio.h>
#include <assert.h>
#include <memlayout.h>

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define ALLOC malloc
#define FREE free

#define PAGE_COUNT 16384

static unsigned fixsizeup(unsigned n) {
    // 如果n已经是2的幂次方，直接返回n
    if (n && !(n & (n - 1))) {
        return n;
    }

    unsigned power = 1;

    // 将n的最高位1的后面所有位都变为1
    while (n > 0) {
        n >>= 1;
        power <<= 1;
    }

    return power;
}

static unsigned fixsizedown(unsigned n){
  n=(fixsizeup(n)/2);
  return n;
}

buddy2* self;
buddy2 buddy;

struct Page* unsigned2page(unsigned i){
  //TODO
  //OK
    struct Page* p= self->base+i;
    return p;
}
unsigned page2unsigned(struct Page* p){
  //TODO
  //OK
    return (p-self->base);
}
// 创建一个新的buddy系统
// 参数: size - buddy系统的大小，必须是2的幂
// 返回值: 成功返回buddy系统的指针，失败返回NULL
void buddy2_init()
{
  self=&buddy;
  cprintf("buddy2_init start\n");
  self->size=0;
  self->longest[0]=0;
  self->free=0;
   //cprintf("size:::%d\n",self->size);
}
void buddy2_new(struct  Page* base, size_t size) {
  size=PAGE_COUNT;
  self->base=base;
  assert(size > 0);
  struct Page *p = base;
  //清理内存块中的每一页
  for (; p != base + size; p ++) {
      assert(PageReserved(p));    //确保每一页都是保留的（即未被使用）。
      p->flags = p->property = 0; //清空页的标志和属性
      set_page_ref(p, 0); //设置页的引用计数为0
  }
  //处理内存块的第一页
  base->property = size; //将内存块的属性设置为页数 n。
  SetPageProperty(base);  //设置内存块的属性标志，表示这是一个有效的内存块

  //将内存块添加到空闲页完全二叉树中

  unsigned node_size;
  int i;

  //self = (struct buddy2*)ALLOC(2 * size * sizeof(unsigned));//分配二叉树的空间
  self->size = size;//设置buddy系统的大小
      cprintf("初始化内存页数:%d\n",self->size);
  node_size = size * 2;//设置节点大小
 //初始化buddy系统的最大可用块大小，开机
  for (i = 0; i < 2 * size - 1; ++i) {
    if (IS_POWER_OF_2(i+1))
      node_size /= 2;
    self->longest[i] = node_size;//longest[i]代表的就是第i个节点的最大可用块大小
                                 //也就是以以这个节点为根节点的子树中最大的可用块大小
                                 //8 44 2222 11111111
  }

  self->free=size;
  cprintf("buddy2_new end\n");
}

// 分配内存块
// 参数: self - buddy系统的指针, size - 要分配的内存块大小
// 返回值: 成功返回内存块的偏移量，失败返回-1
struct Page* buddy2_alloc(size_t block) {
  unsigned index = 0; // 初始化索引为0
  unsigned node_size; // 节点大小
  unsigned offset = 0; // 偏移量

  if (self == NULL) // 如果buddy系统指针为空
    return NULL; // 返回-1表示失败

  if (block <= 0) // 如果请求的大小小于等于0
    block = 1; // 将大小设为1
  else if (!IS_POWER_OF_2(block)) // 如果请求的大小不是2的幂
    block = fixsizeup(block); // 调整大小为2的幂

  if (self->longest[index] < block) // 如果根节点的最大可用块小于请求的大小
    return NULL; // 返回-1表示失败

  // 遍历树找到合适的块
  for (node_size = self->size; node_size != block; node_size /= 2) {
    if (self->longest[LEFT_LEAF(index)] >= block) // 如果左子节点的最大可用块大于等于请求的大小
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

  struct Page* p=unsigned2page(offset);
  ClearPageProperty(p); // 清除真实物理内存已分配块的属性
  self->free -= block; // 更新buddy系统的大小 //0003
  return p; // 返回偏移量
}

// 释放内存块
// 参数: self - buddy系统的指针, offset - 要释放的内存块的偏移量
// 释放内存块
// 参数: Freebase - 要释放的内存块的基地址, n - 要释放的内存块大小
static void buddy2_free(struct Page *Freebase,size_t NoUse) {
  int offset = page2unsigned(Freebase); // 获取内存块的偏移量
  unsigned node_size, index = 0;
  unsigned left_longest, right_longest;

  assert(self && offset >= 0 && offset < self->size); // 确保buddy系统指针不为空且偏移量合法

  node_size = 1;
  index = offset + self->size - 1; // 计算节点索引

  // 找到空闲节点
  for (; self->longest[index]; index = PARENT(index)) {
    node_size *= 2;
    if (index == 0)
      return; // 如果已经到达根节点，直接返回
  }

  self->longest[index] = node_size; // 将节点标记为空闲
  struct Page* p=unsigned2page(index);
  SetPageProperty(p);//设置内存块的属性标志，表示这是一个有效的内存块
  self->free += node_size; // 更新buddy系统的大小 ///0003

  // 更新父节点的最大可用块大小
  while (index) {
    index = PARENT(index); // 获取父节点索引
    node_size *= 2;

    left_longest = self->longest[LEFT_LEAF(index)]; // 获取左子节点的最大可用块大小
    right_longest = self->longest[RIGHT_LEAF(index)]; // 获取右子节点的最大可用块大小

    if (left_longest + right_longest == node_size) // 如果左右子节点的最大可用块大小之和等于当前节点大小
      self->longest[index] = node_size; // 将当前节点标记为空闲

    else
      self->longest[index] = MAX(left_longest, right_longest); // 否则更新当前节点的最大可用块大小
  }
}

// 获取内存块大小
// 参数: self - buddy系统的指针, offset - 内存块的偏移量
// 返回值: 内存块的大小
int buddy2_size(int offset) {
  unsigned node_size, index = 0;

  assert(self && offset >= 0 && offset < self->size);

  node_size = 1;
  for (index = offset + self->size - 1; self->longest[index]; index = PARENT(index))
    node_size *= 2;

  return node_size;
}

//返回空闲页的数量
static size_t
buddy_nr_free_pages(void) {
    return self->free;
}
// static void
// buddy_check(void) {

//   // cprintf("buddy_check start\n");
//   // cprintf("buddy_check start\n");
// }
static void
buddy_check(void) {
    struct Page *a=buddy2_alloc(999);
    struct Page *p= self->base;
    cprintf("当前空余内存大小:%d\n",buddy_nr_free_pages());
    struct Page *b=buddy2_alloc(444);
    cprintf("当前空余内存大小:%d\n",buddy_nr_free_pages());
    struct Page *c=buddy2_alloc(2000);
    cprintf("当前空余内存大小:%d\n",buddy_nr_free_pages());
    buddy2_free(c,0);
    cprintf("当前空余内存大小:%d\n",buddy_nr_free_pages());
    buddy2_free(a,0);
    cprintf("当前空余内存大小:%d\n",buddy_nr_free_pages());
}
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy2_init,
    .init_memmap = buddy2_new,
    .alloc_pages = buddy2_alloc,
    .free_pages = buddy2_free,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};