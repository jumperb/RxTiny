//
//  RxTiny.m
//  JsonView
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019年 zct. All rights reserved.
//

#import "RxTiny.h"
#import <Hodor/HGCDext.h>
#pragma mark - 信号

@interface RxtSignal ()
@property (nonatomic) BOOL hasValue;
@property (nonatomic) id value;
@property (nonatomic) BOOL deaded;
@property (nonatomic) BOOL willDealloc;
@property (nonatomic) NSMutableSet<RxtSignal*> *subSignals;
@end

@interface RxtNext: RxtSignal
@property (nonatomic) RxtNextB nextb;
@end

@interface RxtFilter: RxtSignal
@property (nonatomic) RxtFilterB filterb;
@end

@interface RxtMap: RxtSignal
@property (nonatomic) RxtMapB mapb;
@end

@interface RxtProcess: RxtSignal
@property (nonatomic) RxtProcessB processb;
@end

@implementation RxtSignal

+ (instancetype)fromValue:(id)initValue {
    RxtSignal *o = [RxtSignal new];
    o.value = initValue;
    o.hasValue = YES;
    return o;
}
+ (instancetype)lazy {
    RxtSignal *o = [RxtSignal new];
    o.lazy = YES;
    return o;
}
- (void)dealloc
{
    _willDealloc = YES;
}
- (NSMutableSet<RxtSignal*> *)subSignals {
    if (!_subSignals) _subSignals = [NSMutableSet new];
    return _subSignals;
}

- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    self.value = newValue;
    self.hasValue = YES;
    [self dispatch:newValue];
}
- (id)outputValue {
    return self.value;
}
- (void)dispatch:(id)value {
    id v = [self outputValue];
    for (RxtSignal *signal in self.subSignals) {
        [self dispatchOne:signal value:v];
    }
}

- (void)dispatchOne:(RxtSignal *)signal value:(id)value {
    if (self.willDealloc) return;
    if (self.deaded) return;
    [signal push:value];
}
- (RxtSignal *)addNext:(RxtSignal *)signal {
    [self.subSignals addObject:signal];
    if (!self.lazy && self.hasValue) {
        [self dispatchOne:signal value:[self outputValue]];
    }
    return signal;
}
- (void)unBind:(RxtSignal *)signal {
    [self.subSignals removeObject:signal];
}
- (void (^)(id))push {
    return ^void (id newValue) {
        [self push:newValue];
    };
}
- (RxtSignal *(^)(RxtSignal *))bind {
    return ^RxtSignal* (RxtSignal *n) {
        [self addNext:n];
        return n;
    };
}
- (RxtSignal *(^)(RxtSignal *))dieAt {
    return ^RxtSignal* (RxtSignal *n) {
        RxtNext *o = [RxtNext new];
        o.lazy = YES;
        __weak typeof(self) weakSelf = self;
        [o setNextb:^(id v) {
            [weakSelf dispose];
        }];
        [n addNext:o];
        return self;
    };
}
- (RxtSignal *(^)(NSObject *obj))dieWith {
    return ^RxtSignal* (NSObject *obj) {
        RxtNext *o = [RxtNext new];
        o.lazy = YES;
        __weak typeof(self) weakSelf = self;
        [o setNextb:^(id v) {
            [weakSelf dispose];
        }];
        [obj.rxtDeallocSignal addNext:o];
        return self;
    };
}
- (RxtSignal *(^)(void))die {
    return ^RxtSignal* () {
        [self dispose];
        return self;
    };
}
- (void)dispose {
    self.deaded = YES;
}
- (RxtSignal *(^)(RxtNextB))next {
    return ^RxtSignal* (RxtNextB nb) {
        RxtNext *o = [RxtNext new];
        o.nextb = nb;
        [self addNext:o];
        return o;
    };
}

- (RxtSignal *(^)(RxtFilterB))filter {
    return ^RxtSignal* (RxtFilterB b) {
        RxtFilter *o = [RxtFilter new];
        o.filterb = b;
        [self addNext:o];
        return o;
    };
}
- (RxtSignal *(^)(RxtMapB))map {
    return ^RxtSignal* (RxtMapB b) {
        RxtMap *o = [RxtMap new];
        o.mapb = b;
        [self addNext:o];
        return o;
    };
}

@end

@implementation RxtNext
- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    if (self.nextb) self.nextb(newValue);
}
@end

@interface RxtFilter ()
@property (nonatomic, copy) id lastValue;
@end

@implementation RxtFilter
- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    if (self.filterb && !self.filterb(newValue)) return;
    [super push:newValue];
    self.lastValue = newValue;
}
@end


