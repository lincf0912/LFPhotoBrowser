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

@interface LFActionSheet() <UITableViewDataSource,UITableViewDelegate>
/** 标题 */
@property (nonatomic, copy) NSString *menuTitle;
/** 列表 */
@property (nonatomic, weak) UITableView *tableView;
/** 按钮数组 */
@property (nonatomic, strong) NSArray <NSArray *>*buttonArray;
/** 特殊按钮，标记红色 */
@property (nonatomic, assign) BOOL hasDestructiveButton;
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
        _menuTitle = title;
        _didSelectBlock = didSelectBlock;
        _hasDestructiveButton = NO;
        /* 获取按钮数组 */
        NSMutableArray *otherButtons = [NSMutableArray arrayWithArray:otherButtonTitles];
        if(destructiveButtonTitle){ /** 将特殊按钮归类到最顶层 */
            _hasDestructiveButton = YES;
            [otherButtons insertObject:destructiveButtonTitle atIndex:0];
        }
        /** 补充取消按钮 */
        if (cancelButtonTitle.length == 0) {
            cancelButtonTitle = @"取消";
        }
        self.buttonArray = @[[otherButtons copy], @[cancelButtonTitle]];
        [self buildUI];
    }
    return self;
}

#pragma mark - 创建UI
-(void)buildUI
{
    CGFloat totalHeight = 0;
    for (NSArray *subArr in self.buttonArray) {
        totalHeight += subArr.count * lf_tabelViewCell_Height;
    }
    totalHeight += MAX((self.buttonArray.count-1), 0) * lf_tableViewFooter_Height;
    
    UILabel *headerView = nil;
    if(self.menuTitle){
        headerView = [[UILabel alloc]init];
        NSAttributedString *attrString = [self.menuTitle lf_actionSheetAttributedStringWithFontSize:17.f color:[UIColor grayColor] alignment:NSTextAlignmentCenter lineBreakMode:NSLineBreakByTruncatingTail];
        /** 获取字体的高度 */
        CGFloat fontHeight = [attrString boundingRectWithSize:CGSizeMake(SCREEN_WIDTH, CGFLOAT_MAX) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height + 2.f;
        headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, fontHeight+30);
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        headerView.attributedText = attrString;
        headerView.backgroundColor = [UIColor whiteColor];
        headerView.alpha = 0.9f;
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
    if ([tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
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


#pragma mark - TabelViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.buttonArray.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *arr = self.buttonArray[section];
    return arr.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return lf_tabelViewCell_Height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return self.buttonArray.count == section ? 0.1f : lf_tableViewFooter_Height;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [LFActionSheetCell identifier];
    LFActionSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil){
        cell = [[LFActionSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.alpha = 0.6;
    NSArray * rowsTextArr = self.buttonArray[indexPath.section];
    NSString *text = rowsTextArr[indexPath.row];
    UIColor *textColor = (_hasDestructiveButton && indexPath.section ==0 && indexPath.row ==0) ? [UIColor redColor] : [UIColor blackColor];
    
    cell.attributedText = [text lf_actionSheetAttributedStringWithFontSize:14.f color:textColor alignment:NSTextAlignmentCenter lineBreakMode:NSLineBreakByTruncatingTail];
   
    return cell;
};

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.didSelectBlock) {
        NSInteger index = 0;
        for (NSInteger i=0; i<self.buttonArray.count; i++) {
            if (i >= indexPath.section) {
                NSArray *subArr = self.buttonArray[i];
                NSInteger count = subArr.count;
                if (i == indexPath.section) {
                    count -= indexPath.row+1;
                }
                index += count;
            }
        }
        self.didSelectBlock(index);
    }
    [self actionSheetDidDisappear];
}

#pragma mark - 触碰销毁
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.didSelectBlock) {
        self.didSelectBlock(0);
    }
    [self actionSheetDidDisappear];
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
