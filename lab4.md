# lab4

对实验报告的要求：

基于markdown格式来完成，以文本方式为主
填写各个基本练习中要求完成的报告内容
列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
列出你认为OS原理中很重要，但在实验中没有对应上的知识点
# 练习0：填写已有实验
本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

# 练习1：分配并初始化一个进程控制块（需要编码）
alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）
# 练习2：为新创建的内核线程分配资源（需要编码）
创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

调用alloc_proc，首先获得一块用户信息块。
为进程分配一个内核栈。
复制原进程的内存管理信息到新进程（但内核线程不必做此事）
复制原进程上下文到新进程
将新进程添加到进程列表
唤醒新进程
返回新进程号
请在实验报告中简要说明你的设计实现过程。请回答如下问题：

请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

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




# 练习3：编写proc_run 函数（需要编码）
proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
切换当前进程为要运行的进程。
切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。
实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
允许中断。
请回答如下问题：

在本实验的执行过程中，创建且运行了几个内核线程？
完成代码编写后，编译并运行代码：make qemu

如果可以得到如 附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

扩展练习 Challenge：
说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？