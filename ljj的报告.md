
## do_execve函数

`do_execve` 函数用于加载并执行一个新的程序。它会替换当前进程的内存空间，并将新的程序加载到内存中。以下是对该函数的详细讲解：

### 函数定义

```c
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm;
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
        return -E_INVAL;
    }
    if (len > PROC_NAME_LEN) {
        len = PROC_NAME_LEN;
    }

    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);

    if (mm != NULL) {
        cputs("mm != NULL");
        lcr3(boot_cr3);
        if (mm_count_dec(mm) == 0) {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
    }
    int ret;
    if ((ret = load_icode(binary, size)) != 0) {
        goto execve_exit;
    }
    set_proc_name(current, local_name);
    return 0;

execve_exit:
    do_exit(ret);
    panic("already exit: %e.\n", ret);
}
```

### 详细解释

1. **检查用户内存访问权限**：
   ```c
   if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
       return -E_INVAL;
   }
   ```
   - 调用 `user_mem_check` 函数检查当前进程的内存管理结构 `mm` 是否允许访问 `name` 指向的内存区域。
   - 如果检查失败，返回 `-E_INVAL` 错误码。

2. **处理进程名称长度**：
   ```c
   if (len > PROC_NAME_LEN) {
       len = PROC_NAME_LEN;
   }
   ```
   - 如果传入的进程名称长度 `len` 大于 `PROC_NAME_LEN`，则将 `len` 设置为 `PROC_NAME_LEN`，以确保名称长度不超过限制。

3. **复制进程名称**：
   ```c
   char local_name[PROC_NAME_LEN + 1];
   memset(local_name, 0, sizeof(local_name));
   memcpy(local_name, name, len);
   ```
   - 定义一个本地字符数组 `local_name`，用于存储进程名称。
   - 使用 `memset` 将 `local_name` 初始化为全零。
   - 使用 `memcpy` 将传入的进程名称复制到 `local_name` 中。

4. **处理当前进程的内存管理结构**：
   ```c
   if (mm != NULL) {
       cputs("mm != NULL");
       lcr3(boot_cr3);
       if (mm_count_dec(mm) == 0) {
           exit_mmap(mm);
           put_pgdir(mm);
           mm_destroy(mm);
       }
       current->mm = NULL;
   }
   ```
   - 如果当前进程的内存管理结构 `mm` 不为空，执行以下操作：
     - 输出调试信息 `"mm != NULL"`。
     - 调用 `lcr3(boot_cr3)` 切换到内核页表。
     - 调用 `mm_count_dec(mm)` 减少 `mm` 的引用计数，如果引用计数为 0，执行以下操作：
       - 调用 `exit_mmap(mm)` 释放内存映射。
       - 调用 `put_pgdir(mm)` 释放页目录表。
       - 调用 `mm_destroy(mm)` 销毁内存管理结构。
     - 将当前进程的内存管理结构 `current->mm` 设置为 `NULL`。

5. **加载新的程序**：
   ```c
   int ret;
   if ((ret = load_icode(binary, size)) != 0) {
       goto execve_exit;
   }
   ```
   - 调用 `load_icode` 函数加载新的程序。
   - 如果加载失败，跳转到 `execve_exit` 标签进行错误处理。

6. **设置进程名称**：
   ```c
   set_proc_name(current, local_name);
   ```
   - 调用 `set_proc_name` 函数设置当前进程的名称为 `local_name`。

7. **返回成功**：
   ```c
   return 0;
   ```

8. **错误处理**：
   ```c
   execve_exit:
       do_exit(ret);
       panic("already exit: %e.\n", ret);
   ```
   - 调用 `do_exit` 函数退出当前进程，并传递错误码 `ret`。
   - 调用 `panic` 函数输出错误信息并终止系统。

### 总结

`do_execve` 函数的主要步骤包括：

1. **检查用户内存访问权限**：确保当前进程可以访问传入的进程名称。
2. **处理进程名称长度**：确保进程名称长度不超过限制。
3. **复制进程名称**：将传入的进程名称复制到本地字符数组中。
4. **处理当前进程的内存管理结构**：释放当前进程的内存管理结构，并切换到内核页表。
5. **加载新的程序**：调用 `load_icode` 函数加载新的程序。
6. **设置进程名称**：设置当前进程的名称。
7. **返回成功**：返回 0 表示成功。
8. **错误处理**：在加载新的程序失败时，退出当前进程并输出错误信息。

通过这些步骤，`do_execve` 函数能够加载并执行一个新的程序，替换当前进程的内存空间，并将新的程序加载到内存中。

找到具有 2 个许可证类型的类似代码



## do_fork函数

`do_fork` 函数用于创建一个新的进程（即子进程），并将其初始化为可运行状态。这个函数实现了进程的复制，包括分配进程控制块（PCB）、设置内核栈、复制或共享内存管理结构、设置线程上下文、插入进程链表和哈希表、唤醒子进程等。以下是对该函数的详细讲解：

