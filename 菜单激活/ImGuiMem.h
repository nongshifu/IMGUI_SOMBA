//
//  ImGuiDrawView.h
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>
#import <dispatch/dispatch.h>
#include <vector>
#include <unordered_map>
#include <random>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ImGuiMem : UITextField <UITextFieldDelegate,MTKViewDelegate>
extern bool 菜单显示状态;
extern bool 透视开关,全选,技能开关,野怪绘制开关,血条开关,方框开关,射线开关,兵线,野怪倒计时开关,绘制过直播开关,技能倒计时开关;
extern float 小地图方框横轴,小地图方框大小,技能绘制x调节,技能绘制y调节,小地图血圈大小,头像大小;
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
