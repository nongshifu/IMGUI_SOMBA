#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>


#import "ImGuiDrawView.h"
#import "Class.h"
#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define iPhone8P ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define IPAD129 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(2732,2048), [[UIScreen mainScreen] currentMode].size) : NO)



@interface ImGuiDrawView () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end

@implementation ImGuiDrawView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
    
    
}


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    
    if (!self.device) abort();
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    
    ImGui::StyleColorsDark();
    
    
    NSString *FontPath = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";
    io.Fonts->AddFontFromFileTTF(FontPath.UTF8String, 40.f,NULL,io.Fonts->GetGlyphRangesChineseFull());
    
    
//    ImFontConfig config;
//    config.FontDataOwnedByAtlas = false;
//    io.Fonts->AddFontFromMemoryTTF((void *)jijia_data, jijia_size, 16, NULL,io.Fonts->GetGlyphRangesChineseFull());
    
    ImGui_ImplMetal_Init(_device);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapx=[[NSUserDefaults standardUserDefaults] floatForKey:@"mapx"];
        mapy=[[NSUserDefaults standardUserDefaults] floatForKey:@"mapy"];
        技能绘制x调节=[[NSUserDefaults standardUserDefaults] floatForKey:@"技能绘制x调节"];
        技能绘制y调节=[[NSUserDefaults standardUserDefaults] floatForKey:@"技能绘制y调节"];
        血圈半径=[[NSUserDefaults standardUserDefaults] floatForKey:@"半径"];
        GameCanvas.x = kWidth;
        GameCanvas.y = kHeight;
        
    });
    
    return self;
}



- (MTKView *)mtkView
{
    
    return (MTKView *)self.view;
}

- (void)loadView
{
    
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}


#pragma mark - MTKViewDelegate

+(void)showHiede:(BOOL)MenDeal{
    菜单显示状态=MenDeal;
}
- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
#if TARGET_OS_OSX
    CGFloat framebufferScale = view.window.screen.backingScaleFactor ?: NSScreen.mainScreen.backingScaleFactor;
#else
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
#endif
    if (iPhone8P){
        io.DisplayFramebufferScale = ImVec2(2.60, 2.60);
    }else{
        io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    }
    
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
        [self Drawing:MsDrawList];
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

#pragma mark 绘制=======
//声明默认开关和 状态
static ImVec4 血条颜色 = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
static ImVec4 方框颜色 = ImVec4(0.0f, 1.0f, 0.0f, 1.0f);
static ImVec4 射线颜色 = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);
static ImVec4 野怪颜色 = ImVec4(1.0f, 1.0f, 1.0f, 1.0f);
static ImVec4 回城血条颜色 = ImVec4(1.0f, 1.0f, 0.0f, 1.0f);

bool 菜单显示状态;
bool 透视开关,全开,技能开关,技能倒计时开关,野怪绘制开关,血条开关,方框开关,射线开关,兵线,野怪倒计时开关,绘制过直播开关;
float mapx,mapy,技能绘制x调节,技能绘制y调节,血圈半径;

static Vector2 GameCanvas;
static int YXsum = 0;
std::vector<SaveImage> NetImage;