@implementation RxtMap
- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    if (!self.mapb) return;
    [super push:self.mapb(newValue)];
}
@end

@implementation RxtProcess

- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    if (!self.processb) return;
    self.processb(newValue);
}
@end

#pragma mark - 值观察者
@interface RxtPropertyObserver ()
@property (nonatomic, assign, readwrite) id ref;
@property (nonatomic, readwrite) NSString *propertyName;
@property (nonatomic) BOOL observing;
@end

@implementation RxtPropertyObserver
+ (instancetype)object:(id)ref property:(NSString *)property {
    RxtPropertyObserver *res = [RxtPropertyObserver new];
    res.ref = ref;
    res.propertyName = property;
    [res setup];
    return res;
}
- (void)setup {
    if (!self.observing) {
        self.push([self.ref valueForKey:self.propertyName]);
        [self.ref addObserver:self forKeyPath:self.propertyName options:NSKeyValueObservingOptionNew context:nil];
        [((NSObject *)self.ref).rxtObservers addObject:self];
        self.observing = YES;
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    id value = change[NSKeyValueChangeNewKey];
    if ([value isKindOfClass:[NSNull class]]) value = nil;
    [self push:value];
}
- (void)unObserve {
    if (self.observing) {
        self.observing = NO;
        [self.ref removeObserver:self forKeyPath:self.propertyName];
        [((NSObject *)self.ref).rxtObservers removeObject:self];
    }
}
- (void)dealloc
{
    [self unObserve];
}
- (void)dispose {
    [super dispose];
    [self unObserve];
}
@end

#pragma mark - 通知观察者
@interface RxtNotificationObserver ()
@property (nonatomic, assign) id ref;
@property (nonatomic) NSString *notification;
@property (nonatomic) id obj;
@property (nonatomic) BOOL observing;
@end

@implementation RxtNotificationObserver
+ (instancetype)object:(id)ref notification:(NSString *)notification object:(id)object {
    RxtNotificationObserver *res = [RxtNotificationObserver new];
    res.notification = notification;
    res.ref = ref;
    res.obj = object;
    [res setup];
    return res;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lazy = YES;
    }
    return self;
}
- (void)setup {
    if (!self.observing) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:self.notification object:self.obj];
        [((NSObject *)self.ref).rxtObservers addObject:self];
        self.observing = YES;
    }
}
- (void)handleNotification:(NSNotification *)noti {
    [self push:noti];
}
- (void)unObserve {
    if (self.observing) {
        self.observing = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [((NSObject *)self.ref).rxtObservers removeObject:self];
    }
}
- (void)dealloc
{
    [self unObserve];
}
- (void)dispose {
    [super dispose];
    [self unObserve];
}
@end

#pragma mark - 订阅
@interface RxtProprtySubscriber ()
@property (nonatomic, weak) id ref;
@property (nonatomic) NSString *propertyName;
@end
@implementation RxtProprtySubscriber
@dynamic bindSingalDontUse;
+ (instancetype)object:(id)ref property:(NSString *)property {
    RxtProprtySubscriber *res = [RxtProprtySubscriber new];
    res.ref = ref;
    res.propertyName = property;
    return res;
}
- (void)push:(id)newValue {
    if (self.willDealloc) return;
    if (self.deaded) return;
    if (!self.ref || !self.propertyName) return;
    [self.ref setValue:newValue forKey:self.propertyName];    
}
- (void)setBindSingalDontUse:(RxtSignal *)bindSingalDontUse
{
    [bindSingalDontUse addNext:self];
}
@end
#pragma mark - 合并
RxtSignal* RxtMerge(NSArray *signals) {
    
    RxtSignal *me = [RxtSignal new];
    for  (RxtSignal *signal in signals) {
        [signal addNext:me];
    }
    return me;
}

#pragma mark - 补充转换器
#import <Hodor/UIColor+ext.h>


@implementation RxtSignal(convert)

- (RxtSignal *(^)(RxtToStringB))toString {
    return ^RxtSignal* (RxtToStringB b) {
        return self.map(^id(id v) {
            NSString *v2 = [v stringValue];
            b(v2);
            return v2;
        });
    };
}

- (void (^)(RxtToBoolB))toBool {
    return ^(RxtToBoolB b) {
        self.next(^(id v) {
            b([v boolValue]);
        });
    };
}
- (void (^)(RxtToFloatB))toFloat {
    return ^(RxtToFloatB b) {
        self.next(^(id v) {
            b([v floatValue]);
        });
    };
}

- (void (^)(RxtToDoubleB))toDouble {
    return ^(RxtToDoubleB b) {
        self.next(^(id v) {
            b([v doubleValue]);
        });
    };
}

