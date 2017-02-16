//
//  HoldView.h
//  ios-TSP
//
//  Created by Michael on 17/2/9.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HoldView : UIView

@property (nonatomic, strong) void(^redrawBlock)(void);
@property (nonatomic, strong) void(^endBlock)(void);

- (void)setRandomCitiesWithCount:(NSUInteger)cityCount radius:(CGFloat)radius;  //随机产生点
- (void)setCities:(NSMutableArray<NSValue *> *)cities radius:(CGFloat)radius;   //设置城市数组
- (void)drawLinesAndPoints;
- (void)drawLines;
- (void)drawPoints;

- (void)simulatedAnnealingMethod1;//模拟退火算法
- (void)simulatedAnnealingMethod2;//模拟退火算法
- (void)antColonyOptimizationMethod;//蚁群算法

@end
