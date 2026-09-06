local next = next
local tableInsert = table.insert
local rawget = rawget

-- 共鸣Slot索引字典 -> proto数组：空字典返回nil（让 proto.ResonanceInfo = nil）
local function _DicToArray(dic)
    if not (dic and next(dic)) then return nil end
    local arr = {}
    for _, info in pairs(dic) do
        tableInsert(arr, info)
    end
    return arr
end

---@class XEquip
local XEquip = XClass(nil, "XEquip")

local Default = {
    Id = 0,
    TemplateId = 0,
    CharacterId = 0,
    Level = 1,
    Exp = 0,
    Breakthrough = 0,
    CreateTime = 0,
    IsLock = false,
    IsRecycle = false,
    AwakeSlotList = {},
}

function XEquip.GetDefaultFields()
    return Default
end

-- XEquip实例的metatable：字段访问优先回退到protoData，再回退到方法表(vtbl)
-- 这样实例本身只需保存派生/视图字段，原始字段全部从_ProtoData透明读取
local _vtbl  -- 文件末尾通过GetClassVirtualTable(XEquip)赋值
local _equipMt = {
    __index = function(t, k)
        local proto = rawget(t, "_ProtoData")
        if proto then
            local v = proto[k]
            if v ~= nil then return v end
        end
        return _vtbl[k]
    end,
}

--[[装备共鸣表结构
ResonanceInfo = {
    Slot = slot,
    Type = XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB,
    CharacterId = 0,
    TemplateId = 0,
}
]]
--[[/// 意识自动回收设置
[MessagePackObject(keyAsPropertyName: true)]
public class XChipRecycleSite
{
    // 设置的回收星级
    public List<int> RecycleStar = new List<int>();
    // 设置回收天数, 0为不回收
    public int Days;
}
]]
function XEquip:Ctor(protoData)
    setmetatable(self, _equipMt)
    -- 新建实例时只需绑定 _ProtoData，派生字段保持未定义即可（__index 回退到 nil）
    -- 避免在 obj 上写 nil 触发额外的 hash rehash
    self._ProtoData = protoData
end

function XEquip:Release()

end

function XEquip:SyncData(protoData)
    self._ProtoData = protoData
    self.OverrunCanBlindSuit = nil
    -- 共鸣信息Slot索引字典：惰性构建，首次按Slot读时再建（_GetResonanceDic）
    self._ResonanceDic = nil
    self._UnconfirmedResonanceDic = nil
end

-- 惰性构建ResonanceInfo的Slot索引字典（proto为数组形态）
function XEquip:_GetResonanceDic()
    local dic = self._ResonanceDic
    if dic == nil then
        local arr = self._ProtoData.ResonanceInfo
        if arr and next(arr) then
            dic = {}
            for _, info in pairs(arr) do
                dic[info.Slot] = info
            end
            self._ResonanceDic = dic
        end
    end
    return dic
end

function XEquip:_GetUnconfirmedResonanceDic()
    local dic = self._UnconfirmedResonanceDic
    if dic == nil then
        local arr = self._ProtoData.UnconfirmedResonanceInfo
        if arr and next(arr) then
            dic = {}
            for _, info in pairs(arr) do
                dic[info.Slot] = info
            end
            self._UnconfirmedResonanceDic = dic
        end
    end
    return dic
end

-- 将self._ResonanceDic / self._UnconfirmedResonanceDic (Slot索引字典) 同步回protoData (数组)
function XEquip:_SyncResonanceBackToProto()
    local proto = self._ProtoData
    proto.ResonanceInfo = _DicToArray(self._ResonanceDic)
    proto.UnconfirmedResonanceInfo = _DicToArray(self._UnconfirmedResonanceDic)
end

--@isSelect: 是否自选的技能
function XEquip:Resonance(resonanceInfo, isSelect)
    local slot = resonanceInfo.Slot
    local dic = self:_GetResonanceDic()
    local info = dic and dic[slot]

    if not info then
        if dic == nil then
            dic = {}
            self._ResonanceDic = dic
        end
        dic[slot] = resonanceInfo
    else
        if not isSelect then
            if resonanceInfo and next(resonanceInfo) then
                local udic = self:_GetUnconfirmedResonanceDic()
                if udic == nil then
                    udic = {}
                    self._UnconfirmedResonanceDic = udic
                end
                udic[slot] = resonanceInfo
            end
        else
            dic[slot] = resonanceInfo
        end
    end
    self:_SyncResonanceBackToProto()
    self:SetRecycle(false)
