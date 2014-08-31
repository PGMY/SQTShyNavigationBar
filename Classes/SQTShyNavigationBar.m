//
//  SQTShyNavigationBar.m
//  SQTShyNavigationBar
//
//  Created by Charles Powell on 8/30/14.
//  Copyright (c) 2014 Charles Powell. All rights reserved.
//

#import "SQTShyNavigationBar.h"

@interface SQTShyNavigationBar () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic) CGFloat zeroingOffset;

@end

@implementation SQTShyNavigationBar

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup {
    // Set default config
    _shyHeight = 20.0f;
    _fullHeight = self.frame.size.height;
    _shouldSnap = YES;
    _zeroingOffset = 0.0f;
    
    // Create pan recognizer
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panRecognizer.delegate = self;
}

#pragma mark - Scrolling/Panning

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update secret reference to scrollView
    self.scrollView = scrollView;
    // Update for scrollView position
    [self adjustFrameForOffset:[self offsetOfScrollView:scrollView]];
}

- (void)adjustFrame {
    [self adjustFrameForOffset:[self offsetOfScrollView:self.scrollView]];
}

- (void)adjustFrameForOffset:(CGFloat)offset {
    CGRect frame = self.frame;
    
    NSDictionary *locations = [self scrollLocationsForOffset:offset frame:frame];
    CGFloat minimumLocation = [locations[@"minimum"] floatValue];
    CGFloat maximumLocation = [locations[@"maximum"] floatValue];
    CGFloat originY = [locations[@"originY"] floatValue];
    CGFloat offsetOriginY = [locations[@"offsetOriginY"] floatValue];
    
    //CGFloat trueFraction = (originY - minimumLocation)/(maximumLocation - minimumLocation);
    CGFloat offsetFraction = (offsetOriginY - minimumLocation)/(maximumLocation - minimumLocation);
    if (offsetFraction == 0.0f || offsetFraction == 1.0f) {
        // Reset zeroing offset
        self.zeroingOffset = 0.0f;
    } else {
        originY = offsetOriginY;
    }
    
    // Bound originY
    originY = MAX(MIN(maximumLocation, originY), minimumLocation);
    
    // Use error to adjust animation speed
    CGFloat error = fabs(originY - frame.origin.y);
    
    frame.origin.y = originY;
    
    [UIView animateWithDuration:error/500.0f
                     animations:^{
                         self.frame = frame;
                     }];
}

- (CGFloat)offsetOfScrollView:(UIScrollView *)scrollView {
    return scrollView.contentInset.top + scrollView.contentOffset.y;
}

- (NSDictionary *)scrollLocationsForOffset:(CGFloat)offset frame:(CGRect)frame {
    CGFloat extraStatusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height - 20.0f;
    CGFloat defaultLocation = [self defaultLocation];
    
    CGFloat minimumLocation = (defaultLocation + (self.shyHeight - defaultLocation)) - frame.size.height;
    CGFloat maximumLocation = defaultLocation;
    
    CGFloat originY = MAX(MIN(maximumLocation, defaultLocation - offset), minimumLocation);
    CGFloat offsetOriginY = MAX(MIN(maximumLocation, defaultLocation - offset + self.zeroingOffset), minimumLocation);
    
    NSDictionary *locations = @{@"minimum" : @(minimumLocation),
                                @"maximum" : @(maximumLocation),
                                @"originY" : @(originY),
                                @"offsetOriginY" : @(offsetOriginY)};
    return locations;
}

#pragma mark - Pan Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    // Check if user interaction has stopped
    if ((recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) &&
        !self.scrollView.decelerating && self.shouldSnap) {
        CGRect frame = self.frame;
        NSDictionary *locations = [self scrollLocationsForOffset:[self offsetOfScrollView:self.scrollView] frame:frame];
        CGFloat minimumLocation = [locations[@"minimum"] floatValue];
        CGFloat maximumLocation = [locations[@"maximum"] floatValue];
        CGFloat originY = [locations[@"originY"] floatValue];
        CGFloat fraction = (originY - minimumLocation)/(maximumLocation - minimumLocation);
        if (fraction > 0.0f) {
            // Scroll is not at minimum position, snap back to max
            frame.origin.y = maximumLocation;
            // Set this position as the zeroing offset
            self.zeroingOffset = [self offsetOfScrollView:self.scrollView];
        } else {
            // Fraction is zero, snap to min
            frame.origin.y = minimumLocation;
            // Reset zeroing offset
            self.zeroingOffset = 0.0f;
        }
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             self.frame = frame;
                         }];
    }
}

#pragma mark - Frame Management

- (CGFloat)defaultLocation {
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            return [UIApplication sharedApplication].statusBarFrame.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return 0.0f;
            break;
        default:
            return 20.0f;
            break;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = [super sizeThatFits:size];
    // Change navigation bar height. The height must be even, otherwise there will be a white line above the navigation bar.
    newSize.height = self.fullHeight;
    return newSize;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (void)setCenter:(CGPoint)center {
    CGRect preFrame = self.frame;
    
    // Set center to make subviews happy
    [super setCenter:center];
    
    // Handle startup case
    if (preFrame.origin.y == 0.0f) {
        //return;
    }
    
    [self adjustFrame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - Custom Getters/Setters

- (void)setScrollView:(UIScrollView *)scrollView {
    if (scrollView == _scrollView) {
        return;
    }
    
    _scrollView = scrollView;
    [self.panRecognizer.view removeGestureRecognizer:self.panRecognizer];
    [_scrollView addGestureRecognizer:self.panRecognizer];
}

@end


#pragma mark - Support

@implementation UINavigationController (SQTShyNavigationBar)

- (SQTShyNavigationBar *)shyNavigationBar {
    UINavigationBar *navBar = self.navigationBar;
    if ([navBar isKindOfClass:[SQTShyNavigationBar class]]) {
        return (SQTShyNavigationBar *)navBar;
    }
    
    return nil;
}

@end