---@class XEquipEnum
local XEquipEnum = {}

XEquipEnum.OneClickAutoSettingType = {
    WeaponLevel = 1,
    WeaponResonance = 2,
    WeaponOverrun = 3,

    AwarenessLevel = 4,
    AwarenessResonance = 5,
    AwarenessResonanceSkillTypeUpIndex = 6,
    AwarenessResonanceSkillTypeDownIndex = 7,
    AwarenessResonanceTimesIndex = 8,
    AwarenessResonanceSelectedSkillMap = 9,
    AwarenessOverclocking = 10,

    PartnerLevel = 11,
    PartnerQuality = 12,
    PartnerSkill = 13,

    ConfirmSetting = 14,

    WeaponAutoExchange = 15,
    AwarenessResonanceSelectedItemIdMap = 16,
}

--- 会在公共自动设置页面展示并持久化的设置项。
--- 角色专属缓存项不应加入此列表，否则会被误作为布尔设置提交。
XEquipEnum.OneClickAutoSettingGlobalTypeList = {
    XEquipEnum.OneClickAutoSettingType.WeaponLevel,
    XEquipEnum.OneClickAutoSettingType.WeaponResonance,
    XEquipEnum.OneClickAutoSettingType.WeaponOverrun,
    XEquipEnum.OneClickAutoSettingType.AwarenessLevel,
    XEquipEnum.OneClickAutoSettingType.AwarenessResonance,
    XEquipEnum.OneClickAutoSettingType.AwarenessOverclocking,
    XEquipEnum.OneClickAutoSettingType.PartnerLevel,
    XEquipEnum.OneClickAutoSettingType.PartnerQuality,
    XEquipEnum.OneClickAutoSettingType.PartnerSkill,
    XEquipEnum.OneClickAutoSettingType.ConfirmSetting,
}

--- 一键养成自动设置各项无缓存时的默认值
XEquipEnum.OneClickAutoSettingDefaultValue = {
    [XEquipEnum.OneClickAutoSettingType.WeaponLevel] = true,
    [XEquipEnum.OneClickAutoSettingType.WeaponResonance] = false,
    [XEquipEnum.OneClickAutoSettingType.WeaponOverrun] = false,

    [XEquipEnum.OneClickAutoSettingType.AwarenessLevel] = true,
    [XEquipEnum.OneClickAutoSettingType.AwarenessResonance] = false,
    [XEquipEnum.OneClickAutoSettingType.AwarenessOverclocking] = false,

    [XEquipEnum.OneClickAutoSettingType.PartnerLevel] = true,
    [XEquipEnum.OneClickAutoSettingType.PartnerQuality] = false,
    [XEquipEnum.OneClickAutoSettingType.PartnerSkill] = false,

    [XEquipEnum.OneClickAutoSettingType.ConfirmSetting] = true,
    
    [XEquipEnum.OneClickAutoSettingType.WeaponAutoExchange] = false,

    [XEquipEnum.OneClickAutoSettingType.AwarenessResonanceSkillTypeUpIndex] = 0,
    [XEquipEnum.OneClickAutoSettingType.AwarenessResonanceSkillTypeDownIndex] = 0,
    [XEquipEnum.OneClickAutoSettingType.AwarenessResonanceTimesIndex] = 0,
    [XEquipEnum.OneClickAutoSettingType.AwarenessResonanceSelectedSkillMap] = {},
    [XEquipEnum.OneClickAutoSettingType.AwarenessResonanceSelectedItemIdMap] = {},
}

return XEquipEnum
