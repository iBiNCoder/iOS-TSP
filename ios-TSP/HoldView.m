//
//  HoldView.m
//  ios-TSP
//
//  Created by Michael on 17/2/9.
//  Copyright © 2017年 Michael. All rights reserved.
//

#include <math.h>
#import <Foundation/Foundation.h>
#import "HoldView.h"

@interface HoldView()
@property (nonatomic, strong) NSMutableArray<NSValue *> *cities;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<NSNumber *> *> *graph;//储存城市之间的距离的邻接矩阵,自己到自己记作MAX
@end

@implementation HoldView {
    dispatch_semaphore_t _sem;
}

- (NSMutableArray<NSValue *> *)cities {
    if (_cities == nil) {
        _cities = @[].mutableCopy;
    }
    return _cities;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _sem = dispatch_semaphore_create(0);
        __weak typeof(self) weakSelf = self;
        _redrawBlock = ^{
            [weakSelf drawLinesAndPoints];
        };
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.redrawBlock();
    dispatch_semaphore_signal(_sem);
}

- (void)drawLinesAndPoints {
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    for (int i = 0; i < self.cities.count; i++) {
        CGPoint p = [self.cities[i] CGPointValue];
        CGRect rect = CGRectMake(p.x - self.radius, p.y - self.radius, self.radius * 2, self.radius * 2);
        UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
        [UIColor.orangeColor setFill];
        [ovalPath fill];
        if (i == 0) {
            [bezierPath moveToPoint:p];
            continue;
        }
        [bezierPath addLineToPoint:p];
    }
    [UIColor.orangeColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];
    /*
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (int i = 0; i < self.cities.count; i++) {
        CGPoint p = [self.cities[i] CGPointValue];
        CGContextAddArc(context, p.x, p.y, self.radius, 0, 2 * M_PI, 0);
        [[UIColor orangeColor] setFill];
        CGContextDrawPath(context, kCGPathFill);
        if (i == 0) {
            continue;
        }
        CGPoint preP = [self.cities[i - 1] CGPointValue];
        CGPoint aPoints[2];
        aPoints[0] = p;
        aPoints[1] = preP;
        CGContextAddLines(context, aPoints, 2);
        [[UIColor orangeColor] setStroke];
        CGContextDrawPath(context, kCGPathStroke);
    }
     */
}

- (void)drawLines {
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (int i = 0; i < self.cities.count; i++) {
        CGPoint p = [self.cities[i] CGPointValue];
        if (i == 0) {
            CGContextMoveToPoint(context, p.x, p.y);
        }
        CGContextAddLineToPoint(context, p.x, p.y);
    }
    [[UIColor orangeColor] setStroke];
    CGContextDrawPath(context, kCGPathStroke);
}

- (void)drawPoints {
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (NSValue *value in self.cities) {
        CGPoint p = [value CGPointValue];
        CGContextAddArc(context, p.x, p.y, self.radius, 0, 2 * M_PI, 0);
        [[UIColor orangeColor] setFill];
        CGContextDrawPath(context, kCGPathFill);
    }
}

- (void)setRandomCitiesWithCount:(NSUInteger)cityCount radius:(CGFloat)radius {
    _sem = dispatch_semaphore_create(0);
    self.radius = radius;
    self.cities = @[].mutableCopy;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    for (int i = 0; i < cityCount; i++) {
        CGFloat x = radius + arc4random() % ((uint32_t)(width - 2 * radius) + 1);
        CGFloat y = radius + arc4random() % ((uint32_t)(height - 2 * radius) + 1);
        CGPoint p = CGPointMake(x, y);
        [self.cities addObject:[NSValue valueWithCGPoint:p]];
    }
    
    __weak typeof(self) weakSelf = self;
    self.redrawBlock = ^{
        [weakSelf drawPoints];
    };
    [weakSelf setNeedsDisplay];
}

- (void)setCities:(NSMutableArray<NSValue *> *)cities radius:(CGFloat)radius {
    self.radius = radius;
    self.cities = [cities mutableCopy];
}

