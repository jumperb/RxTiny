//
//  RxtExtentions.h
//  RxTiny
//
//  Created by zct on 2019/7/25.
//  Copyright © 2019 zct. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class RxtSignal;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Rxt)
@property (nonatomic, readonly) NSMutableSet<RxtSignal *> *rxtObservers;
@property (nonatomic, readonly) RxtSignal *(^rxtNotiObserve)(NSString *notification);
@property (nonatomic, readonly) RxtSignal *(^rxtNotiObserve2)(NSString *notification, id obj);
@property (nonatomic, readonly) RxtSignal *rxtDeallocSignal;
@end

@interface UITableViewCell (rxt)
@property (nonatomic, readonly) RxtSignal *rxt_onReuse;
@end

@interface UICollectionReusableView (rxt)
@property (nonatomic, readonly) RxtSignal *rxt_onReuse;
@end

NS_ASSUME_NONNULL_END
