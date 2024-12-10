# lab4

## 练习1：分配并初始化一个进程控制块（需要编码）
alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

    【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

    请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）


### 设计实现过程

根据进程控制块的结构体，以及其成员变量之间的含义
```c
//进程控制块
struct proc_struct {
    enum proc_state state;                      // Process state        //进程状态
    int pid;                                    // Process ID
    int runs;                                   // the running times of Proces      //记录进程被调度运行的次数。
    uintptr_t kstack;                           // Process kernel stack     //进程内核栈  //指向进程的内核栈的指针（无符号整数类型）
    volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?       //是否需要重新调度
    struct proc_struct *parent;                 // the parent process       //父进程
    struct mm_struct *mm;                       // Process's memory management field        //进程的内存管理结构
    struct context context;                     // Switch here to run process       //进程上下文
    struct trapframe *tf;                       // Trap frame for current interrupt     //当前中断的陷阱帧
    uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)      //CR3寄存器：页目录表的基地址
    uint32_t flags;                             // Process flag      //进程标志
    char name[PROC_NAME_LEN + 1];               // Process name     //进程名
    list_entry_t list_link;                     // Process link list        //进程链表
    list_entry_t hash_link;                     // Process hash list        //进程哈希表
};
```

我们可以对其进行初始化

```c
proc->state = PROC_UNINIT;//将进程初始化为 未初始化状态
    proc->pid = -1;
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0; //bool值：需要重新调度以释放CPU？
    proc->parent = NULL;
    proc->mm = NULL;
    memset(&(proc->context), 0, sizeof(struct context));//使用 memset 将 context 结构体的所有字段初始化为 0。
    proc->tf = NULL;
    proc->cr3 = boot_cr3;//boot_cr3 是 boot_pgdir的物理地址
    proc->flags = 0;    //保存进程的标志信息，用于记录进程的特定属性或状态。（无符号整数类型）
    memset(proc->name, 0, PROC_NAME_LEN + 1);//使用 memset 将 name 字符数组的所有元素初始化为 0。
```
其中pid由于需要标识唯一进程，需要设为-1，因为其从0开始

### 成员变量含义和在本实验中的作用：

+ struct context context：保存进程执行的上下文，也就是关键的几个寄存器的值。在进程切换时，操作系统需要保存当前进程的寄存器状态，并从新进程的 context 结构中恢复寄存器状态。在通过proc_run切换到CPU上运行时，需要调用switch_to进行进程切换，将将当前进程的寄存器状态保存到 context 结构中，并从新进程的 context 结构中恢复寄存器状态，以便下次切换回去时能够继续之前的运行状态。
  
+ struct trapframe *tf：用于保存进程的中断帧信息，包括32个通用寄存器、异常相关的寄存器。当进程从用户空间跳转到内核空间时，中断或系统调用会改变寄存器的值。我们可以通过调整中断帧来使的系统调用返回特定的值。比如可以利用s0和s1传递线程执行的函数和参数；在创建子线程时，会将中断帧中的a0设为0。

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


## 练习2：为新创建的内核线程分配资源（需要编码）
创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

+ 调用alloc_proc，首先获得一块用户信息块。
+ 为进程分配一个内核栈。
+ 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
+ 复制原进程上下文到新进程
+ 将新进程添加到进程列表
+ 唤醒新进程
+ 返回新进程号
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

+ 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

在 `ucore` 中，`get_pid` 函数用于为每个新创建的进程分配一个唯一的进程ID (pid)。通过分析 `get_pid` 函数的实现，可以确定 `ucore` 是否能够为每个新 fork 的线程分配一个唯一的 id。

在 `get_pid` 函数中维护了两个静态变量，`last_pid`与`next_safe`,`last_pid`用于分配pid,`next_safe`用于跟踪当前进程列表中未被使用且大于 `last_pid` 的最小 pid.

1. **初始化和递增 `last_pid`**：
   ```c
   if (++last_pid >= MAX_PID) {
       last_pid = 1;
       goto inside;
   }
   ```
   - 每次调用 `get_pid` 时，首先递增 `last_pid`。
   - 如果 `last_pid` 超过 `MAX_PID`，则重置为 1。

   如果没超过并且这时候`last_pid`安全的话，直接返回`last_pid`。
   否则开始遍历进程链表：


   ```c
   if (last_pid >= next_safe) {
   inside:
       next_safe = MAX_PID;
   repeat:
       le = list;
       while ((le = list_next(le)) != list) {
           proc = le2proc(le, list_link);
           if (proc->pid == last_pid) {
               if (++last_pid >= next_safe) {
                   if (last_pid >= MAX_PID) {
                       last_pid = 1;
                   }
                   next_safe = MAX_PID;
                   goto repeat;
               }
           }
           else if (proc->pid > last_pid && next_safe > proc->pid) {
               next_safe = proc->pid;
           }
       }
   }
   ```
   - 如果 `last_pid` 超过 `next_safe`，则重置 `next_safe` 为 `MAX_PID` 并重新开始检查。
   - 遍历进程列表，检查每个进程的 pid。
   - 如果发现某个进程的 pid 与 `last_pid` 相同，则递增 `last_pid` 并重新开始检查。
   - 如果发现某个进程的 pid 大于 `last_pid` 且小于 `next_safe`，则更新 `next_safe`。

