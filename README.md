# 概述

- GCD 的全称为 Grand Center Dispatch （大中驱派发，CPU调度中心，调度的是任务和线程，把任务交给线程执行）。

- GCD 具有以下几点优势：
    1.  通过推迟昂贵计算任务并在后台运行它们来改善应用的响应性能。
    2.  提供一个易于使用的并发模型，而不仅仅只是锁和线程，以避开并发陷阱。
    3.  具有在常见模式（例如单例）上用更高性能的原语优化代码的潜在能力。

# 核心概念
## 队列

- **队列 Dispatch Queue**：负责管理开发者提交的任务，始终以**先进先出**的方式来处理任务。

  - **串行队列（Serial Queues）**每次只能处理一个任务，必须前一个任务处理完成后才处理下一个任务，任务完成顺序有保证。

   - **并发队列（Concurrent Queues）**可同时处理多个任务，只要有空闲的线程，队列就会调度当前任务，交给线程去执行，由于任务的所需执行时间不同，导致任务完成的顺序多变。

  > 并发（Concurrent）和并行（parallelism）的区别：并发指多个线程被一个 cpu 轮流切换着执行，在用户看来好像是同时执行；并行指多个 cpu 同时执行多个线程，是真正的同时执行。

- 获取和创建队列：

  ```objective-c
  // 获取当前执行代码所在的队列
  dispatch_queue_t queue = dispatch_get_current_queue();
  
  // 获取系统主线程的串行队列（刷新UI等） 
  dispatch_queue_t queue = dispatch_get_main_queue();
  
  // 获取系统的全局并发队列（处理其他耗时任务等）
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  
  // 创建串行队列，DISPATCH_QUEUE_SERIAL为NULL
  dispatch_queue_t queue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
  
  // 创建并发队列 
  dispatch_queue_t queue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
  ```

-  暂停和恢复：

  - `dispatch_suspend` 函数暂停一个队列以阻止它执行任务对象；`dispatch_resume` 函数继续队列。
  
  - 暂停会增加队列的引用计数，恢复则减少队列的引用计数。当引用计数大于 0 时，队列就保持挂起状态。

  - 挂起一个队列不会导致正在执行的任务停止。

## 任务 

  - 用户提交给队列的工作单元，交给线程池执行。

      - **同步提交（sync）**：在任务执行完成之前，**会阻塞调用线程后面的代码执行**，也不能开启新线程。

      - **异步提交（async）**：在任务执行完成之前，**不会阻塞调用线程后面的代码执行**，可以开启新线程。

- 提交任务：

  ```objective-c
  // 同步提交
  dispatch_sync(queue, ^{
      //执行任务
  });
  
  // 异步提交
  dispatch_async(queue, ^{
      //执行任务
  });
  ```

- 任务提交到队列的组合：

  | -            | 并发队列                         | 串行队列                       | 主队列                       |
  | ------------ | -------------------------------- | ------------------------------ | ---------------------------- |
  | **异步提交** | 开启多个新线程，任务执行顺序不定 | 开启一个新线程，任务按顺序执行 | 不开启新线程，任务按顺序执行 |
  | **同步提交** | 不开启新线程，任务按顺序执行     | 不开启新线程，任务按顺序执行   | 不开启新线程，死锁           |

  - 队列与线程可以是多对一关系，一个线程上可以执行不同队列的任务，在主线程上一样适用。
  - 队列的同步/异步决定是否具备开启线程的能力，队列的串行/并发决定处理任务的顺序。
  - 最好只在**并发队列中同步提交任务**：在串行队列中同步提交任务也有可能造成死锁（嵌套提交）。例如，任务1和任务2加入串行队列，任务2必须等待任务1完成后才能执行，任务1中包含任务2，造成永久性的互相等待。

  ```objective-c
  dispatch_queue_t queue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
  //任务1
  dispatch_sync(queue, ^{
      NSLog(@"执行");
      //任务2
      dispatch_sync(queue, ^{
          NSLog(@"不会执行");//必须等任务1执行完毕
      });
      NSLog(@"不会执行");//必须等任务2执行完毕
  });
  ```

