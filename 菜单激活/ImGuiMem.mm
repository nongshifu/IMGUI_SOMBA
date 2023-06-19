#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "WX_NongShiFu123.h"
#import "ImGuiMem.h"
#import "Class.h"
#import "Config.h"
#include <cmath>
#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define iPhone8P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define IPAD129 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(2732,2048), [[UIScreen mainScreen] currentMode].size) : NO)

@interface ImGuiMem ()

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end


@implementation ImGuiMem

+ (instancetype)sharedInstance {
    static ImGuiMem *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        小地图方框横轴=[[NSUserDefaults standardUserDefaults] floatForKey:@"小地图方框横轴"];
        小地图方框大小=[[NSUserDefaults standardUserDefaults] floatForKey:@"小地图方框大小"];
        技能绘制x调节=[[NSUserDefaults standardUserDefaults] floatForKey:@"技能绘制x调节"];
        技能绘制y调节=[[NSUserDefaults standardUserDefaults] floatForKey:@"技能绘制y调节"];
        小地图血圈大小=[[NSUserDefaults standardUserDefaults] floatForKey:@"小地图血圈大小"];
        头像大小=[[NSUserDefaults standardUserDefaults] floatForKey:@"头像大小"];
        GameCanvas.x = kWidth;
        GameCanvas.y = kHeight;
        
        sharedInstance = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
    });
    return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.secureTextEntry=YES;
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];
        
        if (!self.device) abort();
        
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO(); (void)io;
        
        ImGui::StyleColorsDark();
        //系统默认字体
        //    NSString *FontPath = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";
        //    io.Fonts->AddFontFromFileTTF(FontPath.UTF8String, 40.f,NULL,io.Fonts->GetGlyphRangesChineseFull());
        //第三方字体
        ImFontConfig config;
        config.FontDataOwnedByAtlas = false;
        io.Fonts->AddFontFromMemoryTTF((void *)jijia_data, jijia_size, 16, NULL,io.Fonts->GetGlyphRangesChineseFull());
        
        
        //加载
        ImGui_ImplMetal_Init(_device);
        
        CGFloat w = CGRectGetWidth(frame);
        CGFloat h = CGRectGetHeight(frame);
        self.mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h) device:_device];
        self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
        self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        self.mtkView.clipsToBounds = YES;
        self.mtkView.delegate = self;
        self.frame=[UIScreen mainScreen].bounds;
        
        [self.subviews.firstObject addSubview:self.mtkView];
        
        // 禁用键盘响应
        self.userInteractionEnabled = YES;
        
    }
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat h = CGRectGetHeight(self.frame);
    self.mtkView.frame = CGRectMake(0, 0, w, h);
}


#pragma mark - MTKViewDelegate


- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui shisange"];
        
        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        [self 菜单];
        //开始绘制==========================
        ImDrawList*MsDrawList = ImGui::GetForegroundDrawList();//读取整个菜单元素
        [self 绘制:MsDrawList];
        
        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
        
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
    [commandBuffer commit];
}