- (CGFloat)totalDistanceWithCities:(NSMutableArray<NSValue *> *)cities {
    CGFloat distance;
    for (int i = 1; i < cities.count; i++) {
        CGPoint p1 = [cities[i - 1] CGPointValue];
        CGPoint p2 = [cities[i] CGPointValue];
        CGFloat delta = sqrt(pow((p1.x - p2.x), 2) + pow((p1.y - p2.y), 2));
        distance += delta;
    }
    return distance;
}

- (NSMutableArray<NSValue *> *)randomExchangeTwoItemWithArray:(NSMutableArray<NSValue *> *)array {       //随机置换数组中两个不同的城市
    NSUInteger count = array.count;
    NSUInteger c1 = arc4random_uniform((u_int32_t)count);
    NSUInteger c2 = arc4random_uniform((u_int32_t)count);
    while (c1 == c2) {
        c1 = arc4random_uniform((u_int32_t)count);
        c2 = arc4random_uniform((u_int32_t)count);
    }
    [array exchangeObjectAtIndex:c1 withObjectAtIndex:c2];
    return array;
}

- (void)simulatedAnnealingMethod1 {    //模拟退火算法

    if (!self.cities) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.redrawBlock = ^{
        [weakSelf drawLinesAndPoints];
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CGFloat temperature = weakSelf.cities.count * 10000;                                              //temperature:初始温度
        NSUInteger iter = 5000;                                                                           //iter:内部蒙特卡洛循环迭代次数
        NSUInteger l = 1;                                                                                 //l:统计迭代次数
        while(temperature > 0.001) {                                                                      //最终温度0.001
            dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
            for (int i = 1; i < iter; i++) {
                CGFloat len1 = [weakSelf totalDistanceWithCities:weakSelf.cities];                                 //原路线总距离
                NSMutableArray *tmp_city = [weakSelf randomExchangeTwoItemWithArray:[weakSelf.cities mutableCopy]];//产生随机扰动
                CGFloat len2 = [weakSelf totalDistanceWithCities:tmp_city];                               //计算新路线总距离
                CGFloat delta_e = len2 - len1;                                                            //新老距离的差值，相当于能量
                if (delta_e < 0) {                                                                        //新路线好于旧路线，用新路线代替旧路线
                    weakSelf.cities = [tmp_city mutableCopy];
                } else {                                                                                  //温度越低，越不太可能接受新解；新老距离差值越大，越不太可能接受新解
                    if (exp(-delta_e / temperature) > (rand() / (float)RAND_MAX)) {                            //以概率选择是否接受新解
                        weakSelf.cities = [tmp_city mutableCopy];                                         //可能得到较差的解
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf setNeedsDisplay];
            });
            NSLog(@"%zd---%f---%f", l++, temperature, [weakSelf totalDistanceWithCities:weakSelf.cities]);//打印执行情况
            temperature *= 0.99;                                                                          //温度不断下降
        }
        weakSelf.endBlock();
    });
}

- (void)randomExchangeTwoIndexWithArray:(int *)array {  //随机置换数组两个不同的城市
    int count = (int)self.cities.count;
    int c1 = (int)arc4random_uniform((u_int32_t)count);
    int c2 = (int)arc4random_uniform((u_int32_t)count);
    while (c1 == c2) {
        c1 = (int)arc4random_uniform((u_int32_t)count);
        c2 = (int)arc4random_uniform((u_int32_t)count);
    }
    array[c1] += array[c2];
    array[c2] = array[c1] - array[c2];
    array[c1] -= array[c2];
}

