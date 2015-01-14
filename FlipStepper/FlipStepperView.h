//
//  FlipStepperView.h
//  FlipClockDemo
//
//  Created by dajing on 1/14/15.
//  Copyright (c) 2015 Mechanical Pants Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlipStepperView : UIView

@property (nonatomic, assign) NSInteger shownNumber;
@property (nonatomic, strong) UIColor *bgColor;

- (void)stepUp;
- (void)stepDown;

- (void)show;

@end
