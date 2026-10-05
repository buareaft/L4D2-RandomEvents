#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <usermessages>
#include <bitbuffer>
#include <left4dhooks>

public Plugin myinfo = {
    name = "Safehouse Random Events (Stacking)",
    author = "randomevents",
    description = "Stacking random timed/instant server events",
    version = "2.0.3"
};

#define D30 30.0
#define D45 45.0
#define D60 60.0

#define DMGT_BURN 8
#define DMGT_ACID 262144

enum
{
    ZC_SMOKER = 1,
    ZC_BOOMER = 2,
    ZC_HUNTER = 3,
    ZC_SPITTER = 4,
    ZC_JOCKEY = 5,
    ZC_CHARGER = 6,
    ZC_TANK = 8
};

enum
{
    
    E_HORDE_NOW,          
    E_HORDE_ENDLESS,
    E_COMMON_FAST,
    E_COMMON_SLOW,
    E_COMMON_STRONG,
    E_COMMON_FRAGILE,
    E_SI_FAST,
    E_SI_STRONG,
    E_SI_FRAGILE,
    E_SI_RAMPAGE,
    E_SI_DISABLE,
    E_TIME_JOCKEY,
    E_TIME_CHARGER,
    E_TIME_HUNTER,
    E_TIME_SMOKER,
    E_TIME_SPITTER,
    E_TIME_BOOMER,

    E_SURV_FAST,
    E_SURV_SLOW,
    E_HIGH_JUMP,
    E_LOW_GRAVITY,
    E_HIGH_GRAVITY,

    E_INF_AMMO,
    E_INF_CLIP,
    E_FAST_RELOAD,
    E_SLOW_RELOAD,
    E_FAST_FIRE,
    E_WEAPON_STRONG,
    E_WEAPON_WEAK,
    E_ACCURATE,
    E_INACCURATE,

    E_LIFESTEAL,
    E_REGEN,
    E_BLEED,
    E_TEMP_HP,            
    E_GLASS_CANNON,
    E_IRONMAN,
    E_SQUISHY,
    E_MELEE_KING,
    E_GUN_KING,
    E_FIRE_IMMUNE,
    E_ACID_IMMUNE,
    E_FF_OFF,
    E_FF_DOUBLE,

    E_DARK,
    E_FOG,
    E_LIGHTS_OFF,
    E_ICE,
    E_RANDOM_PUSH,
    E_EARTHQUAKE,
    E_AIRSTRIKE,
    E_MOLOTOV_RAIN,
    E_LIGHTNING,
    E_COMMON_EXPLODE,
    E_COMMON_FIRE,
    E_BOOMER_NUKE,
    E_CHARGER_ROCKET,
    E_HUNTER_SMASH,
    E_SMOKER_LONG,
    E_SPITTER_SEA,
    E_JOCKEY_MAD,
    E_WITCH_RAGE,
    E_LILLIPUT,
    E_GIANT,
    E_BIG_HEAD,

    E_WEAPON_ROULETTE,
    E_POSITION_ROULETTE,
    E_HEALTH_ROULETTE,
    E_LAUNCH_ALL,
    E_SUPER_KNOCKBACK,
    E_NO_KNOCKBACK,
    E_TIME_FAST,
    E_SLOW_MO,
    E_MEDICAL,
    E_RESCUE_FAST,
    E_RESCUE_SLOW,
    E_INF_PUSH,
    E_NO_PUSH,

    E_DOUBLE_EVENT,       
    E_REDRAW,             
    E_CHAOS_MINUTE,       
    E_HEAL_ALL,           
    E_HURT_ALL,           
    E_RANDOM_TELEPORT,    
    E_WEAPON_SHUFFLE,     
    E_SI_BURST,           
    E_FLING_ALL,          
    E_GIVE_MEDS,          
    E_AMMO_LOSS,          
    E_REVIVE_ONE,         

    EFFECT_COUNT
};

char  g_EffectName[EFFECT_COUNT][48];
float g_EffectDur[EFFECT_COUNT];
bool  g_EffectInstant[EFFECT_COUNT];
int   g_EffectWeight[EFFECT_COUNT];
int   g_DrawWeight[EFFECT_COUNT];

#define MAX_ACTIVE 8
int   g_ActId[MAX_ACTIVE];
float g_ActEnd[MAX_ACTIVE];
float g_Period[MAX_ACTIVE];
int   g_ActCount;

ConVar g_Enable, g_Interval, g_InstantChance, g_MaxActive, g_Announce, g_Difficulty;

float g_SurvSpeed = 1.0;
float g_SpecialSpeed = 1.0;
float g_CommonSpeed = 1.0;
float g_WitchSpeed = 1.0;
float g_DmgDealt = 1.0;
float g_DmgTaken = 1.0;
float g_MeleeMult = 1.0;
float g_GunMult = 1.0;
float g_ReloadMult = 1.0;
float g_CycleMult = 1.0;
float g_SpreadMult = 1.0;
float g_CommonHpMult = 1.0;
float g_SIHpMult = 1.0;
float g_GravityMult = 1.0;
float g_TimeScale = 1.0;
float g_FrictionMult = 1.0;
int   g_FogMode;                 
int   g_SpawnBias;               
bool  g_SIDisable;
bool  g_InfAmmo, g_InfClip;
bool  g_FireImmune, g_AcidImmune;
bool  g_FFOff, g_FFDouble;
bool  g_HighJump;
bool  g_LightsOff;
bool  g_Lifesteal, g_Regen, g_Bleed;
bool  g_CommonExplode, g_CommonFire, g_BoomerNuke;
bool g_TimeOwned;
bool  g_ChargerRocket, g_HunterSmash, g_JockeyMad, g_WitchRage;
bool  g_SuperKnock, g_NoKnock;
bool  g_InfPush, g_NoPush;
bool  g_ModelScaleOn, g_HeadScaleOn;
float g_ModelScale = 1.0;
float g_HeadScale = 1.0;
int g_ScaleRef[2049];
bool g_ModelOwned[2049], g_HeadOwned[2049];
float g_ModelOriginal[2049], g_HeadOriginal[2049];

bool  g_CachedOriginals;
float g_OrigGravity, g_OrigTimeScale, g_OrigFriction, g_OrigAccelerate;
float g_OrigCommonHealth;
float g_OrigSIHealth[9];
float g_OrigJockeySpeed;
float g_OrigMedDuration, g_OrigReviveDuration, g_OrigTongueRange;
int g_CommonRef[2049];
float g_CommonApplied[2049];
bool g_DependencyReady;
char g_ThunderSound[128];
int   g_OrigCheats;

#define GUN_COUNT 17
char g_Guns[GUN_COUNT][] = {
    "weapon_smg", "weapon_smg_silenced", "weapon_pumpshotgun", "weapon_shotgun_chrome", "weapon_smg_mp5",
    "weapon_rifle", "weapon_rifle_ak47", "weapon_rifle_desert", "weapon_autoshotgun", "weapon_shotgun_spas",
    "weapon_hunting_rifle", "weapon_sniper_military", "weapon_rifle_sg552", "weapon_sniper_awp", "weapon_sniper_scout",
    "weapon_rifle_m60", "weapon_grenade_launcher"
};
bool  g_GunCached;
float g_GunOrigReload[GUN_COUNT];
float g_GunOrigCycle[GUN_COUNT];
float g_GunOrigSpread[GUN_COUNT];
float g_GunOrigMaxSpread[GUN_COUNT];

bool  g_LeftStart;
int   g_EventCount;
float g_NextDraw;
int   g_LastEvent = -1;
int   g_FogEntity = -1;
int   g_OrigFog = -1;
int   g_ShakeEntity = -1;
bool  g_HookedEntity[MAXPLAYERS + 1];
bool  g_FxBusy;