- 底层原理：

  - GCD有一个底层线程池中存放了若干个线程。这些线程是可以重用的，当一段时间后这个线程没有被调用，该线程就会被销毁。

    > 注意：开多少条线程是由底层线程池决定的（线程建议控制在3~5条），池是系统自动来维护，不需要程序员来维护；但最大限制是65条线程。

  - 异步提交可以开启多个线程，同步提交不能开启线程（只能在当前线程执行，不一定是主线程，指提交任务时所在的线程）。

  - 程序员只需要向队列中添加任务，队列调度由系统完成：

    - 当任务出队时，底层线程池中会提供一条线程供任务执行，当线程空闲时才会执行该任务；
    
    - 串行队列中的每一个任务需要等待上一个任务执行完毕才可以被调度，只需要使用一个线程（当前线程）；
    
    - 并发队列中的任务不需要等待，底层线程池中会再次提供一个线程供第二个任务执行，执行完毕后再回到底层线程池中。

  > [源码分析](https://www.neroxie.com/2019/01/22/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3GCD%E4%B9%8Bdispatch-queue/)

# dispatch

## dispatch_once

- `dispatch_once` 能保证任务只会被执行一次，即使同时多线程调用也是线程安全的。常用于创建单例、swizzeld method 等功能。

  ```objective-c
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      //创建单例、method swizzled或其他任务
  });
  ```

- 源码分析：

  - `dispatch_once` 的执行过程中可能遇到的情形：

    - 第一次执行，执行block，执行完成后置 onceToken 标记；
    - 非第一次执行，而步骤1尚未执行完毕，此时线程需要等待步骤1完成，步骤1完成后依次唤醒等待的线程；
    - 非第一次执行，且步骤1已经执行完成，线程跳过block继续执行后续任务。

  - 示例：
    - 首个线程A进入后，执行 `_dispatch_once_callout`；
    - 线程B进入后，如果A的流程还未走完，则进入 `_dispatch_once_wait`；
    - 线程C进入后，如果A的流程已经走完，则进入第一个 `return`。

  [源码分析](<https://juejin.cn/post/6844904143753052174>)

  ```c++
  void dispatch_once(dispatch_once_t *val, dispatch_block_t block) {
      dispatch_once_f(val, block, _dispatch_Block_invoke(block));
  }
  
  void dispatch_once_f(dispatch_once_t *val, void *ctxt, dispatch_function_t func) {
      dispatch_once_gate_t l = (dispatch_once_gate_t)val;
  
      uintptr_t v = os_atomic_load(&l->dgo_once, acquire);
      if (likely(v == DLOCK_ONCE_DONE)) {
          return;
      }
    	// 比较 &l->dgo_once 的值是否等于 DLOCK_ONCE_UNLOCKED，若是则将 (uintptr_t)_dispatch_lock_value_for_self() 赋值给 &l->dgo_once
      if (os_atomic_cmpxchg(&l->dgo_once, DLOCK_ONCE_UNLOCKED,
          									(uintptr_t)_dispatch_lock_value_for_self(), relaxed)) {
          return _dispatch_once_callout(l, ctxt, func);
      }
    	// 不停查询 &dgo->dgo_once 的值，若变为DLOCK_ONCE_DONE，则退出。
      return _dispatch_once_wait(l);
  }
  
  static void _dispatch_once_callout(dispatch_once_gate_t l, void *ctxt, dispatch_function_t func) {
    	// 实际执行block操作的地方
      _dispatch_client_callout(ctxt, func);
    	// 在block执行完毕后修改&l->dgo_once的值等于DLOCK_ONCE_DONE
      _dispatch_once_gate_broadcast(l);
  }
  ```

- 不正当地使用 `dispatch_once ` 可能会造成死锁：

  - 单例代码中又调用同一个单例代码。
  - 线程A调用单例，单例中需要同步线程B执行操作，但线程B的操作刚好也在调用单例，它又需要等待线程A执行完毕，造成了互相等待，形成死锁。
    - 子线程先执行单例，然后发送通知。等待 observer 执行完任务，该通知才算发送完成，单例的代码段才能结束。
    - 主线程同时执行单例，要等待子线程调用单例返回才能继续。而子线程调用的单例，却因为observer 的任务要在主线程执行，又要等主线程的单例调用结束。
    - 这样就形成了死锁。所以，在 `dispatch_once` 中要避免跨线程操作。

## dispatch_barrier

- `dispatch_barrier` 允许在一个并发队列中创建一个同步点。在其前面的任务执行结束后它才执行，在它后面的任务等它执行完成之后才会执行，起着分割的作用。

-  `dispatch_barrier_async` 是异步提交任务，`dispatch_barrier_sync` 是同步提交任务。

  - 异步还是同步指 `dispatch_barrier_(a)sync` 后面的代码是否需要等待该 block 中的代码执行完毕才执行。

- **`dispatch_barrier` 必须使用自定义创建的并发队列**。因为： 

  - 自定义串行队列：一个串行队列本来就一次只能执行一个操作。

  - 全局并发队列：失去效果，同普通的任务提交一致。

  - 自定义并发行队列：极佳的选择。

  > The queue you specify should be a concurrent queue that you create yourself using the dispatch_queue_create function. If the queue you pass to this function is a serial queue or one of the global concurrent queues, this function behaves like the dispatch_sync function.

- 使用场景：

  - 栅栏任务

  ```objective-c
  dispatch_queue_t queue = dispatch_queue_create("Queue", DISPATCH_QUEUE_CONCURRENT);
  
  dispatch_async(queue, ^{
      sleep(3);
      NSLog(@"任务3完成");
  });
  
  //栅栏
  dispatch_barrier_async(queue, ^{
      sleep(2);
      NSLog(@"任务2完成");
  });
  NSLog(@"异步最先执行，同步第3执行");
      
  dispatch_async(queue, ^{
      sleep(1);
      NSLog(@"任务1完成");
  });
  
  //异步最先执行，同步第3执行->任务3->任务2->任务1
  ```

  - 使用同步队列及栅栏块代替同步锁：

    - 在多个线程同时访问同一个对象的数据时，会有线程安全的问题。
    
    - 一般情况下可以使用 `@synchronized()` 生成同步块，保证任何时候都只有一个线程访问代码块。但该方法存在效率问题：共用同一个锁的那些同步块，都必须按顺序执行，每个同步块都要等其他同步块执行完毕后才能执行。

  ```objective-c
  // 多个get方法可以并发执行，而get方法与set方法之间并不能并发执行。
  dispatch_queue_t queue = dispatch_queue_create("Queue", DISPATCH_QUEUE_CONCURRENT);
  
  - (NSString *)name {
      __block NSString *name;
      dispatch_async(queue, ^{
          name = _name;
      });
      return name;
  }
  
  - (void)setName:(NSString *)name {
      dispatch_barrier_async(queue, ^{
          _name = name;
      });
  }
  ```

  ![](/Users/3kmac/Desktop/我的文档/图片/dispatch_barrier.png)

## dispatch_semaphore

- `dispatch_semaphore` 信号量主要用于处理多线程中以下两个方面：

  - 加锁（实现锁功能）；

  - 保持线程同步（实现读写功能）。

- API 分析：

  - `dispatch_semaphore_create` 创建信号量，指定信号量数目（必须 ≥ 0）。

  - `dispatch_semaphore_signal` 发送信号量，使信号量值 + 1：
    - 如果信号量增加后（不一定  ≥ 0）造成等待线程被唤醒则返回非 0，否则返回 0。

  - `dispatch_semaphore_wait` 等待信号量，使信号量 - 1：
    - 如果信号量值减小后 ≥ 0 表示线程顺畅，函数立即返回 0，可继续执行；

    - 如果信号量值减小后 < 0 表示线程阻塞，函数不会立即返回，也不可继续执行：

      - 如果阻塞期间信号量增加（不一定  ≥ 0）且该线程获得了信号量，则函数返回 0，可继续执行；
      
      - 如果阻塞期间信号量未增加或增加后但该线程未获得信号量，那么等到超时，则函数返回非 0，可继续执行。因为超时而返回时，会使信号量 + 1。

  > [源码分析](https://www.neroxie.com/2019/01/22/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3GCD%E4%B9%8Bdispatch-semaphore/)

  ```objective-c
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  // 信号量为1
  dispatch_semaphore_t t = dispatch_semaphore_create(1);
          
  dispatch_async(queue, ^{
      // 返回0，表示当前信号量大于0
      NSLog(@"1 wait = %ld", dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER));
      sleep(2);
      // 返回1，表示唤醒了等待线程
      NSLog(@"1 signal = %ld", dispatch_semaphore_signal(t));
  });
          
  dispatch_async(queue, ^{
      // 返回49，表示超时
      NSLog(@"2 wait = %ld", dispatch_semaphore_wait(t, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC)));
    	// 返回0，表示被唤醒
      NSLog(@"2 wait = %ld", dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER));
      NSLog(@"解锁后才能进行的操作2");
  });
      
  dispatch_async(queue, ^{
    	// 返回0，表示被唤醒
      NSLog(@"3 wait = %ld", dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER));
      NSLog(@"解锁后才能进行的操作3");
      sleep(2);
    	// 返回1，表示唤醒了等待线程
      NSLog(@"3 signal = %ld", dispatch_semaphore_signal(t));
   });
  
  /* 输出
  1 wait = 0
  2 wait = 49
  3 wait = 0
  1 signal = 1
  解锁后才能进行的操作3
  3 signal = 1
  2 wait = 0
  解锁后才能进行的操作2
  */
  ```

- **当信号量被销毁时，若信号值小于初始化时的设置值（表明存在调用 `dispatch_semaphore_wait` 而进入等待状态的线程），则会抛出异常 "Semaphore object deallocated while in use"。**

  - **因此，若 signal 方法少于 wait 方法，就有可能导致闪退，但不是绝对的，因为  wait 方法超时后不会对信号值产生增减。**

  - 避免闪退的方案之一：

  ```objective-c
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  for (int i = 0; i < 真正要设置信号值; ++i) {
      dispatch_semaphore_signal(t);
  }
  ```

- 最经典的应用：生产者-消费者

  ```objective-c
  __block int product = 0;
  dispatch_semaphore_t t = dispatch_semaphore_create(0);
  //生产者任务
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while(1) {
          sleep(1);
          NSLog(@"生产前：%d",product);
          product++;
          NSLog(@"生产后：%d",product);
          dispatch_semaphore_signal(t);
      }
  });
  //消费者任务
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while(1) {
          sleep(2);
          if(!dispatch_semaphore_wait(t, dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC))) {
              NSLog(@"消费前：%d",product);
              product--;
              NSLog(@"消费后：%d",product);
          };
      }
  });/
  ```
  
## dispatch_group

- `dispatch_group` 创建组任务：监听一组任务是否完成，完成后得到回调通知。非常适合处理**异步任务的同步**工作。

- API 分析：

  - `dispatch_group_create` 创建组任务，是建立信号值为 `LONG_MAX` 的 `dispatch_semaphore` 信号量。

  - `dispatch_group_enter` 进入组任务，是对 `dispatch_semaphore_wait(dispatch_semaphore, DISPATCH_TIME_FOREVER)` 的封装。

  - `dispatch_group_leave` 退出组任务，对信号量进行加 1 操作，如果操作后信号值等于 `LONG_MAX` 表示所有任务已完成，唤醒组任务回调。

  - `dispatch_group_async` 异步提交组任务：

    - 调用 `dispatch_group_enter`；

    - 将 block 和 queue 等信息记录 push 到 group 的链表中；

    - pop 执行时若任务是 group，执行完毕后再调用 `dispatch_group_leave` ，以达到信号量的平衡。

  - `dispatch_group_wait` 等待组任务回调，原理类似于 `dispatch_semaphore_wait`。

  - `dispatch_group_notify` 组任务回调，本质是用链表把回调通知保存起来，等待唤醒。

    - 直接或间接调用 `dispatch_group_leave` 后——表示所有监听任务已完成，或当前信号值已经等于 `LONG_MAX` ——执行时没有提交监听任务，唤醒组任务回调。

  [源码分析](https://www.neroxie.com/2019/01/22/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3GCD%E4%B9%8Bdispatch-group/)

  ```objective-c
  //1.创建组任务
  dispatch_group_t group = dispatch_group_create();
  
  // 任务执行所在的队列，并行串行队列都可以，不同任务可添加到不同队列中
  dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_t queue2 = dispatch_queue_create("Queue", DISPATCH_QUEUE_CONCURRENT);
      
  //2.将任务添加到组中
  // block方式添加任务
  dispatch_group_async(group, queue1, ^{
      sleep(3);
      NSLog(@"任务1完成");
  });
      
  // enter和leave方式添加任务
  dispatch_group_enter(group);
  dispatch_async(queue2, ^{
      sleep(1);
      NSLog(@"任务2完成");
      dispatch_group_leave(group);
  });
      
  //3.设置回调方式
  // block方式添加回调
  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
      NSLog(@"任务1 2完成");
  });
  
  // 设置超时参数，在该时间内永远等待，在回调前会阻塞当前线程(所以不能放在主线程调用)
  //dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
      
  NSLog(@"在输出‘任务1 2完成’之前执行");
  ```

- 当使用 enter 和 leave 方式添加任务时，`dispatch_group_enter` 和 `dispatch_group_leave` 必须成对出现：

  - 如果 `dispatch_group_enter` 多，则组任务回调不会执行；

  - 如果 `dispatch_group_leave `多，则会抛出异常 "Unbalanced call to dispatch_group_leave()"。

## dispatch_source

- `dispatch_source` 表示操作系统中比较底层级别的事件类型，如 MACH 端口发送和接收、IO 操作、定时器，这些事件可以被监听，并指定发生后进行处理的回调处理器（block对象或函数）和回调所在队列。

- 为了防止事件被积压在队列中，系统使用了事件合并机制：如果当一个新事件到达时，前一个事件处理器虽被放入队列，但还未被执行，则将合并两个事件；如果当一个或多个事件到达时，前一个事件的处理器已经开始执行，则将保存这些事件，直到当前的处理器执行完成后，再将新的事件处理器投入队列中。

  ```objective-c
  //1.创建dispatch源
  dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
      
  //2.设置响应dispatch源事件的block，在指定的队列上运行
  dispatch_source_set_event_handler(source, ^{
      unsigned long value = dispatch_source_get_data(source);
      NSLog(@"%lu %@", value, [NSThread currentThread]);
      if ((int)value == 2) {
          //暂停信号
          //dispatch_suspend(source);
      }
      //输出为 10
  });
      
  //3.dispatch源创建后处于suspend状态，需要手动启动
  dispatch_resume(source);
      
  //4.发送源信号（在全局队列）
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (int i = 1; i <= 4; i ++) {
          //触发事件，向source发送事件，这里i不能为0，否则触发不了事件
          dispatch_source_merge_data(source, i);
          //不睡眠会导致事件合并
          //sleep(1);
      }
  });
  ```

- `dispatch_source` 最常见的用途是实现定时器：

  - 不依赖 RunLoop，任何线程都可以使用（ `NSTimer` 会受 RunLoop 影响，当 RunLoop 处理的任务很多时，就会导致 `NSTimer` 的精度降低）；

  - 使用 block，不会导致循环引用；

  - 自由控制精度，随时修改时间间隔等。

  ```objective-c
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  //必须强引用定时器，否则执行一次就被释放
  _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  
  //设置启动时间，间隔时间和误差
  //设置后会立即调用一次响应block
  //可多次调用，随机修改参数
  dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 2 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
      
  //设置响应block
  dispatch_source_set_event_handler(_timer, ^{
      NSLog(@"每隔2s执行一次");
  });
      
  //启动
  dispatch_resume(_timer);
  ```

  - `dispatch_suspend` 把计时器暂时挂起。在挂起期间，产生的事件会积累起来，等到执行的时候会融合为一个事件发送，即挂起期间需要执行的回调会在恢复后立即执行。

    > `dispatch_suspend` 和 `dispatch_resume` 是一个平衡调用，两者分别会减少和增加计时器的挂起计数。当这个计数大于 0 的时候，计时器就会执行。
    >
    > 已经启动的计时器不能再调用 `dispatch_resume`，否则报错。但已经暂停的计时器可以多次调用 `dispatch_suspend`，此时需要再调用对应次数的 `dispatch_resume` 才能启动计时器。

  - `dispatch_source_cancel` 取消计时器，被取消之后如果想再次执行计时器，只能重新创建。这个过程类似于对 `NSTimer` 执行 `invalidate`。

  - 系统没有提供用于检测计时器挂起计数的函数，即外部不能获取计时器当前的状态。在设计代码逻辑时需要考虑到这一点。 可以添加一个变量实时记录状态（resume，suspend，cancel）。

  - 计时器只有在 cancel 状态下才会被释放；计时器只有在非 suspend 状态下才能被设置为 `nil`。比较安全地销毁计时器方法如下：

    ```objective-c
    dispatch_source_cancel(_timer);
    _timer = nil;
    ```

## dispatch_after

- `dispatch_after` 等到指定的时间节点后异步地将任务添加到指定的队列，而不是等到指定的时间节点后执行任务：在指定时间后提交任务到队列，但并不保证一定该时间后执行。

  ```objective-c
  // 一般为主队列
  dispatch_queue_t mainQueue = dispatch_get_main_queue();
  // 延迟时间
  dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
  dispatch_after(time, mainQueue, ^{
      NSLog(@"afterQueue");
  });
  NSLog(@"先执行");
  ```

- 核心分析：

  - 建立一个 `dispatch_source_t` 计时器。

## dispatch_apply

- `dispatch_apply` 类似一个 `for` 循环里提交任务到队列中，会在指定的队列中运行若干次任务 -> 优化顺序不敏感大体量 `for` 循环。

  ```objective-c
  dispatch_queue_t queue = dispatch_queue_create("Queue", DISPATCH_QUEUE_CONCURRENT);
  for (int i = 0; i < 10; i++) {
      // 创建很多线程，容易造成线程爆炸
      dispatch_async(queue, ^{
          NSLog(@"执行任务%d %@", i, [NSThread currentThread]);
      });
  }
  dispatch_barrier_sync(queue, ^{
  		NSLog(@"若干个任务都执行完毕");
  });
  ```

- `dispatch_apply` 是同步提交任务。如果执行队列是并发队列，则会并发执行；如果执行队列是串行队列，跟 `for` 循环功能一致，无法达到优化性能的目的。

  ```objective-c
  dispatch_queue_t queue = dispatch_queue_create("q", DISPATCH_QUEUE_CONCURRENT);
  dispatch_apply(10, queue, ^(size_t index) {
      NSLog(@"执行任务%zu %@", index, [NSThread currentThread]);
  });
  NSLog(@"所有任务都执行完毕")
  ```

- 执行队列推荐使用 `DISPATCH_APPLY_AUTO`，将随时选择最优的队列，执行当前 index 的任务。

- 核心分析：

  - 实际是调用了 `dispatch_apply_f()` ，对 `dispatch_async()` 和 semaphore 进行封装；

## dispatch_set_target_queue

- 设置队列的执行优先级：自定义队列生成时不可设置优先级，但全局队列却可以。

  ```objective-c
  //自定义queue
  dispatch_queue_t queue = dispatch_queue_create("Queue", DISPATCH_QUEUE_CONCURRENT);
  //全局queue
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
  //queue的优先级设置与globalQueue的优先级一样，即为HIGH
  dispatch_set_target_queue(queue, globalQueue);
  ```

- 多个串行队列同步执行（同时创建多个串行队列，这些串行队列会并行执行，导致执行顺序不一致）。

  ```objective-c
  //1.创建目标队列
  dispatch_queue_t targetQueue = dispatch_queue_create("Queue", DISPATCH_QUEUE_SERIAL);
      
  //2.创建3个串行队列
  dispatch_queue_t queue1 = dispatch_queue_create("Queue1", DISPATCH_QUEUE_SERIAL);
  dispatch_queue_t queue2 = dispatch_queue_create("Queue2", DISPATCH_QUEUE_SERIAL);
  dispatch_queue_t queue3 = dispatch_queue_create("Queue3", DISPATCH_QUEUE_SERIAL);
      
  //3.将3个串行队列分别添加到目标队列
  dispatch_set_target_queue(queue1, targetQueue);
  dispatch_set_target_queue(queue2, targetQueue);
  dispatch_set_target_queue(queue3, targetQueue);
      
  dispatch_async(queue1, ^{
      sleep(4);
      NSLog(@"任务1完成 %@", [NSThread currentThread]);
  });
  dispatch_async(queue1, ^{
      sleep(2);
      NSLog(@"任务2完成 %@", [NSThread currentThread]);
  });
  dispatch_async(queue1, ^{
      sleep(1);
      NSLog(@"任务3完成 %@", [NSThread currentThread]);
  });
  
  // 任务1->任务2->任务3
  ```

## dispatch_specific

  - 解决由于不可重入而导致的死锁，如在线程a中，同步提交任务到线程a中执行，会导致死锁。一般情况下，可以使用 `dispatch_get_current_queue()`（该方法实际已被遗弃）来获取当前线程，再进行比较，以确定是派发任务还是直接执行。但以下情况下都会出现异常：

      - 队列互相嵌套，如a中嵌套b，b中又嵌套a，获取的当前队列是b（这种情况下暂无解）；
      
      - 队列设置了目标队列，如b的目标队列是a，获取的当前队列是b；

    ```objective-c
    dispatch_queue_t queueA = dispatch_queue_create("queueA", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queueB = dispatch_queue_create("queueB", DISPATCH_QUEUE_SERIAL);
    // 设备b的目标队列是a
    dispatch_set_target_queue(queueB, queueA);
    dispatch_sync(queueB, ^{
        dispatch_block_t block = ^{
            NSLog(@"do something");
        };
        // 获取的是queueB，进入else造成死锁
        if (dispatch_get_current_queue() == queueA) {
            block();
        }
        else {
            dispatch_sync(queueA, block);
        }
    });
    ```

- `dispatch_queue_set_specific` 向指定队列里面设置一个标识，`dispatch_get_specific` 取出当前队列的标识。

  ```objective-c
  dispatch_queue_t queueA = dispatch_queue_create("queueA", NULL);
  dispatch_queue_t queueB = dispatch_queue_create("queueB", NULL);
  dispatch_set_target_queue(queueB, queueA);
  
  //设置标记
  static int specificKey;
  CFStringRef specificValue = CFSTR("queueA");
  dispatch_queue_set_specific(queueA, &specificKey, (void*)specificValue, NULL);
      
  dispatch_sync(queueB, ^{
      dispatch_block_t block = ^{
          NSLog(@"do something");
      };
      //获取标记
      CFStringRef retrievedValue = dispatch_get_specific(&specificKey);
      if ([(__bridge NSString *)retrievedValue isEqualToString:@"queueA"]) {
          block();
      }
      else {
          dispatch_sync(queueA, block);
      }
  });
  ```

## dispatch_benchmark

- 指定执行 block 和执行次数，计算出代码执行的平均的纳秒数。

  ```objective-c
  // 使用前需要先申明
  extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));
  
  uint64_t time = dispatch_benchmark(10000, ^{
      // 执行代码
  });
  ```

- 注意：使用该函数可能会被苹果拒审。

