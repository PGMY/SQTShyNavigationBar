//
//  SQTShyNavigationBar.h
//  SQTShyNavigationBar
//
//  Created by Charles Powell on 8/30/14.
//  Copyright (c) 2014 Charles Powell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQTShyNavigationBar : UINavigationBar

// Characteristics
@property (nonatomic) CGFloat shyHeight;
@property (nonatomic) CGFloat fullHeight;
@property (nonatomic) BOOL shouldSnap;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end


@interface UINavigationController (SQTShyNavigationBar)

@property (nonatomic, readonly) SQTShyNavigationBar *shyNavigationBar;

@end