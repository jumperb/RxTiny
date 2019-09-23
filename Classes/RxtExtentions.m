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
static const void *rxtObserversAddr = &rxtObserversAddr;
+ (void)rxt_setup {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL deallocSel = NSSelectorFromString(@"dealloc");
        [NSObject methodSwizzleWithClass:self origSEL:deallocSel overrideSEL:@selector(rxt_dealloc)];
    });
}
- (NSMutableSet<RxtPropertyObserver *> *)rxtObservers
{
    [NSObject rxt_setup];
    id res = objc_getAssociatedObject(self, rxtObserversAddr);
    if (!res)
    {
        res = [NSMutableSet new];
        objc_setAssociatedObject(self, rxtObserversAddr, res, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return res;
}
- (NSMutableSet<RxtPropertyObserver *> *)_rxtObservers
{
    return objc_getAssociatedObject(self, rxtObserversAddr);
}
- (RxtSignal *(^)(NSString *pp))rxtObserve {
    return ^RxtSignal* (NSString *pp) {
        return [RxtPropertyObserver object:self property:pp];
    };
}
- (void)rxt_dealloc {
    RxtSignal *signal = [self _rxtDeallocSignal];
    if (signal) signal.push(nil);
    NSMutableSet *observers = [self _rxtObservers];
    if (observers) {
        NSSet *set = [observers copy];
        for (RxtPropertyObserver *ob in set) {
            [ob removeObserver];
        }
    }
    [self rxt_dealloc];
}

static const void *rxtDeallocSignalAddr = &rxtDeallocSignalAddr;
- (RxtSignal *)rxtDeallocSignal {
    [NSObject rxt_setup];
    RxtSignal *o = objc_getAssociatedObject(self, rxtDeallocSignalAddr);
    if (!o) {
        o = [RxtSignal new];
        objc_setAssociatedObject(self, rxtDeallocSignalAddr, o, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return o;
}
- (RxtSignal *)_rxtDeallocSignal {
    return objc_getAssociatedObject(self, rxtDeallocSignalAddr);
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
