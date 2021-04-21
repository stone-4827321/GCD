//
//  TimerViewController.m
//  GCD_Demo
//
//  Created by stone on 2020/7/3.
//  Copyright © 2020 duoyi. All rights reserved.
//

#import "TimerViewController.h"


@interface TimerViewController () {
    dispatch_source_t _timer;
    int index;
}

@end

@implementation TimerViewController

- (void)dealloc {
    NSLog(@"TimerViewController dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    index = 0;
    
    //必须强引用，否则不会执行block
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    //设置启动时间，间隔时间和误差
    //设置后会立即调用一次响应block
    //可多次调用，随机修改参数
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 2 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    //设置响应block
    dispatch_source_set_event_handler(_timer, ^{
        NSLog(@"%d %@",index, [NSThread currentThread]);
        index ++;
    });

    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button1 setTitle:@"resume" forState:UIControlStateNormal];
    button1.frame = CGRectMake(0, 100, 100, 40);
    [self.view addSubview:button1];
    [button1 addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button2 setTitle:@"suspend" forState:UIControlStateNormal];
    button2.frame = CGRectMake(0, 150, 100, 40);
    [self.view addSubview:button2];
    [button2 addTarget:self action:@selector(suspend) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button3 setTitle:@"cancel" forState:UIControlStateNormal];
    button3.frame = CGRectMake(0, 200, 100, 40);
    [self.view addSubview:button3];
    [button3 addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button4 setTitle:@"setNill" forState:UIControlStateNormal];
    button4.frame = CGRectMake(0, 250, 100, 40);
    [self.view addSubview:button4];
    [button4 addTarget:self action:@selector(setNill) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button5 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button5 setTitle:@"setTimer" forState:UIControlStateNormal];
    button5.frame = CGRectMake(0, 300, 100, 40);
    [self.view addSubview:button5];
    [button5 addTarget:self action:@selector(setTimer) forControlEvents:UIControlEventTouchUpInside];
}

- (void)resume {
    //启动
    NSLog(@"启动");
    dispatch_resume(_timer);
}

- (void)suspend {
    NSLog(@"暂停");
    dispatch_suspend(_timer);
}

- (void)cancel {
    NSLog(@"取消");
    dispatch_source_cancel(_timer);
}

- (void)setNill {
    NSLog(@"置空");
    _timer = nil;
}

- (void)setTimer {
    //
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), 4 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
}

@end
