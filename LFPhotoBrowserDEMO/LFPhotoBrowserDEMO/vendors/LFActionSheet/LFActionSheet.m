//
//  LFActionSheet.m
//  LFActionSheetDemo
//
//  Created by LamTsanFeng on 2017/4/27.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFActionSheet.h"
#import "NSString+LFActionSheetAttributed.h"
#import "LFActionSheetCell.h"
#import "UIView+LFFindTopView.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
/** 每行的高度 */
#define lf_tabelViewCell_Height 44.f
/** 分隔间距 */
#define lf_tableViewFooter_Height 5.f

int defaultButtonIndex = -1;

@interface LFActionSheet() <UITableViewDataSource,UITableViewDelegate>
/** 标题 */
@property (nonatomic, copy) NSString *menuTitle;
/** 列表 */
@property (nonatomic, weak) UITableView *tableView;
/** 按钮数组 */
@property (nonatomic, strong) NSArray <NSString *>*buttonArray;
/** 特殊按钮，标记红色 */
@property (nonatomic, assign) BOOL hasDestructiveButton;
/** 取消按钮 */
@property (nonatomic, assign) BOOL hasCancelButton;
/** 回调 */
@property (nonatomic, copy) LFActionSheetBlock didSelectBlock;

@end

@implementation LFActionSheet

/** 初始化 */
- (instancetype)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSArray <NSString *>*)otherButtonTitles didSelectBlock:(LFActionSheetBlock)didSelectBlock
{
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _cancelButtonIndex = defaultButtonIndex;
        _destructiveButtonIndex = defaultButtonIndex;
        _firstOtherButtonIndex = defaultButtonIndex;
        _markButtonIndex = defaultButtonIndex;
        _menuTitle = title;
        _didSelectBlock = didSelectBlock;
        _hasDestructiveButton = NO;
        _hasCancelButton = NO;
        /* 获取按钮数组 */
        NSMutableArray *otherButtons = [NSMutableArray arrayWithArray:otherButtonTitles];
        if(destructiveButtonTitle){ /** 将特殊按钮归类到最顶层 */
            _hasDestructiveButton = YES;
            _destructiveButtonIndex = 0 ;
            _firstOtherButtonIndex = 1;
            [otherButtons insertObject:destructiveButtonTitle atIndex:0];
        }
        if (cancelButtonTitle) {
            _hasCancelButton = YES;
            [otherButtons addObject:cancelButtonTitle]; /** 返回按钮最低 */
        }
        self.buttonArray = [otherButtons copy];
        _numberOfButtons = otherButtons.count;
        _cancelButtonIndex = !_hasCancelButton ?: (_numberOfButtons - 1);
        
        [self buildUI];
    }
    return self;
}

