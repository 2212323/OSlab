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