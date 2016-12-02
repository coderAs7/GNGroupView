//
//  GNGroupView.m
//  Test
//
//  Created by ccd on 16/6/23.
//  Copyright © 2016年 com.checaiduo. All rights reserved.
//

#import "GNGroupView.h"



@interface GNGroupView ()<UIScrollViewDelegate>

// 当前正在显示的scrollView
@property (nonatomic,weak) UIScrollView *currentScrollView;
/** 用来容纳那几个tableView的 */
@property (nonatomic,weak) UIScrollView *contentScrollView;
/** 内边距 */
@property (nonatomic,assign) CGFloat contentInsetTop;
@property (nonatomic,weak) UIView *bannerView;
@property (nonatomic,strong) UIView *suspendView;
@property (nonatomic,assign) CGRect bannerViewOriginalFrame;
@property (nonatomic,assign) CGRect suspendViewOriginalFrame;
@property (nonatomic,strong) NSArray *childViewControllers;
@property (nonatomic,assign) NSInteger selectedIndex;
// 记录开始拖动和结束拖动
@property (nonatomic,assign) BOOL isDragging;

@end

@implementation GNGroupView

- (instancetype)initWithChildViewControllers:(NSArray *)childViewControllers andBannerView:(UIView *)bannerView andBannerViewFrame:(CGRect)bannerViewFrame andSupendView:(UIView *)suspendView andSuspendViewFrame:(CGRect)suspendViewFrame{
    
    if (self = [super init]) {
        
        _suspendMargin = 64;
        
        _childViewControllers = childViewControllers;
        
        _bannerView = bannerView;
        _bannerView.frame = bannerViewFrame;
        _bannerViewOriginalFrame = bannerViewFrame;
        
        _suspendView = suspendView;
        _suspendView.frame = suspendViewFrame;
        _suspendViewOriginalFrame = suspendViewFrame;
        
        // contentView
        UIScrollView *contentScrollView = [[UIScrollView alloc]init];
        contentScrollView.pagingEnabled = YES;
        contentScrollView.delegate = self;
        contentScrollView.showsHorizontalScrollIndicator = NO;
        contentScrollView.scrollsToTop = NO;
        _contentScrollView = contentScrollView;
        
        _contentInsetTop = (bannerView.frame.size.height + suspendView.frame.size.height);
        
        // 遍历,添加,监听所有的TableView
        NSInteger count = childViewControllers.count;
        
        for (NSInteger i = 0; i < count ; i ++) {
            
            UITableViewController *VC = childViewControllers[i];
            [contentScrollView addSubview:VC.tableView];
            // 设置内边距
            VC.tableView.contentInset = UIEdgeInsetsMake(_contentInsetTop, 0, 0, 0);
            // kvo监听偏移量
            [VC.tableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
            VC.tableView.scrollsToTop = NO;
        }
        
        // 监听supend的frame改变
        [_suspendView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        // 设置currentView
        UIViewController *VC = childViewControllers[0];
        _currentScrollView = (UIScrollView *)VC.view;
        _currentScrollView.scrollsToTop = YES;
        
        // 添加
        [self addSubview:contentScrollView];
        [self addSubview:bannerView];
        [self addSubview:suspendView];
        
    }
    return self;
}


- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat selfWidth = self.frame.size.width;
    CGFloat selfHeight = self.frame.size.height;
    
    _contentScrollView.frame = self.bounds;
    _contentScrollView.contentSize = CGSizeMake(_childViewControllers.count * selfWidth, 0);
    
    // 遍历,添加,监听所有的TableView
    NSInteger count = _childViewControllers.count;
    
    for (NSInteger i = 0; i < count ; i ++) {
        UITableViewController *VC = _childViewControllers[i];
        VC.tableView.frame = CGRectMake(i * selfWidth, 0, selfWidth, selfHeight);
        VC.tableView.contentInset = UIEdgeInsetsMake(_contentInsetTop, 0, 0, 0);
    }
}


- (void)dealloc{
    NSInteger count = _childViewControllers.count;
    for (NSInteger i = 0; i < count ; i ++) {
        UITableViewController *VC = _childViewControllers[i];
        [VC.tableView removeObserver:self forKeyPath:@"contentOffset"];
    }
    [_suspendView removeObserver:self forKeyPath:@"frame"];
}


#pragma mark - public Methods

- (void)selectChildViewControllerAtIndex:(NSInteger)index{
    // 边界数据过滤
    if (index + 1 > _childViewControllers.count) {
        return;
    }
    if (index < 0 ) {
        return;
    }
    
    // 下面的两种考虑主要是用户拖动状态 和 点击按钮状态两种情况下不能共存
    // 如果用户正在拖动状态,那么禁止选择
    if (_isDragging) {
        return;
    }
    
    // 如果移动后和现在的位置一样,那么不进行移动
    CGFloat contentOffsetX = index * self.frame.size.width;
    if (contentOffsetX == self.contentScrollView.contentOffset.x) {
        return;
    }
    
    
    _selectedIndex = index;
    
    _currentScrollView.scrollsToTop = NO;
    _currentScrollView = nil;
    
    
    // 禁止自己的交互,防止用户点击了以后 又点击下拉刷新等操作,导致后面出错,
    self.userInteractionEnabled = NO;
    
    // 调整偏移量
    [self adjustContentOffsetWhenScrollViewWillBeginScrollAnimation];
    
    [self.contentScrollView setContentOffset:CGPointMake(_selectedIndex * self.frame.size.width, 0) animated:YES];
}



#pragma mark scrollView的代理方法

// 此处是监听那个点击按钮以后 调整尺寸的情况
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    // 获取当前页面是哪个
    UITableViewController *tableVC = _childViewControllers[_selectedIndex];
    // 记录当前的是哪个
    _currentScrollView = tableVC.tableView;
    
    // 调整当前即将显示的scrollView的偏移量
    [self adjustContentOffsetWhenScrollViewWillEndScrollingAnimationToTableView:_currentScrollView];
    
    // 恢复自己的可操作性,对应设置为NO的地方在 调用了selectChildViewControllerAtIndex 方法
    self.userInteractionEnabled = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    // 获取当前页面是哪个
    NSInteger page = (targetContentOffset -> x) / self.frame.size.width;
    
    UITableViewController *tableVC = _childViewControllers[page];
    
    _currentScrollView = tableVC.tableView;
    
    [self adjustContentOffsetWhenScrollViewWillEndScrollingAnimationToTableView:_currentScrollView];
    
    
    if ([self.delegate respondsToSelector:@selector(groupView:willScrollToViewControllerAtIndex:)]) {
        [self.delegate groupView:self willScrollToViewControllerAtIndex:page];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    _isDragging = YES;
    _currentScrollView.scrollsToTop = NO;
    _currentScrollView = nil;
    [self adjustContentOffsetWhenScrollViewWillBeginScrollAnimation];
}

// 滚动视图减速完成，滚动将停止时，调用该方法。一次有效滑动，只执行一次。
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    _isDragging = NO;
    
}
#pragma mark - private Methods

