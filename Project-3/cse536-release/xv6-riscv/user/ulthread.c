/* CSE 536: User-Level Threading Library */
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "user/ulthread.h"

/* Standard definitions */
#include <stdbool.h>
#include <stddef.h> 
#include <time.h>

#define MAX_INT ((1<<31)-1)
ulthread ul_thread[MAXULTHREADS];
enum ulthread_scheduling_algorithm algorithm;

int current_tid=0;
int prev_tid=0;

/* Get thread ID */
int get_current_tid(void) {
    return current_tid;
}

/* Thread initialization */
void ulthread_init(int schedalgo) {
    //Kernel Thread Initialisation
    for(int i=0;i<MAXULTHREADS;i++)
        ul_thread[i].tid = -1;
    //printf("THe state of the kernel thread: %d",ul_thread[0].tid);
    ul_thread[0].state = RUNNABLE;
    ul_thread[0].tid = 0;
    //printf("THe state of the kernel thread: %d",ul_thread[0].tid);
    algorithm = schedalgo;
  
}

/* Thread creation */
bool ulthread_create(uint64 start, uint64 stack, uint64 args[], int priority) {
    /* Please add thread-id instead of '0' here. */
    //printf("Ins this ULTHREAD_CREATE  function");
    
    int index=0;
    for(int i=1;i<MAXULTHREADS;i++)
    {
        if(ul_thread[i].tid==-1)
        {
            index = i;
            break;
        }
    }
    //printf("THe iNDEX is: %d", index);
    
    // total_threads+=1;
    ul_thread[index].tid=index;
    ul_thread[index].state=RUNNABLE;

    ul_thread[index].priority = priority;
    // printf("Before the context \n");
    memset(&(ul_thread[index].context), 0, sizeof(struct context));
    ul_thread[index].context.ra = start;
    ul_thread[index].context.sp = stack;
    
    ul_thread[index].context.s0=args[0];
    ul_thread[index].context.s1=args[1];
    ul_thread[index].context.s2=args[2];
    ul_thread[index].context.s3=args[3];
    ul_thread[index].context.s4=args[4];
    ul_thread[index].context.s5=args[5];

    
    // printf("After the context\n");
    //ul_thread[index].time_created = ctime();

    /*Please add thread-id instead of '0' here*/
    printf("[*] ultcreate(tid: %d, ra: %p, sp: %p)\n",ul_thread[index].tid, ul_thread[index].context.ra, ul_thread[index].context.sp);
    
    return true;
}

