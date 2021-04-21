//
//  ViewController.m
//  STGCD
//
//  Created by stone on 2017/7/31.
//  Copyright © 2017年 duoyi. All rights reserved.
//

#import "ViewController.h"
#import "TimerViewController.h"

typedef NS_ENUM(NSInteger, Type) {
    TypeCreateSerialQueue,
    
    TypeCreateConcurrentQueue,
    
    TypeDeadlock,
    
    TypeAfterQueue,
    
    TypeApplyQueue,
    
    TypeOnceQueue,
    
    TypeGroupQueue,
    
    TypeBarrierQueue,
    
    TypeSetPriority,
    
    TypeSetTargetQueue,
    
    TypeSemaphore1,
    
    TypeSemaphore2,
    
    TypeSemaphore3,
    
    TypeSemaphore4,
    
    TypeSource,
    
    TypeTime,
    
    TypeSpecific,
};

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    
    NSArray *_array;
    dispatch_semaphore_t _semaphore;
    dispatch_queue_t _queue1;
    dispatch_queue_t _queue2;
    dispatch_queue_t _queue3;
}

@end




@implementation ViewController

- (void)test2{
    NSLog(@"2---%@",[NSThread currentThread]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    _array = @[@"串行队列",
               @"并发队列",
               @"死锁",
               @"延迟队列dispatch_after",
               @"重复队列dispatch_apply",
               @"单次队列dispatch_once",
               @"组任务监听",
               @"栅栏队列",
               @"目标队列之优先级",
               @"目标队列之串行同步",
               @"信号量之控制线程数量",
               @"信号量同步锁",
               @"信号量生产者消费者",
               @"信号量之异步回调",
               @"Source",
               @"Time",
               @"Specific",
               ];
    
    CGRect rect = self.view.bounds;
    UITableView *tableView = [[UITableView alloc] initWithFrame:rect];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = 40;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:tableView];
    
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"do" style:UIBarButtonItemStyleDone target:self action:@selector(click)];
    self.navigationItem.leftBarButtonItem = item;
    
    _semaphore = dispatch_semaphore_create(0);
    
    _queue1 = dispatch_queue_create("com.ibireme.cache.disk1", DISPATCH_QUEUE_CONCURRENT);
    _queue2 = dispatch_queue_create("com.ibireme.cache.disk2", DISPATCH_QUEUE_CONCURRENT);
    _queue3 = dispatch_queue_create("com.ibireme.cache.disk3", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"%@", _queue1.debugDescription);
    NSLog(@"%@", _queue2.debugDescription);
    NSLog(@"%@", _queue3.debugDescription);

}

- (void)click {
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text   = _array[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Type type = indexPath.row;
    switch (type)
    {
        case TypeCreateSerialQueue:
            [self createSerialQueue];
            break;
        case TypeCreateConcurrentQueue:
            [self createConcurrentQueue];
            break;
        case TypeDeadlock:
            [self deadlock];
            break;
        case TypeAfterQueue:
            [self afterQueue];
            break;
        case TypeApplyQueue:
            [self applyQueue];
            break;
        case TypeOnceQueue:
            [self onceQueue];
            [self onceQueue];
            break;
        case TypeGroupQueue:
            [self groupQueue];
            break;
        case TypeBarrierQueue:
            [self barrierQueue];
            break;
        case TypeSetPriority:
            [self targetQueue1];
            break;
        case TypeSetTargetQueue:
            [self targetQueue2];
            break;
        case TypeSemaphore1:
            [self semaphore1];
            break;
        case TypeSemaphore2:
            [self semaphore2];
            break;
        case TypeSemaphore3:
            [self semaphore3];
            break;
        case TypeSemaphore4:
            [self semaphore4];
            break;
        case TypeSource:
            [self source];
            break;
        case TypeTime:
            [self time];
            break;
        case TypeSpecific:
            [self specific];
            break;

        default:
            break;
    }
}

#pragma mark - 队列

//创建串行队列
- (void)createSerialQueue {
    dispatch_queue_t queue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"in 4");
        sleep(4);
        NSLog(@"4 %@",[NSThread currentThread]);
        NSLog(@"out 4");
    });
    dispatch_async(queue, ^{
        NSLog(@"in 2");
        sleep(2);
        NSLog(@"2 %@",[NSThread currentThread]);
        NSLog(@"out 2");
    });

    dispatch_async(queue, ^{
        NSLog(@"in 1");
        sleep(1);
        NSLog(@"1 %@",[NSThread currentThread]);
        NSLog(@"out 1");
    });

    NSLog(@"here");
    
