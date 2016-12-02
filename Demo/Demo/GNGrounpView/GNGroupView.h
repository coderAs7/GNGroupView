//
//  GNGroupView.h
//  Test
//
//  Created by ccd on 16/6/23.
//  Copyright © 2016年 com.checaiduo. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GNGroupView;

@protocol GNGroupViewDelegate <NSObject>

@optional

/*
 *   即将滚动到哪个控制器... 当用户拖动滚动的时候会告知外界
 */
- (void)groupView:(GNGroupView *)groupView willScrollToViewControllerAtIndex:(NSInteger)index;

/*
 *   suspendViewFrame 一直发生改变的frame
 */
- (void)groupView:(GNGroupView *)groupView didChangeSupsendViewFrame:(CGRect)suspendViewFrame;
@end



@interface GNGroupView : UIView
// 初始化
- (instancetype)initWithChildViewControllers:(NSArray *)childViewControllers andBannerView:(UIView *)bannerView andBannerViewFrame:(CGRect)bannerViewFrame andSupendView:(UIView *)suspendView andSuspendViewFrame:(CGRect)suspendViewFrame;

// 距离顶部多少以后悬浮,默认是64
@property (nonatomic,assign) CGFloat suspendMargin;

// 选择滚动到某个ViewController
- (void)selectChildViewControllerAtIndex:(NSInteger)index;

// 代理
@property (nonatomic,weak) NSObject<GNGroupViewDelegate> *delegate;

@end
