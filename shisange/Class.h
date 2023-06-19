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
    int imageID;
    id<MTLTexture> 图片纹理ID = { NULL };
   
};


bool Gameinitialization();
bool RefreshMatrix();
bool ToScreen(Vector2 GameCanvas,Vector2 HeroPos,Vector2* Screen);
Vector2 ToMiniMap(Vector2 MiniMap,Vector2 HeroPos);
void GetPlayers(std::vector<SmobaHeroData> *Players);
void GetMonster(std::vector<SmobaMonsterData> *野怪数据);
void GetMonsterTime(std::vector<SmobaMonsterTime> *野怪倒计时数据);