//    dispatch_queue_t queue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_sync(queue, ^{
//        NSLog(@"in 4");
//        NSLog(@"4 %@",[NSThread currentThread]);
//        NSLog(@"out 4");
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"in 2");
//        NSLog(@"2 %@",[NSThread currentThread]);
//        NSLog(@"out 2");
//    });
//
//    dispatch_sync(queue, ^{
//        NSLog(@"in 1");
//        NSLog(@"1 %@",[NSThread currentThread]);
//        NSLog(@"out 1");
//    });
//
//    NSLog(@"here");
}

//创建并行队列
- (void)createConcurrentQueue {
    dispatch_queue_t queue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"in 4");
        sleep(4);
        NSLog(@"4 %@",[NSThread currentThread]);
        NSLog(@"out 4");
        
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_async(mainQueue, ^{
            NSLog(@"in main");
            sleep(4);
            NSLog(@"out main");
        });
        NSLog(@"out 444444");
    });
    
    dispatch_async(queue, ^{
        NSLog(@"in 2");
        sleep(2);
        NSLog(@"2 %@",[NSThread currentThread]);
        NSLog(@"out 2");
    });
    
    dispatch_async(queue, ^{
        NSLog(@"in 1");
        sleep(1);
        NSLog(@"1 %@",[NSThread currentThread]);
        NSLog(@"out 1");
    });
    
    NSLog(@"here");
}

- (void)deadlock {
    dispatch_queue_t queue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);
    //任务1
    dispatch_async(queue, ^{
        NSLog(@"执行");
        //任务2
        dispatch_sync(queue, ^{
            NSLog(@"不会执行");
        });
        NSLog(@"不会执行");
    });
}

#pragma mark - 栅栏队列

//依赖队列
- (void)barrierQueue {
    //必须使用自定义创建的并行队列
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    //dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(concurrentQueue, ^{
        sleep(3);
        NSLog(@"任务3完成");
    });
    NSLog(@"1");

    dispatch_sync(concurrentQueue, ^{
        sleep(4);
        NSLog(@"任务4完成");
    });
    
    NSLog(@"2");
    
    dispatch_barrier_async(concurrentQueue, ^{
        sleep(2);
        NSLog(@"任务2完成");
    });
    
    NSLog(@"3");
    
    dispatch_sync(concurrentQueue, ^{
        sleep(1);
        NSLog(@"任务1完成");
    });
    
    NSLog(@"4");
}

#pragma mark - 组队列

//组队列
- (void)groupQueue {
    //1.创建组任务队列，并行串行队列都可以
    dispatch_queue_t globalQueue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t globalQueue2 = dispatch_queue_create("stoneConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    //2.将任务添加到组中，任务可以不在同一个线程中
    dispatch_group_async(group, globalQueue1, ^{
        sleep(3);
        NSLog(@"任务3完成 %@", [NSThread currentThread]);
    });
    dispatch_group_async(group, globalQueue2, ^{
        sleep(2);
        NSLog(@"任务2完成 %@", [NSThread currentThread]);
    });
    
    //其他实现方式
    dispatch_group_enter(group);
    dispatch_async(globalQueue1, ^{
        sleep(1);
        dispatch_async(dispatch_queue_create("stoneConcurrentQueue2", DISPATCH_QUEUE_CONCURRENT), ^{
            NSLog(@"任务1完成 %@", [NSThread currentThread]);
            dispatch_group_leave(group);
        });
    });
    
//    //3.设置超时参数，在该时间内永远等待，在group上任务完成前会阻塞当前线程(所以不能放在主线程调用)
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//    NSLog(@"在输出‘任务X完成’之后执行");
    
    //4.组中所有队列执行完毕后发出通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"任务1 2 3完成");
    });
    NSLog(@"在输出‘任务1 2 3完成’之前执行");
}