public void OnPluginStart()
{
    ValidateRequiredNatives();
    g_DependencyReady = true;
    CacheLightningSound();
    g_Enable        = CreateConVar("safehouse_random_enable", "1", "Enable random events", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_Interval      = CreateConVar("safehouse_random_interval", "30", "Seconds between continuous-event draws", 0, true, 10.0, true, 600.0);
    g_InstantChance = CreateConVar("safehouse_random_instant_chance", "20", "Percent chance to also fire an instant event per draw", 0, true, 0.0, true, 100.0);
    g_MaxActive     = CreateConVar("safehouse_random_max_active", "4", "Maximum simultaneously running continuous events", 0, true, 1.0, true, 8.0);
    g_Announce      = CreateConVar("safehouse_random_announce", "1", "Show the periodic reminder/status chat line", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_Difficulty    = FindConVar("z_difficulty");
    if (g_Difficulty == null) SetFailState("safehouse_random_events requires Left 4 Dead 2 (z_difficulty not found)");

    g_Enable.AddChangeHook(SettingsChanged);
    g_Interval.AddChangeHook(SettingsChanged);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_start_area", Event_LeftStart, EventHookMode_PostNoCopy);
    HookEvent("player_jump", Event_Jump, EventHookMode_Post);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEventEx("mission_lost", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEventEx("finale_win", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEventEx("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy);

    RegConsoleCmd("sm_events", Cmd_Status);
    RegAdminCmd("sm_randomevent", Cmd_Draw, ADMFLAG_ROOT);
    RegAdminCmd("sm_randomevent_instant", Cmd_DrawInstant, ADMFLAG_ROOT);
    RegAdminCmd("sm_random_stop", Cmd_Stop, ADMFLAG_ROOT);
    RegAdminCmd("sm_random_clear", Cmd_Clear, ADMFLAG_ROOT);
    RegAdminCmd("sm_random_list", Cmd_List, ADMFLAG_ROOT);
    RegAdminCmd("sm_random_status", Cmd_Status, ADMFLAG_ROOT);

    SetupEffectTable();
    AutoExecConfig(true, "safehouse_random_events");

    ResetRound();
    CreateTimer(1.0, Tick, _, TIMER_REPEAT);
    CreateTimer(5.0, AnnounceTimer, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    CacheLightningSound();
    ResetRound();
    g_GunCached = false;
    g_CachedOriginals = false;
    CacheCvarOriginals();
    EnsureHooks();
}

public void OnMapEnd()    { if (g_DependencyReady) FinishRound(); }
public void OnPluginEnd() { if (g_DependencyReady) { FinishRound(); StopAllEffects(false); } }

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ResetRound();
    EnsureHooks();
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) { FinishRound(); }

public void Event_LeftStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_LeftStart) return;
    g_LeftStart = true;
    g_NextDraw = g_Interval.FloatValue;
    if (g_Enable.BoolValue)
        PrintToChatAll("\x04[随机事件]\x01 已开始：每 %.0f 秒抽取一个持续事件（自带时长，可叠加）。", g_Interval.FloatValue);
}

void ResetRound()
{
    g_LeftStart = false;
    g_NextDraw = g_Interval.FloatValue;
    g_LastEvent = -1;
    g_EventCount = 0;
    StopAllEffects(false);
}
void FinishRound()
{
    g_LeftStart = false;
    StopAllEffects(true);
}
public void SettingsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_NextDraw = g_Interval.FloatValue;
    if (convar == g_Enable && !g_Enable.BoolValue) StopAllEffects(false);
}

void Def(int id, const char[] name, float dur, bool instant, int weight)
{
    strcopy(g_EffectName[id], sizeof(g_EffectName[]), name);
    g_EffectDur[id] = dur;
    g_EffectInstant[id] = instant;
    g_EffectWeight[id] = weight;
}

void SetupEffectTable()
{
    
    Def(E_HORDE_NOW,      "立刻尸潮",      0.0, true,  100);
    Def(E_HORDE_ENDLESS,  "尸潮不断",      D45, false, 90);
    Def(E_COMMON_FAST,    "丧尸加速",      D45, false, 80);
    Def(E_COMMON_SLOW,    "丧尸减速",      D45, false, 80);
    Def(E_COMMON_STRONG,  "丧尸强化",      D60, false, 70);
    Def(E_COMMON_FRAGILE, "一碰就碎",      D60, false, 70);
    Def(E_SI_FAST,        "特感加速",      D45, false, 80);
    Def(E_SI_STRONG,      "特感强化",      D60, false, 70);
    Def(E_SI_FRAGILE,     "特感脆皮",      D60, false, 70);
    Def(E_SI_RAMPAGE,     "特感暴走",      D45, false, 60);
    Def(E_SI_DISABLE,     "特感禁用",      D45, false, 50);
    Def(E_TIME_JOCKEY,    "Jockey 时间",   D45, false, 60);
    Def(E_TIME_CHARGER,   "Charger 时间",  D45, false, 60);
    Def(E_TIME_HUNTER,    "Hunter 时间",   D45, false, 60);
    Def(E_TIME_SMOKER,    "Smoker 时间",   D45, false, 60);
    Def(E_TIME_SPITTER,   "Spitter 时间",  D45, false, 60);
    Def(E_TIME_BOOMER,    "Boomer 时间",   D45, false, 60);

    Def(E_SURV_FAST,      "全员加速",      D30, false, 70);
    Def(E_SURV_SLOW,      "全员减速",      D30, false, 70);
    Def(E_HIGH_JUMP,      "高跳",          D45, false, 60);
    Def(E_LOW_GRAVITY,    "低重力",        D45, false, 55);
    Def(E_HIGH_GRAVITY,   "高重力",        D45, false, 55);

    Def(E_INF_AMMO,       "无限弹药",      D45, false, 70);
    Def(E_INF_CLIP,       "无限弹匣",      D45, false, 65);
    Def(E_FAST_RELOAD,    "极速换弹",      D45, false, 65);
    Def(E_SLOW_RELOAD,    "龟速换弹",      D45, false, 55);
    Def(E_FAST_FIRE,      "极速射击",      D45, false, 65);
    Def(E_WEAPON_STRONG,  "武器强化",      D60, false, 70);
    Def(E_WEAPON_WEAK,    "武器削弱",      D60, false, 70);
    Def(E_ACCURATE,       "精准射击",      D45, false, 60);
    Def(E_INACCURATE,     "人体描边",      D45, false, 60);

    Def(E_LIFESTEAL,      "吸血",          D45, false, 60);
    Def(E_REGEN,          "自动回血",      D45, false, 60);
    Def(E_BLEED,          "持续流血",      D45, false, 50);
    Def(E_TEMP_HP,        "临时生命",      0.0, true,  90);
    Def(E_GLASS_CANNON,   "玻璃大炮",      D60, false, 55);
    Def(E_IRONMAN,        "铁人",          D60, false, 60);
    Def(E_SQUISHY,        "脆皮",          D60, false, 60);
    Def(E_MELEE_KING,     "近战之王",      D60, false, 55);
    Def(E_GUN_KING,       "枪械之王",      D60, false, 55);
    Def(E_FIRE_IMMUNE,    "火焰免疫",      D45, false, 50);
    Def(E_ACID_IMMUNE,    "酸液免疫",      D45, false, 50);
    Def(E_FF_OFF,         "友伤关闭",      D60, false, 55);
    Def(E_FF_DOUBLE,      "友伤加倍",      D60, false, 50);

    Def(E_DARK,           "黑暗",          D45, false, 45);
    Def(E_FOG,            "浓雾",          D45, false, 45);
    Def(E_LIGHTS_OFF,     "关灯",          D45, false, 45);
    Def(E_ICE,            "冰面",          D45, false, 45);
    Def(E_RANDOM_PUSH,    "随机推力",      D30, false, 55);
    Def(E_EARTHQUAKE,     "地震",          D45, false, 45);
    Def(E_AIRSTRIKE,      "天降爆炸",      D45, false, 40);
    Def(E_MOLOTOV_RAIN,   "天降燃烧瓶",    D45, false, 40);
    Def(E_LIGHTNING,      "闪电",          D45, false, 40);
    Def(E_COMMON_EXPLODE, "感染者爆炸",    D45, false, 50);
    Def(E_COMMON_FIRE,    "感染者燃烧",    D45, false, 50);
    Def(E_BOOMER_NUKE,    "Boomer 核爆",   D45, false, 45);
    Def(E_CHARGER_ROCKET, "Charger 火箭",  D45, false, 45);
    Def(E_HUNTER_SMASH,   "Hunter 重击",   D45, false, 45);
    Def(E_SMOKER_LONG,    "Smoker 长舌",   D45, false, 40);
    Def(E_SPITTER_SEA,    "Spitter 酸海",  D45, false, 45);
    Def(E_JOCKEY_MAD,     "Jockey 疯狗",   D45, false, 45);
    Def(E_WITCH_RAGE,     "Witch 狂暴",    D60, false, 40);
    Def(E_LILLIPUT,       "小人国",        D45, false, 45);
    Def(E_GIANT,          "巨人国",        D45, false, 45);
    Def(E_BIG_HEAD,       "大头模式",      D45, false, 40);

    Def(E_WEAPON_ROULETTE,   "武器轮盘",    D60, false, 40);
    Def(E_POSITION_ROULETTE, "位置轮盘",    D60, false, 40);
    Def(E_HEALTH_ROULETTE,   "血量轮盘",    D60, false, 40);
    Def(E_LAUNCH_ALL,        "全员弹射",    D60, false, 40);
    Def(E_SUPER_KNOCKBACK,   "超级击退",    D45, false, 45);
    Def(E_NO_KNOCKBACK,      "无击退",      D45, false, 45);
    Def(E_TIME_FAST,         "时间加速",    D30, false, 35);
    Def(E_SLOW_MO,           "慢动作",      D30, false, 35);
    Def(E_MEDICAL,           "医疗狂欢",    D45, false, 40);
    Def(E_RESCUE_FAST,       "救援专家",    D60, false, 40);
    Def(E_RESCUE_SLOW,       "救援困难",    D60, false, 40);
    Def(E_INF_PUSH,          "无限推",      D60, false, 45);
    Def(E_NO_PUSH,           "禁止推击",    D45, false, 40);

    Def(E_DOUBLE_EVENT,   "双重事件",      0.0, true,  50);
    Def(E_REDRAW,         "事件重抽",      0.0, true,  40);
    Def(E_CHAOS_MINUTE,   "混乱一分钟",    0.0, true,  30);
    Def(E_HEAL_ALL,       "全员恢复",      0.0, true,  90);
    Def(E_HURT_ALL,       "全员扣血",      0.0, true,  70);
    Def(E_RANDOM_TELEPORT,"随机传送",      0.0, true,  60);
    Def(E_WEAPON_SHUFFLE, "武器洗牌",      0.0, true,  55);
    Def(E_SI_BURST,       "刷新特感",      0.0, true,  60);
    Def(E_FLING_ALL,      "全员弹射(瞬)",  0.0, true,  55);
    Def(E_GIVE_MEDS,      "发放药物",      0.0, true,  70);
    Def(E_AMMO_LOSS,      "弹药流失",      0.0, true,  55);
    Def(E_REVIVE_ONE,     "复活一名玩家",  0.0, true,  40);
}

int EffectWeight(int id)
{

    if (id == E_COMMON_FAST || id == E_COMMON_SLOW
        || id == E_LIGHTS_OFF || id == E_WITCH_RAGE) return 0;
    if ((id == E_RESCUE_FAST || id == E_RESCUE_SLOW) && FindConVar("survivor_revive_duration") == null) return 0;
    if (id == E_MEDICAL && FindConVar("first_aid_kit_use_duration") == null) return 0;
    if (id == E_SMOKER_LONG && FindConVar("tongue_range") == null) return 0;
    if (id == E_BIG_HEAD && FindSendPropInfo("CTerrorPlayer", "m_flHeadScale") < 0) return 0;
    int w = g_EffectWeight[id];
    if (w <= 0) return 0;

    switch (id)
    {
        
        case E_SI_RAMPAGE, E_SI_DISABLE, E_TIME_JOCKEY, E_TIME_CHARGER,
             E_TIME_HUNTER, E_TIME_SMOKER, E_TIME_SPITTER, E_TIME_BOOMER:
            if (!DirectorActive()) return 0;
        case E_WITCH_RAGE:   if (!WitchExists()) return 0;
        case E_COMMON_STRONG, E_COMMON_FRAGILE, E_COMMON_FAST, E_COMMON_SLOW:
            if (!SurvivorLeftSafe()) return 0;
        case E_REVIVE_ONE:
            if (DeadHumanSurvivors() == 0) return 0;
        case E_WEAPON_ROULETTE, E_WEAPON_SHUFFLE:
            if (!InventoryReady()) return 0;
    }
    return w;
}

bool DrawContinuous(bool force)
{
    if (!g_Enable.BoolValue || !g_LeftStart || !HasEligible()) return false;
    int activeMax = g_MaxActive.IntValue;
    if (g_ActCount >= activeMax && !force) return false;

    int total;
    for (int id = 0; id < EFFECT_COUNT; id++)
    {
        g_DrawWeight[id] = 0;
        if (g_EffectInstant[id]) continue;
        if (!force && g_ActCount >= activeMax && !IsActive(id)) continue;
        int w = EffectWeight(id);
        if (w <= 0) continue;
        if (id == g_LastEvent) w = w > 3 ? w / 3 : 1;   
        if (IsActive(id))      w = w > 2 ? w / 2 : 1;   
        g_DrawWeight[id] = w;
        total += w;
    }
    if (total <= 0) return false;

    int r = GetRandomInt(0, total - 1), selected = -1;
    for (int id = 0; id < EFFECT_COUNT; id++)
    {
        if (g_DrawWeight[id] <= 0) continue;
        if (r < g_DrawWeight[id]) { selected = id; break; }
        r -= g_DrawWeight[id];
    }
    if (selected < 0) return false;

    StartEffect(selected);
    g_LastEvent = selected;
    g_EventCount++;
    PrintToChatAll("\x04[随机事件]\x01 持续事件：\x03%s\x01（%.0f 秒）。", g_EffectName[selected], g_EffectDur[selected]);
    LogMessage("RANDOM_EVENT id=%d name=%s type=continuous dur=%.0f active=%d", selected, g_EffectName[selected], g_EffectDur[selected], g_ActCount);
    return true;
}

bool DrawInstant()
{
    if (!g_Enable.BoolValue || !g_LeftStart || !HasEligible()) return false;
    int total;
    for (int id = 0; id < EFFECT_COUNT; id++)
    {
        g_DrawWeight[id] = 0;
        if (!g_EffectInstant[id]) continue;
        int w = EffectWeight(id);
        if (w <= 0) continue;
        if (id == E_REDRAW || id == E_DOUBLE_EVENT || id == E_CHAOS_MINUTE) w = w > 4 ? w / 4 : 1;
        g_DrawWeight[id] = w;
        total += w;
    }
    if (total <= 0) return false;

    int r = GetRandomInt(0, total - 1), selected = -1;
    for (int id = 0; id < EFFECT_COUNT; id++)
    {
        if (g_DrawWeight[id] <= 0) continue;
        if (r < g_DrawWeight[id]) { selected = id; break; }
        r -= g_DrawWeight[id];
    }
    if (selected < 0) return false;

    ApplyInstant(selected);
    LogMessage("RANDOM_EVENT id=%d name=%s type=instant", selected, g_EffectName[selected]);
    return true;
}

bool IsActive(int id)
{
    for (int i = 0; i < g_ActCount; i++) if (g_ActId[i] == id) return true;
    return false;
}
int ActiveIndex(int id)
{
    for (int i = 0; i < g_ActCount; i++) if (g_ActId[i] == id) return i;
    return -1;
}
void StartEffect(int id)
{
    if (g_EffectInstant[id]) { ApplyInstant(id); return; }
    int idx = ActiveIndex(id);
    if (idx != -1)
    {
        
        g_ActEnd[idx] = GetGameTime() + g_EffectDur[id];
        g_Period[idx] = PeriodOf(id);
        RecomputeWorld();
        return;
    }
    if (g_ActCount >= MAX_ACTIVE) RemoveActive(0, true);
    g_ActId[g_ActCount] = id;
    g_ActEnd[g_ActCount] = GetGameTime() + g_EffectDur[id];
    g_Period[g_ActCount] = PeriodOf(id);
    g_ActCount++;
    OnEffectStart(id);
    RecomputeWorld();
}
void StopEffect(int id) { int i = ActiveIndex(id); if (i != -1) RemoveActive(i, true); }
void RemoveActive(int idx, bool announce)
{
    int id = g_ActId[idx];
    for (int i = idx; i < g_ActCount - 1; i++)
    {
        g_ActId[i] = g_ActId[i + 1];
        g_ActEnd[i] = g_ActEnd[i + 1];
        g_Period[i] = g_Period[i + 1];
    }
    g_ActCount--;
    OnEffectStop(id);
    RecomputeWorld();
    if (announce && g_Announce.BoolValue)
        PrintToChatAll("\x04[随机事件]\x01 事件结束：\x03%s\x01。", g_EffectName[id]);
}
void StopAllEffects(bool announce)
{
    for (int i = g_ActCount - 1; i >= 0; i--) RemoveActive(i, false);
    g_ActCount = 0;
    RecomputeWorld();
    CleanupEnvironment();
    if (announce) PrintToChatAll("\x04[随机事件]\x01 全部事件已清除。");
}

public Action Tick(Handle timer)
{
    if (!g_Enable.BoolValue || !g_LeftStart) return Plugin_Continue;
    bool eligible = HasEligible();

    float now = GetGameTime();
    for (int i = g_ActCount - 1; i >= 0; i--)
    {
        if (now >= g_ActEnd[i]) { RemoveActive(i, true); continue; }
        int id = g_ActId[i];
        float iv = PeriodOf(id);
        if (iv > 0.0)
        {
            g_Period[i] -= 1.0;
            if (g_Period[i] <= 0.0 && eligible) { RunPeriodic(id); g_Period[i] = iv; }
        }
    }

    ApplyOngoing();
    EnforcePersistent();

    if (!eligible) return Plugin_Continue;
    g_NextDraw -= 1.0;
    if (g_NextDraw <= 0.0)
    {
        g_NextDraw = g_Interval.FloatValue;
        DrawContinuous(false);
        if (GetRandomInt(1, 100) <= g_InstantChance.IntValue) DrawInstant();
    }
    return Plugin_Continue;
}

public Action AnnounceTimer(Handle timer)
{
    if (!g_Announce.BoolValue || !g_Enable.BoolValue || !g_LeftStart) return Plugin_Continue;
    if (g_ActCount == 0)
    {
        PrintToChatAll("\x04[随机事件]\x01 当前无进行中事件。下次抽取剩余 %.0f 秒。", g_NextDraw);
        return Plugin_Continue;
    }
    char list[256];
    for (int i = 0; i < g_ActCount; i++)
    {
        char bit[64];
        Format(bit, sizeof(bit), "%s(%ds) ", g_EffectName[g_ActId[i]], RoundToCeil(g_ActEnd[i] - GetGameTime()));
        StrCat(list, sizeof(list), bit);
    }
    PrintToChatAll("\x04[随机事件]\x01 进行中：%s｜下次抽取剩余 %.0f 秒。", list, g_NextDraw);
    return Plugin_Continue;
}

void OnEffectStart(int id) { switch (id) {} }   
void OnEffectStop(int id)
{
    if (id == E_EARTHQUAKE && ActiveIndex(E_EARTHQUAKE) == -1) CleanupEnvironment();
}

float PeriodOf(int id)
{
    switch (id)
    {
        case E_HORDE_ENDLESS:   return 5.0;
        case E_SI_RAMPAGE:      return 6.0;
        case E_REGEN, E_BLEED:  return 3.0;
        case E_RANDOM_PUSH:     return 7.0;
        case E_EARTHQUAKE:      return 8.0;
        case E_AIRSTRIKE:       return 6.0;
        case E_MOLOTOV_RAIN:    return 7.0;
        case E_LIGHTNING:       return 9.0;
        case E_WEAPON_ROULETTE: return 10.0;
        case E_POSITION_ROULETTE: return 15.0;
        case E_HEALTH_ROULETTE: return 10.0;
        case E_LAUNCH_ALL:      return 10.0;
        case E_SI_BURST:        return 0.0;
    }
    return 0.0;
}

void RunPeriodic(int id)
{
    switch (id)
    {
        case E_HORDE_ENDLESS:   ForceMob(12);
        case E_SI_RAMPAGE:      ForceSISpawnTimers(4.0);
        case E_REGEN:           { if (g_Regen) RegenAll(2); }
        case E_BLEED:           { if (g_Bleed) BleedAll(1); }
        case E_RANDOM_PUSH:     RandomPushAll(120.0);
        case E_EARTHQUAKE:      FireShake();
        case E_AIRSTRIKE:       RandomExplosionAll();
        case E_MOLOTOV_RAIN:    MolotovRainAll();
        case E_LIGHTNING:       LightningFlash();
        case E_WEAPON_ROULETTE: RouletteWeapons();
        case E_POSITION_ROULETTE: SwapTwoSurvivors();
        case E_HEALTH_ROULETTE: RouletteHealth();
        case E_LAUNCH_ALL:      LaunchAll(380.0);
    }
}

bool ApplyInstant(int id)
{
    switch (id)
    {
        case E_HORDE_NOW:      { ForceMob(25); }
        case E_TEMP_HP:        { for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) L4D_SetTempHealth(c, L4D_GetTempHealth(c) + 30.0); }
        case E_HEAL_ALL:       { for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) HealSurvivor(c, 30); }
        case E_HURT_ALL:       { for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) HurtSurvivor(c, 20); }
        case E_RANDOM_TELEPORT:{ RandomTeleportAll(); }
        case E_WEAPON_SHUFFLE: { RouletteWeapons(); }
        case E_SI_BURST:       { for (int k = 0; k < 2; k++) SpawnRandomSpecial(); }
        case E_FLING_ALL:      { LaunchAll(500.0); }
        case E_GIVE_MEDS:      { GiveMedsAll(); }
        case E_AMMO_LOSS:      { LoseAmmoAll(); }
        case E_REVIVE_ONE:     { ReviveOne(); }
        case E_DOUBLE_EVENT:   { PrintToChatAll("\x04[随机事件]\x01 双重事件！再抽一个持续事件。"); DrawContinuous(false); }
        case E_REDRAW:
        {
            PrintToChatAll("\x04[随机事件]\x01 事件重抽！清除当前效果。");
            for (int i = g_ActCount - 1; i >= 0; i--) RemoveActive(i, false);
            DrawContinuous(false);
        }
        case E_CHAOS_MINUTE:
        {
            PrintToChatAll("\x04[随机事件]\x01 \x03混乱一分钟\x01！同时触发 3 个持续事件。");
            for (int k = 0; k < 3; k++) DrawContinuous(true);
        }
        default: return false;
    }
    return true;
}