- (void)菜单{
    if (菜单显示状态) {
        //菜单显示时 交互为YES可点击
        [self.view setUserInteractionEnabled:YES];
    } else{
        //菜单显示时 交互为NO 不可可点击
        [self.view setUserInteractionEnabled:NO];
        //跨进程旋转屏幕
    }
    ImFont* font = ImGui::GetFont();
    font->Scale = 17.f / font->FontSize;//字体 大小 分辨率
    //默认窗口大小
    CGFloat width =350;//宽度
    CGFloat height =310;//高度
    ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);//大小
    
    //默认显示位置 屏幕中央
    CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - width) / 2;
    CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - height) / 2;
    
    ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);//默认位置
    
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
            if (ImGui::Checkbox("全开", &全开)) {
                技能开关=全开;
                技能倒计时开关=全开;
                野怪绘制开关=全开;
                血条开关=全开;
                兵线=全开;
                方框开关=全开;
                射线开关=全开;
                血条开关=全开;
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
            ImGui::Checkbox("过直播开关", &绘制过直播开关);
            ImGui::NewLine();
            
            if (ImGui::SliderFloat("小地图血圈半径", &血圈半径, 0, 80)) {
                [[NSUserDefaults standardUserDefaults] setFloat:血圈半径 forKey:@"半径"];
            }
            
            if (ImGui::SliderFloat("小地图横轴", &mapx, 0, 500)) {
                [[NSUserDefaults standardUserDefaults] setFloat:mapx forKey:@"mapx"];
            }
            if (ImGui::SliderFloat("小地图大小", &mapy, 0, 500)) {
                [[NSUserDefaults standardUserDefaults] setFloat:mapy forKey:@"mapy"];
            }
            
           
            
            if(ImGui::SliderFloat("技能图标横轴", &技能绘制x调节, 0, 500)){
                [[NSUserDefaults standardUserDefaults] setFloat:技能绘制x调节 forKey:@"技能绘制x调节"];
            }
            
            if(ImGui::SliderFloat("技能图标大小", &技能绘制y调节, 0, 100)){
                [[NSUserDefaults standardUserDefaults] setFloat:技能绘制y调节 forKey:@"技能绘制y调节"];
            }
            
            ImGui::EndTabItem();
        }
        
        if (ImGui::BeginTabItem("其他功能")) // 开始第二个选项卡
        {
            ImGui::Text("人生如戏-全靠演技\n到期时间:2099-01-01 22:55:77\n\n\n");
            ImGui::EndTabItem();
        }
        
        
        ImGui::EndTabBar(); // 结束选项卡栏
        
        
        
        ImGui::Text("QQ:350722326 %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        
        
        
        ImGui::End();
        //结束菜单=========================
        
    }
}
- (void) Drawing:(ImDrawList*)MsDrawList
{
    if (透视开关)
    {
        //读取基础地址
        Gameinitialization();
        //左上角地图方框
        if (方框开关) {
            MsDrawList->AddRect(ImVec2(mapx,0), ImVec2(mapx+mapy,mapy), ImColor(方框颜色));
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
                            //小地图头像
                            Vector2 小地图;
                            小地图.x=mapx;
                            小地图.y=mapy;
                            //小地图头像
                            Vector2 MiniPos = ToMiniMap(小地图, 读取英雄数据[i].Pos);
                            float R=小地图.y/14;
                            
                            // 绘制小地图玩家图像
                            id<MTLTexture> 头像ID=GetHeroImage(读取英雄数据[i].英雄ID, 0);
                            bool isplays=IsPlays(读取英雄数据[i].英雄ID);
                            if (!isplays) continue;//跳过假坐标
                            if(血条开关)
                            {
                                //小地血圈圈条
                                float 血量 =读取英雄数据[i].HP;
                                //小地血血背景
                                DrawSector(MsDrawList, ImVec2(MiniPos.x,MiniPos.y), 血圈半径, 0, 360, ImColor(1,1,1), 32,false,血圈半径/7);
                                
                                //小地血血条 回城黄色
                                DrawSector(MsDrawList, ImVec2(MiniPos.x,MiniPos.y), 血圈半径, 0, 360*血量, 读取英雄数据[i].回城?ImColor(回城血条颜色):ImColor(血条颜色), 32,true,血圈半径/8);
                                
                                
                                //大地图血条背景
                                MsDrawList->AddRect(ImVec2(BoxPos.x-20, BoxPos.y), ImVec2(BoxPos.x+20, BoxPos.y+10), ImColor(方框颜色));
                                //大地图血条
                                MsDrawList->AddRectFilled(ImVec2(BoxPos.x-20, BoxPos.y+1), ImVec2(BoxPos.x-20+血量*40, BoxPos.y+10), ImColor(血条颜色));
                            }
                            // 绘制小地图玩家图像
                            if (头像ID != NULL) {
                                ImVec2 pMin = ImVec2(MiniPos.x-R, MiniPos.y-R);
                                ImVec2 pMax = ImVec2(MiniPos.x+R, MiniPos.y+R);
                                MsDrawList->AddImage((__bridge ImTextureID)头像ID, pMin, pMax);
                            }
                            
                        }
                        if (射线开关) {
                            
                            MsDrawList->AddLine(ImVec2(kWidth/2, kHeight/2), ImVec2(BoxPos.x, BoxPos.y-20), ImColor(射线颜色));
                        }
                        if (方框开关)
                        {
                            MsDrawList->AddRect(ImVec2(BoxPos.x-20, BoxPos.y-50), ImVec2(BoxPos.x+20, BoxPos.y+10), ImColor(方框颜色));
                        }
                        //方框下面的技能点
                        
                        
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
                                
                                // 绘制小地图玩家图像
                                id<MTLTexture> texture1ID = GetHeroImage(读取英雄数据[i].英雄ID, 1);
                                if (texture1ID != NULL) {
                                    ImVec2 pMin = ImVec2(x-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小/2, y+20+圆圈大小/2);
                                    MsDrawList->AddImage((__bridge ImTextureID)texture1ID, pMin, pMax);
                                }
                                
                            }
                            if (读取英雄数据[i].Skill2) {
                                
                                // 绘制小地图玩家图像
                                id<MTLTexture> texture2ID = GetHeroImage(读取英雄数据[i].英雄ID, 2);
                                if (texture2ID != NULL) {
                                    ImVec2 pMin = ImVec2(x+圆圈大小-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小+圆圈大小/2, y+20+圆圈大小/2);
                                    MsDrawList->AddImage((__bridge ImTextureID)texture2ID, pMin, pMax);
                                }
                                
                            }
                            if (读取英雄数据[i].Skill3) {
                                
                                // 绘制小地图玩家图像
                                id<MTLTexture> texture3ID = GetHeroImage(读取英雄数据[i].英雄ID, 3);
                                if (texture3ID != NULL) {
                                    ImVec2 pMin = ImVec2(x+圆圈大小*2-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小*2+圆圈大小/2, y+20+圆圈大小/2);
                                    MsDrawList->AddImage((__bridge ImTextureID)texture3ID, pMin, pMax);
                                }
                            }else{
                                //4个小点上的倒计时
                                DrawText(MsDrawList, 大招倒计时文字, 20, ImVec2(x+圆圈大小*2, y+20), ImColor(方框颜色), true);
                            }
                            if (读取英雄数据[i].Skill4) {
                               
                                // 绘制小地图玩家图像
                                id<MTLTexture> texture4ID = GetHeroImage(读取英雄数据[i].HeroTalent, 0);
                                if (texture4ID != NULL) {
                                    ImVec2 pMin = ImVec2(x+圆圈大小*3-圆圈大小/2, y+20-圆圈大小/2);
                                    ImVec2 pMax = ImVec2(x+圆圈大小*3+圆圈大小/2, y+20+圆圈大小/2);
                                    MsDrawList->AddImage((__bridge ImTextureID)texture4ID, pMin, pMax);
                                }
                            }
                            
                        }
                        
                        //顶部技能图 倒计时
                        if (技能倒计时开关) {
                            YXsum++;
                            // 绘制图玩家图像
                            id<MTLTexture> 头像ID = GetHeroImage(读取英雄数据[i].英雄ID, 0);
                            if (头像ID !=NULL) {
                                ImVec2 pMin = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum, 0);
                                ImVec2 pMax = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节, 技能绘制y调节);
                                MsDrawList->AddImage((__bridge ImTextureID)头像ID, pMin, pMax);
                            }
                            //召唤师图标
                            id<MTLTexture> DZtextureID = GetHeroImage(读取英雄数据[i].HeroTalent, 0);
                            if (DZtextureID != NULL) {
                                ImVec2 DZpMin = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum, 技能绘制y调节+10);
                                ImVec2 DZpMax = ImVec2(技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节, 技能绘制y调节*2+10);
                                MsDrawList->AddImage((__bridge ImTextureID)DZtextureID, DZpMin, DZpMax);
                            }
                           
                            
                            
                            float 字体大小= 技能绘制y调节/1.5;
                            float 字体x = 技能绘制x调节 + (技能绘制y调节+3)*YXsum+技能绘制y调节/2;
                            float 字体y = 技能绘制y调节/2;
                            //绘制大招时间
                            DrawText(MsDrawList, 大招倒计时文字, 字体大小, ImVec2(字体x,字体y), ImColor(方框颜色), true);
                            //绘制技能时间
                            DrawText(MsDrawList, 召唤师技能倒计时文字, 字体大小, ImVec2(字体x,字体y+30), ImColor(方框颜色), true);
                            
                            
                            
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
                            小地图.x=mapx;
                            小地图.y=mapy;
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
                    小地图.x=mapx;
                    小地图.y=mapy;
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
//绘制图片
static id<MTLTexture> getTextureID(UIImage *image) {
    CGImageRef cgImage = [image CGImage];
    if (!cgImage) {
        NSLog(@"无法从图像数据创建 CGImage");
        return NULL;
    }
    // Create a MTLTexture from the UIImage
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
    NSError *error;
    id<MTLTexture> texture = [loader newTextureWithCGImage:cgImage options:nil error:&error];
    if (error) {
        NSLog(@"无法从图像数据创建 MTL 输出: %@", error.localizedDescription);
        return NULL;
    }else{
        return texture;
    }
    return NULL;
}