- (void)adjustContentOffsetWhenScrollViewWillBeginScrollAnimation{
    
    NSInteger count = _childViewControllers.count;
    for (NSInteger i = 0; i < count ; i ++) {
        
        UITableViewController *VC = _childViewControllers[i];
        // 如果处在了中间的位置
        if ((VC.tableView.contentOffset.y >= -1 * _contentInsetTop)&& (VC.tableView.contentOffset.y <= -1 * (  _suspendMargin + _suspendViewOriginalFrame.size.height))) {
            VC.tableView.contentOffset = CGPointMake(0, -1 * CGRectGetMaxY(_suspendView.frame));
            // 如果向下偏移了,那么说明可能是在刷新,也有可能是因为莫名其妙的原因导致了向下移动了
        }else if(VC.tableView.contentOffset.y < -1 * _contentInsetTop){
            CGFloat d_value = -1 * _contentInsetTop - VC.tableView.contentOffset.y;
            CGFloat newContentOffsetY = -1 * (CGRectGetMaxY(_suspendView.frame) + d_value);
            VC.tableView.contentOffset = CGPointMake(0, newContentOffsetY);
        }
    }
}





- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary <NSString *,id> *)change context:(void *)context
{
    
    if (object == _suspendView) {
        CGRect newFrame = [change[@"new"] CGRectValue];
        if ([self.delegate respondsToSelector:@selector(groupView:didChangeSupsendViewFrame:)]) {
            [self.delegate groupView:self didChangeSupsendViewFrame:newFrame];
        }
        return;
    }
    
    // 如果不是当前正在显示的tableView,那么忽略它的滚动
    if (object != _currentScrollView) {
        return;
    }
    // 这里是为了iOS10适配所写的代码,因为iOS10 莫名其妙的就不能回到顶部了,而且还有可能崩溃
    // 遍历一波,设置点击状态栏,回到顶部
    if (_currentScrollView.scrollsToTop == NO) {
        for (NSInteger i = 0; i < _childViewControllers.count; i++) {
            
            UIScrollView *scrollView = _childViewControllers[i];
            
            // 此处有一个bug.不知道如何解决,只能通过下面的代码解决
            if ([scrollView respondsToSelector:@selector(setScrollsToTop:)]) {
                scrollView.scrollsToTop = NO;
            }
        }
        _currentScrollView.scrollsToTop = YES;
    }
    // 这里是为了iOS10适配所写的代码,因为iOS10 莫名其妙的就不能回到顶部了,而且还有可能崩溃
    
    CGPoint newOffset = [change[@"new"] CGPointValue];
    CGFloat newOffsetY = newOffset.y;
    
    
    CGRect suspendViewFrame = _suspendViewOriginalFrame;
    CGRect bannerViewFrame = _bannerViewOriginalFrame;
    
    
    // 回到顶部bug修复
    if (newOffsetY <= -_contentInsetTop) {
        _suspendView.frame = _suspendViewOriginalFrame;
        _bannerView.frame = _bannerViewOriginalFrame;
        return;
    }
    if (newOffsetY >= -1 * (_suspendMargin + _suspendViewOriginalFrame.size.height)) {
        suspendViewFrame.origin.y = _suspendMargin;
        bannerViewFrame.origin.y = _suspendMargin - _bannerViewOriginalFrame.size.height;
        
        _suspendView.frame = suspendViewFrame;
        _bannerView.frame = bannerViewFrame;
        return;
    }
    
    suspendViewFrame.origin.y -= (newOffsetY + _contentInsetTop);
    bannerViewFrame.origin.y -= (newOffsetY + _contentInsetTop);
    _suspendView.frame = suspendViewFrame;
    _bannerView.frame = bannerViewFrame;
    
}