void RecomputeWorld()
{
    g_SurvSpeed = 1.0; g_SpecialSpeed = 1.0; g_CommonSpeed = 1.0; g_WitchSpeed = 1.0;
    g_DmgDealt = 1.0; g_DmgTaken = 1.0; g_MeleeMult = 1.0; g_GunMult = 1.0;
    g_ReloadMult = 1.0; g_CycleMult = 1.0; g_SpreadMult = 1.0;
    g_CommonHpMult = 1.0; g_SIHpMult = 1.0; g_GravityMult = 1.0; g_TimeScale = 1.0;
    g_FrictionMult = 1.0; g_FogMode = 0; g_SpawnBias = 0; g_SIDisable = false;
    g_InfAmmo = g_InfClip = false;
    g_FireImmune = g_AcidImmune = false;
    g_FFOff = g_FFDouble = false;
    g_HighJump = false; g_LightsOff = false;
    g_Lifesteal = g_Regen = g_Bleed = false;
    g_CommonExplode = g_CommonFire = g_BoomerNuke = false;
    g_ChargerRocket = g_HunterSmash = g_JockeyMad = g_WitchRage = false;
    g_SuperKnock = g_NoKnock = false;
    g_InfPush = g_NoPush = false;
    g_ModelScaleOn = g_HeadScaleOn = false; g_ModelScale = 1.0; g_HeadScale = 1.0;

    for (int i = 0; i < g_ActCount; i++) ApplyEffectToState(g_ActId[i]);

    CacheCvarOriginals();
    if (L4D_HasMapStarted()) CacheGunOriginals();
    ApplyCvars();
    ApplyWeaponAttributes();
    ApplyEntityScaling();
    ApplyFog();
}

