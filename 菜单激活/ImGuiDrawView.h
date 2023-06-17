//
//  ImGuiDrawView.h
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ImGuiDrawView : UIViewController
extern bool 菜单显示状态;
extern bool 透视开关,全开,技能开关,野怪绘制开关,血条开关,方框开关,射线开关,兵线,野怪倒计时开关,绘制过直播开关,技能倒计时开关;
extern float mapx,mapy,技能绘制x调节,技能绘制y调节,血圈半径;
+(void)showHiede:(BOOL)MenDeal;
@end

NS_ASSUME_NONNULL_END