#pragma mark - 延迟、重复、一次执行队列

//延迟执行队列
- (void)afterQueue
{
//    // 一般为主队列
//    dispatch_queue_t mainQueue = dispatch_get_main_queue();
//    // 延迟时间
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
//    dispatch_block_t block = dispatch_block_create(0, ^{
//          NSLog(@"1");
//      });
//    dispatch_after(time, mainQueue, block);
//    NSLog(@"先执行");
//    dispatch_block_cancel(block);
    
    // 一般为主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // 延迟时间
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    dispatch_after(time, mainQueue, ^{
        NSLog(@"afterQueue");
    });
    NSLog(@"先执行");
}



//重复执行队列
- (void)applyQueue {
    {
        NSLog(@"旧方案");
        dispatch_queue_t queue = dispatch_queue_create("旧方案", DISPATCH_QUEUE_CONCURRENT);
        for (int i = 0; i < 5; i++){
              // 创建很多线程，容易造成线程爆炸
            dispatch_async(queue, ^{
                NSLog(@"执行旧任务%d %@", i, [NSThread currentThread]);
                sleep(1);
            });
        }
        dispatch_barrier_sync(queue, ^{
            NSLog(@"若干个任务都执行完毕");
        });
        NSLog(@"旧方案 done");
    }
    {
        NSLog(@"新方案");
        dispatch_queue_t queue = dispatch_queue_create("新方案", DISPATCH_QUEUE_CONCURRENT);
        dispatch_apply(5, queue, ^(size_t index) {
            NSLog(@"执行新任务%zu %@", index, [NSThread currentThread]);
            sleep(1);
        });
        NSLog(@"若干个任务都执行完毕");
        NSLog(@"新方案 done");
    }
//    {
//        NSLog(@"新方案DISPATCH_APPLY_AUTO");
//        dispatch_apply(5, DISPATCH_APPLY_AUTO, ^(size_t index) {
//            NSLog(@"执行任务%zu %@", index, [NSThread currentThread]);
//            sleep(1);
//        });
//        NSLog(@"若干个任务都执行完毕");
//        NSLog(@"新方案 done");
//    }
}


//只执行一次队列
- (void)onceQueue {
    static dispatch_once_t onceToken;
    static int i = 0;
    dispatch_once(&onceToken, ^{
        i = 1;
        NSLog(@"onceQueue");
    });
    NSLog(@"后执行 %d", i);
    
//    [self dispatchOnce:^{
//        NSLog(@"onceQueue");
//    }];
//    NSLog(@"后执行");
//    for (int i = 0; i < 100; i++) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self dispatchOnce:^{
//                NSLog(@"onceQueue");
//            }];
//        });
//    }
}

static long _onceToken = 0;
- (void)dispatchOnce:(void (^)(void))block {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if (_onceToken == 0) {
        _onceToken = 1;
        dispatch_semaphore_signal(semaphore);
        block();
    }
    else {
        dispatch_semaphore_signal(semaphore);
        do {
            NSLog(@"waiting");
        } while (_onceToken != 1);
        NSLog(@"执行完毕");
    }
}

# pragma mark - 目标队列