- (void)simulatedAnnealingMethod2 {                     //模拟退火算法2
    if (!self.cities) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.redrawBlock = ^{
        [weakSelf drawLinesAndPoints];
    };
    
    int count = (int)self.cities.count;
    
    [self createGraphWithCities:weakSelf.cities];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CGFloat temperature = weakSelf.cities.count * 10000;                                              //temperature:初始温度
        NSUInteger iter = 5000;                                                                           //iter:内部蒙特卡洛循环迭代次数
        NSUInteger l = 1;                                                                                 //l:统计迭代次数
        
        NSMutableArray *originCities = [weakSelf.cities mutableCopy];
        NSMutableArray *newCities = @[].mutableCopy;
        int *citiesPath, tempCons1[count], tempCons2[count];
        for (int i = 0; i < count; i++) {
            tempCons1[i] = i;
        }
        citiesPath = tempCons1;
        
        while(temperature > 0.001) {                                                                      //最终温度0.001
            dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
            for (int i = 1; i < iter; i++) {
                double len1 = [weakSelf distance:citiesPath];                                             //原路线总距离
                int *anOtherPath = (citiesPath == tempCons1 ? tempCons2 : tempCons1);
                
                for (int i = 0; i < count; i++) {
                    anOtherPath[i] = citiesPath[i];
                }
                [weakSelf randomExchangeTwoIndexWithArray:anOtherPath];                                   //产生随机扰动
                
                double len2 = [weakSelf distance:anOtherPath];                                            //计算新路线总距离
                
                double delta_e = len2 - len1;                                                             //新老距离的差值，相当于能量
                if (delta_e < 0) {                                                                        //新路线好于旧路线，用新路线代替旧路线
                    citiesPath = anOtherPath;
                } else {                                                                                  //温度越低，越不太可能接受新解；新老距离差值越大，越不太可能接受新解
                    if (exp(-delta_e / temperature) > (rand() / (float)RAND_MAX)) {                        //以概率选择是否接受新解
                        citiesPath = anOtherPath;                                                         //可能得到较差的解
                    }
                }
            }
            for (int i = 0; i < count; i++) {
                newCities[i] = originCities[citiesPath[i]];
            }
            self.cities = [newCities mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf setNeedsDisplay];
            });
            NSLog(@"%zd---%f---%f", l++, temperature, [weakSelf totalDistanceWithCities:weakSelf.cities]);//打印执行情况
            temperature *= 0.99;                                                                          //温度不断下降
        }
        weakSelf.endBlock();
    });
}