### 函数定义

```c
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;

    // 1. 调用 alloc_proc 分配一个 proc_struct
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }

    // 2. 设置子进程的父进程为当前进程
    proc->parent = current;
    assert(current->wait_state == 0);

    // 3. 调用 setup_kstack 为子进程分配内核栈
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }

    // 4. 调用 copy_mm 根据 clone_flags 复制或共享内存管理结构
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }

    // 5. 调用 copy_thread 设置子进程的 trapframe 和上下文
    copy_thread(proc, stack, tf);

    // 6. 插入 proc_struct 到 hash_list 和 proc_list，并设置进程关系
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    // 7. 唤醒子进程
    wakeup_proc(proc);

    // 8. 设置返回值为子进程的 PID
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```

### 详细解释

1. **检查进程数量限制**：
   ```c
   if (nr_process >= MAX_PROCESS) {
       goto fork_out;
   }
   ```
   - 检查当前进程数量是否达到最大限制 `MAX_PROCESS`。
   - 如果达到限制，设置返回值为 `-E_NO_FREE_PROC` 并跳转到 `fork_out` 标签。

2. **分配进程控制块（PCB）**：
   ```c
   if ((proc = alloc_proc()) == NULL) {
       goto fork_out;
   }
   ```
   - 调用 `alloc_proc` 函数分配一个新的 `proc_struct` 结构体。
   - 如果分配失败，设置返回值为 `-E_NO_MEM` 并跳转到 `fork_out` 标签。

3. **设置子进程的父进程**：
   ```c
   proc->parent = current;
   assert(current->wait_state == 0);
   ```
   - 将子进程的 `parent` 字段设置为当前进程 `current`。
   - 使用 `assert` 确保当前进程的 `wait_state` 为 0。

4. **分配内核栈**：
   ```c
   if (setup_kstack(proc) != 0) {
       goto bad_fork_cleanup_proc;
   }
   ```
   - 调用 `setup_kstack` 函数为子进程分配内核栈。
   - 如果分配失败，跳转到 `bad_fork_cleanup_proc` 标签进行清理。

5. **复制或共享内存管理结构**：
   ```c
   if (copy_mm(clone_flags, proc) != 0) {
       goto bad_fork_cleanup_kstack;
   }
   ```
   - 调用 `copy_mm` 函数根据 `clone_flags` 复制或共享内存管理结构。
   - 如果操作失败，跳转到 `bad_fork_cleanup_kstack` 标签进行清理。

6. **设置子进程的 trapframe 和上下文**：
   ```c
   copy_thread(proc, stack, tf);
   ```
   - 调用 `copy_thread` 函数设置子进程的 trapframe 和上下文。

7. **插入进程链表和哈希表，并设置进程关系**：
   ```c
   bool intr_flag;
   local_intr_save(intr_flag);
   {
       proc->pid = get_pid();
       hash_proc(proc);
       set_links(proc);
   }
   local_intr_restore(intr_flag);
   ```
   - 禁用中断并保存当前中断状态。
   - 调用 `get_pid` 函数分配一个唯一的 PID 给子进程。
   - 调用 `hash_proc` 函数将子进程插入到哈希表中。
   - 调用 `set_links` 函数设置进程关系。
   - 恢复中断状态。

8. **唤醒子进程**：
   ```c
   wakeup_proc(proc);
   ```
   - 调用 `wakeup_proc` 函数将子进程的状态设置为 `PROC_RUNNABLE`，使其可运行。

9. **设置返回值为子进程的 PID**：
   ```c
   ret = proc->pid;
   ```

10. **错误处理和清理**：
    ```c
    bad_fork_cleanup_kstack:
        put_kstack(proc);
    bad_fork_cleanup_proc:
        kfree(proc);
        goto fork_out;
    ```

### 总结

`do_fork` 函数的主要步骤包括：

1. 检查进程数量限制。
2. 分配进程控制块（PCB）。
3. 设置子进程的父进程。
4. 分配内核栈。
5. 复制或共享内存管理结构。
6. 设置子进程的 trapframe 和上下文。
7. 插入进程链表和哈希表，并设置进程关系。
8. 唤醒子进程。
9. 设置返回值为子进程的 PID。
10. 错误处理和清理。

通过这些步骤，`do_fork` 函数能够创建一个新的子进程，并将其初始化为可运行状态。

## load_icode

选中的代码是一个名为 `load_icode` 的函数，用于加载并解析一个处于内存中的 ELF 执行文件格式的应用程序。以下是该函数的执行流程：

1. **检查当前进程的内存管理结构**：
   ```c
   if (current->mm != NULL) {
       panic("load_icode: current->mm must be empty.\n");
   }
   ```
   如果当前进程已经有一个内存管理结构（`mm`），则触发 panic。