end

function XEquip:ResonanceConfirm(slot, isUse)
    local udic = self:_GetUnconfirmedResonanceDic()
    local info = udic and udic[slot]
    if not info then return end

    if isUse then
        local dic = self:_GetResonanceDic()
        if dic == nil then
            dic = {}
            self._ResonanceDic = dic
        end
        dic[slot] = info
    end
    udic[slot] = nil
    if not next(udic) then
        self._UnconfirmedResonanceDic = nil
    end
    self:_SyncResonanceBackToProto()
    self:SetRecycle(false)
end

function XEquip:SetAwake(slot)
    local list = self._ProtoData.AwakeSlotList
    if list then
        -- 已存在则跳过，避免重复加
        for _, s in pairs(list) do
            if s == slot then
                self:SetRecycle(false)
                return
            end
        end
        tableInsert(list, slot)
    else
        self._ProtoData.AwakeSlotList = { slot }
    end
    self:SetRecycle(false)
end

function XEquip:PutOn(characterId)
    characterId = characterId or 0
    self._ProtoData.CharacterId = characterId
    self:SetRecycle(false)
end

function XEquip:TakeOff()
    self._ProtoData.CharacterId = 0
end

function XEquip:SetLock(isLock)
    self._ProtoData.IsLock = isLock and true or false
    self:SetRecycle(false)
end

function XEquip:SetRecycle(isRecycle)
    self._ProtoData.IsRecycle = isRecycle and true or false
end

function XEquip:BreakthroughOneTime()
    local proto = self._ProtoData
    proto.Breakthrough = proto.Breakthrough + 1
    proto.Level = 1
    proto.Exp = 0
    self:SetRecycle(false)
end

function XEquip:SetBreakthrough(breakthrough)
    self._ProtoData.Breakthrough = breakthrough
end

function XEquip:SetLevel(level)
    self._ProtoData.Level = level
    self:SetRecycle(false)
end

function XEquip:SetExp(exp)
    self._ProtoData.Exp = exp
end

function XEquip:IsEquipPosAwaken(slot)
    local list = self._ProtoData.AwakeSlotList
    if not list then return false end
    for _, s in pairs(list) do
        if s == slot then return true end
    end
    return false
end

function XEquip:GetEquipViewModel()
    local viewModelScript
    if self:IsWeapon() then
        viewModelScript = require("XEntity/XEquip/XWeaponViewModel")
    else
        viewModelScript = require("XEntity/XEquip/XEquipViewModel")
    end
    local viewModel = viewModelScript.New(self.TemplateId)
    local proto = self._ProtoData
    local data = {}
    for key, _ in pairs(Default) do
        data[key] = proto[key]
    end
    viewModel:UpdateWithData(data)
    return viewModel
end

-- 是否有穿戴在角色身上
function XEquip:IsWearing()
    return self.CharacterId and self.CharacterId > 0
end

function XEquip:CheckCanCharWear(characterId)
    local requireEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
    return XMVCA.XEquip:IsTypeEqual(self.Id, requireEquipType)
end

-- 是否是武器
function XEquip:IsWeapon()
    return XMVCA.XEquip:IsEquipWeapon(self.TemplateId)
end

-- 是否是意识
-- 传site则判断是否是对应位置的意识
function XEquip:IsAwareness(site)
    return XMVCA.XEquip:IsEquipAwareness(self.TemplateId, site)
end

-- 获取装备位置
function XEquip:GetEquipSite()
    return XMVCA.XEquip:GetEquipSite(self.TemplateId)
end

--- 是否是狗粮
function XEquip:IsFood()
    return self:GetType() == XEnumConst.EQUIP.EQUIP_TYPE.FOOD
end

-- 获取品质横图
function XEquip:GetEquipQualityPath()
    if self.WeaponOverrunData and self.WeaponOverrunData.Level > 0 then
        local deregulateUICfg = XMVCA.XEquip:GetConfigWeaponDeregulateUI(self.WeaponOverrunData.Level)
        return deregulateUICfg.IconQuality
    end

    return XMVCA.XEquip:GetEquipQualityPath(self.TemplateId)
end

-- 获取品质横特效
function XEquip:GetEquipQualityEffectPath()
    if self.WeaponOverrunData and self.WeaponOverrunData.Level > 0 then
        local deregulateUICfg = XMVCA.XEquip:GetConfigWeaponDeregulateUI(self.WeaponOverrunData.Level)
        return deregulateUICfg.IconQualityEffect
    end

    return
