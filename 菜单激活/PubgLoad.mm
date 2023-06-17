//
//  PubgLoad.m
//  pubg
//
//  Created by 李良林 on 2021/2/14.
//

#import "PubgLoad.h"
#import <UIKit/UIKit.h>

#import "ImGuiMem.h"
#import <AVFoundation/AVFoundation.h>
@interface PubgLoad()<UITextFieldDelegate>

@end

@implementation PubgLoad
static PubgLoad *extraInfo;
+ (void)load
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        extraInfo =  [PubgLoad alloc];
        [extraInfo jtyl];
        [extraInfo volumeChanged];
    });
}
- (void)jtyl{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2;//点击次数
    tap.numberOfTouchesRequired = 3;//手指数
    [tap addTarget:self action:@selector(volumeChanged)];//三指调用
    [[UIApplication sharedApplication].keyWindow addGestureRecognizer:tap];//三指添加到顶层视图
    
}



- (void)volumeChanged {
    菜单显示状态=!菜单显示状态;
    [[UIApplication sharedApplication].keyWindow addSubview:[ImGuiMem sharedInstance]];//imgui 添加到顶层视图

}
- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end