#pragma mark - 封装绘制函数===
//绘制扇形
static void DrawSector(ImDrawList* drawList, const ImVec2& center, float radius, float fromAngle, float toAngle, ImU32 color, int num_segments, bool fill, float thickness)
{
    const float PI = 3.14159265358979323846f;
    
    // 计算角度
    fromAngle = fromAngle * PI / 180.0f;
    toAngle = toAngle * PI / 180.0f;
    
    // 添加路径
    drawList->PathLineTo(center);
    for (int i = 0; i <= num_segments; ++i)
    {
        float angle = fromAngle + (toAngle - fromAngle) * (float)i / (float)num_segments;
        ImVec2 pos(center.x + radius * cosf(angle), center.y + radius * sinf(angle));
        drawList->PathLineTo(pos);
    }
    drawList->PathLineTo(center);
    
    // 判断是否需要填充扇形
    if (fill)
    {
        // 关闭路径并填充
        drawList->PathFillConvex(color);
    }
    else
    {
        // 绘制边框线段
        drawList->PathStroke(color, false, thickness);
    }
}
//绘制文字
static void DrawText(ImDrawList* drawList, const char* text, float font_size, const ImVec2& pos, ImColor color, bool center)
{
    // 计算文本大小
    ImVec2 text_size = ImGui::GetFont()->CalcTextSizeA(font_size, FLT_MAX, 0.0f, text);
    
    // 计算文本起始位置
    ImVec2 text_pos = pos;
    if (center)
    {
        text_pos.x -= text_size.x * 0.5f;
        text_pos.y -= text_size.y * 0.5f;
    }
    
    // 绘制文本
    drawList->AddText(ImGui::GetFont(), font_size, text_pos, color, text);
}
//绘制图片
static void DrawImage(ImDrawList* drawList,id<MTLTexture> ImageID,const ImVec2& 起点 , const ImVec2& 终点){
    if (ImageID ==NULL) return;
    drawList->AddImage((__bridge ImTextureID)ImageID, 起点, 终点);
}
//绘制圆角矩形
static void DrawRoundedRect(ImDrawList* drawList, const ImVec2& start, const ImVec2& end, ImU32 color, float thickness, float rounding, bool fill)
{
    const float IM_PI =3.14159265358979323846f;
    const float radius = rounding;
    const ImVec2 size = ImVec2(end.x - start.x, end.y - start.y);
    const ImVec2 center = ImVec2(start.x + size.x / 2.0f, start.y + size.y / 2.0f);

    if (fill)
    {
        drawList->AddRectFilled(
            ImVec2(center.x - size.x / 2.0f + radius, center.y - size.y / 2.0f + radius),
            ImVec2(center.x + size.x / 2.0f - radius, center.y + size.y / 2.0f - radius),
            color, radius);
    }
    else
    {
        drawList->AddRect(
            ImVec2(center.x - size.x / 2.0f + radius, center.y - size.y / 2.0f + radius),
            ImVec2(center.x + size.x / 2.0f - radius, center.y + size.y / 2.0f - radius),
            color, radius, ImDrawCornerFlags_All, thickness);
    }

    drawList->PathArcTo(
        ImVec2(center.x - size.x / 2.0f + radius, center.y - size.y / 2.0f + radius + thickness),
        radius - thickness, IM_PI, IM_PI * 1.5f, ImDrawCornerFlags_TopLeft);
    drawList->PathArcTo(
        ImVec2(center.x - size.x / 2.0f + radius + thickness, center.y - size.y / 2.0f + radius),
        radius - thickness, IM_PI * 1.5f, IM_PI * 2.0f, ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_TopRight);
    drawList->PathArcTo(
        ImVec2(center.x + size.x / 2.0f - radius - thickness, center.y - size.y / 2.0f + radius),
        radius - thickness, 0.0f, IM_PI * 0.5f, ImDrawCornerFlags_TopRight);
    drawList->PathArcTo(
        ImVec2(center.x + size.x / 2.0f - radius, center.y - size.y / 2.0f + radius + thickness),
        radius - thickness, IM_PI * 0.5f, IM_PI, ImDrawCornerFlags_BotRight);
    drawList->PathArcTo(
        ImVec2(center.x + size.x / 2.0f - radius, center.y + size.y / 2.0f - radius - thickness),
        radius - thickness, 0.0f, IM_PI * -0.5f, ImDrawCornerFlags_BotRight | ImDrawCornerFlags_BotLeft);
    drawList->PathArcTo(
        ImVec2(center.x + size.x / 2.0f - radius - thickness, center.y + size.y / 2.0f - radius),
        radius - thickness, IM_PI * -0.5f, 0.0f, ImDrawCornerFlags_BotLeft);
    drawList->PathArcTo(
        ImVec2(center.x - size.x / 2.0f + radius + thickness, center.y + size.y / 2.0f - radius),
        radius - thickness, IM_PI, IM_PI * -0.5f, ImDrawCornerFlags_TopLeft | ImDrawCornerFlags_BotLeft);
    drawList->PathArcTo(
        ImVec2(center.x - size.x / 2.0f + radius, center.y + size.y / 2.0f - radius - thickness),
        radius - thickness, IM_PI * -0.5f, 0.0f, ImDrawCornerFlags_TopRight | ImDrawCornerFlags_BotRight);
    drawList->PathStroke(color, true, thickness);
}
#pragma mark - IMGUI菜单
char 输入框内容[256] = "";
- (void)菜单{
    
    //默认窗口大小
    CGFloat width =350;//宽度
    CGFloat height =310;//高度
    ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);//大小
    //默认显示位置 屏幕中央
    CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - width) / 2;
    CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - height) / 2;
    
    ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);//默认位置
    [self setUserInteractionEnabled:菜单显示状态];//当菜单显示时候允许搜索 隐藏时禁用手势;
    //开始菜单=====================
    if (菜单显示状态) {
        
        ImGui::Begin("十三哥WX:NongShiFu123",&菜单显示状态);
        
        //选项卡例子=============
        ImGui::BeginTabBar("绘制功能"); // 开始一个选项卡栏
        
        if (ImGui::BeginTabItem("绘制功能")) // 开始第一个选项卡
        {
            // 在这里添加第一个选项卡的内容
            ImGui::Checkbox("透视总开关", &透视开关);
            ImGui::SameLine();
            if (ImGui::Checkbox("全选", &全选)) {
                技能开关=全选;
                技能倒计时开关=全选;
                野怪绘制开关=全选;
                血条开关=全选;
                兵线=全选;
                方框开关=全选;
                射线开关=全选;
                血条开关=全选;
            }
            ImGui::SameLine();
            if(ImGui::Checkbox("过直播开关", &绘制过直播开关)){
                self.secureTextEntry=绘制过直播开关;
            }
            
            ImGui::Checkbox("技能", &技能开关);
            ImGui::SameLine();
            ImGui::Checkbox("技能倒计时", &技能倒计时开关);
            ImGui::SameLine();
            ImGui::Checkbox("野怪", &野怪绘制开关);
            ImGui::SameLine();
            ImGui::Checkbox("野怪倒计时", &野怪倒计时开关);
            
            ImGui::Checkbox("血条", &血条开关);
            
            ImGui::SameLine();
            ImGui::Checkbox("兵线", &兵线);
            ImGui::ColorEdit3("血条颜色", (float*)&血条颜色);
            
            
            ImGui::Checkbox("方框", &方框开关);
            ImGui::ColorEdit3("方框颜色", (float*) &方框颜色);
            
            
            ImGui::Checkbox("射线", &射线开关);
            ImGui::ColorEdit3("射线颜色", (float*) &射线颜色);
            
            ImGui::EndTabItem(); // 结束第一个选项卡
        }
        
        if (ImGui::BeginTabItem("高级功能")) // 开始第二个选项卡
        {
            // 在这里添加第二个选项卡的内容
            
            ImGui::NewLine();
            
            if (ImGui::SliderFloat("小地图血圈大小", &小地图血圈大小, 0, 80)) {
                [[NSUserDefaults standardUserDefaults] setFloat:        小地图血圈大小 forKey:@"小地图血圈大小"];
            }
            if (ImGui::SliderFloat("头像大小", &头像大小, 0, 80)) {
                [[NSUserDefaults standardUserDefaults] setFloat:头像大小 forKey:@"头像大小"];
            }
            
            if (ImGui::SliderFloat("小地图横轴", &小地图方框横轴, 0, 500)) {
                [[NSUserDefaults standardUserDefaults] setFloat:小地图方框横轴 forKey:@"小地图方框横轴"];
            }
            if (ImGui::SliderFloat("小地图方框大小", &小地图方框大小, 0, 500)) {
                [[NSUserDefaults standardUserDefaults] setFloat:小地图方框大小 forKey:@"小地图方框大小"];
            }
            
           
            
            if(ImGui::SliderFloat("技能图标横轴", &技能绘制x调节, 0, 500)){
                [[NSUserDefaults standardUserDefaults] setFloat:技能绘制x调节 forKey:@"技能绘制x调节"];
            }
            
            if(ImGui::SliderFloat("技能图标大小", &技能绘制y调节, 0, 100)){
                [[NSUserDefaults standardUserDefaults] setFloat:技能绘制y调节 forKey:@"技能绘制y调节"];
            }
            
            ImGui::EndTabItem();
        }
        
        if (ImGui::BeginTabItem("卡密验证")) // 开始第二个选项卡
        {
            ImGui::NewLine();
            //版本========
            static NSString*str;
            if (![软件版本号 isEqual:JN_VERSION]) {
                str=[NSString stringWithFormat:@"发现新版:%@-更新新版",软件版本号];
                const char* banbemstr = strdup([str UTF8String]);
                if (ImGui::Button(banbemstr)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件url地址] options:@{} completionHandler:^(BOOL success) {
                        
                    }];
                }
            }else{
                str=[NSString stringWithFormat:@"已是最新版:%@",JN_VERSION];
                const char* banbemstr = strdup([str UTF8String]);
                ImGui::Button(banbemstr);
            }
            
            //公告========
            const char* ggstr = strdup([软件公告 UTF8String]);
            ImGui::TextColored(ImVec4(1.0f, 0.0f, 0.0f, 1.0f), "%s",ggstr);
            
            //验证菜单=====
            if (!验证状态) {
                bool validated = false;
                ImGui::Text("请先验证");
                ImGui::Text("%s", [验证信息 UTF8String]);
                ImGui::Text("卡密:%s", [卡密 UTF8String]);
                if (ImGui::Button("复制卡密")) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string=卡密;
                }
                ImGui::NewLine();
                // 输入框
                ImGui::InputText("##input", 输入框内容, sizeof(输入框内容));
                
                // 粘贴按钮
                if (ImGui::Button("粘贴")) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    NSString *text = pasteboard.string;
                    if (text != nil) {
                        NSLog(@"粘贴=%@",text);
                        strncpy(输入框内容, text.UTF8String, sizeof(输入框内容));
                        ImGui::SetNextItemWidth(-1);
                        ImGui::InputText("##input", 输入框内容, sizeof(输入框内容));
                    }
                }
                ImGui::SameLine();
                if (ImGui::Button("清除")) {
                    strncpy(输入框内容, @"".UTF8String, sizeof(输入框内容));
                    
                }
                ImGui::SameLine();
                
                ImGui::SameLine();
                
                // 确认按钮
                if (ImGui::Button("确认激活")) {
                    validated = true;
                    if (validated) {
                        validated = false;
                        // 验证通过的逻辑
                        卡密 = [NSString stringWithUTF8String:输入框内容];
                        [[WX_NongShiFu123 alloc] yanzhengAndUseIt:卡密];
                       
                    }
                }
                if(软件网页地址.length>5){
                    ImGui::SameLine();
                    if (ImGui::Button("购买卡密")) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址] options:@{} completionHandler:^(BOOL success) {
                            exit(0);
                        }];
                        
                    }
                }
                
                
            }else{
                
                const char* kmcstr = strdup([卡密 UTF8String]);
                
                ImGui::Text("卡密:%s",kmcstr);
                if (ImGui::Button("复制本地卡密")) {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string=卡密;
                    
                }
                ImGui::SameLine();
                if(软件网页地址.length>5){
                    ImGui::SameLine();
                    if (ImGui::Button("购买卡密")) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:软件网页地址] options:@{} completionHandler:^(BOOL success) {
                            
                        }];
                        
                    }
                }
                ImGui::NewLine();
                
            }
            
            
            ImGui::NextColumn();
            ImGui::EndTabItem();
        }
        
        ImGui::EndTabBar(); // 结束选项卡栏
        
        const char* cstr = strdup([到期时间 UTF8String]);
        ImVec4 color = ImVec4(1.0f, 0.0f, 0.0f, 1.0f); // 红色
        ImGui::PushStyleColor(ImGuiCol_Text, color);
        ImGui::Text("到期时间:%s (%.1f FPS)", cstr,ImGui::GetIO().Framerate);
        
        ImGui::PopStyleColor();
        
        
        ImGui::End();
        //结束菜单=========================
        
    }
}

