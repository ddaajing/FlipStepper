//
//  FlipStepperView.m
//  FlipClockDemo
//
//  Created by dajing on 1/14/15.
//  Copyright (c) 2015 Mechanical Pants Software. All rights reserved.
//

typedef enum {
    kFlipAnimationNormal = 0,
    kFlipAnimationTopDown,
    kFlipAnimationBottomDown
} kFlipAnimationState;

#import "FlipStepperView.h"

@interface FlipStepperView () {
    kFlipAnimationState animationState;
    
    UIView *topHalfFrontView;
    UIView *bottomHalfFrontView;
    UIView *topHalfBackView;
    UIView *bottomHalfBackView;

    CGFloat duration;
    CGFloat zDepth;
}

@property (nonatomic, assign) NSInteger plusClicked;

@property (nonatomic, strong) UIView *currentView;
@property (nonatomic, strong) UIView *nextView;
@property (nonatomic, strong) UIView *preView;

@end

@implementation FlipStepperView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        duration = 0.5f;
        zDepth = 1000.f;
    }
    return self;
}

- (void)show {
    UIView *newView = [self viewWithText:[NSString stringWithFormat:@"%li", self.shownNumber]];
    self.currentView = newView;
    
    [self addSubview:self.currentView];
}

- (UIView *)viewWithText:(NSString *)text; {
    UIView *aNewView = nil;
    
    // Make a label
    UILabel *digitLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    digitLabel.font = [UIFont systemFontOfSize:(self.bounds.size.width - 20) / 3];
    digitLabel.text = text;
    digitLabel.tag = 101;
    digitLabel.textAlignment = NSTextAlignmentCenter;
    digitLabel.textColor = [UIColor whiteColor];
    digitLabel.backgroundColor = [UIColor clearColor];
    [digitLabel sizeToFit];
    digitLabel.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);

    // Add the label to a wrapper view for corners.
    aNewView = [[UIView alloc] initWithFrame:CGRectZero];
    aNewView.frame = self.bounds;
    aNewView.layer.cornerRadius = 10.f;
    aNewView.layer.masksToBounds = YES;
    aNewView.backgroundColor = self.bgColor;
    
    [aNewView addSubview:digitLabel];

    // Put a dividing line over the label:
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = self.bgColor;
    lineView.frame = CGRectMake(0.f, 0.f, aNewView.frame.size.width, 3.f);
    lineView.center = digitLabel.center;
    
    [aNewView addSubview:lineView];
    
    aNewView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    return aNewView;
}

