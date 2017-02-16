//
//  ViewController.m
//  ios-TSP
//
//  Created by Michael on 17/2/9.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "ViewController.h"
#import "HoldView.h"

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>
#include<time.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) HoldView *holdView;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *simuButton;
@property (weak, nonatomic) IBOutlet UIButton *antButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addHoldView];
}

- (void)addHoldView {
    [self.stackView layoutIfNeeded];
    HoldView *holdView = [[HoldView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.stackView.frame), self.view.frame.size.width, self.view.frame.size.height - 20 - self.stackView.frame.size.height)];
    self.holdView = holdView;
    [self.view addSubview:holdView];
}

- (IBAction)createPoints:(id)sender {
    self.holdView = nil;
    [self addHoldView];
    NSUInteger cityCount = 50;     //随机城市数量
    CGFloat radius = 2;            //城市小圆点半径
    [self.holdView setRandomCitiesWithCount:cityCount radius:radius];
    
    __weak typeof(self) weakSelf = self;
    self.holdView.endBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.simuButton.enabled = YES;
            weakSelf.antButton.enabled = YES;
        });
    };
    self.holdView.endBlock();
}

- (IBAction)simulatedAnnealing:(id)sender {
    self.simuButton.enabled = NO;
    self.antButton.enabled = NO;
    [self.holdView simulatedAnnealingMethod1];
}

- (IBAction)antColonyOptimization:(id)sender {
    self.simuButton.enabled = NO;
    self.antButton.enabled = NO;
    [self.holdView antColonyOptimizationMethod];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