#pragma mark - 声明默认开关和 状态
//声明默认开关和 状态
static ImVec4 血条颜色 = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
static ImVec4 方框颜色 = ImVec4(0.0f, 1.0f, 0.0f, 1.0f);
static ImVec4 射线颜色 = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
static ImVec4 野怪颜色 = ImVec4(1.0f, 1.0f, 1.0f, 1.0f);
static ImVec4 回城血条颜色 = ImVec4(1.0f, 1.0f, 0.0f, 1.0f);

bool 菜单显示状态;
bool 透视开关,全选,技能开关,技能倒计时开关,野怪绘制开关,血条开关,方框开关,射线开关,兵线,野怪倒计时开关,绘制过直播开关;
float 小地图方框横轴,小地图方框大小,技能绘制x调节,技能绘制y调节,        小地图血圈大小,头像大小;

static Vector2 GameCanvas;
static int YXsum = 0;
std::vector<SaveImage> NetImage;
#pragma mark - 绘制=====
- (void)绘制:(ImDrawList*)MsDrawList
{
    if (透视开关)
    {
        //读取基础地址
        Gameinitialization();
        //左上角地图方框
        if (方框开关) {
            MsDrawList->AddRect(ImVec2(小地图方框横轴,0), ImVec2(小地图方框横轴+小地图方框大小,小地图方框大小), ImColor(方框颜色));
        }
        
        if (RefreshMatrix())
        {
            std::vector<SmobaHeroData> 读取英雄数据;
            GetPlayers(&读取英雄数据);
            if (读取英雄数据.size() > 0)
            {
                YXsum = 0;
                for (int i=0; i<读取英雄数据.size(); i++) {
                    
                    Vector2 BoxPos;
                    if (!读取英雄数据[i].Dead)
                    {
                        if (ToScreen(GameCanvas,读取英雄数据[i].Pos,&BoxPos))
                        {
                            if (读取英雄数据[i].英雄ID ==0) continue;
                            //小地图头像
                            Vector2 小地图;
                            小地图.x=小地图方框横轴;
                            小地图.y=小地图方框大小;
                            //小地图头像
                            Vector2 MiniPos = ToMiniMap(小地图, 读取英雄数据[i].Pos);
                            // 绘制小地图玩家图像
                            
                            //小地血圈圈条
                            if(血条开关)
                            {
                                float 血量 =读取英雄数据[i].HP;
                                //小地血血背景
                                DrawSector(MsDrawList, ImVec2(MiniPos.x,MiniPos.y),小地图血圈大小, 0, 360, ImColor(1,1,1), 32,false,小地图血圈大小/7);
                                
                                //小地血血条 回城黄色
                                DrawSector(MsDrawList, ImVec2(MiniPos.x,MiniPos.y),小地图血圈大小, 0, 360*血量, 读取英雄数据[i].回城?ImColor(回城血条颜色):ImColor(血条颜色), 32,true,        小地图血圈大小/8);
                                
                                
                                //大地图血条背景
                                MsDrawList->AddRect(ImVec2(BoxPos.x-20, BoxPos.y), ImVec2(BoxPos.x+20, BoxPos.y+10), ImColor(方框颜色));
                                //大地图血条
                                MsDrawList->AddRectFilled(ImVec2(BoxPos.x-20, BoxPos.y+1), ImVec2(BoxPos.x-20+血量*40, BoxPos.y+10), ImColor(血条颜色));
                            }
                            // 绘制小地图玩家图像
                            GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 0, ^(id<MTLTexture> texture) {
                                ImVec2 pMin = ImVec2(MiniPos.x-头像大小, MiniPos.y-头像大小);
                                ImVec2 pMax = ImVec2(MiniPos.x+头像大小, MiniPos.y+头像大小);
                                DrawImage(MsDrawList, texture, pMin,pMax);
                            });
                           
                            
                        }
                        if (射线开关) {
                            
                            MsDrawList->AddLine(ImVec2(kWidth/2, kHeight/2), ImVec2(BoxPos.x, BoxPos.y-20), ImColor(射线颜色));
                        }
                        if (方框开关)
                        {
                            MsDrawList->AddRect(ImVec2(BoxPos.x-20, BoxPos.y-50), ImVec2(BoxPos.x+20, BoxPos.y+10), ImColor(方框颜色));
                        }
                        //大招技能时间显示
                        const char *召唤师技能倒计时文字;
                        const char *大招倒计时文字;
                        if(读取英雄数据[i].召唤师技能倒计时 == 0){
                            召唤师技能倒计时文字="";
                        }else{
                            
                            召唤师技能倒计时文字 = [NSString stringWithFormat:@"%d", (读取英雄数据[i].召唤师技能倒计时)].UTF8String;
                        }
                        
                        //召唤师大招时间
                        if(读取英雄数据[i].大招倒计时 == 0){
                            大招倒计时文字="";
                        }
                        else{
                            大招倒计时文字 = [NSString stringWithFormat:@"%d", (读取英雄数据[i].大招倒计时)].UTF8String;
                            
                        }
                        if (技能开关)
                        {
                            
                            //方框下面的技能点
                            float 圆圈大小=20;
                            float x=BoxPos.x-30;
                            float y=BoxPos.y;
                            //背景圆圈
                            MsDrawList->AddCircle(ImVec2(x, y+20), 圆圈大小/2, ImColor(血条颜色) ,36 ,1);
                            MsDrawList->AddCircle(ImVec2(x+圆圈大小, y+20), 圆圈大小/2, ImColor(血条颜色) ,36 ,1);
                            MsDrawList->AddCircle(ImVec2(x+圆圈大小*2, y+20), 圆圈大小/2, ImColor(血条颜色) ,36 ,1);
                            MsDrawList->AddCircle(ImVec2(x+圆圈大小*3, y+20), 圆圈大小/2, ImColor(血条颜色) ,36 ,1);
                            
                            //图片圆圈
                            if (读取英雄数据[i].Skill1) {
                                GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 1, ^(id<MTLTexture> texture) {
                                   ImVec2 pMin = ImVec2(x-圆圈大小/2, y+20-圆圈大小/2);
                                   ImVec2 pMax = ImVec2(x+圆圈大小/2, y+20+圆圈大小/2);
                                   DrawImage(MsDrawList, texture, pMin,pMax);
                                });
                                
                            }
                            if (读取英雄数据[i].Skill2) {
                                GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 2, ^(id<MTLTexture> texture) {
                                   ImVec2 pMin = ImVec2(x+圆圈大小-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小+圆圈大小/2, y+20+圆圈大小/2);
                                    DrawImage(MsDrawList, texture, pMin,pMax);
                                });
                               
                            }
                            if (读取英雄数据[i].Skill3) {
                                GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 3, ^(id<MTLTexture> texture) {
                                    ImVec2 pMin = ImVec2(x+圆圈大小*2-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小*2+圆圈大小/2, y+20+圆圈大小/2);
                                    DrawImage(MsDrawList, texture, pMin,pMax);
                                });
                               
                            }else{
                                //4个小点上的倒计时
                                DrawText(MsDrawList, 大招倒计时文字, 12, ImVec2(x+圆圈大小*2, y+20), ImColor(方框颜色), true);
                            }
                            if (读取英雄数据[i].Skill4) {
                                GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 4, ^(id<MTLTexture> texture) {
                                    ImVec2 pMin = ImVec2(x+圆圈大小*3-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小*3+圆圈大小/2, y+20+圆圈大小/2);
                                    DrawImage(MsDrawList, texture, pMin,pMax);
                                });
                                
                                
                            }else{
                                //4个小点上的倒计时
                                DrawText(MsDrawList, 召唤师技能倒计时文字, 12, ImVec2(x+圆圈大小*3, y+20), ImColor(方框颜色), true);
                            }
                            
                        }
                        
                        //顶部技能图 倒计时
                        if (技能倒计时开关) {
                            YXsum++;
                            // 绘制图玩家图像
                            
                            GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 0, ^(id<MTLTexture> texture) {
                                ImVec2 pMin = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum, 0);
                                ImVec2 pMax = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节, 技能绘制y调节);
                                DrawImage(MsDrawList, texture, pMin ,pMax);
                            });
                            
                            
                            //召唤师图标
                            GetHeroImageAsync(读取英雄数据[i].英雄ID, 读取英雄数据[i].召唤师技能ID, 4, ^(id<MTLTexture> texture) {
                                if (texture==NULL) {
                                    NSLog(@"空的=%d  %d",读取英雄数据[i].英雄ID,读取英雄数据[i].召唤师技能ID);
                                }
                                ImVec2 DZpMin = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum, 技能绘制y调节+10);
                                ImVec2 DZpMax = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节, 技能绘制y调节*2+10);
                                DrawImage(MsDrawList, texture, DZpMin ,DZpMax);
                            });
                            
                            
                           
                            float 字体大小= 技能绘制y调节/2;
                            float 字体x = 技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节/2;
                            float 字体y = 技能绘制y调节/2;
                            //绘制大招时间
                            DrawText(MsDrawList, 大招倒计时文字, 字体大小, ImVec2(字体x,字体y), ImColor(方框颜色), true);
                            //绘制技能时间
                            DrawText(MsDrawList, 召唤师技能倒计时文字, 字体大小, ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节/2, 技能绘制y调节*2+10-技能绘制y调节/2), ImColor(血条颜色), true);
                            
                        }
                        
                    }
                }
                
               
                
            }
            
            //==================大地图野怪====================
           
            if (野怪绘制开关) {
                Vector2 MonsterScreen;
                std::vector<SmobaMonsterData> 野怪数据;
                GetMonster(&野怪数据);
                
                for (int i= 0; i < 野怪数据.size(); i++) {
                    
                    if (野怪数据[i].野怪当前血量 > 0) {
                        if (ToScreen(GameCanvas,野怪数据[i].MonsterPos,&MonsterScreen)){
                            //小地图野怪
                            Vector2 小地图;
                            小地图.x=小地图方框横轴;
                            小地图.y=小地图方框大小;
                            Vector2 MiniMonsterPos = ToMiniMap(小地图, 野怪数据[i].MonsterPos);
                            
                            //小地图野怪背景
                            DrawSector(MsDrawList, ImVec2(MiniMonsterPos.x,MiniMonsterPos.y), 4, 0, 360, ImColor(1,1,1), 32,true,1);
                            //小地图野怪血条
                            DrawSector(MsDrawList, ImVec2(MiniMonsterPos.x,MiniMonsterPos.y), 4, 0, 360*野怪数据[i].野怪当前血量/野怪数据[i].野怪最大血量, ImColor(血条颜色), 32,true,2);
                            
                            //大地图野怪
                            if(血条开关)
                            {
                                //大地血背景
                                MsDrawList->AddRect(ImVec2(MonsterScreen.x-20, MonsterScreen.y), ImVec2(MonsterScreen.x+20, MonsterScreen.y+10), ImColor(方框颜色));
                                //大地血条
                                MsDrawList->AddRectFilled(ImVec2(MonsterScreen.x-20, MonsterScreen.y+1), ImVec2(MonsterScreen.x-20+(40*野怪数据[i].野怪当前血量/野怪数据[i].野怪最大血量), MonsterScreen.y+10), ImColor(血条颜色));
                                
                            }
                            
                            if (方框开关)
                            {
                                MsDrawList->AddRect(ImVec2(MonsterScreen.x-20, MonsterScreen.y-50), ImVec2(MonsterScreen.x+20, MonsterScreen.y+10), ImColor(方框颜色));
                            }
                            
                            
                        }
                    }
                }
                
                
            }
            if (野怪倒计时开关) {
                
                std::vector<SmobaMonsterTime> 野怪倒计时数据;
                GetMonsterTime(&野怪倒计时数据);
                
                for (int i=0; i<野怪倒计时数据.size(); i++) {
                    
                    Vector2 小地图;
                    小地图.x=小地图方框横轴;
                    小地图.y=小地图方框大小;
                    Vector2 MiniMonsterPos = ToMiniMap(小地图, 野怪倒计时数据[i].MonsterPos);
                    const char *倒计时文字;
                    倒计时文字 = [NSString stringWithFormat:@"%d", (野怪倒计时数据[i].野怪倒计时)].UTF8String;
                    NSLog(@"读取野怪倒计时数据=%s %f  %f",倒计时文字,MiniMonsterPos.x,MiniMonsterPos.y);
                    DrawText(MsDrawList, 倒计时文字, 15, ImVec2(MiniMonsterPos.x, MiniMonsterPos.y), ImColor(1,0,0,1), true);
                    
                }
            }
            
        }
    }
    
}