- (NSArray *)snapshotsForView:(UIView *)aView {
    // Render the tapped view into an image:
    UIGraphicsBeginImageContextWithOptions(aView.bounds.size, aView.layer.opaque, 0.f);
    [aView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // The size of each part is half the height of the whole image:
    CGSize size = CGSizeMake(renderedImage.size.width, renderedImage.size.height / 2);
    
    UIImage *top = nil;
    UIImage *bottom = nil;
    UIGraphicsBeginImageContextWithOptions(size, aView.layer.opaque, 0.f);{{
        // Draw into context, bottom half is cropped off
        [renderedImage drawAtPoint:CGPointZero];
        
        // Grab the current contents of the context as a UIImage
        // and add it to our array
        top = UIGraphicsGetImageFromCurrentImageContext();
    }}
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContextWithOptions(size, aView.layer.opaque, 0.f); {{
        // Now draw the image starting half way down, to get the bottom half
        [renderedImage drawAtPoint:CGPointMake(CGPointZero.x, -renderedImage.size.height / 2)];
        
        // And store that image in the array too
        bottom = UIGraphicsGetImageFromCurrentImageContext();
    }}
    UIGraphicsEndImageContext();
    
    UIImageView *topHalfView = [[UIImageView alloc] initWithImage:top];
    UIImageView *bottomHalfView = [[UIImageView alloc] initWithImage:bottom];
    
    NSArray *views = @[topHalfView, bottomHalfView];
    for (UIView *view in views) {
        [self setEdgeAntialiasingOn:view.layer];
    }
    
    return views;
}

/// Helper for enabling edge antialiasing on 7.0+.
- (void)setEdgeAntialiasingOn:(CALayer *)layer {
    // Only test this selector once.
    static BOOL deviceTested = NO;
    static BOOL deviceSupportsAntialiasing = NO;
    if (!deviceTested) {
        deviceTested = YES;
        deviceSupportsAntialiasing = [CALayer instancesRespondToSelector:@selector(setAllowsEdgeAntialiasing:)];
    }
    
    // Turn on edge antialiasing.
    if (deviceSupportsAntialiasing) {
        layer.allowsEdgeAntialiasing = YES;
    }
}

- (void)animateViewDown:(UIView *)aView withNextView:(UIView *)nextView withDuration:(CGFloat)aDuration {
    // Get snapshots for the first view:
    NSArray *frontViews = [self snapshotsForView:aView];
    topHalfFrontView = [frontViews firstObject];
    bottomHalfFrontView = [frontViews lastObject];
    
    // Move this view to be where the original view is:
    topHalfFrontView.frame = CGRectOffset(topHalfFrontView.frame, aView.frame.origin.x, aView.frame.origin.y);
    [self addSubview:topHalfFrontView];
    
    // Move the bottom half into place:
    bottomHalfFrontView.frame = topHalfFrontView.frame;
    bottomHalfFrontView.frame = CGRectOffset(bottomHalfFrontView.frame, 0.f, topHalfFrontView.frame.size.height);
    [self addSubview:bottomHalfFrontView];
    // And get rid of the original view:
//    [aView removeFromSuperview];
    
    // Get snapshots for the second view:
    NSArray *backViews = [self snapshotsForView:nextView];
    topHalfBackView = [backViews firstObject];
    bottomHalfBackView = [backViews lastObject];
    topHalfBackView.frame = topHalfFrontView.frame;
    // And place them in the view hierarchy:
    [self insertSubview:topHalfBackView belowSubview:topHalfFrontView];
    bottomHalfBackView.frame = bottomHalfFrontView.frame;
    [self insertSubview:bottomHalfBackView belowSubview:bottomHalfFrontView];
    
    ////////////////
    // Animations //
    ////////////////
    
    // Skewed identity for camera perspective:
    CATransform3D skewedIdentityTransform = CATransform3DIdentity;
    float zDistance = zDepth;
    skewedIdentityTransform.m34 = 1.0 / -zDistance;
    // We use this instead of setting a sublayer transform on our view's layer,
    // because that gives an undesirable skew on views not centered horizontally.
    
    // Top tile:
    // Set the anchor point to the bottom edge:
    CGPoint newTopViewAnchorPoint = CGPointMake(0.5, 1.0);
    CGPoint newTopViewCenter = [self center:topHalfFrontView.center movedFromAnchorPoint:topHalfFrontView.layer.anchorPoint toAnchorPoint:newTopViewAnchorPoint withFrame:topHalfFrontView.frame];
    topHalfFrontView.layer.anchorPoint = newTopViewAnchorPoint;
    topHalfFrontView.center = newTopViewCenter;
    
    // Add an animation to swing from top to bottom.
    CABasicAnimation *topAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    topAnim.beginTime = CACurrentMediaTime();
    topAnim.duration = aDuration;
    topAnim.fromValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
    topAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, -M_PI_2, 1.f, 0.f, 0.f)];
    topAnim.delegate = self;
    topAnim.removedOnCompletion = NO;
    topAnim.fillMode = kCAFillModeForwards;
    topAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [topHalfFrontView.layer addAnimation:topAnim forKey:@"topDownFlip"];
    
    // Bottom tile:
    // Change its anchor point:
    CGPoint newAnchorPointBottomHalf = CGPointMake(0.5f, 0.f);
    CGPoint newBottomHalfCenter = [self center:bottomHalfBackView.center movedFromAnchorPoint:bottomHalfBackView.layer.anchorPoint toAnchorPoint:newAnchorPointBottomHalf withFrame:bottomHalfBackView.frame];
    bottomHalfBackView.layer.anchorPoint = newAnchorPointBottomHalf;
    bottomHalfBackView.center = newBottomHalfCenter;
    
    // Add an animation to swing from top to bottom.
    CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    bottomAnim.beginTime = topAnim.beginTime + topAnim.duration;
    bottomAnim.duration = topAnim.duration / 4;
    bottomAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, M_PI_2, 1.f, 0.f, 0.f)];
    bottomAnim.toValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
    bottomAnim.delegate = self;
    bottomAnim.removedOnCompletion = NO;
    bottomAnim.fillMode = kCAFillModeBoth;
    bottomAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [bottomHalfBackView.layer addAnimation:bottomAnim forKey:@"bottomDownFlip"];
}

