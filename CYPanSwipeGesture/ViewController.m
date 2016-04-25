//
//  ViewController.m
//  CYPanSwipeGesture
//
//  Created by 薛国宾 on 16/4/25.
//  Copyright © 2016年 千里之行始于足下. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    dispatch_source_t _timerSource;
    float _indexSec;
    float _firstTime_x;
    float _firstTime_y;
    __weak IBOutlet UILabel *myLabel;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     /**
        当实现拖手势（UIPanGestureRecognizer）后将不能响应左右划（UISwipeGestureRecognizer）事件，事件会被拖手势栏截，所以左右划和拖手势只能选其一.
      但是即需要拖手势还需要左右划手势呢?
        我想到了一个简单方案.在UIPanGestureRecognizer基础上做一个伪轻滑手势.在一定的时间范围内滑动,视为左右划手势,反之为拖手势.
      */
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [self.view addGestureRecognizer:pan];
}

- (void)panEvent:(UIPanGestureRecognizer *)recognizer {
	
    if (!_timerSource) {
        _firstTime_x = -1;
        _firstTime_y = -1;
        [self createTimer:^(float indexSec) {
            _indexSec = indexSec;
        }];
    }
    
    //  获取手指拖拽的时候, 平移的值
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    // 大于0.1秒滑动时视为拖手势
    if (_indexSec > 1) {
        NSLog(@"拖 --->  %@",NSStringFromCGPoint(translation));
        myLabel.text = [NSString stringWithFormat:@"拖->point = %@",NSStringFromCGPoint(translation)];
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            [self cancelTimer];
             _indexSec = 0;
        }
    } else {
        // 在0.1秒滑动结束后 视为左右划
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            [self cancelTimer];
            CGFloat lastTime_x = fabs(translation.x);
            CGFloat lastTime_y = fabs(translation.y);
            
            if (lastTime_y - _firstTime_y > 50 && lastTime_x - _firstTime_x < 100) {
                NSLog(@"上下滑无效");
                myLabel.text = @"上下滑无效";
            } else if (lastTime_y - _firstTime_y < 100 && lastTime_x - _firstTime_x > 5) {
                if (translation.x > 0) {
                    NSLog(@"右");
                    myLabel.text = @"右滑";
                } else {
                    NSLog(@"左");
                    myLabel.text = @"左滑";
                }
            }
            
            _indexSec = 0;
        }
        if (_firstTime_x == -1) {
            _firstTime_x = fabs(translation.x);
        }
        if (_firstTime_y == -1) {
            _firstTime_y = fabs(translation.y);
        }
    }
}

#pragma mark - 创建一个定时器
- (void)createTimer:(void(^)(float indexSec))block {
    _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("timerSource", 0));
    // 时间间隔
    double interval = 0.05f * NSEC_PER_SEC;
    dispatch_source_set_timer(_timerSource, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0/*最小误差*/);
    
    __block float sec = 0;
    dispatch_source_set_event_handler(_timerSource, ^{
        sec += 0.5f;
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"sec = %f",sec);
            block(sec);
        });
    });
    dispatch_resume(_timerSource);
}

#pragma mark - 取消定时器
- (void)cancelTimer {
    if (_timerSource) {
        dispatch_source_cancel(_timerSource);
        _timerSource = nil;
    }
}

@end