//蚁群算法
- (void)antColonyOptimizationMethod {
    if (!self.cities) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.redrawBlock = ^{
        [weakSelf drawLinesAndPoints];
    };
    
    NSUInteger N = weakSelf.cities.count;//城市的数量
    
    [self createGraphWithCities:weakSelf.cities];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        int M = (int)N / 2;         //蚂蚁的数量
        int IN = 1;                 //初始化的信息素的量
        double phe[N][N];           //每条路径上的信息素的量
        double add[N][N];           //代表相应路径上的信息素的增量
        double yita[N][N];          //启发函数,yita[i][j]=1/graph[i][j]
        int vis[M][N];              //标记已经走过的城市
        int map[M][N];              //map[K][N]记录第K只蚂蚁走的路线
        double solution[M];         //记录某次循环中每只蚂蚁走的路线的距离
        int bestway[N];             //记录最近的那条路线
        double bestsolution = MAXFLOAT;
        int NcMax = 10000;          //代表迭代次数,理论上迭代次数越多所求的解更接近最优解,最具有说服力
        double alpha, betra, rou, Q;//信息素系数、启发因子系数、蒸发系数、信息量
        alpha = 2; betra = 2; rou = 0.7; Q = 5000;
        
        int NC = 0;
        int i, j, k;
        int s;
        double drand, pro, psum;
        
        for(i = 0; i < N; i++) {
            for(j = 0; j < N; j++) {
                phe[i][j] = IN;                                                    //信息素初始化
                if(i != j) yita[i][j] = 100.0 / [weakSelf.graph[i][j] doubleValue];//期望值,与距离成反比
            }
        }
        
        memset(map, -1, sizeof(map));     //把蚂蚁走的路线置空(map进行清零操作)
        memset(vis, 0, sizeof(vis));      //0表示未访问,1表示已访问
        srand((unsigned int)time(NULL)); //随机数发生器的初始化函数,srand和rand()配合使用产生伪随机数序列
        
        NSMutableArray *originCities = [weakSelf.cities mutableCopy];
        NSMutableArray *newCities = @[].mutableCopy;
        
        while(NC++ <= NcMax) {
            dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
            
            for(k = 0; k < M; k++) {
                map[k][0] = (k+NC) % N; //给每只蚂蚁分配一个起点,并且保证起点在N个城市里
                vis[k][map[k][0]] = 1;  //将起点标记为已经访问
            }
            s = 1;
            while(s < N) {
                for(k = 0; k < M; k++) {
                    psum = 0;
                    for(j = 0; j < N; j++) {
                        if(vis[k][j] == 0) {
                            psum += pow(phe[map[k][s-1]][j], alpha) * pow(yita[map[k][s-1]][j], betra);
                        }
                    }
                    drand = rand() / (float)RAND_MAX; //生成一个小于1的随机数
                    pro = 0;
                    for(j = 0; j < N; j++) {
                        if(vis[k][j] == 0) pro += pow(phe[map[k][s-1]][j], alpha) * pow(yita[map[k][s-1]][j], betra) / psum;
                        if(pro > drand) break;
                    }
                    vis[k][j] = 1;                   //将走过的城市标记起来
                    map[k][s] = j;                   //记录城市的顺序
                }
                s++;
            }
            memset(add, 0, sizeof(add));
            for(k = 0; k < M; k++) {                 //计算本次中的最短路径
                solution[k] = [self distance:map[k]];//蚂蚁k所走的路线的总长度
                if(solution[k] < bestsolution) {
                    bestsolution = solution[k];
                    for(i = 0; i < N; ++i) {
                        bestway[i] = map[k][i];
                    }
                }
            }
            for(k = 0; k < M; k++) {
                for(j = 0; j < N-1; j++) {
                    add[map[k][j]][map[k][j+1]] += Q / solution[k];
                }
                add[N-1][0] += Q / solution[k];
            }
            for(i = 0; i < N; i++) {
                for(j = 0; j < N; j++) {
                    phe[i][j] = phe[i][j] * rou + add[i][j];
                    if(phe[i][j] < 0.0001) phe[i][j] = 0.0001;//设立一个下界
                    else if(phe[i][j] > 20) phe[i][j] = 20;   //设立一个上界,防止启发因子的作用被淹没
                }
            }
            memset(vis, 0, sizeof(vis));
            memset(map, -1, sizeof(map));
            
            for (int i = 0; i < N; i++) {
                newCities[i] = originCities[bestway[i]];
            }
            self.cities = [newCities mutableCopy];
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf setNeedsDisplay];
            });
            NSLog(@"%zd--%f", NC, bestsolution);              //打印执行情况
        }
        weakSelf.endBlock();
    });
}

- (double)distance:(int *)p {                                 //计算p路线的总长度
    double d = 0;
    int i;
    for(i = 0; i < self.cities.count - 1; i++) {
        d += self.graph[*(p+i)][*(p + i + 1)].doubleValue;
    }
    d += self.graph[*(p+i)][*p].doubleValue;
    return d;
}

- (void)createGraphWithCities:(NSMutableArray<NSValue *> *)cities {
    if (!self.graph) {
        self.graph = @[].mutableCopy;
        for (int i = 0; i < self.cities.count; i++) {
            self.graph[i] = @[].mutableCopy;
        }
    }
    
    for(int i = 0; i < cities.count - 1; i++) {
        self.graph[i][i] = [NSNumber numberWithFloat:MAXFLOAT];//自己到自己标记为无穷大
        for(int j = i + 1; j < cities.count; j++) {
            CGPoint pi = [cities[i] CGPointValue];
            CGPoint pj = [cities[j] CGPointValue];
            self.graph[j][i] = self.graph[i][j] = [NSNumber numberWithFloat:sqrt(pow((pi.x - pj.x), 2) + pow((pi.y - pj.y), 2))];
        }
    }
    self.graph[cities.count - 1][cities.count - 1] = [NSNumber numberWithFloat:MAXFLOAT];
}

@end
