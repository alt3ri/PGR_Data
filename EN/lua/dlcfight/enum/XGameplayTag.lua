--自动生成，请勿手动更改

---[XGamePlayTag枚举](https://kurogame.feishu.cn/sheets/Ma88su1BThVPawtGEEPc0oolnec?sheet=b3f22f)
---@enum EGameplayTag
local EGameplayTag = {
    root = 0,
    Missile = 1,
    Missile_Parry = 2,
    Missile_Parry_Trigger = 3,
    Missile_Parry_Counter = 4,
    Missile_Parry_Trigger_Interrupt = 5,
    Missile_Parry_Trigger_Sustain = 6,
    Missile_Parry_Trigger_MultiInteract = 7,
    Missile_Parry_Counter_Heavy = 8,
    Missile_Parry_Counter_Light = 9,
    Missile_Parry_Counter_Medium = 10,
    Missile_BehitType = 11,
    Missile_BehitType_Melee = 12,
    Missile_BehitType_Ranged = 13,
    Magic = 14,
    Magic_RelinkDamage = 15,
    Magic_RelinkDamage_HitType = 16,
    Magic_RelinkDamage_HitType_Break = 17,
    Magic_RelinkDamage_HitType_Ultra = 18,
    Magic_RelinkDamage_HitType_MultiSupQte = 19,
    Magic_RelinkDamage_HitType_MultiEndQte = 20,
    Effect = 21,
    Effect_Visiable = 22,
    Effect_Visiable_Launcher = 23,
    Effect_Visiable_Target = 24,
    Effect_Visiable_OtherNpc = 25,
    Effect_Visiable_Launcher_SelfUnvisiable = 26,
    Effect_Visiable_Launcher_SelfCampUnvisiable = 27,
    Effect_Visiable_Launcher_FriendCampUnvisiable = 28,
    Effect_Visiable_Launcher_EnemyCampUnvisiable = 29,
    Effect_Visiable_Target_SelfUnvisiable = 30,
    Effect_Visiable_Target_SelfCampUnvisiable = 31,
    Effect_Visiable_Target_FriendCampUnvisiable = 32,
    Effect_Visiable_Target_EnemyCampUnvisiable = 33,
    Effect_Visiable_OtherNpc_SelfUnvisiable = 34,
    Magic_RelinkDamage_DamageType = 35,
    Magic_RelinkDamage_DamageType_NormalAttack = 36,
    Magic_RelinkDamage_DamageType_CoreAttack = 37,
    Magic_RelinkDamage_DamageType_Skill = 38,
    Magic_RelinkDamage_DamageType_Ultra = 39,
    Buff = 40,
    Buff_BuffType = 41,
    Buff_BuffType_Block = 42,
    Buff_BuffType_Dodge = 43,
    Buff_BuffType_Block_Normal = 44,
    Buff_BuffType_Block_Extreme = 45,
    Buff_BuffType_Dodge_Normal = 46,
    Buff_BuffType_Dodge_Extreme = 47,
    Magic_RelinkDamage_DamageType_ChainSkill = 48,
    Magic_Theatre6 = 49,
    Magic_Theatre6_Damage = 50,
    Magic_Theatre6_Damage_BuffType = 51,
    Magic_Theatre6_Damage_BuffType_Burn = 52,
    Magic_Theatre6_Damage_BuffType_Poison = 53,
    Missile_Theatre6 = 54,
    Missile_Theatre6_HitAffixType = 55,
    Missile_Theatre6_HitAffixType_Activate = 56,
    Missile_Theatre6_HitAffixType_HitFly = 57,
    Missile_Theatre6_HitAffixType_HitDown = 58,
    Missile_Theatre6_HitAffixType_Burn = 59,
    Missile_Theatre6_HitAffixType_Poison = 60,
    Missile_Theatre6_HitAffixType_Block = 61,
    Missile_Theatre6_HitAffixType_Crit = 62,
    Missile_Theatre6_HitAffixType_Kill = 63,
    Missile_Trigger_Npc_Enter = 64,
    Missile_Trigger_Npc_Exit = 65,
    Missile_Trigger_Missile_Enter = 66,
    Missile_Trigger_Missile_Exit = 67,
    Custom = 68,
    Custom_Char = 69,
    Custom_LevelPlay = 70,
    Custom_Quest = 71,
    Custom_Char_Char7008 = 72,
    Custom_Char_Char7008_Stage2 = 73,
    Custom_Char_Char7008_Stage2_Skill01 = 74,
    Custom_Char_Char7008_Stage2_Skill01_RevertCamFov = 75,
    Magic_DamageV3 = 76,
    Magic_DamageV3_DamageType = 77,
    Magic_DamageV3_DamageType_NormalAttack = 78,
    Magic_DamageV3_DamageType_CoreAttack = 79,
    Magic_DamageV3_DamageType_HeavyAttack = 80,
    Magic_DamageV3_DamageType_QTE = 81,
    Magic_DamageV3_DamageType_Entry = 82,
    Magic_DamageV3_DamageType_Ultra = 83,
    Magic_DamageV3_DamageType_Skill = 84,
}
return EGameplayTag