- (void)targetQueue1 {
    
    dispatch_queue_t queue1 = dispatch_queue_create("stoneQueue1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue2 = dispatch_queue_create("stoneQueue2", DISPATCH_QUEUE_CONCURRENT);
    
//    //变更前
//    dispatch_async(queue1, ^{
//        NSLog(@"1");
//    });
//    dispatch_async(queue2, ^{
//        NSLog(@"2");
//    });
//
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    //queue的优先级设置与globalQueue的优先级一样
    dispatch_set_target_queue(queue2, globalQueue);

    //变更前
    dispatch_async(queue1, ^{
        NSLog(@"11");
    });
    dispatch_async(queue2, ^{
        NSLog(@"22");
    });
}

- (void)targetQueue22 {
    //1.创建目标队列
    dispatch_queue_t targetQueue = dispatch_queue_create("targetQueue", DISPATCH_QUEUE_SERIAL);
    
    //2.创建3个串行队列
    dispatch_queue_t queue1 = dispatch_queue_create("queue1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("queue2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue3 = dispatch_queue_create("queue2", DISPATCH_QUEUE_SERIAL);
    
    //3.将3个串行队列分别添加到目标队列
    dispatch_set_target_queue(queue1, targetQueue);
    dispatch_set_target_queue(queue2, targetQueue);
    dispatch_set_target_queue(queue3, targetQueue);
    
    dispatch_async(queue1, ^{
        sleep(4);
        NSLog(@"任务1完成 %@", [NSThread currentThread]);
    });
    dispatch_async(queue2, ^{
        sleep(2);
        NSLog(@"任务2完成 %@", [NSThread currentThread]);
    });
    dispatch_async(queue3, ^{
        sleep(1);
        NSLog(@"任务3完成 %@", [NSThread currentThread]);
    });
}


- (void)targetQueue2
{
    //创建一个串行队列queue1
    dispatch_queue_t queue1 = dispatch_queue_create("test.1", DISPATCH_QUEUE_SERIAL);
    //创建一个串行队列queue2
    dispatch_queue_t queue2 = dispatch_queue_create("test.2", DISPATCH_QUEUE_SERIAL);
    
//    dispatch_async(queue1, ^{
//        NSLog(@"！queue1:%@", [NSThread currentThread]);
//    });
    
    dispatch_async(queue2, ^{
        NSLog(@"！queue2:%@", [NSThread currentThread]);
    });
    
    dispatch_set_target_queue(queue1, queue2);
    dispatch_async(queue1, ^{
        NSLog(@"!！queue1:%@", [NSThread currentThread]);
    });
    dispatch_async(queue1, ^{
        NSLog(@"!！queue1:%@", [NSThread currentThread]);
    });
    
    //使用dispatch_set_target_queue()实现队列的动态调度管理
    
    
    
    /*
     
     <*>dispatch_set_target_queue(Dispatch Queue1, Dispatch Queue2);
     那么dispatchA上还未运行的block会在dispatchB上运行。这时如果暂停dispatchA运行：
     
     <*>dispatch_suspend(dispatchA);
     这时则只会暂停dispatchA上原来的block的执行，dispatchB的block则不受影响。而如果暂停dispatchB的运行，则会暂停dispatchA的运行。
     
     这里只简单举个例子，说明dispatch队列运行的灵活性，在实际应用中你会逐步发掘出它的潜力。
     
     dispatch队列不支持cancel（取消），没有实现dispatch_cancel()函数，不像NSOperationQueue，不得不说这是个小小的缺憾
     
     //*/
    
//    dispatch_async(queue1, ^{
//        for (NSInteger i = 0; i < 10; i++) {
//            NSLog(@"queue1:%@, %ld", [NSThread currentThread], i);
//            if (i == 5) {
//                dispatch_suspend(queue2);
//            }
//        }
//    });
}

#pragma mark - 信号量

//基本使用：控制线程数量
- (void)semaphore1
{
    /*
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建10个信号总量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    for (int i = 0; i < 100; i++)
    {
        //等待信号，当信号总量少于0的时候就会一直等待，否则就可以正常的执行，并让信号总量-1
        long a = dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"!!%ld",a);
        dispatch_async(queue, ^{
            NSLog(@"%i",i);
            sleep(4);
            //发送一个信号，让信号总量+1
            long b = dispatch_semaphore_signal(semaphore);
            NSLog(@"~~%ld",b);
        });
    }
    */

    // 每次只允许一个线程访问
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    for (int i = 0; i < 10; i++) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            NSLog(@"%@ 必须加锁访问的资源",[NSThread currentThread]);
            dispatch_semaphore_signal(semaphore);
        });
    }
}

static dispatch_semaphore_t semaphore2_t;
- (void)semaphore2 {
    // 创建信号量，个数为1
    dispatch_semaphore_t t = dispatch_semaphore_create(1);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
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
        NSLog(@"2 wait = %ld", dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER));
        NSLog(@"解锁后才能进行的操作2");
    });
    
    dispatch_async(queue, ^{
        // 返回0，表示被唤醒
        NSLog(@"3 wait = %ld", dispatch_semaphore_wait(t, DISPATCH_TIME_FOREVER));
        NSLog(@"解锁后才能进行的操作3");
        sleep(2);
        NSLog(@"3 signal = %ld", dispatch_semaphore_signal(t));
    });
    
    semaphore2_t = t;
}