void ApplyEffectToState(int id)
{
    switch (id)
    {
        case E_COMMON_FAST:    g_CommonSpeed *= 1.5;
        case E_COMMON_SLOW:    g_CommonSpeed *= 0.5;
        case E_COMMON_STRONG:  g_CommonHpMult *= 2.0;
        case E_COMMON_FRAGILE: g_CommonHpMult *= 0.05;
        case E_SI_FAST:        g_SpecialSpeed *= 1.5;
        case E_SI_STRONG:      g_SIHpMult *= 1.75;
        case E_SI_FRAGILE:     g_SIHpMult *= 0.5;
        case E_SI_DISABLE:     g_SIDisable = true;
        case E_TIME_JOCKEY:    g_SpawnBias = ZC_JOCKEY;
        case E_TIME_CHARGER:   g_SpawnBias = ZC_CHARGER;
        case E_TIME_HUNTER:    g_SpawnBias = ZC_HUNTER;
        case E_TIME_SMOKER:    g_SpawnBias = ZC_SMOKER;
        case E_TIME_SPITTER:   g_SpawnBias = ZC_SPITTER;
        case E_TIME_BOOMER:    g_SpawnBias = ZC_BOOMER;
        case E_SURV_FAST:      g_SurvSpeed *= 1.4;
        case E_SURV_SLOW:      g_SurvSpeed *= 0.65;
        case E_HIGH_JUMP:      g_HighJump = true;
        case E_LOW_GRAVITY:    g_GravityMult *= 0.35;
        case E_HIGH_GRAVITY:   g_GravityMult *= 2.2;
        case E_INF_AMMO:       g_InfAmmo = true;
        case E_INF_CLIP:       g_InfClip = true;
        case E_FAST_RELOAD:    g_ReloadMult *= 0.35;
        case E_SLOW_RELOAD:    g_ReloadMult *= 2.0;
        case E_FAST_FIRE:      g_CycleMult *= 0.5;
        case E_WEAPON_STRONG:  g_DmgDealt *= 1.5;
        case E_WEAPON_WEAK:    g_DmgDealt *= 0.6;
        case E_ACCURATE:       g_SpreadMult *= 0.3;
        case E_INACCURATE:     g_SpreadMult *= 3.0;
        case E_LIFESTEAL:      g_Lifesteal = true;
        case E_REGEN:          g_Regen = true;
        case E_BLEED:          g_Bleed = true;
        case E_GLASS_CANNON:   { g_DmgDealt *= 2.0; g_DmgTaken *= 2.0; }
        case E_IRONMAN:        g_DmgTaken *= 0.5;
        case E_SQUISHY:        g_DmgTaken *= 1.6;
        case E_MELEE_KING:     g_MeleeMult *= 3.0;
        case E_GUN_KING:       { g_GunMult *= 1.4; g_MeleeMult *= 0.4; }
        case E_FIRE_IMMUNE:    g_FireImmune = true;
        case E_ACID_IMMUNE:    g_AcidImmune = true;
        case E_FF_OFF:         g_FFOff = true;
        case E_FF_DOUBLE:      g_FFDouble = true;
        case E_DARK:           if (g_FogMode < 1) g_FogMode = 1;
        case E_FOG:            if (g_FogMode < 2) g_FogMode = 2;
        case E_LIGHTS_OFF:     g_LightsOff = true;
        case E_ICE:            g_FrictionMult *= 0.2;
        case E_EARTHQUAKE:     if (g_ShakeEntity == -1) CreateShake();
        case E_COMMON_EXPLODE: g_CommonExplode = true;
        case E_COMMON_FIRE:    g_CommonFire = true;
        case E_BOOMER_NUKE:    g_BoomerNuke = true;
        case E_CHARGER_ROCKET: g_ChargerRocket = true;
        case E_HUNTER_SMASH:   g_HunterSmash = true;
        case E_SPITTER_SEA:    {} 
        case E_JOCKEY_MAD:     g_JockeyMad = true;
        case E_WITCH_RAGE:     { g_WitchRage = true; g_WitchSpeed = 1.8; }
        case E_LILLIPUT:       { g_ModelScaleOn = true; g_ModelScale *= 0.6; }
        case E_GIANT:          { g_ModelScaleOn = true; g_ModelScale *= 1.5; }
        case E_BIG_HEAD:       { g_HeadScaleOn = true; g_HeadScale *= 2.0; }
        case E_SUPER_KNOCKBACK: g_SuperKnock = true;
        case E_NO_KNOCKBACK:    g_NoKnock = true;
        case E_TIME_FAST:      g_TimeScale *= 1.5;
        case E_SLOW_MO:        g_TimeScale *= 0.6;
        case E_INF_PUSH:       g_InfPush = true;
        case E_NO_PUSH:        g_NoPush = true;
    }
}

