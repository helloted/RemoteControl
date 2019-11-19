//
//  InfoViewController.m
//  RemoteControl
//
//  Created by iMac on 2019/10/28.
//  Copyright © 2019 iMac. All rights reserved.
//

#import "InfoViewController.h"
#import "Masonry.h"
#import <SVProgressHUD/SVProgressHUD.h>

#define COLOR_HEX(_hex)     [UIColor colorWithRed:((float)((_hex & 0xFF0000) >> 16)) / 255.0 \
green:((float)((_hex & 0xFF00)>> 8)) / 255.0 \
blue:((float) (_hex & 0xFF)) / 255.0 alpha:1.0f]

#define Margin 10
#define MainColor  COLOR_HEX(0x00C78C)

@interface InfoViewController ()<UITextViewDelegate>

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"使用说明";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UITextView *urlTextView = [[UITextView alloc]init];
    urlTextView.backgroundColor = [UIColor whiteColor];
    [urlTextView sizeToFit];
    [self.view addSubview:urlTextView];
    [urlTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(Margin);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
    }];
    urlTextView.text = @"1、首先下载Mac端应用程序http://www.helloted.com/mac_app/";
    

    urlTextView.attributedText = [self getContentLabelAttributedText];
    urlTextView.textAlignment = NSTextAlignmentLeft;
    urlTextView.delegate = self;
    urlTextView.editable = NO;        //必须禁止输入，否则点击将弹出输入键盘
    urlTextView.scrollEnabled = NO;
    urlTextView.textContainerInset = UIEdgeInsetsZero;
    urlTextView.textContainer.lineFragmentPadding = 0;
    urlTextView.linkTextAttributes = @{NSForegroundColorAttributeName:MainColor};
    
    
    UILabel *installedLabel = [[UILabel alloc]init];
    [self.view addSubview:installedLabel];
    installedLabel.text = @"2、Mac端安装并且打开MacControl,如下图";
    installedLabel.textColor = [UIColor lightGrayColor];
    [installedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(urlTextView.mas_bottom).offset(5);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
    }];
    
    UIImageView *imgV = [[UIImageView alloc]init];
    [self.view addSubview:imgV];
    imgV.image = [UIImage imageNamed:@"mac_screen"];
    [imgV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(installedLabel.mas_bottom).offset(5);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
    }];
    imgV.contentMode = UIViewContentModeLeft;
    
    
    UILabel *refreshLabel = [[UILabel alloc]init];
    [self.view addSubview:refreshLabel];
    refreshLabel.text = @"3、首页左上角按钮进行刷新，获取Mac的地址";
    refreshLabel.textColor = [UIColor lightGrayColor];
    [refreshLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(imgV.mas_bottom).offset(5);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
    }];
    
    UILabel *findLabel = [[UILabel alloc]init];
    [self.view addSubview:findLabel];
    findLabel.text = @"4、查找到Mac,获得按钮界面";
    findLabel.textColor = [UIColor lightGrayColor];
    [findLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(refreshLabel.mas_bottom).offset(5);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
    }];
    
    UIImageView *macImgV = [[UIImageView alloc]init];
    [self.view addSubview:macImgV];
    macImgV.image = [UIImage imageNamed:@"mac_image"];
    [macImgV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(findLabel.mas_bottom).offset(5);
        make.left.mas_equalTo(self.view.mas_left).offset(Margin);
        make.right.mas_equalTo(self.view).offset(-Margin);
        make.height.mas_equalTo(300);
    }];
    macImgV.contentMode = UIViewContentModeScaleAspectFit;
}

- (NSAttributedString *)getContentLabelAttributedText
{
    NSString *text = @"1、首先下载Mac端应用程序 http://www.helloted.com/mac_app/";
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    
    [attrStr addAttribute:NSLinkAttributeName value:@"http://www.helloted.com/mac_app/" range:NSMakeRange(15, 32)];
    return attrStr;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(nonnull NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = @"http://www.helloted.com/mac_app/";
    [SVProgressHUD showSuccessWithStatus:@"复制成功"];
    return NO;
}

//- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
//
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
