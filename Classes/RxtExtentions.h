//
//  RxtExtentions.h
//  RxTiny
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019 migu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class RxtSignal;
@class RxtPropertyObserver;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Rxt)
@property (nonatomic, strong) NSMutableSet<RxtPropertyObserver *> *rxtObservers;
@property (nonatomic, readonly) RxtSignal *(^rxtObserve)(NSString *pp);
@end

@interface UITableViewCell (rxt)
@property (nonatomic, readonly) RxtSignal *rxt_onReuse;
@end

@interface UICollectionReusableView (rxt)
@property (nonatomic, readonly) RxtSignal *rxt_onReuse;
@end

NS_ASSUME_NONNULL_END
