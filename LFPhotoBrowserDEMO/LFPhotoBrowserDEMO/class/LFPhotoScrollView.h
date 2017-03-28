//
//  LFScrollView.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/11/22.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFPhotoScrollView : UIScrollView

/** 重写父类方法（对UISlider的滑动判断） */
- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view;
@end