- (void)animateViewDown:(UIView *)aView withPreView:(UIView *)nextView withDuration:(CGFloat)aDuration; {
    // Get snapshots for the first view:
    NSArray *frontViews = [self snapshotsForView:nextView];
    topHalfFrontView = [frontViews firstObject];
    bottomHalfFrontView = [frontViews lastObject];
    
    // Move this view to be where the original view is:
    topHalfFrontView.frame = CGRectOffset(topHalfFrontView.frame, aView.frame.origin.x, aView.frame.origin.y);
    [self addSubview:topHalfFrontView];
    
    // Move the bottom half into place:
    bottomHalfFrontView.frame = topHalfFrontView.frame;
    bottomHalfFrontView.frame = CGRectOffset(bottomHalfFrontView.frame, 0.f, topHalfFrontView.frame.size.height);
    [self addSubview:bottomHalfFrontView];
    // And get rid of the original view:
    
    // Get snapshots for the second view:
    NSArray *backViews = [self snapshotsForView:aView];
//    [aView removeFromSuperview];
    
    topHalfBackView = [backViews firstObject];
    bottomHalfBackView = [backViews lastObject];
    topHalfBackView.frame = topHalfFrontView.frame;
    // And place them in the view hierarchy:
    [self insertSubview:topHalfBackView belowSubview:topHalfFrontView];
    bottomHalfBackView.frame = bottomHalfFrontView.frame;
    [self insertSubview:bottomHalfBackView belowSubview:bottomHalfFrontView];
    
    ////////////////
    // Animations //
    ////////////////
    
    // Skewed identity for camera perspective:
    CATransform3D skewedIdentityTransform = CATransform3DIdentity;
    float zDistance = zDepth;
    skewedIdentityTransform.m34 = 1.0 / -zDistance;
    // We use this instead of setting a sublayer transform on our view's layer,
    // because that gives an undesirable skew on views not centered horizontally.
    
    // Top tile:
    // Set the anchor point to the bottom edge:
    CGPoint newTopViewAnchorPoint = CGPointMake(0.5, 1.0);
    CGPoint newTopViewCenter = [self center:topHalfFrontView.center movedFromAnchorPoint:topHalfFrontView.layer.anchorPoint toAnchorPoint:newTopViewAnchorPoint withFrame:topHalfFrontView.frame];
    topHalfFrontView.layer.anchorPoint = newTopViewAnchorPoint;
    topHalfFrontView.center = newTopViewCenter;
    
    // Add an animation to swing from top to bottom.
    CABasicAnimation *topAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    topAnim.beginTime = CACurrentMediaTime();
    topAnim.duration = aDuration;
    topAnim.fromValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
    topAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, M_PI_2, 1.f, 0.f, 0.f)];
    topAnim.delegate = self;
    topAnim.removedOnCompletion = NO;
    topAnim.fillMode = kCAFillModeForwards;
    topAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [bottomHalfBackView.layer addAnimation:topAnim forKey:@"bottomDownFlip"];
    
    // Bottom tile:
    // Change its anchor point:
    CGPoint newAnchorPointBottomHalf = CGPointMake(0.5f, 0.f);
    CGPoint newBottomHalfCenter = [self center:bottomHalfBackView.center movedFromAnchorPoint:bottomHalfBackView.layer.anchorPoint toAnchorPoint:newAnchorPointBottomHalf withFrame:bottomHalfBackView.frame];
    bottomHalfBackView.layer.anchorPoint = newAnchorPointBottomHalf;
    bottomHalfBackView.center = newBottomHalfCenter;
    
    // Add an animation to swing from top to bottom.
    CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
    bottomAnim.beginTime = topAnim.beginTime + topAnim.duration;
    bottomAnim.duration = topAnim.duration / 4;
    bottomAnim.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(skewedIdentityTransform, -M_PI_2, 1.f, 0.f, 0.f)];
    bottomAnim.toValue = [NSValue valueWithCATransform3D:skewedIdentityTransform];
    bottomAnim.delegate = self;
    bottomAnim.removedOnCompletion = NO;
    bottomAnim.fillMode = kCAFillModeBoth;
    bottomAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [topHalfFrontView.layer addAnimation:bottomAnim forKey:@"topDownFlip"];
}

