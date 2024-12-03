#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
    bool intr_flag; // 定义一个布尔变量用于保存中断状态
    list_entry_t *le, *last; // 定义两个指向进程列表项的指针
    struct proc_struct *next = NULL; // 定义一个指向下一个要运行的进程的指针，并初始化为NULL
    local_intr_save(intr_flag); // 关闭中断，并保存当前中断状态到intr_flag
    {
        current->need_resched = 0; // 将当前进程的need_resched标志置为0
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 确定从哪个进程开始查找下一个可运行进程
        le = last; // 初始化le为last
        do {
            if ((le = list_next(le)) != &proc_list) { // 获取下一个进程列表项
                next = le2proc(le, list_link); // 获取进程结构体指针
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行
                    break; // 跳出循环
                }
            }
        } while (le != last); // 如果没有遍历完所有进程列表项，则继续循环
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
            next = idleproc; // 将空闲进程设置为下一个要运行的进程
        }
        next->runs ++; // 增加下一个要运行进程的运行次数计数器
        if (next != current) { // 如果下一个要运行的进程不是当前进程
            proc_run(next); // 切换到下一个进程运行
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
void
schedule(void) {
    bool intr_flag; // 定义一个布尔变量用于保存中断状态
    list_entry_t *le, *last; // 定义两个指向进程列表项的指针
    struct proc_struct *next = NULL; // 定义一个指向下一个要运行的进程的指针，并初始化为NULL
    local_intr_save(intr_flag); // 关闭中断，并保存当前中断状态到intr_flag
    {
        current->need_resched = 0; // 将当前进程的need_resched标志置为0
        last = (current == idleproc) ? &proc_list : &(current->list_link); // 确定从哪个进程开始查找下一个可运行进程
        le = last; // 初始化le为last
        do {
            if ((le = list_next(le)) != &proc_list) { // 获取下一个进程列表项
                next = le2proc(le, list_link); // 获取进程结构体指针
                if (next->state == PROC_RUNNABLE) { // 如果进程状态为可运行
                    break; // 跳出循环
                }
            }
        } while (le != last); // 如果没有遍历完所有进程列表项，则继续循环
        if (next == NULL || next->state != PROC_RUNNABLE) { // 如果没有找到可运行的进程
            next = idleproc; // 将空闲进程设置为下一个要运行的进程
        }
        next->runs ++; // 增加下一个要运行进程的运行次数计数器
        if (next != current) { // 如果下一个要运行的进程不是当前进程
            proc_run(next); // 切换到下一个进程运行
        }
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}