void SIClassHealthCvar(int cls, char[] buf, int size)
{
    buf[0] = '\0';
    switch (cls)
    {
        case ZC_SMOKER:  strcopy(buf, size, "z_smoker_health");
        case ZC_BOOMER:  strcopy(buf, size, "z_exploding_health");
        case ZC_HUNTER:  strcopy(buf, size, "z_hunter_health");
        case ZC_SPITTER: strcopy(buf, size, "z_spitter_health");
        case ZC_JOCKEY:  strcopy(buf, size, "z_jockey_health");
        case ZC_CHARGER: strcopy(buf, size, "z_charger_health");
        case ZC_TANK:    strcopy(buf, size, "z_tank_health");
    }
}

void ApplyCvars()
{
    SetCvarFloat("sv_gravity", g_OrigGravity * g_GravityMult);
    SetCvarFloat("sv_friction", g_OrigFriction * g_FrictionMult);

    SetCvarFloat("sv_accelerate", g_OrigAccelerate * (ActiveIndex(E_ICE) != -1 ? 0.2 : 1.0));
    bool timeActive = ActiveIndex(E_TIME_FAST) != -1 || ActiveIndex(E_SLOW_MO) != -1;
    if (timeActive)
    {
        if (!g_TimeOwned)
        {
            g_OrigTimeScale = CvarFloat("host_timescale", 1.0);
            ConVar cheats = FindConVar("sv_cheats");
            g_OrigCheats = cheats == null ? 0 : cheats.IntValue;
            g_TimeOwned = true;
        }
        SetCvarInt("sv_cheats", 1);
        float scale = g_OrigTimeScale * g_TimeScale;
        if (scale < 0.25) scale = 0.25;
        if (scale > 2.0) scale = 2.0;
        SetCvarFloat("host_timescale", scale);
    }
    else if (g_TimeOwned)
    {
        SetCvarFloat("host_timescale", g_OrigTimeScale);
        SetCvarInt("sv_cheats", g_OrigCheats);
        g_TimeOwned = false;
    }
    SetCvarFloat("tongue_range", ActiveIndex(E_SMOKER_LONG) != -1 ? g_OrigTongueRange * 2.0 : g_OrigTongueRange);

    SetCvarFloat("z_health", g_OrigCommonHealth * g_CommonHpMult);

    for (int c = 1; c <= 8; c++)
    {
        char cv[24]; SIClassHealthCvar(c, cv, sizeof(cv));
        if (cv[0] == '\0') continue;
        SetCvarFloat(cv, g_OrigSIHealth[c] * g_SIHpMult);
    }

    SetCvarFloat("z_jockey_speed", g_JockeyMad ? g_OrigJockeySpeed * 2.2 : g_OrigJockeySpeed);

    float med = ActiveIndex(E_MEDICAL) != -1 ? 0.3 : (ActiveIndex(E_RESCUE_SLOW) != -1 ? 1.0 : 1.0);
    SetCvarFloat("first_aid_kit_use_duration", g_OrigMedDuration * med);
    float rev = ActiveIndex(E_RESCUE_FAST) != -1 ? 0.4 : (ActiveIndex(E_RESCUE_SLOW) != -1 ? 1.8 : 1.0);
    SetCvarFloat("survivor_revive_duration", g_OrigReviveDuration * rev);
}

void CacheCvarOriginals()
{
    if (g_CachedOriginals) return;
    g_OrigGravity    = CvarFloat("sv_gravity", 800.0);
    g_OrigTimeScale  = CvarFloat("host_timescale", 1.0);
    g_OrigFriction   = CvarFloat("sv_friction", 4.0);
    g_OrigAccelerate = CvarFloat("sv_accelerate", 5.0);
    g_OrigCommonHealth = CvarFloat("z_health", 50.0);
    g_OrigJockeySpeed  = CvarFloat("z_jockey_speed", 400.0);
    g_OrigMedDuration   = CvarFloat("first_aid_kit_use_duration", 5.0);
    g_OrigReviveDuration = CvarFloat("survivor_revive_duration", 5.0);
    g_OrigTongueRange = CvarFloat("tongue_range", 750.0);
    ConVar cheats = FindConVar("sv_cheats");
    g_OrigCheats = cheats == null ? 0 : cheats.IntValue;

    for (int c = 1; c <= 8; c++)
    {
        char cv[24]; SIClassHealthCvar(c, cv, sizeof(cv));
        if (cv[0] != '\0') g_OrigSIHealth[c] = CvarFloat(cv, 100.0);
    }
    g_CachedOriginals = true;
}

void CacheGunOriginals()
{
    if (g_GunCached) return;
    for (int i = 0; i < GUN_COUNT; i++)
    {
        if (!L4D2_IsValidWeapon(g_Guns[i])) continue;
        g_GunOrigReload[i]    = L4D2_GetFloatWeaponAttribute(g_Guns[i], L4D2FWA_ReloadDuration);
        g_GunOrigCycle[i]     = L4D2_GetFloatWeaponAttribute(g_Guns[i], L4D2FWA_CycleTime);
        g_GunOrigSpread[i]    = L4D2_GetFloatWeaponAttribute(g_Guns[i], L4D2FWA_SpreadPerShot);
        g_GunOrigMaxSpread[i] = L4D2_GetFloatWeaponAttribute(g_Guns[i], L4D2FWA_MaxSpread);
    }
    g_GunCached = true;
}

void ApplyWeaponAttributes()
{
    if (!g_GunCached) return;
    for (int i = 0; i < GUN_COUNT; i++)
    {
        if (!L4D2_IsValidWeapon(g_Guns[i])) continue;
        L4D2_SetFloatWeaponAttribute(g_Guns[i], L4D2FWA_ReloadDuration, g_GunOrigReload[i] * g_ReloadMult);
        L4D2_SetFloatWeaponAttribute(g_Guns[i], L4D2FWA_CycleTime,      g_GunOrigCycle[i] * g_CycleMult);
        L4D2_SetFloatWeaponAttribute(g_Guns[i], L4D2FWA_SpreadPerShot,  g_GunOrigSpread[i] * g_SpreadMult);
        L4D2_SetFloatWeaponAttribute(g_Guns[i], L4D2FWA_MaxSpread,      g_GunOrigMaxSpread[i] * g_SpreadMult);
    }
}

void ApplyFog()
{
    if (g_FogMode == 0) { RestoreFog(); return; }

    if (g_FogEntity == -1 || !IsValidEntity(g_FogEntity))
    {
        
        int existing = -1;
        while ((existing = FindEntityByClassname(existing, "env_fog_controller")) != -1)
        {
            g_OrigFog = existing;
            AcceptEntityInput(existing, "TurnOff");
            break;
        }
        int ent = CreateEntityByName("env_fog_controller");
        if (ent == -1) return;
        DispatchSpawn(ent);
        g_FogEntity = ent;
    }

    if (g_FogMode == 1)
    {
        DispatchKeyValue(g_FogEntity, "fogcolor", "10 10 14");
        DispatchKeyValue(g_FogEntity, "fogcolor2", "10 10 14");
        DispatchKeyValue(g_FogEntity, "fogstart", "0");
        DispatchKeyValue(g_FogEntity, "fogend", "260");
        DispatchKeyValue(g_FogEntity, "fogmaxdensity", "1.0");
    }
    else
    {
        DispatchKeyValue(g_FogEntity, "fogcolor", "150 160 150");
        DispatchKeyValue(g_FogEntity, "fogcolor2", "150 160 150");
        DispatchKeyValue(g_FogEntity, "fogstart", "40");
        DispatchKeyValue(g_FogEntity, "fogend", "420");
        DispatchKeyValue(g_FogEntity, "fogmaxdensity", "0.95");
    }
    AcceptEntityInput(g_FogEntity, "TurnOn");
}
void RestoreFog()
{
    if (g_FogEntity != -1)
    {
        if (IsValidEntity(g_FogEntity)) RemoveEntity(g_FogEntity);
        g_FogEntity = -1;
    }
    if (g_OrigFog != -1)
    {
        if (IsValidEntity(g_OrigFog)) AcceptEntityInput(g_OrigFog, "TurnOn");
        g_OrigFog = -1;
    }
}
void CleanupEnvironment()
{
    if (g_ShakeEntity != -1 && IsValidEntity(g_ShakeEntity)) { RemoveEntity(g_ShakeEntity); g_ShakeEntity = -1; }
    RestoreFog();
}

void CreateShake()
{
    int ent = CreateEntityByName("env_shake");
    if (ent == -1) return;
    DispatchKeyValue(ent, "amplitude", "8");
    DispatchKeyValue(ent, "frequency", "80");
    DispatchKeyValue(ent, "duration", "2.5");
    DispatchKeyValue(ent, "radius", "2000");
    DispatchKeyValue(ent, "spawnflags", "1");
    DispatchSpawn(ent);
    g_ShakeEntity = ent;
}
void FireShake()
{
    if (g_ShakeEntity != -1 && IsValidEntity(g_ShakeEntity)) AcceptEntityInput(g_ShakeEntity, "StartShake");
}