// Scales center points by the difference in their anchor points scaled to their frame size.
// Lets you move anchor points around without dealing with CA's implicit frame math.
- (CGPoint)center:(CGPoint)oldCenter movedFromAnchorPoint:(CGPoint)oldAnchorPoint toAnchorPoint:(CGPoint)newAnchorPoint withFrame:(CGRect)frame {
    //	NSLog(@"%s moving center (%.2f, %.2f) from oldAnchor (%.2f, %.2f) to newAnchor (%.2f, %.2f)", __func__,
    //		  oldCenter.x, oldCenter.y, oldAnchorPoint.x, oldAnchorPoint.y, newAnchorPoint.x, newAnchorPoint.y);
    CGPoint anchorPointDiff = CGPointMake(newAnchorPoint.x - oldAnchorPoint.x, newAnchorPoint.y - oldAnchorPoint.y);
    CGPoint newCenter = CGPointMake(oldCenter.x + (anchorPointDiff.x * frame.size.width),
                                    oldCenter.y + (anchorPointDiff.y * frame.size.height));
    //	NSLog(@"%s new center is (%.2f, %.2f) (frame size: (%.2f, %.2f))", __func__, newCenter.x, newCenter.y, frame.size.width, frame.size.height);
    return newCenter;
}

#pragma mark - CAAnimation delegate callbacks
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self changeAnimationState];
}

- (void)changeAnimationState {
    switch (animationState) {
        case kFlipAnimationNormal:
        {{
            UIView *aView = self.currentView;
            
            if (self.plusClicked) {
                self.nextView = [self viewWithText:[NSString stringWithFormat:@"%li", self.shownNumber + 1]];
                
                [self animateViewDown:aView withNextView:self.nextView withDuration:duration];
            }
            else {
                self.preView = [self viewWithText:[NSString stringWithFormat:@"%li", self.shownNumber - 1]];
                
                [self animateViewDown:aView withPreView:self.preView withDuration:duration];
            }
            
            animationState = kFlipAnimationTopDown;
        }}
            break;
        case kFlipAnimationTopDown:
            // Swap some tiles around:
            [bottomHalfBackView.superview bringSubviewToFront:bottomHalfBackView];
            
            animationState = kFlipAnimationBottomDown;
            break;
        case kFlipAnimationBottomDown:
        {{
            if (self.plusClicked) {
                ((UILabel *)[self.currentView viewWithTag:101]).text = [NSString stringWithFormat:@"%li", self.shownNumber + 1];

                [self.preView removeFromSuperview];
                self.shownNumber++;
            }
            else {
                ((UILabel *)[self.currentView viewWithTag:101]).text = [NSString stringWithFormat:@"%li", self.shownNumber - 1];

                [self.nextView removeFromSuperview];
                self.shownNumber--;
            }
            
            // Remove snapshots:
            [topHalfFrontView removeFromSuperview];
            [bottomHalfFrontView removeFromSuperview];
            [topHalfBackView removeFromSuperview];
            [bottomHalfBackView removeFromSuperview];
            topHalfFrontView = bottomHalfFrontView = topHalfBackView = bottomHalfBackView = nil;
            
            animationState = kFlipAnimationNormal;
        }}
            break;
    }
}

- (void)stepDown {
    self.plusClicked = NO;
    animationState = kFlipAnimationNormal;
    
    [self changeAnimationState];
}

- (void)stepUp {
    self.plusClicked = YES;
    animationState = kFlipAnimationNormal;
    
    [self changeAnimationState];
}

@end