#pragma mark 读取玩家头像

//读取沙盒文件图标
static NSString* getFilePath(NSString*fileName) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *imgPath = [documentsPath stringByAppendingPathComponent:@"IMG"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:imgPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"创建目录失败: %@", error.localizedDescription);
            return nil;
        }
    }
    return [imgPath stringByAppendingPathComponent:fileName];
}
//读取纹理ID NSData形式
static id<MTLTexture> loadImageTexture(NSData *imageData){
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    void *data= (void*)[imageData bytes];
    NSUInteger length = [imageData length];
    if (length ==0) return NULL;
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = 50;
    textureDescriptor.height = 50;
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];

    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
    NSError *error;
    texture = [loader newTextureWithData:[NSData dataWithBytes:data length:length] options:nil error:&error];
    if (error) {
        NSLog(@"Error loading texture: %@", error.localizedDescription);
    } else {
        return texture;
    }
    return NULL;
}
// 异步下载图片
static void DocumenImageAsync(int HeroID, int 召唤师技能ID) {
    //多线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //判断是否已经下载过图片 下载过就跳过
        static NSString *urlstring;
        for (int 编号=0; 编号<5; 编号++) {
            NSString *filePath = getFilePath([NSString stringWithFormat:@"%d%d.png",HeroID,编号]);
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                //不存在走网络下载
                
                if (编号==0) {
                    //头像
                    urlstring=[NSString stringWithFormat:@"https://qmui.oss-cn-hangzhou.aliyuncs.com/CIKEimage/%d.png",HeroID];
                }else if(编号==4){
                    urlstring=[NSString stringWithFormat:@"https://qmui.oss-cn-hangzhou.aliyuncs.com/CIKEimage/%d.png",召唤师技能ID];
                }else{
                    //技能
                    urlstring=[NSString stringWithFormat:@"https://game.gtimg.cn/images/yxzj/img201606/heroimg/%d/%d%d.png",HeroID,HeroID,编号*10];
                }
                
                NSURL *url = [NSURL URLWithString:urlstring];
                NSData*imageData = [NSData dataWithContentsOfURL:url];
                if (imageData.length < 1000)
                {
                    //重复下载5次直到下载完成图片
                    for (int i=0; i<5; i++) {
                        imageData = [NSData dataWithContentsOfURL:url];
                        if (imageData.length > 1000){
                            break;
                        }
                    }
                }
                
                [imageData writeToFile:filePath atomically:YES];//写入本地文件
            }
        }
        
    });
    
}