void EnforcePersistent()
{
    
    if (g_LightsOff)
    {
        for (int c = 1; c <= MaxClients; c++)
        {
            if (!AliveSurvivor(c)) continue;
            int fx = GetEntProp(c, Prop_Send, "m_fEffects");
            if ((fx & 4) != 0) SetEntProp(c, Prop_Send, "m_fEffects", fx & ~4);
        }
    }
    
    if (g_InfPush)
    {
        for (int c = 1; c <= MaxClients; c++)
        {
            if (!AliveSurvivor(c)) continue;
            SetEntProp(c, Prop_Send, "m_iShovePenalty", 0);
            L4D2Direct_SetNextShoveTime(c, 0.0);
        }
    }
}

void ApplyOngoing()
{
    if (g_CommonHpMult != 1.0 || g_CommonSpeed != 1.0 || g_ModelScaleOn || g_HeadScaleOn || g_WitchRage)
        ApplyInfectedEntityPass();
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && (g_ModelOwned[c] || g_HeadOwned[c])) ApplyVisualScale(c);
}

void ApplyEntityScaling()
{
    ApplyInfectedEntityPass();
}

void ApplyInfectedEntityPass()
{
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "infected")) != -1)
    {
        if (ent < sizeof(g_CommonRef))
        {
            int ref = EntIndexToEntRef(ent);
            if (g_CommonRef[ent] != ref) { g_CommonRef[ent] = ref; g_CommonApplied[ent] = 1.0; }
            float previous = g_CommonApplied[ent];
            if (FloatAbs(previous - g_CommonHpMult) > 0.001)
            {
                int hp = GetEntProp(ent, Prop_Data, "m_iHealth");

                if (hp > 0) SetEntProp(ent, Prop_Data, "m_iHealth", RoundToCeil(float(hp) * g_CommonHpMult / previous));
                g_CommonApplied[ent] = g_CommonHpMult;
            }
        }
        if (g_CommonSpeed != 1.0 && HasEntProp(ent, Prop_Send, "m_flPlaybackRate")) SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", g_CommonSpeed);
        ApplyVisualScale(ent);
    }
    
    ent = -1;
    while ((ent = FindEntityByClassname(ent, "witch")) != -1)
    {
        if (g_WitchRage && HasEntProp(ent, Prop_Send, "m_flPlaybackRate")) SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", g_WitchSpeed);
        ApplyVisualScale(ent);
    }
    
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsSI(c)) continue;
        ApplyVisualScale(c);

        int cls = GetEntProp(c, Prop_Send, "m_zombieClass");
        if (cls >= 1 && cls <= 8 && g_OrigSIHealth[cls] > 0.0)
        {
            int newMax = RoundToNearest(g_OrigSIHealth[cls] * g_SIHpMult);
            int curMax = GetEntProp(c, Prop_Data, "m_iMaxHealth");
            if (newMax > 0 && curMax != newMax)
            {
                int hp = GetEntProp(c, Prop_Data, "m_iHealth");
                SetEntProp(c, Prop_Data, "m_iMaxHealth", newMax);
                int newHp = curMax > 0 ? RoundToNearest(float(hp) * float(newMax) / float(curMax)) : newMax;
                if (newHp > newMax) newHp = newMax;
                if (newHp < 1) newHp = 1;
                SetEntityHealth(c, newHp);
            }
        }
    }
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && GetClientTeam(c) == 2) ApplyVisualScale(c);

}

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
    if (!IsClientInGameSafe(target)) return Plugin_Continue;
    int team = GetClientTeam(target);
    float m = 1.0;
    if (team == 2) m = g_SurvSpeed;
    else if (team == 3) m = g_SpecialSpeed;
    if (m == 1.0) return Plugin_Continue;
    retVal *= m;
    return Plugin_Changed;
}
public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
    if (!IsClientInGameSafe(target)) return Plugin_Continue;
    int team = GetClientTeam(target);
    float m = (team == 2) ? g_SurvSpeed : (team == 3 ? g_SpecialSpeed : 1.0);
    if (m == 1.0) return Plugin_Continue;
    retVal *= m;
    return Plugin_Changed;
}
public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
    if (!IsClientInGameSafe(target)) return Plugin_Continue;
    int team = GetClientTeam(target);
    float m = (team == 2) ? g_SurvSpeed : (team == 3 ? g_SpecialSpeed : 1.0);
    if (m == 1.0) return Plugin_Continue;
    retVal *= m;
    return Plugin_Changed;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "infected") || StrEqual(classname, "witch"))
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    else if (StrEqual(classname, "player"))
    {
        if (entity > 0 && entity <= MaxClients && !g_HookedEntity[entity])
        {
            g_HookedEntity[entity] = true;
            SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}
void EnsureHooks()
{

    for (int c = 1; c <= MaxClients; c++)
        if (IsValidEntity(c) && !g_HookedEntity[c])
        {
            g_HookedEntity[c] = true;
            SDKHook(c, SDKHook_OnTakeDamage, OnTakeDamage);
        }
}
public void OnClientPutInServer(int client)
{
    if (!g_HookedEntity[client] && IsValidEntity(client))
    {
        g_HookedEntity[client] = true;
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}
public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    g_HookedEntity[client] = false;
}
public void OnEntityDestroyed(int entity)
{
    if (entity > 0 && entity <= MaxClients) g_HookedEntity[entity] = false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    bool victimSurv = IsSurvivor(victim);
    bool victimInf  = IsInfected(victim);

    if (victimSurv)
    {
        if (IsSurvivor(attacker))
        {
            if (g_FFOff) { damage = 0.0; return Plugin_Handled; }
            if (g_FFDouble) damage *= 2.0;
        }
        if (g_HunterSmash && IsSI(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") == ZC_HUNTER)
            damage *= 1.8;
        if ((damagetype & DMGT_BURN) && g_FireImmune) { damage = 0.0; return Plugin_Handled; }
        if ((damagetype & DMGT_ACID) && g_AcidImmune) { damage = 0.0; return Plugin_Handled; }
        if (g_DmgTaken != 1.0) damage *= g_DmgTaken;
        return Plugin_Changed;
    }

    if (victimInf)
    {
        if (IsSurvivor(attacker))
        {
            bool melee = IsMeleeWeapon(weapon);
            float mult = g_DmgDealt;
            mult *= melee ? g_MeleeMult : g_GunMult;
            if (mult != 1.0) damage *= mult;

            if (g_SuperKnock) { for (int i = 0; i < 3; i++) damageForce[i] *= 3.0; }
            if (g_NoKnock)    { for (int i = 0; i < 3; i++) damageForce[i] *= 0.05; }

            if (g_Lifesteal && damage > 0.0)
            {
                int hp = GetClientHealth(attacker);
                int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
                int heal = RoundToCeil(damage * 0.15);
                if (heal > 0 && hp < max) SetEntityHealth(attacker, hp + heal > max ? max : hp + heal);
            }
        }

        if (victim > MaxClients && !g_FxBusy && (g_CommonExplode || g_CommonFire))
        {
            int hp = GetEntProp(victim, Prop_Data, "m_iHealth");
            if (hp > 0 && damage >= float(hp))
            {
                float pos[3];
                GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
                g_FxBusy = true;
                if (g_CommonExplode) MakeExplosion(pos, 50, 150);
                if (g_CommonFire) { float ang[3] = {0.0, 0.0, -90.0}; pos[2] += 10.0; L4D_MolotovPrj(0, pos, ang); }
                g_FxBusy = false;
            }
        }
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
    if (g_SIDisable) return Plugin_Handled;
    if (g_SpawnBias > 0 && zombieClass != g_SpawnBias && GetRandomInt(1, 100) <= 75)
    {
        zombieClass = g_SpawnBias;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z)
{
    if (!IsActive(E_SPITTER_SEA)) return Plugin_Continue;
    x *= 1.8; y *= 1.8; z *= 1.6;
    return Plugin_Changed;
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
    if (g_NoPush) return Plugin_Handled;
    return Plugin_Continue;
}

public void L4D2_OnThrowImpactedSurvivor_Post(int attacker, int victim)
{
    if (!g_ChargerRocket) return;
    if (!IsSurvivor(victim)) return;
    float dir[3];
    dir[0] = 0.0; dir[1] = 0.0; dir[2] = 1.0;
    L4D2_CTerrorPlayer_Fling(victim, attacker, dir);
}

public void Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_HighJump) return;
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!AliveSurvivor(client)) return;
    float vel[3];
    vel[0] = 0.0; vel[1] = 0.0; vel[2] = 260.0;
    SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", vel);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_InfAmmo && !g_InfClip) return;
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!AliveSurvivor(client)) return;
    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (weapon <= 0 || !IsValidEntity(weapon)) return;
    if (g_InfAmmo) L4D_SetReserveAmmo(client, weapon, 999);
    if (g_InfClip)
    {
        char cls[64]; GetEntityClassname(weapon, cls, sizeof(cls));
        if (L4D2_IsValidWeapon(cls))
        {
            int max = L4D2_GetIntWeaponAttribute(cls, L4D2IWA_ClipSize);
            if (max > 0) SetEntProp(weapon, Prop_Send, "m_iClip1", max);
        }
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_CommonExplode && !g_CommonFire && !g_BoomerNuke) return;
    int victim = GetClientOfUserId(event.GetInt("userid"));
    float pos[3];

    if (victim > 0 && IsClientInGame(victim) && GetClientTeam(victim) == 3)
    {
        if (g_BoomerNuke && !g_FxBusy && GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_BOOMER)
        {
            GetClientAbsOrigin(victim, pos);
            g_FxBusy = true;
            MakeExplosion(pos, 250, 400);
            g_FxBusy = false;
        }
        return;
    }
    return;
}

void ForceMob(int count)
{
    L4D2Direct_SetPendingMobCount(count);
    L4D2_CTimerStart(L4D2CT_MobSpawnTimer, 2.0);
    L4D_ResetMobTimer();
}
void ForceSISpawnTimers(float dur)
{
    L4D2_CTimerStart(L4D2CT_SmokerSpawnTimer, dur);
    L4D2_CTimerStart(L4D2CT_BoomerSpawnTimer, dur);
    L4D2_CTimerStart(L4D2CT_HunterSpawnTimer, dur);
    L4D2_CTimerStart(L4D2CT_SpitterSpawnTimer, dur);
    L4D2_CTimerStart(L4D2CT_JockeySpawnTimer, dur);
    L4D2_CTimerStart(L4D2CT_ChargerSpawnTimer, dur);
}
void RegenAll(int amount)
{
    for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) HealSurvivor(c, amount);
}
void BleedAll(int amount)
{
    for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) HurtSurvivor(c, amount);
}
void RandomPushAll(float force)
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        float ang = GetRandomFloat(0.0, 6.283);
        float vel[3];
        vel[0] = Cosine(ang) * force; vel[1] = Sine(ang) * force; vel[2] = GetRandomFloat(0.0, 80.0);
        SetEntPropVector(c, Prop_Send, "m_vecBaseVelocity", vel);
    }
}
void LaunchAll(float force)
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        float vel[3];
        vel[0] = GetRandomFloat(-80.0, 80.0); vel[1] = GetRandomFloat(-80.0, 80.0); vel[2] = force;
        SetEntPropVector(c, Prop_Send, "m_vecBaseVelocity", vel);
    }
}
void RandomExplosionAll()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        float pos[3], off[3];
        GetClientAbsOrigin(c, pos);
        off[0] = pos[0] + GetRandomFloat(-300.0, 300.0);
        off[1] = pos[1] + GetRandomFloat(-300.0, 300.0);
        off[2] = pos[2] + 20.0;
        MakeExplosion(off, 60, 0);
    }
}
void MolotovRainAll()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        float pos[3], ang[3] = {0.0, 0.0, -90.0};
        GetClientAbsOrigin(c, pos);
        pos[0] += GetRandomFloat(-250.0, 250.0);
        pos[1] += GetRandomFloat(-250.0, 250.0);
        pos[2] += 200.0;
        L4D_MolotovPrj(0, pos, ang);
    }
}
void LightningFlash()
{
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && !IsFakeClient(c))
            SendFade(c, 255, 255, 255, 200, 60, 0x0001); 
    if (g_ThunderSound[0]) EmitSoundToAll(g_ThunderSound);
    CreateTimer(0.15, Timer_FadeOut);
}
public Action Timer_FadeOut(Handle timer)
{
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && !IsFakeClient(c))
            SendFade(c, 255, 255, 255, 0, 120, 0x0002); 
    return Plugin_Stop;
}
void SendFade(int client, int r, int g, int b, int a, int dur, int flags)
{
    Handle msg = StartMessageOne("Fade", client, USERMSG_RELIABLE);
    if (msg == null) return;
    BfWriteShort(msg, dur);
    BfWriteShort(msg, dur);
    BfWriteShort(msg, flags);
    BfWriteByte(msg, r); BfWriteByte(msg, g); BfWriteByte(msg, b); BfWriteByte(msg, a);
    EndMessage();
}
void MakeExplosion(const float pos[3], int magnitude, int radius)
{
    int ent = CreateEntityByName("env_explosion");
    if (ent == -1) return;
    char buf[16];
    IntToString(magnitude, buf, sizeof(buf));
    DispatchKeyValue(ent, "iMagnitude", buf);
    if (radius > 0) { IntToString(radius, buf, sizeof(buf)); DispatchKeyValue(ent, "iRadiusOverride", buf); }
    DispatchKeyValue(ent, "spawnflags", "0");
    DispatchSpawn(ent);
    TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(ent, "Explode");
}