- (void)adjustContentOffsetWhenScrollViewWillEndScrollingAnimationToTableView:(UIScrollView *)tableView{
    
    //#warning 后来增加的判断罢了....认为没有足够的空间往上滚动了
    if (tableView.contentSize.height <= self.frame.size.height - _suspendMargin) {
        // 设置banner也向下滚动
        self.userInteractionEnabled = NO;
        [UIView animateWithDuration:.5 animations:^{
            [tableView setContentOffset:CGPointMake(0,-1 * _contentInsetTop) animated:NO];
            _bannerView.frame = _bannerViewOriginalFrame;
            _suspendView.frame = _suspendViewOriginalFrame;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
        return;
    }
    // 理论上只要满足了这个条件,就是已经达到了悬浮的状态...但是实际上,由于引用了MJ,导致于有时候这个条件也是成立的,但是 实际上tableView只是向上滚动了一点点
    // 如果滚动的已经超过了BannerView的frame.如果超过了...
    if (tableView.contentOffset.y + _contentInsetTop > _contentInsetTop - CGRectGetMaxY(_suspendView.frame))
        
    {
        // 说明悬浮了
        if (tableView.contentOffset.y >= -1 * (_suspendMargin + _suspendViewOriginalFrame.size.height)) {
            // 计算需要滚动上去多少
            CGFloat offsetY = _suspendView.frame.origin.y - _suspendMargin;
            // 判断是否有足够的空间以供往上滚
            BOOL isHasEnoughOffsetY = tableView.contentSize.height - tableView.frame.size.height - tableView.contentOffset.y >= offsetY;
            // 如果有足够的空间
            if (isHasEnoughOffsetY) {
                
                CGPoint contentOffset = tableView.contentOffset;
                contentOffset.y += offsetY;
                // 禁止自己的交互,避免发生意外
                self.userInteractionEnabled = NO;
                
                [UIView animateWithDuration:.5 animations:^{
                    tableView.contentOffset = contentOffset;
                } completion:^(BOOL finished) {
                    self.userInteractionEnabled = YES;
                }];
            }else{// 认为没有足够的空间往上滚了. 那只能滚动banner 和 悬浮的View了
                
                CGRect bannerViewFrame = _bannerView.frame;
                CGRect supendViewFrame = _suspendView.frame;
                
                bannerViewFrame.origin.y -= offsetY;
                supendViewFrame.origin.y -= offsetY;
                
                // 禁止自己的交互,避免发生意外
                self.userInteractionEnabled = NO;
                
                [UIView animateWithDuration:.5 animations:^{
                    _bannerView.frame = bannerViewFrame;
                    _suspendView.frame = supendViewFrame;
                } completion:^(BOOL finished) {
                    self.userInteractionEnabled = YES;
                }];
            }
            // 并没有悬浮,只是偶尔出现了一些小问题罢了
        }else{}
    }
    else
        // 其实此时似乎忽略了一种情况,就是tableView也滚动了到上面
        // 理想状态是tableView 处于刷新状态
        // 说明下拉刷新了 或者 tableView滚动到更下面了
    {
        // 计算需要向下滚动多少
        CGFloat offsetY = _currentScrollView.contentOffset.y * -1 - CGRectGetMaxY(_suspendView.frame);
        CGRect bannerViewFrame = _bannerView.frame;
        CGRect supendViewFrame = _suspendView.frame;
        
        bannerViewFrame.origin.y += offsetY;
        supendViewFrame.origin.y += offsetY;
        
        if (CGRectGetMaxY(supendViewFrame) >= _contentInsetTop) {
            bannerViewFrame = _bannerViewOriginalFrame;
            supendViewFrame = _suspendViewOriginalFrame;
        }
        // 此时应该调整banner和suspends的位置
        // 禁止自己的交互,避免发生意外
        self.userInteractionEnabled = NO;
        [UIView animateWithDuration:.5 animations:^{
            _bannerView.frame = bannerViewFrame;
            _suspendView.frame = supendViewFrame;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    }
    tableView.scrollsToTop = YES;
}



@end
