//
//  ViewController.m
//  RemoteControl
//
//  Created by iMac on 2019/10/20.
//  Copyright © 2019 iMac. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncUdpSocket.h"
#import "HTSlideBaseController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "Reachability.h"
#import "KeyBoadKey.h"
#import "InfoViewController.h"

#define COLOR_HEX(_hex)     [UIColor colorWithRed:((float)((_hex & 0xFF0000) >> 16)) / 255.0 \
green:((float)((_hex & 0xFF00)>> 8)) / 255.0 \
blue:((float) (_hex & 0xFF)) / 255.0 alpha:1.0f]

typedef enum : NSUInteger {
    BroadcastSendType = 1,
    KeyBoardSendType = 3,
} SendType;


#define MacPort 31243
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define MainColor  COLOR_HEX(0x00C78C)
#define kRemoteIPKey  @"kRemoteIPKey"
#define kNotFirstInstallKey  @"kNotFirstInstallKey"

@interface ViewController () <UITextFieldDelegate,GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong)UITextField    *serverField;

@property (nonatomic, strong)NSString       *lastIP;

@property (strong, nonatomic)GCDAsyncUdpSocket * udpSocket;


@property (nonatomic, strong)UIView         *baseView;

@property (nonatomic, strong)UIView         *maskView;

@property (nonatomic, strong)NSString       *receivedMacHostName;
@property (nonatomic, strong)NSString       *receivedMacHostIP;

@property (nonatomic, strong)NSTimer        *timer;
@property (nonatomic, assign)NSInteger      timerCount;

@property (nonatomic, strong)NSMutableDictionary   *sendDatas;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = MainColor;
    self.title = @"Mac遥控器";
    
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setMaximumDismissTimeInterval:2];
    
    self.baseView = [[UIView alloc]initWithFrame:self.view.bounds];
    self.baseView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.baseView];
    [self addAllActionButtons];
    self.baseView.hidden = YES;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(leftBtnClicked)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"light"] style:UIBarButtonItemStylePlain target:self action:@selector(lightBtnClicked)];
    
    [self createClientUdpSocket];
    
    self.lastIP = [[NSUserDefaults standardUserDefaults] valueForKey:kRemoteIPKey];
    if (self.lastIP && self.lastIP.length) {
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        NetworkStatus status = [reachability currentReachabilityStatus];
        if (status != ReachableViaWiFi) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请先打开WIFI" message:@"iPhone与Mac电脑需在同一个局域网WiFi" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:cancelAction];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
            return;
        }else{
            self.serverField.text = self.lastIP;
            self.baseView.hidden = NO;
        }

    }else{ // 没有记录过IP
        self.baseView.hidden = YES;
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"扫描同一个局域网Wifi下的Mac电脑" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self leftBtnClicked];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.navigationController presentViewController:alertController animated:YES completion:nil];
//        });
        
    }
    
    
    BOOL notFirst = [[NSUserDefaults standardUserDefaults] boolForKey:kNotFirstInstallKey];
    if (!notFirst) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self lightBtnClicked];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNotFirstInstallKey];
        });
    }
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [SVProgressHUD dismiss];
    [self.timer invalidate];
}

- (void)leftBtnClicked{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status != ReachableViaWiFi) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请先打开WIFI" message:@"iPhone与Mac电脑需在同一个WiFi" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
        self.baseView.hidden = YES;
        return;
    }
    
    // 开始扫描
    _timerCount = 0;
    self.baseView.hidden = YES;
    self.receivedMacHostIP = nil;
    [SVProgressHUD showWithStatus:@"请先打开电脑端程序，确保iPhone与Mac电脑在同一个局域网内\n正在搜索中..."];
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
}

- (void)timerAction{
    if (self.receivedMacHostIP && self.receivedMacHostIP.length) {
        [self.timer invalidate];
        NSString *str =[NSString stringWithFormat:@"成功找到Mac电脑\n%@(%@)",self.receivedMacHostName,self.receivedMacHostIP];
        [SVProgressHUD showSuccessWithStatus:str];
        self.baseView.hidden = NO;
        self.serverField.text = self.receivedMacHostIP;
    }else{
        [self broadcast];
    }
    
    if (_timerCount >= 20) {
        [self.timer invalidate];
        [SVProgressHUD showErrorWithStatus:@"扫描结束，没有找到Mac\n请确认同一个局域网Wifi下的Mac电脑已安装Mac端程序,请确认后再重试 "];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }else{
        _timerCount += 1;
    }
    
}

- (void)lightBtnClicked{
    InfoViewController *infoVC = [[InfoViewController alloc]init];
    [self.navigationController pushViewController:infoVC animated:YES];
}


- (void)addAllActionButtons{
    SEL action = @selector(clickAction:);
    CGFloat centerX = kScreenWidth/2;
    CGFloat centerY = self.view.frame.size.height/2;
    CGFloat size = 120;
    
    if (kScreenWidth < 350){
        size = 90;
    }
    
    CGFloat MidY = centerY - size/2 + 30;
    
    CGFloat  X_left = centerX - (size + 10);
    CGFloat  X_right = centerX + 10;
    
    // 中间一行
    [self addBtnWithFrame:CGRectMake(X_left, MidY, size, size) icon:[UIImage imageNamed:@"player_pause"] action:action tag:NX_KEYTYPE_PLAY];
    [self addBtnWithFrame:CGRectMake(X_right, MidY, size, size) icon:[UIImage imageNamed:@"volume_none"] action:action tag:NX_KEYTYPE_MUTE];
    
    
    // 第一行，音量行
    [self addBtnWithFrame:CGRectMake(X_left, MidY-size-20, size, size) icon:[UIImage imageNamed:@"volume_down"] action:action tag:NX_KEYTYPE_SOUND_DOWN];
    [self addBtnWithFrame:CGRectMake(X_right, MidY-size-20, size, size) icon:[UIImage imageNamed:@"volume_up"] action:action tag:NX_KEYTYPE_SOUND_UP];
    
    // 第三行，节目行
    [self addBtnWithFrame:CGRectMake(X_left, MidY + size + 20, size, size) icon:[UIImage imageNamed:@"play_pre"] action:action tag:NX_KEYTYPE_PREVIOUS];
    [self addBtnWithFrame:CGRectMake(X_right, MidY + size+ 20, size, size) icon:[UIImage imageNamed:@"play_next"] action:action tag:NX_KEYTYPE_NEXT];

    
    [self addTextFieldWith:MidY size:size];
}


