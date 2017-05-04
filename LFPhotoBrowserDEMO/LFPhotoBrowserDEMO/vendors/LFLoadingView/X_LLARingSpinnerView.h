//
//  X_LLARingSpinnerView.h
//  X_LLARingSpinnerView
//
//  Created by Lukas Lipka on 05/04/14.
//  Copyright (c) 2014 Lukas Lipka. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface X_LLARingSpinnerView : UIView

@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic) CGFloat lineWidth;
/** 进度显示*/
@property (nonatomic ,assign) float  progress;

- (void)startAnimating;
- (void)stopAnimating;

@end
