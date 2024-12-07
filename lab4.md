# lab4

## 练习1：分配并初始化一个进程控制块（需要编码）
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

## 扩展练习 Challenge：
+ 说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？