// 异步获取图片
static void GetHeroImageAsync(int HeroID, int 召唤师技能ID, int 编号, void (^completionHandler)(id<MTLTexture>)) {
    static id<MTLTexture> Texture = NULL;
    int imageID = HeroID*10+编号;
    for (int i=0; i<NetImage.size(); i++) {
        if (NetImage[i].imageID==imageID) {
            completionHandler(NetImage[i].图片纹理ID);
            return;
        }
    }
    
    NSString *filePath = getFilePath([NSString stringWithFormat:@"%d.png",imageID]);
    NSData*imageData = [NSData dataWithContentsOfFile:filePath];
    Texture = loadImageTexture(imageData);
    //多线程
    if (Texture==NULL) {
        DocumenImageAsync(HeroID, 召唤师技能ID);
    }else{
        SaveImage Temp;
        Temp.imageID = imageID;
        Temp.图片纹理ID = Texture;
        NetImage.push_back(Temp);
    }
    completionHandler(Texture);
}

// 全局变量，用于维护图片缓存
std::unordered_map<int, id<MTLTexture>> imageCache;
// 异步获取图片
static void GetHeroImageAsync2(int HeroID, int 召唤师技能ID, int 编号, void (^completionHandler)(id<MTLTexture>)) {
    id<MTLTexture> texture = NULL;
    int imageID = HeroID * 10 + 编号;
    auto iterator = imageCache.find(imageID);
    if (iterator != imageCache.end()) {
        // 如果缓存中已经有该图片，则直接返回缓存中的纹理
        completionHandler(iterator->second);
        return;
    }

    // 否则从磁盘或网络中加载图片
    NSString *filePath = getFilePath([NSString stringWithFormat:@"%d.png", imageID]);
    NSData* imageData = [NSData dataWithContentsOfFile:filePath];
    if (imageData != nil) {
        // 如果从磁盘中读取到了图片数据，则解码图片并将纹理添加到缓存中
        texture = loadImageTexture(imageData);
        if (texture != NULL) {
            imageCache[imageID] = texture;
            completionHandler(texture);
            return;
        }
    }
    // 如果从磁盘中没有读取到图片数据，则从网络下载图片
    DocumenImageAsync(HeroID, 召唤师技能ID);
    completionHandler(NULL);
   
}

#pragma mark - 触摸互动
- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self];
    
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    
    
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}
@end

