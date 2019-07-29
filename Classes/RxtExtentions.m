//
//  RxtExtentions.m
//  RxTiny
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019 migu. All rights reserved.
//

#import "RxtExtentions.h"
#import "RxTiny.h"
#import <objc/runtime.h>
#import <Hodor/NSObject+ext.h>

@implementation NSObject (Rxt)
@dynamic rxtObservers;
static const void *rxtObserversAddr = &rxtObserversAddr;
- (NSMutableSet<RxtPropertyObserver *> *)rxtObservers
{
    id res = objc_getAssociatedObject(self, rxtObserversAddr);
    if (!res)
    {
        res = [NSMutableSet new];
        objc_setAssociatedObject(self, rxtObserversAddr, res, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return res;
}
- (void)setRxtObservers:(NSMutableSet<RxtPropertyObserver *> *)rxtObservers
{
    objc_setAssociatedObject(self, rxtObserversAddr, rxtObservers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (RxtSignal *(^)(NSString *pp))rxtObserve {
    return ^RxtSignal* (NSString *pp) {
        return [RxtPropertyObserver object:self property:pp];
    };
}
@end

@implementation UITableViewCell (rxt)
static const void *rxtOnReuseAddress_tableViewCell = &rxtOnReuseAddress_tableViewCell;
- (RxtSignal *)rxt_onReuse {
    RxtSignal *signal = objc_getAssociatedObject(self, rxtOnReuseAddress_tableViewCell);
    if (signal != nil) return signal;
    
    signal = [RxtSignal new];
    objc_setAssociatedObject(self, rxtOnReuseAddress_tableViewCell, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject methodSwizzleWithClass:UITableViewCell.class origSEL:@selector(prepareForReuse) overrideSEL:@selector(rxt_prepareForReuse)];
    });
    return signal;
}
- (void)rxt_prepareForReuse {
    [self rxt_prepareForReuse];
    RxtSignal *signal = objc_getAssociatedObject(self, rxtOnReuseAddress_tableViewCell);
    if (signal) {
        signal.push(nil);
    }
}
@end

@implementation UICollectionReusableView (rxt)
static const void *rxtOnReuseAddress_collectCell = &rxtOnReuseAddress_collectCell;
- (RxtSignal *)rxt_onReuse {
    RxtSignal *signal = objc_getAssociatedObject(self, rxtOnReuseAddress_collectCell);
    if (signal != nil) return signal;
    
    signal = [RxtSignal new];
    objc_setAssociatedObject(self, rxtOnReuseAddress_collectCell, signal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject methodSwizzleWithClass:UICollectionReusableView.class origSEL:@selector(prepareForReuse) overrideSEL:@selector(rxt_prepareForReuse)];
    });
    return signal;
}
- (void)rxt_prepareForReuse {
    [self rxt_prepareForReuse];
    RxtSignal *signal = objc_getAssociatedObject(self, rxtOnReuseAddress_collectCell);
    if (signal) {
        signal.push(nil);
    }
}
@end