- (void (^)(RxtToCharB))toChar {
    return ^(RxtToCharB b) {
        self.next(^(id v) {
            b([v charValue]);
        });
    };
}
- (void (^)(RxtToIntegerB))toInteger {
    return ^(RxtToIntegerB b) {
        self.next(^(id v) {
            b([v integerValue]);
        });
    };
}
- (void (^)(RxtToUIntegerB))toUInteger {
    return ^(RxtToUIntegerB b) {
        self.next(^(id v) {
            b([v unsignedIntegerValue]);
        });
    };
}
- (void (^)(RxtToIntB))toInt {
    return ^(RxtToIntB b) {
        self.next(^(id v) {
            b([v intValue]);
        });
    };
}
- (void (^)(RxtToLongB))toLong {
    return ^(RxtToLongB b) {
        self.next(^(id v) {
            b([v longValue]);
        });
    };
}
- (void (^)(RxtToLongLongB))toLongLong {
    return ^(RxtToLongLongB b) {
        self.next(^(id v) {
            b([v longLongValue]);
        });
    };
}
- (void (^)(RxtToUnsignedIntB))toUnsignedInt {
    return ^(RxtToUnsignedIntB b) {
        self.next(^(id v) {
            b([v unsignedIntValue]);
        });
    };
}
- (void (^)(RxtToUnsignedLongB))toUnsignedLong {
    return ^(RxtToUnsignedLongB b) {
        self.next(^(id v) {
            b([v unsignedLongValue]);
        });
    };
}
- (void (^)(RxtToUnsignedLongLongB))toUnsignedLongLong {
    return ^(RxtToUnsignedLongLongB b) {
        self.next(^(id v) {
            b([v unsignedLongLongValue]);
        });
    };
}


- (RxtSignal *(^)(void))notNull {
    return ^RxtSignal* () {
        RxtFilter *o = [RxtFilter new];
        [o setFilterb:^BOOL(id value) {
            return (value != NULL);
        }];
        return [self addNext:o];
    };
}

- (RxtSignal *(^)(void))revertBool {
    return ^RxtSignal* () {
        RxtMap *o = [RxtMap new];
        [o setMapb:^id(id value) {
            return @(![value boolValue]);
        }];
        return [self addNext:o];
    };
}

- (RxtSignal *(^)(void))onChanged {
    return ^RxtSignal* () {
        RxtFilter *o = [RxtFilter new];
        __weak RxtFilter *weakO = o;
        [o setFilterb:^BOOL(id value) {
            return (value != weakO.lastValue && ![value isEqual:weakO.lastValue]);
        }];
        return [self addNext:o];
    };
}
- (RxtSignal *(^)(NSUInteger times))skip {
    return ^RxtSignal* (NSUInteger times) {
        RxtFilter *o = [RxtFilter new];
        o.lazy = YES;
        __block unsigned int skiped = 0;
        [o setFilterb:^BOOL(id value) {
            if (skiped >= times) return YES;
            else {
                skiped ++;
                return NO;
            }
        }];
        return [self addNext:o];
    };
}

- (RxtSignal *(^)(RxtToColorB))toColor {
    return ^RxtSignal* (RxtToColorB b) {
        return self.map(^id(id v) {
            UIColor *color = nil;
            if ([v isKindOfClass:[NSString class]]) {
                color = [UIColor h_colorWithString:v];
            }
            else if ([v isKindOfClass:[NSNumber class]]) {
                color = [UIColor h_colorWithHex:[v intValue]];
            }
            else if ([v isKindOfClass:[UIColor class]]) {
                color = v;
            }
            if (b) b(color);
            return color;
        });
    };
}

- (RxtSignal *(^)(void))syncAtMain {
    return ^RxtSignal* () {
        RxtProcess *o = [RxtProcess new];
        __weak RxtProcess *wo = o;
        [o setProcessb:^(id v) {
            wo.value = v;
            syncAtMain(^{
                [wo dispatch:v];
            });
        }];
        [self addNext:o];
        return o;
    };
}
- (RxtSignal *(^)(void))asyncAtMain {
    return ^RxtSignal* () {
        RxtProcess *o = [RxtProcess new];
        __weak RxtProcess *wo = o;
        [o setProcessb:^(id v) {
            wo.value = v;
            asyncAtMain(^{
                [wo dispatch:v];
            });
        }];
        [self addNext:o];
        return o;
    };
}
- (void (^)(NSString *))rlog {
    return ^void (NSString *format) {
        self.next(^(id v) {
            NSLog(format, v);
        });
    };
}
@end