void HealSurvivor(int client, int amount)
{
    int max = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    int hp = GetClientHealth(client);
    if (hp <= 0) return;
    SetEntityHealth(client, hp + amount > max ? max : hp + amount);
}
void HurtSurvivor(int client, int amount)
{
    float temp = L4D_GetTempHealth(client);
    if (temp > 0.0)
    {
        L4D_SetTempHealth(client, temp - float(amount) > 0.0 ? temp - float(amount) : 0.0);
        return;
    }
    int hp = GetClientHealth(client);
    if (hp - amount < 1) hp = 1; else hp -= amount;
    SetEntityHealth(client, hp);
}
void RandomTeleportAll()
{
    
    int list[MAXPLAYERS], count;
    float pos[MAXPLAYERS][3];
    for (int c = 1; c <= MaxClients; c++)
        if (AliveSurvivor(c)) { list[count] = c; GetClientAbsOrigin(c, pos[count]); count++; }
    if (count < 2) return;
    for (int i = count - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        int tmp = list[i]; list[i] = list[j]; list[j] = tmp;
    }
    for (int i = 0; i < count; i++)
    {
        int src = (i + 1) % count;
        TeleportEntity(list[i], pos[src], NULL_VECTOR, NULL_VECTOR);
    }
}
void SpawnRandomSpecial()
{
    int cls = GetRandomInt(1, 6);
    float pos[3];
    int ref = GetHighestFlowSurvivorSafe();
    if (ref == 0) return;
    if (L4D_GetRandomPZSpawnPosition(ref, cls, 10, pos))
        L4D2_SpawnSpecial(cls, pos, NULL_VECTOR);
}
void GiveMedsAll()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        L4D_SetTempHealth(c, L4D_GetTempHealth(c) + 25.0);
        if (InventoryReady()) SetItem(c, 4, "weapon_pain_pills");
    }
}
void LoseAmmoAll()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        int weapon = GetEntPropEnt(c, Prop_Send, "m_hActiveWeapon");
        if (weapon <= 0 || !IsValidEntity(weapon)) continue;
        int reserve = L4D_GetReserveAmmo(c, weapon);
        L4D_SetReserveAmmo(c, weapon, reserve / 2);
    }
}
void ReviveOne()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!IsClientInGame(c) || IsFakeClient(c) || GetClientTeam(c) != 2) continue;
        if (IsPlayerAlive(c)) continue;
        L4D_RespawnPlayer(c);
        return;
    }
}
void RouletteWeapons()
{
    if (!InventoryReady()) return;
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        char item[64];
        strcopy(item, sizeof(item), g_Guns[GetRandomInt(0, GUN_COUNT - 1)]);
        SetItem(c, 0, item);
    }
}
void SwapTwoSurvivors()
{
    int list[MAXPLAYERS], count;
    for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) list[count++] = c;
    if (count < 2) return;
    int i = GetRandomInt(0, count - 1), j = GetRandomInt(0, count - 1);
    if (i == j) j = (j + 1) % count;
    float p1[3], p2[3];
    GetClientAbsOrigin(list[i], p1);
    GetClientAbsOrigin(list[j], p2);
    TeleportEntity(list[i], p2, NULL_VECTOR, NULL_VECTOR);
    TeleportEntity(list[j], p1, NULL_VECTOR, NULL_VECTOR);
}
void RouletteHealth()
{
    for (int c = 1; c <= MaxClients; c++)
    {
        if (!AliveSurvivor(c)) continue;
        int delta = GetRandomInt(-10, 10);
        if (delta == 0) continue;
        if (delta > 0) HealSurvivor(c, delta);
        else HurtSurvivor(c, -delta);
    }
}

public Action Cmd_Status(int client, int args)
{
    char list[256];
    for (int i = 0; i < g_ActCount; i++)
    {
        char bit[64];
        Format(bit, sizeof(bit), "%s(%ds) ", g_EffectName[g_ActId[i]], RoundToCeil(g_ActEnd[i] - GetGameTime()));
        StrCat(list, sizeof(list), bit);
    }
    ReplyToCommand(client, "[随机事件] enabled=%d started=%d active=%d [%s] next=%.0f interval=%.0f draws=%d",
        g_Enable.IntValue, g_LeftStart, g_ActCount, list, g_NextDraw, g_Interval.FloatValue, g_EventCount);
    return Plugin_Handled;
}
public Action Cmd_Draw(int client, int args)
{
    bool ok = DrawContinuous(false);
    ReplyToCommand(client, "RANDOM_DRAW continuous=%d", ok);
    return Plugin_Handled;
}
public Action Cmd_DrawInstant(int client, int args)
{
    bool ok = DrawInstant();
    ReplyToCommand(client, "RANDOM_DRAW instant=%d", ok);
    return Plugin_Handled;
}
public Action Cmd_Stop(int client, int args)
{
    char arg[16];
    int id;
    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_random_stop <event ID; see sm_random_list>");
        return Plugin_Handled;
    }
    GetCmdArg(1, arg, sizeof(arg));
    if (StringToIntEx(arg, id) != strlen(arg) || id < 0 || id >= EFFECT_COUNT || ActiveIndex(id) == -1)
    {
        ReplyToCommand(client, "Event ID invalid or inactive.");
        return Plugin_Handled;
    }
    StopEffect(id);
    ReplyToCommand(client, "RANDOM_STOP done id=%d", id);
    return Plugin_Handled;
}
public Action Cmd_Clear(int client, int args)
{
    StopAllEffects(true);
    ReplyToCommand(client, "RANDOM_CLEAR done");
    return Plugin_Handled;
}
public Action Cmd_List(int client, int args)
{
    for (int id = 0; id < EFFECT_COUNT; id++)
        ReplyToCommand(client, "#%d %s [%s] dur=%.0f weight=%d", id, g_EffectName[id], g_EffectInstant[id] ? "瞬时" : "持续", g_EffectDur[id], EffectWeight(id));
    return Plugin_Handled;
}

