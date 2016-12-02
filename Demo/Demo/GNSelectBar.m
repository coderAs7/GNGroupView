
//
//  GNSelectBar.m
//  Demo
//
//  Created by ccd on 16/12/1.
//  Copyright © 2016年 ccd. All rights reserved.
//

#import "GNSelectBar.h"

@implementation GNSelectBar


+ (instancetype)selectBar{
    return [[[NSBundle mainBundle]loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] lastObject];
}
@end
