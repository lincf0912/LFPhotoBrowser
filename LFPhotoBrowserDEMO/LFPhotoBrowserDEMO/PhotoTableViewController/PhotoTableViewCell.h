//
//  PhotoTableViewCell.h
//  LFPhotoBrowserDEMO
//
//  Created by LamTsanFeng on 2016/10/20.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *url;

-(CGRect)obtainPhotoViewFrameInView:(UIView *)view;
@end