end

-- 获取品质竖图
function XEquip:GetEquipBgPath()
    if self.WeaponOverrunData and self.WeaponOverrunData.Level > 0 then
        local deregulateUICfg = XMVCA.XEquip:GetConfigWeaponDeregulateUI(self.WeaponOverrunData.Level)
        return deregulateUICfg.ItemsQuality
    end

    return XMVCA.XEquip:GetEquipBgPath(self.TemplateId)
end

-- 获取品质竖特效
function XEquip:GetEquipBgEffectPath()
    if self.WeaponOverrunData and self.WeaponOverrunData.Level > 0 then
        local deregulateUICfg = XMVCA.XEquip:GetConfigWeaponDeregulateUI(self.WeaponOverrunData.Level)
        return deregulateUICfg.ItemsQualityEffect
    end

    return
end

--#region 共鸣
-- 获取共鸣数据表，key为Pos
function XEquip:GetResonanceInfoDic()
    return self:_GetResonanceDic() or {}
end

-- 获取对应位置的共鸣信息
function XEquip:GetResonanceInfo(pos)
    local dic = self:_GetResonanceDic()
    return dic and dic[pos]
end

-- 是否共鸣过
function XEquip:IsResonance()
    local dic = self:_GetResonanceDic()
    return dic ~= nil and next(dic) ~= nil
end

-- 获取共鸣的数量
function XEquip:GetResonanceCount()
    local count = 0
    local dic = self:_GetResonanceDic()
    if dic then
        for _ in pairs(dic) do
            count = count + 1
        end
    end

    return count
end

-- 获取共鸣绑定的角色ID
function XEquip:GetResonanceBindCharacterId(pos)
    local dic = self:_GetResonanceDic()
    local info = dic and dic[pos]
    return info and info.CharacterId or 0
end

-- 共鸣技能是否有绑定角色ID
function XEquip:IsResonanceBindCharacter(characterId)
    local dic = self:_GetResonanceDic()
    if not dic then
        return false
    end

    for _, info in pairs(dic) do
        if info.CharacterId == characterId then
            return true
        end
    end

    return false
end

--- 获取共鸣未确认信息
---@param slot number 共鸣位置
function XEquip:GetResonanceUnConfirmInfo(slot)
    local udic = self:_GetUnconfirmedResonanceDic()
    return udic and udic[slot]
end

-- 是否有未确认的共鸣信息
function XEquip:IsUnconfirmedResonance()
    local udic = self:_GetUnconfirmedResonanceDic()
    return udic ~= nil and next(udic) ~= nil
end

--- 获取共鸣的未确认技能信息
function XEquip:GetResonanceUnConfirmSkillInfo(slot)
    local info = self:GetResonanceUnConfirmInfo(slot)
    if info then
        local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
        return XSkillInfoObj.New(info.Type, info.TemplateId)
    end
end
--#endregion 共鸣

--#region 武器超限
-- 设置超限数据
function XEquip:SetOverrunData(overrunData)
    self._ProtoData.WeaponOverrunData = overrunData
    self.OverrunCanBlindSuit = nil  -- 失效缓存，下次IsOverrunCanBlindSuit()读时再算
end

-- 获取超限等级
function XEquip:GetOverrunLevel()
    return self.WeaponOverrunData and self.WeaponOverrunData.Level or 0
end

-- 获取超限等级名称
---@param characterId number? 角色Id（默认使用 self.CharacterId）
function XEquip:GetOverrunLevelName(characterId)
    local lv = self:GetOverrunLevel()
    if not XTool.IsNumberValidEx(characterId) then
        characterId = XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    end
    if lv == 0 or not XTool.IsNumberValidEx(characterId) then
        return ""
    end
    local overrunCfgIds = XMVCA.XEquip:GetWeaponOverrunCfgIds(self.TemplateId, characterId)
    local overrunCfgId = overrunCfgIds[lv]
    if not XTool.IsNumberValidEx(overrunCfgId) then
        return ""
    end

    local overrunConfig = XMVCA.XEquip:GetWeaponOverrunConfigById(overrunCfgId)
    return overrunConfig.LevelName
end