static void NetGetHeroImage(int HeroID)
{
    SaveImage Temp;
    Temp.HeroID = HeroID;
    static UIImage*Image[5];
    static NSString*urlstring;
    for (int i=0; i<5; i++) {
        if (i==0) {
            urlstring=[NSString stringWithFormat:@"https://qmui.oss-cn-hangzhou.aliyuncs.com/CIKEimage/%d.png",HeroID];
        }else{
            urlstring=[NSString stringWithFormat:@"https://game.gtimg.cn/images/yxzj/img201606/heroimg/%d/%d%d.png",HeroID,HeroID,i*10];
        }
        
        NSURL *url = [NSURL URLWithString:urlstring];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data.length < 1000)
        {
            //重复下载20次直到下载完成图片
            for (int i=0; i<20; i++) {
                data = [NSData dataWithContentsOfURL:url];
                if (data.length > 1000) break;
            }
        }
        Image[i]=[UIImage imageWithData:data];
        //判断真玩家 能正常获取头像的
        if (Image[i]!=nil) {
            Temp.IsPlays=true;
        }
        Temp.图片纹理ID[i]=getTextureID(Image[i]);
    }
    
    NetImage.push_back(Temp);
}

static id<MTLTexture> GetHeroImage(int HeroID ,int 编号)
{
    
    for (int i=0;i<NetImage.size();i++)
    {
        if (NetImage[i].HeroID == HeroID) {
            return NetImage[i].图片纹理ID[编号];
        }
    }
    NetGetHeroImage(HeroID);
    return NULL;
}
static bool IsPlays(int HeroID)
{
    
    for (int i=0;i<NetImage.size();i++)
    {
        if (NetImage[i].HeroID == HeroID) {
            return NetImage[i].IsPlays;
        }
    }
    
    return false;
}
#pragma mark - 触摸互动
- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    
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