最后返回唯一的pid：
   ```c
   return last_pid;
   ```


通过上述分析，可以得出以下结论：

- `get_pid` 函数通过递增 `last_pid` 并检查进程列表中的 pid，确保每次分配的 pid 都是唯一的。
- 如果 `last_pid` 已经被使用，则递增 `last_pid` 并继续检查，直到找到一个未被使用的 pid。
- `next_safe` 用于跟踪当前进程列表中未被使用且大于 `last_pid` 的最小 pid，确保 `last_pid` 是安全的。

因此，`ucore` 能够为每个新 fork 的线程分配一个唯一的 id。通过遍历进程列表并检查每个进程的 pid，`get_pid` 函数能够找到一个未被使用的 pid 并返回，从而确保每个新创建的进程或线程都有一个唯一的 pid。

## 练习3：编写proc_run 函数（需要编码）
proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

+ 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
+ 禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
+ 切换当前进程为要运行的进程。
+ 切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。
+ 实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
+ 允许中断。
请回答如下问题：

+ 在本实验的执行过程中，创建且运行了几个内核线程？
完成代码编写后，编译并运行代码：make qemu

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。


### 代码实现

```c
void
proc_run(struct proc_struct *proc) {
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


1. **进程比较**：
   ```c
   if (proc != current) {
   ```
   首先，函数检查传入的目标进程 `proc` 是否与当前正在运行的进程 `current` 不同。如果相同，则无需进行任何操作，直接返回；如果不同，则需要进行进程切换。

2. **中断处理**：
   ```c
   bool intr_flag;
   local_intr_save(intr_flag);
   ```
   使用 `local_intr_save` 宏（或函数）禁用中断，并保存当前的中断状态到 `intr_flag` 变量中。这是为了防止在进程切换过程中发生中断，确保切换操作的原子性和一致性。

3. **保存当前和目标进程**：
   ```c
   struct proc_struct *prev = current, *next = proc;
   ```
   定义两个指针 `prev` 和 `next`，分别指向当前进程和目标进程。这有助于后续的上下文切换操作。

4. **更新当前进程**：
   ```c
   current = proc;
   ```
   将全局变量 `current` 更新为目标进程 `proc`，表示当前运行的进程已经切换为目标进程。

5. **修改 CR3 寄存器**：
   ```c
   lcr3(next->cr3);
   ```
   使用 `lcr3` 函数修改 CR3 寄存器的值。CR3 寄存器保存了当前进程的页目录基址，修改它意味着切换到目标进程的虚拟地址空间。

6. **上下文切换**：
   ```c
   switch_to(&(prev->context), &(next->context));
   ```
   调用 `switch_to` 函数，传入前一个进程和目标进程的上下文结构体指针。`switch_to` 负责保存前一个进程的上下文（如寄存器状态）并恢复目标进程的上下文，从而实现实际的上下文切换。

7. **恢复中断状态**：
   ```c
   local_intr_restore(intr_flag);
   ```
   使用 `local_intr_restore` 宏（或函数）恢复之前保存的中断状态。这确保了在进程切换完成后，中断状态与切换前保持一致，系统可以继续正常响应中断。

### 在本实验的执行过程中，创建且运行了几个内核线程？
2个，分别为idle和init线程。

## 扩展练习 Challenge：
+ 说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？

### 宏的定义

```c
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)

#define local_intr_restore(x) __intr_restore(x);
```

### 工作原理

1. **禁用中断并保存状态**：
   
   ```c
   bool intr_flag;
   local_intr_save(intr_flag);
   ```
   
   - **`local_intr_save(intr_flag);`**：
     - 调用 `__intr_save()` 函数。
     - `__intr_save()` 检查当前中断是否启用。
     - 如果中断是启用的，禁用中断并返回 `true`。
     - 如果中断已经禁用，返回 `false`。
     - 结果保存在 `intr_flag` 变量中，记录之前的中断状态。

3. **恢复中断状态**：

   ```c
   local_intr_restore(intr_flag);
   ```
   
   - **`local_intr_restore(intr_flag);`**：
     - 调用 `__intr_restore(intr_flag)` 函数。
     - 如果 `intr_flag` 是 `true`，表示之前中断是启用的，则重新启用中断。
     - 如果 `intr_flag` 是 `false`，表示之前中断已经禁用，则保持中断禁用状态。

### 总结

- **`local_intr_save(intr_flag);`**：检查当前中断状态，如果中断是开启的，就禁用中断并记录状态。
- **`local_intr_restore(intr_flag);`**：根据之前记录的状态，恢复中断的开启或保持禁用。