--- 获取武器超限等级信息
---@param characterId number 角色Id
---@return string levelName     当前等级名称（lv=0 时为 ""）
---@return boolean isShowDot    等级包含 ATTR 类型（需展示进度点）
---@return number reachedDot    已达成的进度点数（仅 UP_SKILL 类型计入）
---@return number totalDot      总进度点数
function XEquip:GetOverrunLevelInfo(characterId)
    if not XTool.IsNumberValidEx(characterId) then
        characterId = XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    end

    local lv = self:GetOverrunLevel()
    local levelName = self:GetOverrunLevelName(characterId)

    local UNLOCK_TYPE = XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE
    local isShowDot = false
    local reachedDot = 0
    local totalDot = 0
    local cfgs = XMVCA.XEquip:GetWeaponOverrunCfgsByTemplateId(self.TemplateId, characterId)
    for _, cfg in pairs(cfgs) do
        if cfg.OverrunType == UNLOCK_TYPE.ATTR or cfg.OverrunType == UNLOCK_TYPE.UP_SKILL then
            isShowDot = true
            totalDot = totalDot + 1
            if lv >= cfg.Level then
                reachedDot = reachedDot + 1
            end
        end
    end
    return levelName, isShowDot, reachedDot, totalDot
end

--- 取超限"展示技能"Id（来源于首个 ATTR 类型配置，按 Level 升序）
---@param characterId number? 角色Id（默认使用 self.CharacterId）
---@return number? ShowOverrunSkillId，无 ATTR 配置时返回 nil
function XEquip:GetOverrunShowSkillId(characterId)
    local attrConfig = self:GetOverrunAttrConfig(characterId)
    return attrConfig and attrConfig.ShowOverrunSkillId or nil
end

function XEquip:GetOverrunAttrConfig(characterId)
    if not XTool.IsNumberValidEx(characterId) then
        characterId = XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    end

    return XMVCA.XEquip:GetWeaponOverrunAttrCfgByTemplateId(self.TemplateId, characterId)
end

function XEquip:IsOverrunAttrUnlock(characterId)
    local attrConfig = self:GetOverrunAttrConfig(characterId)
    if not attrConfig then
        return false
    end

    return self:GetOverrunLevel() >= attrConfig.Level
end

-- 获取超限选择的意识套装
function XEquip:GetOverrunChoseSuit()
    return self.WeaponOverrunData and self.WeaponOverrunData.ChoseSuit or 0
end

-- 获取超限已激活意识列表
function XEquip:GetOverrunActiveSuits()
    return self.WeaponOverrunData and self.WeaponOverrunData.ActiveSuits or {}
end

-- 是否可以超限
function XEquip:CanOverrun()
    return XMVCA.XEquip:CanOverrunByTemplateId(self.TemplateId)
end

-- 是否已经超限
function XEquip:IsOverrun()
    return self:GetOverrunLevel() > 0
end

-- 是否可绑定意识套装（首次访问惰性计算，结果缓存）
function XEquip:IsOverrunCanBlindSuit()
    local v = self.OverrunCanBlindSuit
    if v == nil then
        v = self:CheckCanBlindSuit()
        self.OverrunCanBlindSuit = v
    end
    return v
end

-- 武器超限是否可绑定套装
function XEquip:CheckCanBlindSuit()
    local lv = self:GetOverrunLevel()
    if lv <= 0 then
        return false
    end
    local cfg = XMVCA.XEquip:GetWeaponOverrunSuitCfgByTemplateId(self.TemplateId)
    if not cfg then
        return false
    end

    return lv >= cfg.Level
end

-- 超限绑定的意识是否匹配角色类型
-- 可传 characterId 判断与当前绑定的意识是否匹配
function XEquip:IsOverrunBlindMatch(characterId)
    local choseSuit = self:GetOverrunChoseSuit()
    -- case 1: 未选套装 → 不存在不匹配
    if choseSuit == 0 then
        return true
    end

    -- case 2: 既未穿戴也未指定角色 → 无对照对象，视为匹配
    characterId = characterId or (self:IsWearing() and self.CharacterId or nil)
    if not characterId then
        return true
    end

    -- case 3: 类型比对（ALL 或类型相同则匹配）
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local suitCharType = XMVCA.XEquip:GetSuitCharacterType(choseSuit)
    return suitCharType == XEnumConst.EQUIP.USER_TYPE.ALL or suitCharType == charType
end