- (void)semaphore3 {
    __block int product = 0;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    //生产者任务
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(1) {
            sleep(1);
            NSLog(@"生产前：%d",product);
            product++;
            NSLog(@"生产后：%d",product);
            dispatch_semaphore_signal(sem);
        }
    });
    //消费者任务
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(1) {
            sleep(2);
            if(!dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC))) {
                NSLog(@"消费前：%d",product);
                product--;
                NSLog(@"消费后：%d",product);
            };
        }
    });
}

// 异步队列中做事，等待回调后执行某件事
- (void)semaphore4
{
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    //创建0个信号总量
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//
//    //异步执行
//    dispatch_async(queue, ^{
//        NSLog(@"开始执行");
//        NSURL *url = [NSURL URLWithString:@"http://120.25.226.186:32812/login"];
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//        request.HTTPMethod = @"POST";
//        request.HTTPBody   = [@"username=520it&pwd=520it&type=JSON" dataUsingEncoding:NSUTF8StringEncoding];
//        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//        NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration];
//        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//            {
//                NSLog(@"异步返回");
//                dispatch_semaphore_signal(semaphore);
//            }
//        }];
//        [task resume];
//    });
//
//    long flag = dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    NSLog(@"回调异步执行 %ld", flag);
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        NSLog(@"task1 begin : %@",[NSThread currentThread]);
        dispatch_async(queue, ^{
            sleep(2);
            NSLog(@"task1 finish : %@",[NSThread currentThread]);
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"task2 begin : %@",[NSThread currentThread]);
        dispatch_async(queue, ^{
            sleep(10);
            NSLog(@"task2 finish : %@",[NSThread currentThread]);
        });
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"refresh UI");
    });
}

#pragma mark - dispatch_source_t

- (void)source {
    //1.创建dispatch源
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    
    //2.设置响应dispatch源事件的block，在指定的队列上运行
    dispatch_source_set_event_handler(source, ^{
        unsigned long value = dispatch_source_get_data(source);
        NSLog(@"%lu %@", value, [NSThread currentThread]);
        if ((int)value == 2) {
            // 暂停信号
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
            //不睡眠回导致事件合并
            //sleep(1);
        }
    });
}

- (void)time {
    TimerViewController *vc = [[TimerViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)specific {
    
    /*
    dispatch_queue_t queueA = dispatch_queue_create("queueA", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queueB = dispatch_queue_create("queueB", DISPATCH_QUEUE_SERIAL);
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
    */
    
    /*
    dispatch_queue_t queueA = dispatch_queue_create("queueA", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queueB = dispatch_queue_create("queueB", DISPATCH_QUEUE_SERIAL);
    static int specificKey;
    CFStringRef specificValue = CFSTR("queueA");
    dispatch_queue_set_specific(queueA, &specificKey, (void *)specificValue, NULL);
    dispatch_sync(queueA, ^{
        CFStringRef retrievedValue = dispatch_get_specific(&specificKey);
        NSString *string = (__bridge NSString *)retrievedValue;
        dispatch_sync(queueB, ^{
            dispatch_block_t block = ^{
                NSLog(@"do something");
            };
            // 获取的是queueB，进入else造成死锁
            CFStringRef retrievedValue = dispatch_get_specific(&specificKey);
            NSString *string = (__bridge NSString *)retrievedValue;
            if (retrievedValue) {
                block();
            }
            else {
                dispatch_sync(queueA, block);
            }
        });
    });
    */
    
    
    dispatch_queue_t queueA = dispatch_queue_create("queueA", NULL);
    dispatch_queue_t queueB = dispatch_queue_create("queueB", NULL);
    dispatch_set_target_queue(queueB, queueA);

    //设置标记
    static int specificKey;
    CFStringRef specificValue = CFSTR("queueA");
    dispatch_queue_set_specific(queueA, &specificKey, (void*)specificValue, NULL);
    
    dispatch_sync(queueB, ^{
        dispatch_block_t block = ^{
            NSLog(@"do something %@", [NSThread currentThread]);
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
}

@end