bool AliveSurvivor(int c) { return c > 0 && c <= MaxClients && IsClientInGame(c) && !IsFakeClient(c) && GetClientTeam(c) == 2 && IsPlayerAlive(c); }
bool IsSurvivor(int c)   { return c > 0 && c <= MaxClients && IsClientInGame(c) && GetClientTeam(c) == 2; }
bool IsSI(int c)         { return c > 0 && c <= MaxClients && IsClientInGame(c) && GetClientTeam(c) == 3 && IsPlayerAlive(c); }
bool IsInfected(int e)
{
    if (e <= 0) return false;
    if (e <= MaxClients) return IsSI(e);
    if (!IsValidEntity(e)) return false;
    char cls[32]; GetEntityClassname(e, cls, sizeof(cls));
    return StrEqual(cls, "infected") || StrEqual(cls, "witch");
}
bool IsClientInGameSafe(int c) { return c > 0 && c <= MaxClients && IsClientInGame(c); }
bool IsMeleeWeapon(int weapon)
{
    if (weapon <= 0 || !IsValidEntity(weapon)) return false;
    char cls[64]; GetEntityClassname(weapon, cls, sizeof(cls));
    return StrEqual(cls, "weapon_melee") || StrEqual(cls, "weapon_chainsaw");
}
bool HasEligible()
{
    for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) return true;
    return false;
}
bool SurvivorLeftSafe() { return L4D_HasAnySurvivorLeftSafeArea(); }
bool DirectorActive()   { return !L4D_IsSurvivalMode(); }
bool WitchExists()      { return L4D2_GetWitchCount() > 0; }
int  DeadHumanSurvivors()
{
    int n;
    for (int c = 1; c <= MaxClients; c++)
        if (IsClientInGame(c) && !IsFakeClient(c) && GetClientTeam(c) == 2 && !IsPlayerAlive(c)) n++;
    return n;
}
int GetHighestFlowSurvivorSafe()
{
    int top = L4D_GetHighestFlowSurvivor();
    if (AliveSurvivor(top)) return top;
    for (int c = 1; c <= MaxClients; c++) if (AliveSurvivor(c)) return c;
    return 0;
}
float CvarFloat(const char[] name, float def)
{
    ConVar c = FindConVar(name);
    return c == null ? def : c.FloatValue;
}
void SetCvarFloat(const char[] name, float v)
{
    ConVar c = FindConVar(name);
    if (c != null) c.SetFloat(v);
}
void SetCvarInt(const char[] name, int v)
{
    ConVar c = FindConVar(name);
    if (c != null) c.SetInt(v);
}

bool InventoryReady()
{
    return GetCommandFlags("sm_inventory_set") != INVALID_FCVAR_FLAGS
        && GetCommandFlags("sm_inventory_laser") != INVALID_FCVAR_FLAGS;
}
bool Token(int client, char[] token, int size)
{
    return GetClientAuthId(client, AuthId_SteamID64, token, size);
}
bool SetItem(int client, int slot, const char[] item)
{
    char token[32];
    if (!AliveSurvivor(client) || !InventoryReady() || !Token(client, token, sizeof(token))) return false;
    ServerCommand("sm_inventory_set %d %s %d %s", GetClientUserId(client), token, slot, item);
    ServerExecute();
    int entity=GetPlayerWeaponSlot(client,slot);
    if(StrEqual(item,"none"))return entity<=0;
    if(entity<=0 || !IsValidEntity(entity))return false;
    char actual[64];GetEntityClassname(entity,actual,sizeof(actual));
    return StrEqual(actual,item);
}

void CacheLightningSound()
{
    g_ThunderSound[0] = '\0';
    char candidates[][] = {"ambient/weather/thunder.wav", "ambient/random_amb_sfx/randthunder01.wav", "buttons/arena_switch_press_02.wav"};
    for (int i = 0; i < sizeof(candidates); i++)
    {
        char path[160];Format(path,sizeof(path),"sound/%s",candidates[i]);
        if (FileExists(path,true) && PrecacheSound(candidates[i],true))
        { strcopy(g_ThunderSound,sizeof(g_ThunderSound),candidates[i]);return; }
    }

    if (PrecacheSound("buttons/arena_switch_press_02.wav",true))
        strcopy(g_ThunderSound,sizeof(g_ThunderSound),"buttons/arena_switch_press_02.wav");
}

void ValidateRequiredNatives()
{
    
    char required[][] = { "L4D2Direct_SetNextShoveTime","L4D2Direct_SetPendingMobCount","L4D2_CTerrorPlayer_Fling","L4D2_CTimerStart","L4D2_GetFloatWeaponAttribute","L4D2_GetIntWeaponAttribute","L4D2_GetWitchCount","L4D2_IsValidWeapon","L4D2_SetFloatWeaponAttribute","L4D2_SpawnSpecial","L4D_GetHighestFlowSurvivor","L4D_GetRandomPZSpawnPosition","L4D_GetReserveAmmo","L4D_GetTempHealth","L4D_HasAnySurvivorLeftSafeArea","L4D_HasMapStarted","L4D_IsSurvivalMode","L4D_MolotovPrj","L4D_ResetMobTimer","L4D_RespawnPlayer","L4D_SetReserveAmmo","L4D_SetTempHealth" };
    for (int i=0;i<sizeof(required);i++)
        if (GetFeatureStatus(FeatureType_Native,required[i]) != FeatureStatus_Available)
            SetFailState("Required Left4DHooks native unavailable: %s; load left4dhooks.smx first",required[i]);
}

public void NativeBindingAnchors()
{
    float vector[3];char text[64];int number;
    L4D2Direct_SetNextShoveTime(number,0.0);
    L4D2Direct_SetPendingMobCount(number);
    L4D2_CTerrorPlayer_Fling(number,number,vector);
    L4D2_CTimerStart(view_as<L4D2CountdownTimer>(0),0.0);
    L4D2_GetFloatWeaponAttribute(text,view_as<L4D2FloatWeaponAttributes>(0));
    L4D2_GetIntWeaponAttribute(text,view_as<L4D2IntWeaponAttributes>(0));
    L4D2_GetWitchCount();
    L4D2_IsValidWeapon(text);
    L4D2_SetFloatWeaponAttribute(text,view_as<L4D2FloatWeaponAttributes>(0),0.0);
    L4D2_SpawnSpecial(number,vector,vector);
    L4D_GetHighestFlowSurvivor();
    L4D_GetRandomPZSpawnPosition(number,number,number,vector);
    L4D_GetReserveAmmo(number,number);
    L4D_GetTempHealth(number);
    L4D_HasAnySurvivorLeftSafeArea();
    L4D_HasMapStarted();
    L4D_IsSurvivalMode();
    L4D_MolotovPrj(number,vector,vector,vector,vector);
    L4D_ResetMobTimer();
    L4D_RespawnPlayer(number);
    L4D_SetReserveAmmo(number,number,number);
    L4D_SetTempHealth(number,0.0);
}

void ApplyVisualScale(int ent)
{
    if (ent <= 0 || ent >= sizeof(g_ScaleRef) || !IsValidEntity(ent)) return;
    int ref = EntIndexToEntRef(ent);
    if (g_ScaleRef[ent] != ref)
    {
        g_ScaleRef[ent] = ref;
        g_ModelOwned[ent] = g_HeadOwned[ent] = false;
    }
    if (HasEntProp(ent, Prop_Send, "m_flModelScale"))
    {
        if (g_ModelScaleOn)
        {
            if (!g_ModelOwned[ent]) g_ModelOriginal[ent] = GetEntPropFloat(ent, Prop_Send, "m_flModelScale");
            g_ModelOwned[ent] = true;
            SetEntPropFloat(ent, Prop_Send, "m_flModelScale", g_ModelOriginal[ent] * g_ModelScale);
        }
        else if (g_ModelOwned[ent])
        {
            SetEntPropFloat(ent, Prop_Send, "m_flModelScale", g_ModelOriginal[ent]);
            g_ModelOwned[ent] = false;
        }
    }
    if (HasEntProp(ent, Prop_Send, "m_flHeadScale"))
    {
        if (g_HeadScaleOn)
        {
            if (!g_HeadOwned[ent]) g_HeadOriginal[ent] = GetEntPropFloat(ent, Prop_Send, "m_flHeadScale");
            g_HeadOwned[ent] = true;
            SetEntPropFloat(ent, Prop_Send, "m_flHeadScale", g_HeadOriginal[ent] * g_HeadScale);
        }
        else if (g_HeadOwned[ent])
        {
            SetEntPropFloat(ent, Prop_Send, "m_flHeadScale", g_HeadOriginal[ent]);
            g_HeadOwned[ent] = false;
        }
    }
}
