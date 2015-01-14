//
//  ViewController.m
//  FlipStepper
//
//  Created by dajing on 1/14/15.
//  Copyright (c) 2015 freedj. All rights reserved.
//

#import "ViewController.h"
#import "FlipStepperView.h"

@interface ViewController ()

@property (nonatomic, strong) FlipStepperView *fv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.fv = [[FlipStepperView alloc] initWithFrame:CGRectMake(100, 60, 200, 200)];
    self.fv.shownNumber = 2015;
    self.fv.bgColor = [UIColor colorWithRed:0.447 green:0.614 blue:0.801 alpha:1.000];
    [self.fv show];
    
    [self.view addSubview:self.fv];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)increaseStepper:(id)sender {
    [self.fv stepUp];
}

- (IBAction)decreaseStepper:(id)sender {
    [self.fv stepDown];
}

@end
