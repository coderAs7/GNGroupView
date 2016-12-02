//
//  ViewController.m
//  Demo
//
//  Created by ccd on 16/12/1.
//  Copyright © 2016年 ccd. All rights reserved.
//

#import "ViewController.h"
#import "GNGroupView.h"
#import "GNTestTableViewController.h"
#import "GNBannerView.h"
#import "GNSelectBar.h"


#define KNavigationBarHeight 64


@interface ViewController () <GNGroupViewDelegate>

// 选择条 用来切换控制器
@property (nonatomic,weak) GNSelectBar *selectBar;
@property (nonatomic,weak) GNGroupView *groupView;
// 一个假的navigationBar , 在storyBoard中拖出来的
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (nonatomic,assign) CGRect selectBarFrame;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 禁止自动调整scrollView的位置
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // 创建banner
    GNBannerView *bannerView = [GNBannerView bannerView];
    CGRect bannerViewFrame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 150);
    
    // 创建选择条
    GNSelectBar *selectBar = [GNSelectBar selectBar];
    _selectBarFrame = CGRectMake(0, CGRectGetMaxY(bannerViewFrame), [UIScreen mainScreen].bounds.size.width, 40);
    [selectBar.button1 addTarget:self action:@selector(selectBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [selectBar.button2 addTarget:self action:@selector(selectBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [selectBar.button3 addTarget:self action:@selector(selectBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    _selectBar = selectBar;
    
    // 创建多个tableView
    GNTestTableViewController *vc1 = [[GNTestTableViewController alloc]init];
    GNTestTableViewController *vc2 = [[GNTestTableViewController alloc]init];
    GNTestTableViewController *vc3 = [[GNTestTableViewController alloc]init];
    
    // 添加控制器
    [self addChildViewController:vc1];
    [self addChildViewController:vc2];
    [self addChildViewController:vc3];
    
    // 创建groupView
    GNGroupView *groupView = [[GNGroupView alloc]initWithChildViewControllers:self.childViewControllers andBannerView:bannerView andBannerViewFrame:bannerViewFrame andSupendView:selectBar andSuspendViewFrame:_selectBarFrame];
    // 设置groupView的Frame
    groupView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 49);
    // 设置距离顶部多少悬浮
    groupView.suspendMargin = KNavigationBarHeight;
    groupView.delegate = self;
    _groupView = groupView;
    
    // 添加
    [self.view addSubview:groupView];
    
    // 将在storyBoard中拖出来的 _navigationBar 移动到顶层
    [self.view addSubview:_navigationBar];
}


- (void)selectBarButtonClick:(UIButton *)button{
    
    if (button == _selectBar.button1) {
        [_groupView selectChildViewControllerAtIndex:0];
        return;
    }
    if (button == _selectBar.button2) {
        [_groupView selectChildViewControllerAtIndex:1];
        return;
    }
    if (button == _selectBar.button3) {
        [_groupView selectChildViewControllerAtIndex:2];
        return;
    }
}


/*
 *   suspendViewFrame 一直发生改变的frame
 */
- (void)groupView:(GNGroupView *)groupView didChangeSupsendViewFrame:(CGRect)suspendViewFrame{
    
    CGFloat alpha = 1 - (suspendViewFrame.origin.y - KNavigationBarHeight) / (_selectBarFrame.origin.y - KNavigationBarHeight);
    _navigationBar.alpha = alpha;
}

/*
 *   即将滚动到哪个控制器... 当用户拖动滚动的时候会告知外界
 */
- (void)groupView:(GNGroupView *)groupView willScrollToViewControllerAtIndex:(NSInteger)index{
    NSLog(@"当前滚动到第 %zd个控制器",index);
}

@end