/* Thread scheduler */
void ulthread_schedule(void) {
    
    while(1){
    int next_tid=MAX_INT;
    if(algorithm==FCFS)
    {
        //First Come First Serve Algorithm
        int next_priority=-1;
        for(int i=1;i<MAXULTHREADS;i++)
        {
            if(ul_thread[i].state == RUNNABLE)
            {
                next_priority=i;
                break;
            }
        }

        if(next_priority==-1)
        {
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if( ul_thread[i].state==YIELD){
                    ul_thread[i].state=RUNNABLE;
                    next_priority=i;
                }
            }
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if((ul_thread[i].priority>ul_thread[next_priority].priority) && ul_thread[i].state==RUNNABLE)
                    next_priority=i;
            }
        }

        //printf("next_priority, %d \n", next_priority);

        if(next_priority==-1)
            return ;
        else{
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if((ul_thread[i].time_created<ul_thread[next_priority].time_created) && ul_thread[i].state==RUNNABLE)
                    next_priority=i;
            }
        }

        //printf("next_priority, %d \n", next_priority);
        
        printf("[*] ultschedule (next tid: %d)\n", next_tid);
        prev_tid=current_tid;
        current_tid=next_priority;

        if(prev_tid!=0)
        {
            if(ul_thread[prev_tid].state==YIELD){
                ul_thread[prev_tid].state=RUNNABLE;
                //printf("CHANGED\n");
            }

            if((next_priority==-1) && (ul_thread[prev_tid].state==RUNNABLE))
                next_tid=prev_tid;
        }
        ulthread_context_switch(&(ul_thread[0].context), &(ul_thread[current_tid].context));

    }
    else if(algorithm==ROUNDROBIN)
    {
        //Round Robin Scheduling
        int found = 0;
        int element=current_tid+1;
        for(int i=0; i<MAXULTHREADS;i++)
        {
            element=current_tid+i;
            element = element%MAXULTHREADS;
            
            if(element==0)
                continue;
            //printf("THe elements are:  %d\n", element);
            //printf("THe state are:  %d\n", ul_thread[element].state);
            if(ul_thread[element].state==RUNNABLE)
            {
                found = 1;
                break;
            }  
        }
        if(found == 0){
            //printf("In found\n");
            break;
        }
        printf("[*] ultschedule (next tid: %d)\n", element);
        // printf("THe current_tid context: %d", ul_thread[current_tid].context.ra);
        prev_tid=current_tid;
        current_tid=element;
        //printf("THe next_tid tid: %d\n", ul_thread[current_tid].tid);
        //printf("THe prev_tid tid: %d\n", ul_thread[prev_tid].tid);
        if(current_tid == prev_tid) break;
        if(prev_tid!=0)
        {
            if(ul_thread[prev_tid].state==YIELD){
                ul_thread[prev_tid].state=RUNNABLE;
                //printf("CHANGED\n");
            }
        }
        ulthread_context_switch(&(ul_thread[0].context), &(ul_thread[current_tid].context));
    }
    else
    {
        //Priority Scheduling
        int next_priority=-1;
        for(int i=1;i<MAXULTHREADS;i++)
        {
            if(ul_thread[i].state==RUNNABLE)
            {
                next_priority=i;
                break;
            }
        }

        if(next_priority==-1)
        {
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if( ul_thread[i].state==YIELD){
                    ul_thread[i].state=RUNNABLE;
                    next_priority=i;
                }
            }
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if((ul_thread[i].priority>ul_thread[next_priority].priority) && ul_thread[i].state==RUNNABLE)
                    next_priority=i;
            }
        }

        if(next_priority==-1)
            return;
        else{
            for(int i=1;i<MAXULTHREADS;i++)
            {
                if((ul_thread[i].priority>ul_thread[next_priority].priority) && ul_thread[i].state==RUNNABLE)
                    next_priority=i;
            }
        }
    
        printf("[*] ultschedule (next tid: %d)\n", ul_thread[next_priority].tid);
        prev_tid = current_tid;
        current_tid=next_priority;
        //printf("The next priority is: %d", next_priority);
        //if(current_tid == prev_tid) break;
        
        if(prev_tid!=0)
        {
            if(ul_thread[prev_tid].state==YIELD){
                ul_thread[prev_tid].state=RUNNABLE;
                //printf("CHANGED\n");
            }

            if((next_priority==-1) && (ul_thread[prev_tid].state==RUNNABLE))
                next_tid=prev_tid;
        }
        ulthread_context_switch(&(ul_thread[0].context), &(ul_thread[current_tid].context));
        //current_tid=next_priority;
    }
    
    }
    
}

/* Yield CPU time to some other thread. */
void ulthread_yield(void) {
    /* Please add thread-id instead of '0' here. */
    printf("[*] ultyield(tid: %d)\n", ul_thread[current_tid].tid);
    ul_thread[current_tid].state = YIELD;
    ulthread_context_switch(&(ul_thread[current_tid].context), &(ul_thread[0].context));
    //ulthread_schedule();
}

/* Destroy thread */
void ulthread_destroy(void) {
 
    //printf("THe current_tid from destroy tid: %d\n", current_tid);

    if(current_tid!=0)
    {
        printf("[*] ultdestroy(tid: %d)\n", ul_thread[current_tid].tid);
        ul_thread[current_tid].state=FREE;
        ul_thread[current_tid].tid=-1;
        prev_tid=current_tid;

        //current_tid=0;
        // printf("THe next_tid tid: %d\n", ul_thread[current_tid].tid);
        // printf("THe prev_tid tid: %d\n", ul_thread[prev_tid].tid);
        ulthread_context_switch(&(ul_thread[current_tid].context), &(ul_thread[0].context));
    }
    else
        return;
}