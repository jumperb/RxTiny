//
//  RxTiny.m
//  JsonView
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019年 migu. All rights reserved.
//

#import "RxTiny.h"

#pragma mark - 信号

@interface RxtSignal ()
@property (nonatomic) id value;
@property (nonatomic) BOOL deaded;
@property (nonatomic) NSMutableSet<RxtSignal*> *subSignals;
@end

@interface RxtNext: RxtSignal
@property (nonatomic) RxtNextB nextb;
@end

@interface RxtFilter: RxtSignal
@property (nonatomic) RxtFilterB filterb;
@end

@interface RxtNotNull: RxtSignal
@end

@interface RxtMap: RxtSignal
@property (nonatomic) RxtMapB mapb;
@end

@implementation RxtSignal

- (NSMutableSet<RxtSignal*> *)subSignals {
    if (!_subSignals) _subSignals = [NSMutableSet new];
    return _subSignals;
}

- (void)push:(id)newValue {
    self.value = newValue;
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
    if (self.deaded) return;
    [signal push:value];
}
- (RxtSignal *)addNext:(RxtSignal *)signal {
    return [self addNext:signal setupTriger:YES];
}
- (RxtSignal *)addNext:(RxtSignal *)signal setupTriger:(BOOL)setupTriger{
    [self.subSignals addObject:signal];
    if (setupTriger) [self dispatchOne:signal value:[self outputValue]];
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
        __weak typeof(self) weakSelf = self;
        [o setNextb:^(id v) {
            [weakSelf dispose];
        }];
        [n addNext:o setupTriger:NO];
        return self;
    };
}
- (RxtSignal *(^)(NSObject *obj))dieWith {
    return ^RxtSignal* (NSObject *obj) {
        RxtNext *o = [RxtNext new];
        __weak typeof(self) weakSelf = self;
        [o setNextb:^(id v) {
            [weakSelf dispose];
        }];
        [obj.rxtDeallocSignal addNext:o setupTriger:NO];
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
    if (self.nextb) self.nextb(newValue);
}
@end

@implementation RxtFilter
- (void)dispatchOne:(RxtSignal *)signal value:(id)value {
    if (!self.filterb) return;
    if (!self.filterb(value)) return;
    [super dispatchOne:signal value:value];
}
@end

@implementation RxtNotNull
- (void)dispatchOne:(RxtSignal *)signal value:(id)value {
    if (!value) return;
    [super dispatchOne:signal value:value];
}
@end

@implementation RxtMap
- (void)push:(id)newValue {
    if (!self.mapb) return;
    [super push:self.mapb(newValue)];
}
@end

#pragma mark - 值观察者
@interface RxtPropertyObserver ()
@property (nonatomic, weak) id ref;
@property (nonatomic) NSString *propertyName;
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
- (void)removeObserver{
    [self removeObserver:self.ref]; //dealloc中self.ref提前释放
}
- (void)removeObserver:(id)ref {
    if (self.observing) {
        self.observing = NO;
        [ref removeObserver:self forKeyPath:self.propertyName];
        [((NSObject *)ref).rxtObservers removeObject:self];
    }
}
- (void)dealloc
{
    [self removeObserver];
}
- (void)dispose {
    [super dispose];
    [self removeObserver];
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

//
//@property (nonatomic, readonly) RxtSignal *(^toString)(RxtToStringB);
//@property (nonatomic, readonly) RxtSignal *(^toBool)(RxtToBoolB);
//@property (nonatomic, readonly) RxtSignal *(^toFloat)(RxtToFloatB);
//@property (nonatomic, readonly) RxtSignal *(^toDouble)(RxtToDoubleB);
//@property (nonatomic, readonly) RxtSignal *(^toChar)(RxtToCharB);
//@property (nonatomic, readonly) RxtSignal *(^toInteger)(RxtToIntegerB);
//@property (nonatomic, readonly) RxtSignal *(^toUInteger)(RxtToUIntegerB);
//@property (nonatomic, readonly) RxtSignal *(^toInt)(RxtToIntB);
//@property (nonatomic, readonly) RxtSignal *(^toLong)(RxtToLongB);
//@property (nonatomic, readonly) RxtSignal *(^toLongLong)(RxtToLongLongB);
//@property (nonatomic, readonly) RxtSignal *(^toUnsignedInt)(RxtToUnsignedIntB);
//@property (nonatomic, readonly) RxtSignal *(^toUnsignedLong)(RxtToUnsignedLongB);
//@property (nonatomic, readonly) RxtSignal *(^toUnsignedLongLong)(RxtToUnsignedLongLongB);

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
- (RxtSignal *(^)(RxtToColorB))toColor {
    return ^RxtSignal* (RxtToColorB b) {
        return self.map(^id(id v) {
            UIColor *color = nil;
            if ([v isKindOfClass:[NSString class]]) {
                color = [UIColor colorWithString:v];
            }
            else if ([v isKindOfClass:[NSNumber class]]) {
                color = [UIColor colorWithHex:[v intValue]];
            }
            else if ([v isKindOfClass:[UIColor class]]) {
                color = v;
            }
            if (b) b(color);
            return color;
        });
    };
}
- (void (^)(NSString *))log {
    return ^void (NSString *format) {
        self.next(^(id v) {
            NSLog(format, v);
        });
    };
}
@end
