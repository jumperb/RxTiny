//
//  RxTiny.h
//  JsonView
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019年 zct. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxtExtentions.h"

typedef void (^RxtNextB)(id v);
typedef id (^RxtMapB)(id v);
typedef BOOL (^RxtFilterB)(id v);
typedef void (^RxtProcessB)(id v);

#pragma mark - 信号
@interface RxtSignal: NSObject
//给信号输入值
@property (nonatomic, readonly) void (^push)(id newValue);
//绑定信号，追加信号
@property (nonatomic, readonly) RxtSignal *(^bind)(RxtSignal *s);
//如果收到信号s，则让自己死掉
@property (nonatomic, readonly) RxtSignal *(^dieAt)(RxtSignal *s);
//跟obj一起死
@property (nonatomic, readonly) RxtSignal *(^dieWith)(NSObject *obj);
//杀死信号
@property (nonatomic, readonly) RxtSignal *(^die)(void);
//下一步操作
@property (nonatomic, readonly) RxtSignal *(^next)(RxtNextB);
//过滤器
@property (nonatomic, readonly) RxtSignal *(^filter)(RxtFilterB);
//映射信号数据
@property (nonatomic, readonly) RxtSignal *(^map)(RxtMapB);
//是否订阅就触发一次
@property (nonatomic) BOOL lazy;
//以初始值初始化
+ (instancetype)fromValue:(id)initValue;
+ (instancetype)lazy;
//直接输出值
- (id)outputValue;
//解除绑定，s是指下级信号
- (void)unBind:(RxtSignal *)s;
//失效
- (void)dispose;
@end

#pragma mark - 暂停闸门（一般不直接创建，用 pausable / sample 操作符）

/**
 带暂停开关的信号：
 - paused == NO：正常向下游派发
 - paused == YES：只记录末值（value / hasValue），不向下游派发；恢复时由 pausable 补发末值
 */
@interface RxtPause: RxtSignal

// NO = 放行（默认），YES = 暂停
@property (nonatomic, assign) BOOL paused;

// 无视 paused，立即把当前末值派发一次（无末值则什么都不做）
- (void)emit;

@end

#pragma mark - 值观察者，一般不直接使用，请使用宏
@interface RxtPropertyObserver: RxtSignal
@property (nonatomic, readonly) id ref;
@property (nonatomic, readonly) NSString *propertyName;
+ (instancetype)object:(id)ref property:(NSString *)property;
@end

#pragma mark - 通知观察者，一般不直接使用，请使用宏
@interface RxtNotificationObserver: RxtSignal
+ (instancetype)object:(id)ref notification:(NSString *)notification object:(id)object;
@end

#pragma mark - 订阅，一般不直接使用，请使用宏
@interface RxtProprtySubscriber: RxtSignal
@property (nonatomic) RxtSignal *bindSingalDontUse; //宏辅助属性，不要直接使用
+ (instancetype)object:(id)ref property:(NSString *)property;
@end

#pragma mark - 合并
RxtSignal* RxtMerge(NSArray *nodes);

#pragma mark - 快捷宏

#define rxo(ref, propertyName) [RxtPropertyObserver object:ref property:((NO&&((void)ref.propertyName, NO))?nil:@#propertyName)]
#define rxp(ref, propertyName) [RxtProprtySubscriber object:ref property:((NO&&((void)ref.propertyName, NO))?nil:@#propertyName)]
#define rxsp(ref, propertyName) [RxtProprtySubscriber object:ref property:((NO&&((void)ref.propertyName, NO))?nil:@#propertyName)].bindSingalDontUse
#define rxmerge(...) RxtMerge(@[__VA_ARGS__])
#define rxn(ref, notiName) [RxtNotificationObserver object:ref notification:notiName object:nil]

#pragma mark - 补充转换器

typedef void (^RxtToBoolB)(BOOL v);
typedef void (^RxtToStringB)(NSString *v);
typedef void (^RxtToDoubleB)(double v);
typedef void (^RxtToFloatB)(float v);
typedef void (^RxtToCharB)(char v);
typedef void (^RxtToUIntegerB)(NSUInteger v);
typedef void (^RxtToIntegerB)(NSInteger v);
typedef void (^RxtToIntB)(int v);
typedef void (^RxtToLongB)(long v);
typedef void (^RxtToLongLongB)(long long v);
typedef void (^RxtToUnsignedIntB)(unsigned int v);
typedef void (^RxtToUnsignedLongB)(unsigned long v);
typedef void (^RxtToUnsignedLongLongB)(unsigned long long v);
typedef void (^RxtToColorB)(UIColor *color);

@interface RxtSignal (covert)
@property (nonatomic, readonly) RxtSignal *(^toString)(RxtToStringB);
@property (nonatomic, readonly) void (^toBool)(RxtToBoolB);
@property (nonatomic, readonly) void (^toFloat)(RxtToFloatB);
@property (nonatomic, readonly) void (^toDouble)(RxtToDoubleB);
@property (nonatomic, readonly) void (^toChar)(RxtToCharB);
@property (nonatomic, readonly) void (^toInteger)(RxtToIntegerB);
@property (nonatomic, readonly) void (^toUInteger)(RxtToUIntegerB);
@property (nonatomic, readonly) void (^toInt)(RxtToIntB);
@property (nonatomic, readonly) void (^toLong)(RxtToLongB);
@property (nonatomic, readonly) void (^toLongLong)(RxtToLongLongB);
@property (nonatomic, readonly) void (^toUnsignedInt)(RxtToUnsignedIntB);
@property (nonatomic, readonly) void (^toUnsignedLong)(RxtToUnsignedLongB);
@property (nonatomic, readonly) void (^toUnsignedLongLong)(RxtToUnsignedLongLongB);

@property (nonatomic, readonly) RxtSignal *(^revertBool)(void);
@property (nonatomic, readonly) RxtSignal *(^notNull)(void);
@property (nonatomic, readonly) RxtSignal *(^onChanged)(void);
@property (nonatomic, readonly) RxtSignal *(^skip)(NSUInteger times);
@property (nonatomic, readonly) RxtSignal *(^toColor)(RxtToColorB);


@property (nonatomic, readonly) RxtSignal *(^syncAtMain)(void);
@property (nonatomic, readonly) RxtSignal *(^asyncAtMain)(void);
@property (nonatomic, readonly) RxtSignal *(^asyncAtMainIfNeed)(void);

@property (nonatomic, readonly) void (^rlog)(NSString *format);
@end

#pragma mark - 暂停 / 采样

@interface RxtSignal (pause)

// gate 输出 BOOL：YES 放行 / NO 暂停；暂停期间只记末值，NO→YES 时补发末值一次
@property (nonatomic, readonly) RxtSignal *(^pausable)(RxtSignal *gate);

// 只在 sampler 发信号时输出自己的末值（自身不主动派发）
@property (nonatomic, readonly) RxtSignal *(^sample)(RxtSignal *sampler);

@end