2. **创建新的内存管理结构**：
   ```c
   if ((mm = mm_create()) == NULL) {
       goto bad_mm;
   }
   ```

3. **创建新的页目录表**：
   ```c
   if (setup_pgdir(mm) != 0) {
       goto bad_pgdir_cleanup_mm;
   }
   ```

4. **解析 ELF 文件头和程序头**：
   ```c
   struct elfhdr *elf = (struct elfhdr *)binary;
   struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
   if (elf->e_magic != ELF_MAGIC) {
       ret = -E_INVAL_ELF;
       goto bad_elf_cleanup_pgdir;
   }
   ```

5. **遍历程序头表，加载各个段**：
第五步是遍历 ELF 文件的程序头表，并加载各个段到进程的内存空间中。具体步骤如下：

1. **遍历程序头表**：
   ```c
   for (; ph < ph_end; ph++) {
       if (ph->p_type != ELF_PT_LOAD) {
           continue;
       }
       if (ph->p_filesz > ph->p_memsz) {
           ret = -E_INVAL_ELF;
           goto bad_cleanup_mmap;
       }
       if (ph->p_filesz == 0) {
           continue;
       }
   ```

   - 遍历每个程序头表项 `ph`。
   - 如果程序头类型不是 `ELF_PT_LOAD`，则跳过。
   - 如果文件大小大于内存大小，返回错误。
   - 如果文件大小为零，跳过。

2. **设置虚拟内存标志和权限**：
   ```c
   vm_flags = 0, perm = PTE_U | PTE_V;
   if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
   if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
   if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
   if (vm_flags & VM_READ) perm |= PTE_R;
   if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
   if (vm_flags & VM_EXEC) perm |= PTE_X;
   ```

   - 根据程序头的标志设置虚拟内存标志 `vm_flags` 和权限 `perm`。

3. **映射内存区域**：
   ```c
   if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
       goto bad_cleanup_mmap;
   }
   ```

   - 调用 `mm_map` 函数将程序头指定的内存区域映射到进程的内存空间中。

4. **复制程序段内容到内存**：
   ```c
   unsigned char *from = binary + ph->p_offset;
   size_t off, size;
   uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

   end = ph->p_va + ph->p_filesz;
   while (start < end) {
       if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
           goto bad_cleanup_mmap;
       }
       off = start - la, size = PGSIZE - off, la += PGSIZE;
       if (end < la) {
           size -= la - end;
       }
       memcpy(page2kva(page) + off, from, size);
       start += size, from += size;
   }
   ```

   - 计算程序段的起始地址 `start` 和结束地址 `end`。
   - 循环分配页并将程序段内容复制到进程的内存中。

5. **初始化 BSS 段**：
   ```c
   end = ph->p_va + ph->p_memsz;
   if (start < la) {
       if (start == end) {
           continue;
       }
       off = start + PGSIZE - la, size = PGSIZE - off;
       if (end < la) {
           size -= la - end;
       }
       memset(page2kva(page) + off, 0, size);
       start += size;
       assert((end < la && start == end) || (end >= la && start == la));
   }
   while (start < end) {
       if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
           goto bad_cleanup_mmap;
       }
       off = start - la, size = PGSIZE - off, la += PGSIZE;
       if (end < la) {
           size -= la - end;
       }
       memset(page2kva(page) + off, 0, size);
       start += size;
   }
   ```

   - 计算 BSS 段的结束地址 `end`。
   - 循环分配页并将 BSS 段初始化为零。

通过以上步骤，`load_icode` 函数将 ELF 文件的各个程序段加载到进程的内存空间中，并初始化 BSS 段。

找到具有 2 个许可证类型的类似代码

6. **建立用户栈内存**：
   ```c
   if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
       goto bad_cleanup_mmap;
   }
   assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
   ...
   ```

7. **设置当前进程的内存管理结构和页目录表**：
   ```c
   mm_count_inc(mm);
   current->mm = mm;
   current->cr3 = PADDR(mm->pgdir);
   lcr3(PADDR(mm->pgdir));
   ```

8. **设置用户环境的 trapframe**：
   ```c
   struct trapframe *tf = current->tf;
   uintptr_t sstatus = tf->status;
   memset(tf, 0, sizeof(struct trapframe));
   tf->gpr.sp = USTACKTOP;
   tf->epc = elf->e_entry;
   tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
   ```

9. **错误处理和清理**：
   ```c
   bad_cleanup_mmap:
       exit_mmap(mm);
   bad_elf_cleanup_pgdir:
       put_pgdir(mm);
   bad_pgdir_cleanup_mm:
       mm_destroy(mm);
   bad_mm:
       goto out;
   ```

整个流程包括创建内存管理结构、设置页目录表、解析 ELF 文件、加载程序段、建立用户栈、设置 trapframe 以及错误处理和清理。
