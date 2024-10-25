### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


不断的分配，直到引发异常trap
为了将内核自行探测内存大小的方法与异常处理机制结合，核心思路是：在内核通过逐页访问物理内存探测其大小的过程中，如果访问到非法的或不可用的物理地址，处理器会触发异常（例如“加载/存储错误”异常），此时内核通过异常处理机制捕获这些异常，确保探测过程安全且不会崩溃。

下面是具体的步骤和改进：

#### 1. **异常处理与内存探测的结合**
在进行物理内存探测时，当访问无效的物理地址，系统会产生如“加载错误（`FAULT_LOAD`）”或“存储错误（`FAULT_STORE`）”的异常。你可以通过修改异常处理器，使其识别出当前正在进行内存探测操作，并在捕获异常时终止探测过程，记录有效的内存范围。

我们可以通过在异常处理器中增加特定标记来区分探测期间的异常和其他异常。

#### 2. **修改异常处理器**
首先，扩展 `exception_handler`，增加对探测期间产生的异常的处理。为此，我们可以引入一个全局变量 `is_mem_probe`，当内存探测过程开始时将其设为 `true`，探测结束后再将其恢复为 `false`。

```c
bool is_mem_probe = false;  // 标记是否在进行内存探测

void exception_handler(struct trapframe *tf) {
    // 检查是否在进行内存探测
    if (is_mem_probe) {
        switch (tf->cause) {
            case CAUSE_FAULT_LOAD:
            case CAUSE_FAULT_STORE:
                // 在内存探测时，加载或存储错误表示内存探测到无效区域
                // 直接返回以终止探测过程
                return;
            default:
                // 如果发生其他异常类型，在探测期间未处理的异常应当终止探测
                print_trapframe(tf);
                panic("Unexpected exception during memory probing!");
        }
    }
    
    // 正常异常处理
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            break;
        case CAUSE_BREAKPOINT:
            break;
        case CAUSE_MISALIGNED_LOAD:
            break;
        case CAUSE_FAULT_LOAD:
            break;
        case CAUSE_MISALIGNED_STORE:
            break;
        case CAUSE_FAULT_STORE:
            break;
        case CAUSE_USER_ECALL:
            break;
        case CAUSE_SUPERVISOR_ECALL:
            break;
        case CAUSE_HYPERVISOR_ECALL:
            break;
        case CAUSE_MACHINE_ECALL:
            break;
        default:
            print_trapframe(tf);
            panic("Unknown exception!");
    }
}
```

#### 3. **改进内存探测函数**
接下来，在内存探测函数 `detect_physical_memory_size` 中，在探测开始时设置 `is_mem_probe` 为 `true`，当探测完成后将其恢复为 `false`。同时，我们不需要使用过于复杂的写读测试，只需要在遇到加载或存储异常时捕获并停止探测即可。

```c
static size_t detect_physical_memory_size(void) {
    uint64_t current_addr = mem_probe_start;  // 从物理内存起始地址开始探测
    size_t detected_pages = 0;                // 已检测到的可用物理页面数量

    // 标记开始内存探测
    is_mem_probe = true;

    while (current_addr < mem_probe_end) {
        volatile uint64_t *test_addr = (volatile uint64_t *)PADDR(current_addr);

        // 尝试访问该地址，捕获任何加载/存储错误异常
        // 这里不需要显式地捕获错误，异常处理器会处理无效访问
        uint64_t value = *test_addr;

        // 如果成功访问，继续探测下一页
        current_addr += PGSIZE;
        detected_pages++;
    }

    // 探测完成，恢复标记
    is_mem_probe = false;

    return detected_pages;
}
```

在这个版本中，如果访问了无效的内存地址，系统将触发加载/存储错误异常。此时，异常处理器会检查 `is_mem_probe` 变量，判断当前正在进行内存探测，并返回以终止探测过程。这种方式能够确保在探测过程中不会导致系统崩溃。

#### 4. **将内存探测集成到内存管理初始化中**
最后，将内存探测逻辑集成到内存管理器的初始化流程中。修改 `page_init` 函数，使其在初始化过程中首先探测物理内存大小，并根据探测结果设置物理内存页数。

```c
static void page_init(void) {
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END;

    cprintf("physical memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin, mem_end - 1);

    // 调用内存探测函数，获取实际的物理内存页数
    size_t detected_pages = detect_physical_memory_size();
    cprintf("Detected physical memory pages: %lu\n", detected_pages);

    // 根据探测到的页面数量初始化
    npage = detected_pages;

    // 初始化页面数组，指向内核后面的页面
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    // 将所有页面标记为内核保留状态
    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);
    }

    // 标记可用的物理内存区域
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}
```

#### 5. **总结**
通过结合异常处理机制，内核能够在探测物理内存时安全地捕获无效地址访问，避免系统崩溃。这种方法不仅有效地探测了系统中实际可用的物理内存，还充分利用了异常处理机制确保探测过程的安全性。

主要改进点如下：
1. **标记内存探测过程**：通过 `is_mem_probe` 标记探测期间的异常，异常处理器可以做出适当反应。
2. **探测期间异常捕获**：在异常处理器中，根据 `cause` 判断当前是否在进行内存探测，并安全退出探测过程。
3. **改进探测流程**：探测内存时不必显式捕获错误，由异常处理器处理非法访问即可终止探测。

这种方案确保了探测过程中不会出现系统崩溃，并且可以安全、稳定地确定系统的物理内存大小。