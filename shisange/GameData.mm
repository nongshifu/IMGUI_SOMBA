#include <stdio.h>
#include "Class.h"
#import <mach-o/dyld.h>
#import <mach/mach.h>
#include <shisangeIMGUI/imgui_impl_metal.h>
#include <shisangeIMGUI/imgui.h>
#include <sys/sysctl.h>
#import <string.h>
#include <string>
#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
long Imageaddress,Game_Data,Game_Viewport;
Matrix ViewMatrix;
std::vector<SmobaHeroData>Players;
std::vector<SmobaMonsterData>野怪数据;
std::vector<SmobaMonsterTime>野怪倒计时数据;

static void Read_Data(long Src,int Size,void* Dst)
{
    vm_copy(mach_task_self(),(vm_address_t)Src,Size,(vm_address_t)Dst);
}

static long Read_Long(long src)
{
    long Buff=0;
    Read_Data(src,8,&Buff);
    return Buff;
}

static int Read_Int(long src)
{
    int Buff=0;
    Read_Data(src,4,&Buff);
    return Buff;
}

static int Read_Short(long src)
{
    int Buff=0;
    Read_Data(src,2,&Buff);
    return Buff;
}

static float Read_Float(long src)
{
    float Buff=0;
    Read_Data(src,4,&Buff);
    return Buff;
}
//地图转屏幕坐标
bool ToScreen(Vector2 GameCanvas,Vector2 HeroPos,Vector2* Screen)
{
    Screen->x=0;Screen->y=0;
    float ViewW;
    ViewW = ViewMatrix._13 * HeroPos.x + ViewMatrix._33 * HeroPos.y + ViewMatrix._43;
    if (ViewW < 0.01) return false;
    ViewW = 1/ViewW;
    Screen->x = (1+(ViewMatrix._11 * HeroPos.x + ViewMatrix._31 * HeroPos.y + ViewMatrix._41) * ViewW)*GameCanvas.x/2;
    Screen->y = (1-(ViewMatrix._12 * HeroPos.x + ViewMatrix._32 * HeroPos.y + ViewMatrix._42) * ViewW)*GameCanvas.y/2;
    return true;
}
//读取小地图坐标
Vector2 ToMiniMap(Vector2 MiniMap,Vector2 HeroPos)
{
    Vector2 Pos;
    float transformation = ViewMatrix._11>0?1:-1;
    Pos.x = (50 + HeroPos.x*transformation)/100;
    Pos.y = (50 - HeroPos.y*transformation)/100;
    
    return {MiniMap.x + Pos.x*MiniMap.y,Pos.y*MiniMap.y};
}

//读取屏幕坐标
static Vector2 GetPlayerPos(long Target)
{
    long Target_P1 = Read_Long(Target+0x1D0);
    long Target_P2 = Read_Long(Target_P1+0x10);
    long Target_P3 = Read_Long(Target_P2);
    long Target_P4 = Read_Long(Target_P3 + 0x10);
    
    int x1 = Read_Short(Target_P4);
    int x2 = Read_Short(Target_P4+2);
    
    int y1 = Read_Short(Target_P4+8);
    int y2 = Read_Short(Target_P4+10);
    
    return {(float)(x1-x2)/(float)1000,(float)(y1-y2)/(float)1000};
}
//读取技能
static bool GetKillActivate(long P_Skill)
{
    if (Read_Int(P_Skill+0x10)==0) return false;
    return Read_Int(P_Skill+0x34)==1;
}
//读取4技能
static void GetHeroSkill(long Target,bool *Skill1,bool *Skill2,bool *Skill3,bool *Skill4)
{
    long SkillList = Read_Long(Target+0x110);
    long P_Skill1 = Read_Long(SkillList+0xD8);
    long P_Skill2 = Read_Long(SkillList+0xF0);
    long P_Skill3 = Read_Long(SkillList+0x108);
    long P_Skill4 = Read_Long(SkillList+0x150);
    
    
    *Skill1 = GetKillActivate(P_Skill1);
    *Skill2 = GetKillActivate(P_Skill2);
    *Skill3 = GetKillActivate(P_Skill3);
    *Skill4 = GetKillActivate(P_Skill4);
}

