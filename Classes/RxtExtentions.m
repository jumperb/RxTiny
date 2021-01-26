//
//  RxtExtentions.m
//  RxTiny
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019 zct. All rights reserved.
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
- (NSMutableSet<RxtSignal *> *)_rxtObservers
{
    return objc_getAssociatedObject(self, rxtObserversAddr);
}
- (RxtSignal *(^)(NSString *pp))rxtObserve {
    return ^RxtSignal* (NSString *pp) {
        return [RxtPropertyObserver object:self property:pp];
    };
}
- (RxtSignal * (^)(NSString *noti))rxtNotiObserve {
    return ^RxtSignal* (NSString *noti) {
        return [RxtNotificationObserver object:self notification:noti object:nil];
    };
}

- (RxtSignal * (^)(NSString *noti, id obj))rxtNotiObserve2 {
    return ^RxtSignal* (NSString *noti, id obj) {
        return [RxtNotificationObserver object:self notification:noti object:obj];
    };
}
- (void)rxt_removeObserverWithProperty:(NSString *)property {
    NSMutableArray *needDelete = [NSMutableArray new];
    for (RxtSignal *o in self.rxtObservers) {
        if ([o isKindOfClass:[RxtPropertyObserver class]]) {
            RxtPropertyObserver *o2 = (RxtPropertyObserver *)o;
            if ([o2.propertyName isEqualToString:property]) {
                [needDelete addObject:o2];
            }
        }
    }
    for (RxtSignal *o in needDelete) {
        [self.rxtObservers removeObject:o];
    }
}
- (void)rxt_dealloc {
    RxtSignal *signal = [self _rxtDeallocSignal];
    if (signal) signal.push(nil);
    NSMutableSet *observers = [self _rxtObservers];
    if (observers) {
        NSSet *set = [observers copy];
        for (RxtSignal *ob in set) {
            [ob dispose];
        }
    }
    [self rxt_dealloc];
}

static const void *rxtDeallocSignalAddr = &rxtDeallocSignalAddr;
- (RxtSignal *)rxtDeallocSignal {
    [NSObject rxt_setup];
    RxtSignal *o = objc_getAssociatedObject(self, rxtDeallocSignalAddr);
    if (!o) {
        o = [RxtSignal lazy];
        objc_setAssociatedObject(self, rxtDeallocSignalAddr, o, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return o;
}
- (RxtSignal *)_rxtDeallocSignal {
    return objc_getAssociatedObject(self, rxtDeallocSignalAddr);
}

- (void)rxt_observeNotification:(NSString *)name object:(id)obj {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rxt_getNotification:) name:name object:obj];
}
- (void)rxt_getNotification:(NSNotification *)noti {
    
}
@end

@implementation UITableViewCell (rxt)
static const void *rxtOnReuseAddress_tableViewCell = &rxtOnReuseAddress_tableViewCell;
- (RxtSignal *)rxt_onReuse {
    RxtSignal *signal = objc_getAssociatedObject(self, rxtOnReuseAddress_tableViewCell);
    if (signal != nil) return signal;
    
    signal = [RxtSignal lazy];
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
    
    signal = [RxtSignal lazy];
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