- (NSInteger)indexButtonWithTitle:(nullable NSString *)title
{
     return [self.buttonArray indexOfObject:title];
}
- (nullable NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex
{
    return [self.buttonArray objectAtIndex:buttonIndex];
}

#pragma mark - 创建UI
-(void)buildUI
{
    /** 阻止其他手势 */
    UIButton *background = [UIButton buttonWithType:UIButtonTypeCustom];
    background.frame = self.bounds;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [background addTarget:self action:@selector(tapBackgroundView) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:background];
    
    CGFloat totalHeight = MAX(self.buttonArray.count, 1) * lf_tabelViewCell_Height;
    
    totalHeight += !self.hasCancelButton ?: lf_tableViewFooter_Height;
    
    UILabel *headerView = nil;
    if(self.menuTitle){
        headerView = [[UILabel alloc]init];
        NSAttributedString *attrString = [self.menuTitle lf_actionSheetAttributedStringWithFontSize:17.f color:[UIColor grayColor] alignment:NSTextAlignmentCenter lineBreakMode:NSLineBreakByTruncatingTail];
        /** 获取字体的高度 */
        CGFloat fontHeight = [attrString boundingRectWithSize:CGSizeMake(SCREEN_WIDTH, CGFLOAT_MAX) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height + 2.f;
        headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, fontHeight+30);
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        headerView.attributedText = attrString;
        headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.f];
        headerView.numberOfLines = 0;
        totalHeight += CGRectGetHeight(headerView.frame);
    }
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), totalHeight) style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.alwaysBounceVertical = NO;
    tableView.scrollEnabled = NO;
    /** 这个设置iOS9以后才有，主要针对iPad，不设置的话，分割线左侧空出很多 */
    if ([tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    /** 解决ios7中tableview每一行下面的线向右偏移的问题 */
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if(headerView){
        tableView.tableHeaderView = headerView;
    }
    [self addSubview:tableView];
    self.tableView = tableView;
    
    UIView *tableBGView = [[UIView alloc] initWithFrame:self.tableView.frame];
    tableBGView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    tableBGView.backgroundColor = [UIColor grayColor];
    [self addSubview:tableBGView];
    
    [self bringSubviewToFront:self.tableView];
}

/** 显示在最顶层 */
- (void)show
{
    UIView *keyBoardView = [UIView lf_findKeyboardView];
    if(keyBoardView){
        [keyBoardView addSubview:self];
    }else{
        UIWindow * window=[[[UIApplication sharedApplication] delegate]window];
        [window addSubview:self];
    }
    [self actionSheetDidAppear];
}

/** 显示某个view上 */
- (void)showInView:(UIView *)view
{
    if (view) {        
        [view addSubview:self];
        [self actionSheetDidAppear];
    }
}


#pragma mark - TabelViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.hasCancelButton) { /** 有取消 */
        if (_numberOfButtons > 1) { /** 有其他 */
            return 2;
        }
    }
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.hasCancelButton) {
        if (section == 0) {
            return _numberOfButtons - 1;
        } else {
            return 1;
        }
    }
    
    return MAX(_numberOfButtons, 1); /** 最少有1个 */
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return lf_tabelViewCell_Height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return self.buttonArray.count == section ? 0.1f : lf_tableViewFooter_Height;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, lf_tableViewFooter_Height)];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    footerView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.f];
    return footerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [LFActionSheetCell identifier];
    LFActionSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil){
        cell = [[LFActionSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor whiteColor];
        cell.alpha = 0.6;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSInteger index = indexPath.row;
    if (indexPath.section == 1) {
        index = _numberOfButtons-1;
    }
    if (index < self.buttonArray.count) {
        NSString *text = self.buttonArray[index];
        UIColor *textColor = (_hasDestructiveButton && indexPath.section ==0 && indexPath.row ==0) ? [UIColor redColor] : [UIColor blackColor];
        
        cell.attributedText = [text lf_actionSheetAttributedStringWithFontSize:14.f color:textColor alignment:NSTextAlignmentCenter lineBreakMode:NSLineBreakByTruncatingTail];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        if (indexPath.section == 0 && _numberOfButtons > 1 && index == self.markButtonIndex) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
   
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_numberOfButtons) { /** 有数据才触发 */
        if (self.didSelectBlock) {
            NSInteger index = 0;
            if (indexPath.section == 0) {
                index = indexPath.row;
            } else if (indexPath.section == 1) {
                index = self.cancelButtonIndex;
            }
            self.didSelectBlock(self, index);
        }
        [self actionSheetDidDisappear];
    }
}

#pragma mark - 触碰销毁
- (void)tapBackgroundView
{
    if (self.hasCancelButton) {
        if (self.didSelectBlock) {
            self.didSelectBlock(self, self.cancelButtonIndex);
        }
        [self actionSheetDidDisappear];
    }
}

#pragma mark - 视图显示
-(void)actionSheetDidAppear
{
    CGRect frame = self.tableView.frame;
    frame.origin.y = CGRectGetHeight(self.frame) - frame.size.height;
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.tableView.frame = frame;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    } completion:^(BOOL finished) {
        
    }];
}
#pragma mark - 视图销毁
-(void)actionSheetDidDisappear
{
    CGRect frame = self.tableView.frame;
    frame.origin.y = CGRectGetHeight(self.frame);
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.tableView.frame = frame;
        self.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end
