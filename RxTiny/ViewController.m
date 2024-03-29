//
//  ViewController.m
//  RxTiny
//
//  Created by zct on 2019/7/24.
//  Copyright © 2019 zct. All rights reserved.
//

#import "ViewController.h"
#import "RxTiny.h"
#import <Hodor/HCommon.h>

@interface HTestVC () <UITableViewDataSource>
@end

@interface ViewController ()
@property (nonatomic) NSString *str;
@property (nonatomic) NSString *str2;
@property (nonatomic) BOOL b1;
@property (nonatomic) UIColor *color;
@property (nonatomic) CGPoint point;
@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        @weakify(self);
        [self addMenu:@"观察订阅" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1";
            rxo(self, str).next(^(id v) {
                NSLog(@"%@", v);
            });
            self.str = @"2";
            self.str = nil;
        }];
        
        [self addMenu:@"自定义信号" callback:^(id sender, id data) {
            RxtSignal *s = [RxtSignal new];
            s.push(@"1");
            s.rlog(@"%@");
            s.push(@"2");
        }];
        [self addMenu:@"过滤" callback:^(id sender, id data) {
            RxtSignal *s = [RxtSignal new];
            s.filter(^BOOL(id v) {
                return [v isEqual:@"2"];
            }).rlog(@"%@");
            
            s.push(@"1");
            s.push(@"2");
            
        }];
        [self addMenu:@"映射" callback:^(id sender, id data) {
            RxtSignal *s = [RxtSignal new];
            s.map(^id(NSString *v) {
                if ([v isEqual:@"a"]) return @(1);
                if ([v isEqual:@"b"]) return @(2);
                return nil;
            }).toInt(^(int v) {
                NSLog(@"%d", v);
            });
            s.push(@"a");
            s.push(@"b");
        }];
        [self addMenu:@"合并" callback:^(id sender, id data) {
            @strongify(self);
            RxtSignal *s = [RxtSignal new];
            s.push(@"a");
            self.str = @"1";
            rxmerge(rxo(self, str), s).rlog(@"%@");
            self.str = @"2";
            s.push(@"b");
            
        }];
        [self addMenu:@"弄死" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1";
            RxtSignal *s = rxo(self, str);
            s.rlog(@"%@");
            self.str = @"2";
            s.die();
            self.str = @"3";
        }];
        
        [self addMenu:@"弄死信号" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1";
            RxtSignal *s2 = [RxtSignal lazy];
            RxtSignal *s = rxo(self, str);
            s.dieAt(s2).rlog(@"%@");
            self.str = @"2";
            s2.push(@"any");
            self.str = @"3";
        }];
        
        [self addMenu:@"一起死" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1";
            RxtSignal *s = rxo(self, str);
            s.rlog(@"%@");
            self.str = @"2";
            if (YES) {
                NSObject *a = [NSObject new];
                s.dieWith(a);
            }            
            self.str = @"3";
        }];
        
        [self addMenu:@"信号绑定" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1";
            RxtSignal *s2 = [RxtSignal new];
            s2.rlog(@"%@");
            rxo(self, str).bind(s2);
            self.str = @"2";
        }];
        [self addMenu:@"值绑定" callback:^(id sender, id data) {
            @strongify(self);
            rxsp(self, str2) = rxo(self, str);
            self.str = @"1";
            NSLog(@"%@" ,self.str2);
            self.str = @"2";
            NSLog(@"%@" ,self.str2);
        }];
        
        [self addMenu:@"不为空" callback:^(id sender, id data) {
            @strongify(self);
            rxo(self, str).rlog(@"可为空:%@");
            rxo(self, str).notNull().rlog(@"不为空:%@");
            self.str = @"1";
            self.str = nil;
            self.str = @"2";
        }];
        
        [self addMenu:@"取反" callback:^(id sender, id data) {
            @strongify(self);
            self.b1 = YES;
            rxo(self, b1).revertBool().toBool(^(BOOL v) {
                NSLog(v?@"YES":@"NO");
            });
        }];
        
        [self addMenu:@"其他转换" callback:^(id sender, id data) {
            @strongify(self);
            self.str = @"1234";
            rxo(self, str).toLongLong(^(long long v) {
                NSLog(@"%lli", v);
            });
            self.str = @"4566";
        }];
        
        [self addMenu:@"UI重用信号" callback:^(id sender, NSIndexPath *indexPath) {
            @strongify(self);
            self.color = [UIColor h_random];
            NSLog(@"见-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath");
        }];
        [self addMenu:@"监听结构体" callback:^(id sender, id data) {
            @strongify(self);
            self.point = CGPointMake(10, 10);
            rxo(self, point).rlog(@"%@");
            self.point = CGPointMake(20, 20);
        }];
        
        [self addMenu:@"观察者自动释放" callback:^(id sender, id data) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            rxo(view, frame).rlog(@"%@");
            view.frame = CGRectMake(2, 2, 5, 5);
        }];
        
        [self addMenu:@"通知" callback:^(id sender, id data) {
            if (1) {
                NSObject *o = [NSObject new];
                o.rxtNotiObserve(@"noti1234").next(^(NSNotification *v) {
                    NSLog(@"%@", v.userInfo);
                });
                [[NSNotificationCenter defaultCenter] postNotificationName:@"noti1234" object:nil userInfo:@{@"k":@"v"}];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"noti1234" object:nil userInfo:@{@"k":@"v2"}];
        }];
        
        [self addMenu:@"转线程" callback:^(id sender, id data) {
            @strongify(self)
            self.str = @"1";
            rxo(self, str).syncAtMain().next(^(id v) {
                NSLog(@"%@", v);
            });
            self.str = @"2";
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                self.str = @"3";
            });                        
        }];
        
        [self addMenu:@"变化过滤" callback:^(id sender, id data) {
            @strongify(self)
            self.str = @"1";
            rxo(self, str).onChanged().rlog(@"%@");
            self.str = @"1";
            self.str = @"2";
            self.str = @"2";
            self.str = @"1";
        }];
        
        [self addMenu:@"跳过" callback:^(id sender, id data) {
            @strongify(self)
            self.str = @"1";
            rxo(self, str).skip(2).rlog(@"%@");
            self.str = @"2";
            self.str = @"3";
            self.str = @"4";
        }];
        [self addMenu:@"测试" callback:^(id sender, id data) {
            @strongify(self)
            __block int changed = 0;
            RxtSignal *s = [RxtSignal lazy].next(^(id v) {
                changed += 1;
            });
            s.push(nil);
            s.push(nil);
            [s dispose];
            s.push(nil);
            NSLog(@"%d", changed);
            
        }];
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    rxsp(cell.textLabel, textColor) = rxo(self, color).dieAt(cell.rxt_onReuse);
    return cell;
}

@end
