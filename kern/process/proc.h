#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle
enum proc_state {
    PROC_UNINIT = 0,  // uninitialized
    PROC_SLEEPING,    // sleeping
    PROC_RUNNABLE,    // runnable(maybe running)
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource
};

struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

extern list_entry_t proc_list;

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

#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