-- 超限增加的战力
function XEquip:GetOverrunAbility()
    local lv = self:GetOverrunLevel()
    if lv < 1 then
        return 0
    end

    local ability = 0
    local overrunCfgs = XMVCA.XEquip:GetWeaponOverrunCfgsByTemplateId(self.TemplateId, self.CharacterId)
    for _, overrunCfg in pairs(overrunCfgs) do
        if lv >= overrunCfg.Level then
            if overrunCfg.OverrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT then
                -- 当前绑定的意识需要与角色匹配
                if self:GetOverrunChoseSuit() ~= 0 and self:IsOverrunBlindMatch() then
                    ability = ability + overrunCfg.Ability
                end
            else
                ability = ability + overrunCfg.Ability
            end
        end
    end
    return ability
end

-- 获取超限提升技能等级
---@return number 提升等级
function XEquip:GetOverrunUpSkillLevel(skillGroupId)
    local upLevel = 0
    local lv = self:GetOverrunLevel()
    if lv < 1 then
        return upLevel
    end
    local overrunCfgs = XMVCA.XEquip:GetWeaponOverrunCfgsByTemplateId(self.TemplateId, self.CharacterId)
    for _, overrunCfg in pairs(overrunCfgs) do
        if lv >= overrunCfg.Level and overrunCfg.UpSkillGroupId == skillGroupId then
            upLevel = upLevel + 1
        end
    end
    return upLevel
end

-- 是否显示超限红点
function XEquip:IsShowOverrunRed()
    if not self:CanOverrun() then
        return false
    end

    if not self:IsWearing() then
        return false
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        return false
    end

    return self:IsShowEnterOverrunRed() or self:IsShowEnterOverrun2Red() or self:IsShowOverrunSuitRed()
end

function XEquip:IsShowEnterOverrunRed()
    if self:GetOverrunLevel() >= XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL1 then
        return false
    end

    return XSaveTool.GetData(self:GetEnterOverrunSaveKey()) ~= true
end

function XEquip:IsShowEnterOverrun2Red()
    if self:GetOverrunLevel() >= XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL2 then
        return false
    end

    return self:IsHasOverrunLevel2() and XSaveTool.GetData(self:GetEnterOverrun2SaveKey()) ~= true
end

function XEquip:IsHasOverrunLevel2()
    return XMVCA.XEquip:IsHasOverrunLevel2(self.TemplateId, self.CharacterId)
end

function XEquip:GetEnterOverrunSaveKey()
    return "XUiEquipDetail:GetEnterOverrunSaveKey()  XPlayer.Id" .. tostring(XPlayer.Id)
end

function XEquip:GetEnterOverrun2SaveKey()
    return "XUiEquipDetail:GetEnterOverrun2SaveKey()  XPlayer.Id" .. tostring(XPlayer.Id) .. " EquipId" .. tostring(self.Id)
end

function XEquip:SaveEnterOverrunRedData()
    XSaveTool.SaveData(self:GetEnterOverrunSaveKey(), true)

    if self:IsHasOverrunLevel2() then
        XSaveTool.SaveData(self:GetEnterOverrun2SaveKey(), true)
    end
end

function XEquip:IsShowOverrunSuitRed()
    return self:GetOverrunChoseSuit() == 0 and self:IsOverrunCanBlindSuit()
end
--#endregion 武器超限

--#region Config
--- 获取装备配置表
function XEquip:GetConfig()
    return XMVCA.XEquip:GetConfigEquip(self.TemplateId)
end

--- 获取装备类型
function XEquip:GetType()
    return XMVCA.XEquip:GetEquipType(self.TemplateId)
end

--- 获取装备名称
function XEquip:GetName()
    return XMVCA.XEquip:GetEquipName(self.TemplateId)
end

--- 获取装备部位Id
function XEquip:GetSite()
    return XMVCA.XEquip:GetEquipSite(self.TemplateId)
end

--- 获取装备星级
function XEquip:GetStar()
    return XMVCA.XEquip:GetEquipStar(self.TemplateId)
end

--- 获取装备意识套装Id
function XEquip:GetSuitId()
    return XMVCA.XEquip:GetEquipSuitId(self.TemplateId)
end
--#endregion Config


--- 是否达到最大等级和突破阶段
function XEquip:IsMaxLevelAndBreakthrough()
    local maxBreakthrough, maxLevel =XMVCA.XEquip:GetEquipMaxBreakthrough(self.TemplateId)
    return self.Breakthrough >= maxBreakthrough and self.Level >=maxLevel
end

--- 装备星级是否足够超频
function XEquip:IsStarCanAwake()
    return self:GetStar() >= XEnumConst.EQUIP.SIX_STAR
end

_vtbl = GetClassVirtualTable(XEquip)

return XEquip