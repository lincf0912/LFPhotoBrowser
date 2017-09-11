//
//  LFActionSheetCell.m
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFActionSheetCell.h"

@interface LFActionSheetCell ()

@property (nonatomic, weak) UILabel *label;

@end

@implementation LFActionSheetCell

+(NSString *)identifier
{
    return NSStringFromClass([self class]);
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        [self customInit];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    UILabel *label = [[UILabel alloc] init];
    [self.contentView addSubview:label];
    self.label = label;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.label.text = nil;
    self.label.attributedText = nil;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    _label.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - setter／getter
- (void)setAttributedText:(NSAttributedString *)attributedText
{
    self.label.attributedText = attributedText;
}

- (NSAttributedString *)attributedText
{
    return self.label.attributedText;
}

@end
