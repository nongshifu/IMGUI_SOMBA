#import <UIKit/UIKit.h>
#include <vector>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <shisangeIMGUI/imgui_impl_metal.h>
#import <shisangeIMGUI/imgui.h>

struct Vector2
{
    float x,y;
};

struct Vector3
{
    float x,y,z;
};

struct Matrix
{
    float _11;
    float _12;
    float _13;
    float _14;
    float _21;
    float _22;
    float _23;
    float _24;
    float _31;
    float _32;
    float _33;
    float _34;
    float _41;
    float _42;
    float _43;
    float _44;
};

struct SmobaHeroData{
    float HP;
    int 英雄ID;
    int 技能1倒计时;
    int 技能2倒计时;
    int 大招倒计时;
    int 召唤师技能ID;
    int 召唤师技能倒计时;
    bool 回城;
    int HeroTeam;
    Vector2 Pos;
    int32_t HeroHP;
    int32_t HeroMaxHP;
    bool Dead;
    bool Skill1;
    bool Skill2;
    bool Skill3;
    bool Skill4;
    
    
};
struct SmobaMonsterData{
    
    int32_t 野怪ID;
    int32_t 野怪当前血量;
    int32_t 野怪最大血量;
    Vector2 MonsterPos;
};
struct SmobaMonsterTime{
    
    Vector2 MonsterPos;
    int 野怪倒计时;
    int32_t 野怪ID;
   
   
};

struct SaveImage
{
    int HeroID;
    id<MTLTexture> 图片纹理ID[5];
    bool IsPlays;
    
};

static Vector2 MsMonsterLocFun(int offset){
    Vector2 loc;//蓝方
    if(offset == 0){//蓝Buff
        loc.x = -23.14;
        loc.y = 1.3;
    }else if(offset == 24){//红Buff
        loc.x = 2.588;
        loc.y = -30;
    }else if(offset == 264){//蜥蜴
        loc.x = -36.16;
        loc.y = 4.495;
    }else if(offset == 288){//穿山甲
        loc.x = -33.252;
        loc.y = 20;
    }else if(offset == 312){//猪
        loc.x = -3.657;
        loc.y = -18.733;
    }else if(offset == 336){//鸟
        loc.x = 16.74;
        loc.y = -36.072;
    }else if(offset == 240){//狼
        loc.x = -30.266;
        loc.y = -9.662;
    }else if(offset == 48){//==红方===蓝BUFF
        loc.x = 23.151;
        loc.y = -0.846;
    }else if(offset == 72){//红BUFF
        loc.x = -2.427;
        loc.y = 29.948;
    }else if(offset == 384){//蜥蜴
        loc.x = 36.371;
        loc.y = -4.302;
    }else if(offset == 408){//穿山甲
        loc.x = 33.173;
        loc.y = -20.75;
    }else if(offset == 432){//猪
        loc.x = 3.655;;
        loc.y = 18.843;
    }else if(offset == 456){//鸟
        loc.x = -16.649;
        loc.y = 35.984;
    }else if(offset == 360){//狼
        loc.x = 30.266;
        loc.y = 9.662;
    }else if(offset == 192){//上路河道精灵
        loc.x = -34.09;
        loc.y = 34.09;
    }else if(offset == 216){//下路河道精灵
        loc.x = 35.5;
        loc.y = -35.5;
    }else if(offset == 536){//上路河道精灵
        loc.x = -34.09;
        loc.y = 34.09;
    }else if(offset == 664){//下路河道精灵
        loc.x = 35.5;
        loc.y = -35.5;
    }
    
    return loc;
}
bool Gameinitialization();
bool RefreshMatrix();
bool ToScreen(Vector2 GameCanvas,Vector2 HeroPos,Vector2* Screen);
Vector2 ToMiniMap(Vector2 MiniMap,Vector2 HeroPos);
void GetPlayers(std::vector<SmobaHeroData> *Players);
void GetMonster(std::vector<SmobaMonsterData> *野怪数据);
void GetMonsterTime(std::vector<SmobaMonsterTime> *野怪倒计时数据);