- (void)addTextFieldWith:(CGFloat)MidY size:(CGFloat)size{
    self.serverField = [[UITextField alloc]initWithFrame:CGRectMake(0, MidY-size-20-60, kScreenWidth, 50)];
    self.serverField.placeholder = @"输入Mac的内网Ip";
    [self.baseView addSubview:self.serverField];
    self.serverField.font = [UIFont boldSystemFontOfSize:30];
    self.serverField.textColor = MainColor;
    self.serverField.tintColor = MainColor;
    self.serverField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.serverField.textAlignment = NSTextAlignmentCenter;
    self.serverField.delegate = self;
}

- (void)moveLeftMenuAction{
    [self.slideVC moveSideBar];
}


- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField.text) {
        [[NSUserDefaults standardUserDefaults] setValue:textField.text forKey:kRemoteIPKey];
        self.lastIP = textField.text;
    }
}


- (void)addBtnWithFrame:(CGRect)rect icon:(UIImage *)icon action:(SEL)action tag:(NSInteger)tag{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = tag;
    btn.frame = rect;
    btn.backgroundColor = MainColor;
    
    btn.layer.cornerRadius = 8;
    btn.layer.masksToBounds = YES;
    [btn setImage:icon forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    btn.showsTouchWhenHighlighted = YES;
    [self.baseView addSubview:btn];
}


- (void)clickAction:(UIButton *)btn{
    NSDictionary *firstDict = @{@"type":@(3),@"inputKey":@(btn.tag)};
    [self sendUDPWithData:firstDict toHost:self.lastIP];
 
//    NSString *url = [NSString stringWithFormat:@"http://%@:20881/?cmd=key&val=%@",self.lastIP,@(btn.tag)];
//    NSLog(@"url=%@",url);
//    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    NSURLSession *session = [NSURLSession sharedSession];
//    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSLog(@"response==%@",response);
//        if (error) {
//            NSLog(@"error===%@",error);
//        }
//    }];
//    [dataTask resume];
}


-(void)createClientUdpSocket{
    //创建udp socket
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    //banding一个端口(可选),如果不绑定端口,那么就会随机产生一个随机的电脑唯一的端口
    NSError * error = nil;
    //    [self.udpSocket bindToPort:udpPort error:&error];
    
    //启用广播
    [self.udpSocket enableBroadcast:YES error:&error];
    
    if (error) {//监听错误打印错误信息
        NSLog(@"error:%@",error);
    }else {//监听成功则开始接收信息
        NSLog(@"UDP创建成功");
        [self.udpSocket beginReceiving:&error];
    }
}

//广播
-(void)broadcast{
    NSDictionary *firstDict = @{@"type":@(BroadcastSendType),@"msg":@"Broadcast Searching..."};
    NSString *host = @"255.255.255.255";
    [self sendUDPWithData:firstDict toHost:host];
}

- (void)sendUDPWithData:(NSDictionary *)data toHost:(NSString *)host{
    if (!data) {
        NSLog(@"data为空");
        return;
    }
    NSError *error;
    int tag = arc4random() % 1000;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    //发送数据（tag: 消息标记）
    [self.udpSocket sendData:jsonData toHost:host port:MacPort withTimeout:-1 tag:tag];
    
    [self.sendDatas setValue:data forKey:@(tag).stringValue];
}

#pragma mark GCDAsyncUdpSocketDelegate


//发送数据成功
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSDictionary *send = [self.sendDatas valueForKey:@(tag).stringValue];
    NSLog(@"iphone=>mac:%@",send);
}

//发送数据失败
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"标记为%ld的数据发送失败，失败原因：%@",tag, error);
}

//接收到数据
-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    if (port != MacPort) {
        return;
    }
    
    if (!data) {
        return;
    }
    
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *result = [self dictionaryWithJsonString:str];
    NSLog(@"mac=>iphone:%@",result);
    
    if (result) {
        NSInteger type = 0;
        NSNumber *typeNum = [result objectForKey:@"type"];
        if (typeNum && [typeNum respondsToSelector:@selector(integerValue)]) {
            type = typeNum.integerValue;
        }
        
        if (type == 2) { // 向外广播搜索时的回消息
            self.receivedMacHostName = [result objectForKey:@"hostname"];
            self.receivedMacHostIP = [GCDAsyncUdpSocket hostFromAddress:address];
            self.lastIP = self.receivedMacHostIP;
            [[NSUserDefaults standardUserDefaults] setValue:self.lastIP forKey:kRemoteIPKey];
        }

    }
    
}


#pragma mark Tools

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

-(NSString *)strFromJsonDict:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}

- (UIView *)maskView{
    if (!_maskView) {
        _maskView = [[UIView alloc]initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor blackColor];
        _maskView.alpha = 0.1;
    }
    return _maskView;
}


- (NSMutableDictionary *)sendDatas{
    if (!_sendDatas) {
        _sendDatas = [NSMutableDictionary dictionary];
    }
    return _sendDatas;
}

@end