//判断敌我
static int GetPlayerTeam(long Target)
{
    return Read_Int(Target+0x34);
}
//判断死亡
static bool GetPlayerDead(long Target)
{
    long PlayerHP = Read_Long(Target+0x128);
    return Read_Int(PlayerHP+0x98)==0;
}
//血量百分百
static float GetPlayerHP(long Target)
{
    long PlayerHP = Read_Long(Target + 0x128);
    int HP = Read_Int(PlayerHP + 0x98) / 8192;
    int MaxHP = Read_Int(PlayerHP + 0xA8);
    if (HP == 0 || MaxHP == 0) return 0;
    return (float)HP / MaxHP;
}
//当前血量
static int32_t GetGameHP(long Target){
    long HeroHP = Read_Long(Target+0x128);
    int32_t HP = Read_Int(HeroHP+0xA0);
    return HP;
}
//最大血量
static int32_t GetGameMaxHP(long Target){
    long MonsterMaxHP = Read_Long(Target+0x128);
    int32_t MaxHP = Read_Int(MonsterMaxHP+0xA8);
    return MaxHP;
}
//英雄ID
static int GetPlayerHero(long Target)
{
    return Read_Int(Target+0x28);//影响id
}

//召唤师时间
static int GetPlayerHeroTalentTime(long Target){
    long PlayerTime1 = Read_Long(Target+ 0x110);
    long PlayerTime2 = Read_Long(PlayerTime1+ 0x150);
    long PlayerTime3 = Read_Long(PlayerTime2+ 0xA0);
    int PlayerTime4 = Read_Int(PlayerTime3+ 0x38);
    return (PlayerTime4 / 8192000);
}
//召唤师技能
static int GetPlayerHeroTalent(long Target){
    long PlayerData1 = Read_Long(Target+ 0x110);
    long PlayerData2 = Read_Long(PlayerData1+ 0x150);
    return Read_Int(PlayerData2+ 0x330);
}

