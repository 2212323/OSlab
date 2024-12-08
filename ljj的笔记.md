# 执行流程
从init.c中调用proc_init()函数，


# 练习1：分配并初始化一个进程控制块（需要编码）
alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

    【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

    请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）


成员变量含义和作用：

+ struct context context：保存进程执行的上下文，也就是关键的几个寄存器的值。用于进程切换中还原之前的运行状态。在通过proc_run切换到CPU上运行时，需要调用switch_to将原进程的寄存器保存，以便下次切换回去时读出，保持之前的状态。
  
+ struct trapframe *tf：保存了进程的中断帧（32个通用寄存器、异常相关的寄存器）。在进程从用户空间跳转到内核空间时，系统调用会改变寄存器的值。我们可以通过调整中断帧来使的系统调用返回特定的值。比如可以利用s0和s1传递线程执行的函数和参数；在创建子线程时，会将中断帧中的a0设为0。

中断处理：当中断或异常发生时，CPU 会自动保存当前的寄存器状态到陷阱帧（trapframe）中。操作系统可以通过 tf 成员变量访问这些信息，以便处理中断或异常。

系统调用：在处理系统调用时，陷阱帧用于保存系统调用的参数和返回值。操作系统可以通过 tf 成员变量访问和修改这些信息。

在 forkret 函数中，可以看到 tf 成员变量在中断处理中的作用：
```c
static void forkret(void) {
    forkrets(current->tf);
}
```
forkrets(current->tf)：在新进程第一次运行时，恢复陷阱帧 tf 中保存的寄存器状态。



```c
struct trapframe {
    struct pushregs gpr;    //总共32个寄存器
    uintptr_t status;    //状态寄存器
    uintptr_t epc;  //程序计数器
    uintptr_t badvaddr; //发生异常的地址
    uintptr_t cause;    //异常原因
};
```



在 proc_struct结构体中，`kstack` 字段用于记录分配给该进程/线程的内核栈的位置。内核栈在操作系统中起着至关重要的作用，特别是在进程切换和中断处理过程中。以下是对 `kstack` 字段的详细解释及其作用：

### `kstack` 字段的含义

内核栈是每个进程在内核态运行时使用的栈，用于保存函数调用信息、中断处理信息等

```cpp
uintptr_t kstack; // Process kernel stack
```

- **类型**：无符号整数类型（`uintptr_t`）。
- **作用**：指向进程的内核栈的指针，记录了分配给该进程/线程的内核栈的位置。

### 内核栈的作用

1. **进程切换**：
   - 当内核准备从一个进程切换到另一个进程时，需要根据 `kstack` 的值正确设置任务状态段（TSS），以便在进程切换后再发生中断时能够使用正确的栈。
   - 具体来说，进程切换时，内核会保存当前进程的上下文信息到其内核栈中，并从下一个进程的内核栈中恢复上下文信息。

2. **中断处理**：
   - 对于普通进程，当发生特权级改变（如从用户态切换到内核态）时，内核栈用于保存被打断的硬件信息。
   - 内核栈位于内核地址空间，并且是不共享的，每个线程都有自己的内核栈。

3. **内核栈的分配和回收**：
   - 在创建进程时，操作系统会分配内核栈空间。uCore 在创建进程时分配了 2 个连续的物理页（参见 `memlayout.h` 中 `KSTACKSIZE` 的定义）作为内核栈的空间。
   - 当进程退出时，内核能够根据 `kstack` 的值快速定位栈的位置并进行回收。

### 示例代码

以下是一个示例代码，展示了 `kstack` 字段在进程切换和中断处理中的作用：

#### 进程切换

```c
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = proc;
            lcr3(next->cr3);
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
}
```

- 在 `proc_run` 函数中，进程切换时会保存当前进程的上下文信息到其内核栈中，并从下一个进程的内核栈中恢复上下文信息。

#### 中断处理

```c
void interrupt_handler(struct trapframe *tf) {
    struct proc_struct *proc = current;
    proc->tf = tf;
    // 处理中断
}
```

- 在中断处理函数中，内核栈用于保存中断发生时的寄存器状态和其他硬件信息。

### 总结

- **`kstack` 字段的含义**：记录分配给该进程/线程的内核栈的位置。
- **内核栈的作用**：
  1. **进程切换**：在进程切换时，内核栈用于保存当前进程的上下文信息，并从下一个进程的内核栈中恢复上下文信息。
  2. **中断处理**：在发生特权级改变时，内核栈用于保存被打断的硬件信息。
  3. **内核栈的分配和回收**：在创建进程时分配内核栈空间，在进程退出时根据 `kstack` 的值快速定位栈的位置并进行回收。

通过 `kstack` 字段，操作系统能够有效地管理每个进程的内核栈，确保进程切换和中断处理的正确性和效率。

找到具有 1 个许可证类型的类似代码



### hash_link的作用
hash_link 是 proc_struct 结构体中的一个字段，用于将进程链接到进程哈希表中。它的主要作用是通过哈希表实现对进程的快速查找和管理

```c
// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);//le2proc(le, hash_link)：将链表节点转换为进程结构体。
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}
```
pid_hashfn(pid)：计算进程 ID 的哈希值，确定进程在哈希表中的位置。
hash_list + pid_hashfn(pid)：获取哈希表中对应位置的链表头。
list：指向哈希表中对应位置的链表头。
while ((le = list_next(le)) != list)：遍历链表，直到回到链表头。

### proc_struct

flags 字段可以用来记录进程的特定属性，例如进程是否处于某种特殊状态，是否具有某些特权等。
通过设置不同的标志位，可以表示进程的不同属性。