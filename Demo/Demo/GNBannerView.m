//
//  GNBannerView.m
//  Demo
//
//  Created by ccd on 16/12/1.
//  Copyright © 2016年 ccd. All rights reserved.
//

#import "GNBannerView.h"

@implementation GNBannerView

+ (instancetype)bannerView{
    return [[[NSBundle mainBundle]loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] lastObject];
}

@end