//大招偏移
static int GetGetHeroSkillTime(long Target){
    long Target_P1 = Read_Long(Target + 0x110);
    long Target_P2 = Read_Long(Target_P1 + 0x108);
    long Target_P3 = Read_Long(Target_P2 + 0xA0);
    int Target_P4 = Read_Int(Target_P3 + 0x38);
    int HeroSkillTime = Target_P4/8192000;
    return HeroSkillTime;
}
//回城
static bool GetHeroBack(long Target){
    long GoBack_1 = Read_Long(Target+0x110);
    long GoBack_2 = Read_Long(GoBack_1+0x168);
    long GoBack_3 = Read_Long(GoBack_2+0x110);
    int GoBack = Read_Int(GoBack_3+0x20);
    return GoBack==1; //返回是否为1 为1回城不为1正常
}
void GetPlayers(std::vector<SmobaHeroData> *Players)
{
    Players->clear();
    long PDatas = *(long*)(*(long*)(Game_Data)+0x378);
    if (PDatas > Imageaddress)
    {
        
        int MyTeam = ViewMatrix._11>0?1:2;
        long Array = *(long*)(PDatas+0x60);
        int ArraySize = *(int*)(PDatas+0x7C);
        if (ArraySize > 0 && ArraySize <= 20)
        {
            
            for (int i=0; i < ArraySize; i++) {
                long P_player = *(long*)(Array+i*0x18);
                if (P_player > Imageaddress){
                    SmobaHeroData HeroData;
                    HeroData.英雄ID = GetPlayerHero(P_player);
                    HeroData.HeroTeam = GetPlayerTeam(P_player);
                    HeroData.Dead = GetPlayerDead(P_player);
                    HeroData.HeroHP = GetGameHP(P_player);
                    HeroData.HeroMaxHP = GetGameMaxHP(P_player);
                    HeroData.Pos = GetPlayerPos(P_player);
                    HeroData.HP = GetPlayerHP(P_player);
                    HeroData.大招倒计时 = GetGetHeroSkillTime(P_player);
                    HeroData.HeroTalent = GetPlayerHeroTalent(P_player);
                    HeroData.召唤师技能倒计时 = GetPlayerHeroTalentTime(P_player);
                    HeroData.回城 = GetHeroBack(P_player);
                    GetHeroSkill(P_player,&HeroData.Skill1,&HeroData.Skill2,&HeroData.Skill3,&HeroData.Skill4);
                    if (HeroData.HeroTeam != MyTeam)Players->push_back(HeroData);;
                }
            }
        }
        
        
        
    }
}
//野怪
void GetMonster(std::vector<SmobaMonsterData> *野怪数据)
{
    野怪数据->clear();
    long PDatas = *(long*)(*(long*)(Game_Data)+0x378);
    if (PDatas > Imageaddress)
    {
        
        long Monster_Data = *(long*)(PDatas+0x148);
        int Monster_Count = *(int*)(PDatas+0x164);
        NSLog(@"Monster_Count=%d",Monster_Count);
        for (int i=0; i < Monster_Count; i++) {
            SmobaMonsterData Monster;
            long P_Monster = *(long*)(Monster_Data+i*0x18);
            Monster.野怪ID = GetPlayerHero(P_Monster);
            Monster.野怪当前血量 = GetGameHP(P_Monster);
            Monster.野怪最大血量 = GetGameMaxHP(P_Monster);
            Monster.MonsterPos = GetPlayerPos(P_Monster);
            
            野怪数据->push_back(Monster);
        }
        
    }
}
//野怪倒计时
void GetMonsterTime(std::vector<SmobaMonsterTime> *野怪倒计时数据)
{
    野怪倒计时数据->clear();
    int64_t MsWorld = *(long long*)(Imageaddress + 0x10CC33DC8);
    int64_t MsDead = *(long long*)(MsWorld + 0x3A8);
    int64_t MsMonsterDataV1 = *(long long*)(MsDead + 0x88);
    int64_t MsMonsterDataV3 = *(long long*)(MsMonsterDataV1 + 0x120);
    int MonsterDeathArr[16] = {0,24,264,408,432,456,360,48,72,384,288,312,336,240,192,216};
    for (int i = 0; i < 16; i++) {
        int64_t DeathMonster = *(long long*)(MsMonsterDataV3 + MonsterDeathArr[i]);
        int32_t MonsterTime = *(int32_t*)(DeathMonster + 0x238)/1000 +3; //0x230
        if (!MonsterTime)continue;
        int32_t MonsterTimeMax = *(int32_t*)(DeathMonster + 0x1E4)/1000 +3;
        if (!MonsterTimeMax)continue;
        Vector2 MonsterLoc = MsMonsterLocFun(MonsterDeathArr[i]);
        if (!MonsterLoc.x&&!MonsterLoc.y)continue;
        SmobaMonsterTime Monstertime;
        Monstertime.野怪ID=MonsterDeathArr[i];
        Monstertime.野怪倒计时=MonsterTime;
        野怪倒计时数据->push_back(Monstertime);
    }
    
}
//数组
bool RefreshMatrix()
{
    long P_Level1 = Read_Long(Game_Viewport+0xA0);
    long P_Level2 = Read_Long(P_Level1);
    long P_Level3 = Read_Long(P_Level2+0x10);
    long Ptr_View =Read_Long(Read_Long(P_Level3 + 0x30)+0x30);
    if (Ptr_View < Imageaddress) return false;
    long P_ViewMatrix = Read_Long(Ptr_View+0x18)+0x2C8;
    Read_Data(P_ViewMatrix,64,&ViewMatrix);
    return true;
}
//基础地址
bool Gameinitialization()
{
    Imageaddress = _dyld_get_image_vmaddr_slide(0);
    Game_Data = Read_Long(Imageaddress+0x10E2ACA50);
    Game_Viewport = Read_Long(Imageaddress+0x10CDE16C8);
    return Game_Data > Imageaddress && Game_Viewport > Imageaddress;
    
}
