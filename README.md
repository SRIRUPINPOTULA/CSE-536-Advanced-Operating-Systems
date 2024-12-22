# README for CSE 536: Advanced Operating Systems - Course Assignments

This repository contains the solutions for four assignments from the course **CSE 536: Advanced Operating Systems**. Each assignment involves implementing system-level functionalities in the **xv6 operating system** or designing low-level mechanisms related to security, memory management, user-level threading, and virtualization.

## Table of Contents

1. [Assignment 1: Boot ROM, Bootloader, and Secure Boot with PMP](#assignment-1-boot-rom-bootloader-and-secure-boot-with-pmp)
2. [Assignment 2: Process Memory Management in xv6](#assignment-2-process-memory-management-in-xv6)
3. [Assignment 3: User-Level Threads in xv6](#assignment-3-user-level-threads-in-xv6)
4. [Assignment 4: Trap and Emulate Virtualization](#assignment-4-trap-and-emulate-virtualization)

---

### **Assignment 1: Boot ROM, Bootloader, and Secure Boot with PMP**

#### **Objective**:
In this assignment, we explore and implement foundational boot mechanisms in a system, including the **Boot ROM**, **Bootloader**, and **Secure Boot**, with an emphasis on **Physical Memory Protection (PMP)** to ensure system integrity during startup.

#### **Key Tasks**:
- Implement a **Boot ROM** that initiates the boot process.
- Develop the **Bootloader** to load the kernel and start the OS.
- Ensure system security using **Secure Boot** combined with **Physical Memory Protection** to protect memory during the boot phase.

#### **Key Concepts**:
- System boot process
- Secure Boot mechanisms
- Memory protection via PMP

#### **Deliverables**:
- Functional implementations of the Boot ROM, Bootloader, and Secure Boot with PMP integration.

---

### **Assignment 2: Process Memory Management in xv6**

#### **Objective**:
This assignment extends the **xv6 operating system's** memory management, focusing on **on-demand paging**, **copy-on-write (CoW)**, and **page swapping**.

#### **Key Tasks**:
- Modify **xv6** to implement **on-demand binary loading** for processes.
- Design a **page fault handler** to load pages dynamically.
- Implement **on-demand heap memory** allocation and **page swapping** to disk.
- Optimize the `fork()` system call using **CoW** to share memory between parent and child processes.

#### **Deliverables**:
- Updated code with memory management mechanisms like CoW and page swapping.
- Documentation answering all the questions in the assignment handout.

---

### **Assignment 3: User-Level Threads in xv6**

#### **Objective**:
The goal of this assignment is to implement **user-level threads (ULT)** in **xv6**. This involves designing a thread management library (ULTLib) and implementing thread scheduling, context switching, and time management for user-level threads.

#### **Key Tasks**:
- Implement a **thread management library** for creation, yielding, and destruction of threads.
- Implement a **user-level scheduler** using various scheduling algorithms like Round-Robin, First-Come-First-Serve, and Priority-based scheduling.
- Create a system call `ctime` for getting the current system time.
- Implement **context switching** in assembly (`ulthread_context_switch`).

#### **Deliverables**:
- Code for the ULT library, thread scheduler, and system calls.
- A set of test cases for verifying thread management and scheduling.

---

### **Assignment 4: Trap and Emulate Virtualization**

#### **Objective**:
This assignment focuses on implementing **virtualization** with a **Trap and Emulate** technique. The goal is to simulate a **virtual machine (VM)** running in user mode, where privileged instructions are trapped and emulated by the **Virtual Machine Monitor (VMM)**.

#### **Key Tasks**:
- **Initialize the VM state** with privileged register management.
- Implement **trap handling** for privileged instructions like `csrr`, `csrw`, `sret`, `mret`, and `ecall`.
- **Emulate** these instructions in a **VM** environment, handling transitions between execution modes (User, Supervisor, Machine).
- Implement **Physical Memory Protection (PMP)** within the VM by emulating page table protections.

#### **Deliverables**:
- Implementation of the trap and emulation mechanism for privileged instructions.
- Correctly functioning **memory protection** emulation via PMP.
- Test cases for validating the VM state transitions and instruction emulation.

---

## Installation and Setup

To set up the repository and start working on the assignments:

1. **Build the Project**:
   - Once you’ve set up **xv6**, use the following commands to compile and test the code:
     ```bash
     make
     make qemu
     ```

2. **Testing**:
   - You can run the provided test scripts to verify the correctness of your implementation. Each assignment contains test cases that can be run using the **QEMU** emulator.

---

## License

This repository is for educational purposes as part of the **CSE 536: Advanced Operating Systems** course. Please use the code only for academic learning and assignments.
