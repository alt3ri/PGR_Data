local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local BUTTON_STATE_LIST = { "Normal", "Press" }

---@class XUiEquipDetailWeaponPanel : XUiNode
---@field Parent XUiEquipDetailChildV2P6
---@field _Control XEquipControl
local XUiEquipDetailWeaponPanel = XClass(XUiNode, "XUiEquipDetailWeaponPanel")

function XUiEquipDetailWeaponPanel:OnStart()
    self._ResonanceSkillDic = {}
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local effect = self["GridEquipResonance" .. pos]:GetObject("Effect")
        self["GridEquipResonanceEffect" .. pos] = effect
        effect.gameObject:SetActiveEx(false)
    end
    self.OverrunBlindEffect = self.BtnOverrunBlind.transform:Find("Normal/Effect")

    self:SetButtonCallBack()
end

function XUiEquipDetailWeaponPanel:SetButtonCallBack()
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local btn = self["GridEquipResonance" .. pos]
        self.Parent:RegisterClickEvent(btn, function() self:OnBtnResonanceSkill(pos) end)
    end
    self.Parent:RegisterClickEvent(self.BtnResonance, function() self:OnBtnResonanceSkill() end)

    self.Parent:RegisterClickEvent(self.BtnOverrunNoLevel, function() self:OnBtnOverrun() end)
    self.Parent:RegisterClickEvent(self.BtnOverrunLevel, function() self:OnBtnOverrun() end)
    self.Parent:RegisterClickEvent(self.BtnOverrunBlind, function() self:OnBtnOverrunClick() end)
    self.Parent:RegisterClickEvent(self.BtnOverrunEmpty, function() self:OnBtnOverrunClick() end)
end

-- 共鸣槽点击（武器）
function XUiEquipDetailWeaponPanel:OnBtnResonanceSkill(pos)
    local parent = self.Parent
    if parent.IsPreview then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(parent.EquipId)
    local star = XMVCA.XEquip:GetEquipQuality(equip.TemplateId)
    local characterId = parent.CharacterId or equip.CharacterId

    -- 选中位置与当前角色绑定时跳替换界面
    if pos and equip:GetResonanceBindCharacterId(pos) == characterId and characterId and characterId ~= 0 then
        XLuaUiManager.Open("UiEquipResonanceSkillChangeV2P6", characterId, parent.EquipId)

    -- 5星武器只能共鸣一次
    elseif equip:GetResonanceInfo(pos) and star == XEnumConst.EQUIP.FIVE_STAR then
        XLuaUiManager.Open("UiEquipDetailV2P6", parent.EquipId, nil, parent.CharacterId, parent.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    else
        XLuaUiManager.Open("UiEquipDetailV2P6", parent.EquipId, nil, parent.CharacterId, parent.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
    end
end

-- 超限按钮（跳转详情超限页）
function XUiEquipDetailWeaponPanel:OnBtnOverrun()
    local parent = self.Parent
    if parent.IsPreview then
        return
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
        XUiManager.TipError(tips)
        return
    end

    XLuaUiManager.Open("UiEquipDetailV2P6", parent.EquipId, nil, parent.CharacterId, parent.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN)
end

-- 超限套装选择
function XUiEquipDetailWeaponPanel:OnBtnOverrunClick()
    if self.OverrunIconTips then
        XUiManager.TipError(self.OverrunIconTips)
        return
    end

    local parent = self.Parent
    XLuaUiManager.Open("UiEquipOverrunSelect", parent.EquipId, function()
        self:UpdateOverrun()
        self:SetOverrunBlindEffectActive(true)
    end)
end

-- 刷新武器面板
function XUiEquipDetailWeaponPanel:Refresh()
    self:LoadWeaponModel()
    self:UpdateEquipSkillDesc()
    self:UpdateEquipResonance()
    self:UpdateOverrun()
    self:UpdateOverrunSceneEffect()
end

-- 刷新技能详情
function XUiEquipDetailWeaponPanel:UpdateEquipSkillDesc()
    local weaponSkillInfo = XMVCA.XEquip:GetEquipWeaponSkillInfo(self.Parent.TemplateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新装备共鸣
function XUiEquipDetailWeaponPanel:UpdateEquipResonance()
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(self.Parent.TemplateId)
        or (self.Parent.OpenUiType and self.Parent.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI)
    self.PaneEquipResonance.gameObject:SetActive(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        self:UpdateEquipResonanceSkill(pos)
    end
end

-- 刷新单个装备共鸣
function XUiEquipDetailWeaponPanel:UpdateEquipResonanceSkill(pos)
    local parent = self.Parent
    local isEquip = not parent.IsPreview and XMVCA.XEquip:CheckEquipPosResonanced(parent.EquipId, pos) ~= nil
    local uiObj = self["GridEquipResonance" .. pos]
    uiObj:GetComponent("XUiButton"):SetDisable(not isEquip)
    self["GridEquipResonanceEffect" .. pos].gameObject:SetActiveEx(false)
    if isEquip then
        -- 按钮每个状态对应创建一个XUiGridResonanceSkill
        if not self._ResonanceSkillDic[pos] then
            self._ResonanceSkillDic[pos] = {}
            for _, stateName in ipairs(BUTTON_STATE_LIST) do
                local stateGo = uiObj:GetObject(stateName)
                self._ResonanceSkillDic[pos][stateName] = XUiGridResonanceSkill.New(stateGo, parent.EquipId, pos, parent.CharacterId, function()
                    self:OnBtnResonanceSkill(pos)
                end, nil, parent.ForceShowBindCharacter, true)
            end
        end

        -- 刷新所有状态的XUiGridResonanceSkill
        for _, stateName in ipairs(BUTTON_STATE_LIST) do
            local grid = self._ResonanceSkillDic[pos][stateName]
            grid:SetEquipIdAndPos(parent.EquipId, pos)
            grid:Refresh()
        end
    end
end

-- 刷新武器超限
function XUiEquipDetailWeaponPanel:UpdateOverrun()
    self.OverrunIconTips = nil
    local equip = XMVCA.XEquip:GetEquip(self.Parent.EquipId)

    -- 不可谐振，直接隐藏
    local canOverrun = equip and equip:CanOverrun() or false
    self.PanelOverrun.gameObject:SetActiveEx(canOverrun)
    if not canOverrun then
        return
    end

    self:_RefreshOverrunLevelBtn(equip)
    self:_RefreshOverrunSuitBtn(equip)
    self:_RefreshOverrunSkillBtn(equip)
end

-- 刷新谐振等级按钮
---@param equip XEquip
function XUiEquipDetailWeaponPanel:_RefreshOverrunLevelBtn(equip)
    local lv = equip:GetOverrunLevel()
    local isLevel = lv > 0
    self.BtnOverrunNoLevel.gameObject:SetActiveEx(not isLevel)
    self.BtnOverrunLevel.gameObject:SetActiveEx(isLevel)
    self.BtnOverrunLevel:ShowReddot(equip:IsShowOverrunRed())
    if not isLevel then
        return
    end

    local levelName, showDot, reachedDot, totalDot = equip:GetOverrunLevelInfo(self.Parent.CharacterId)
    local isLv1 = lv == XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL1
    local isLvGe2 = lv >= XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL2
    for _, stateName in ipairs(BUTTON_STATE_LIST) do
        local stateObj = self.BtnOverrunLevelUiObj:GetObject(stateName)
        stateObj:GetObject("UiTxtLevel").text = levelName
        stateObj:GetObject("UiTxtLevelImg1").gameObject:SetActiveEx(isLv1)
        stateObj:GetObject("UiTxtLevelImg2").gameObject:SetActiveEx(isLvGe2)
        stateObj:GetObject("PanelDotGroup").gameObject:SetActiveEx(showDot)
        if showDot then
            for i = 1, totalDot - 1 do
                local dotGo = stateObj:GetObject("PanelDot" .. i)
                local isOn = reachedDot - 1 >= i
                dotGo.transform:Find("ImgBgLevelOn").gameObject:SetActiveEx(isOn)
                dotGo.transform:Find("ImgBgLevelOff").gameObject:SetActiveEx(not isOn)
            end
        end
    end
end

-- 刷新意识套装按钮
---@param equip XEquip
function XUiEquipDetailWeaponPanel:_RefreshOverrunSuitBtn(equip)
    self.BtnOverrunBlind.gameObject:SetActiveEx(false)
    self.BtnOverrunEmpty.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)

    local progress = equip:GetOverrunLevel() > 0 and "1/1" or "0/1"

    -- 未解锁
    if not equip:IsOverrunCanBlindSuit() then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(true)
        self.BtnOverrunBlind:SetName(progress)
        self.OverrunIconTips = XUiHelper.GetText("EquipOverrunClickTips")
        return
    end

    -- 解锁未绑定
    local choseSuitId = equip:GetOverrunChoseSuit()
    if choseSuitId == 0 then
        self.BtnOverrunEmpty.gameObject:SetActiveEx(true)
        self.BtnOverrunEmpty:SetName(progress)
        return
    end

    -- 解锁并且有绑定
    self.BtnOverrunBlind.gameObject:SetActiveEx(true)
    self.BtnOverrunBlind:SetDisable(false)
    self.BtnOverrunBlind:SetName(progress)
    local iconPath = XMVCA.XEquip:GetEquipSuitIconPath(choseSuitId)
    local isMatch = equip:IsOverrunBlindMatch(self.Parent.CharacterId)
    local uiObj = self.BtnOverrunBlind:GetComponent("UiObject")
    for _, stateName in ipairs(BUTTON_STATE_LIST) do
        local stateObj = uiObj:GetObject(stateName)
        stateObj:GetObject("RImgSuit"):SetRawImage(iconPath)
        stateObj:GetObject("ImgNotMatching").gameObject:SetActiveEx(not isMatch)
    end
end

-- 刷新谐振被动技能按钮
---@param equip XEquip
function XUiEquipDetailWeaponPanel:_RefreshOverrunSkillBtn(equip)
    -- 1. 取 ATTR 类型对应的展示技能 Id
    local showSkillId = equip:GetOverrunShowSkillId(self.Parent.CharacterId)
    self.BtnOverrunSkill.gameObject:SetActiveEx(showSkillId ~= nil)
    if not showSkillId then
        return
    end

    -- 2. 技能图标
    local skillCfg = XMVCA.XEquip:GetWeaponOverrunSkillConfigById(showSkillId)
    local iconPath = skillCfg.Icon

    -- 3. 进度
    local _, _, reachedDot, totalDot = equip:GetOverrunLevelInfo(self.Parent.CharacterId)
    local isFull = reachedDot >= totalDot
    self.BtnOverrunSkill:SetDisable(reachedDot == 0)

    -- 4. 遍历 Normal/Press 子节点
    for _, stateName in ipairs(BUTTON_STATE_LIST) do
        local stateObj = self.BtnOverrunSkillUiObj:GetObject(stateName)
        stateObj:GetObject("RImgSuit"):SetRawImage(iconPath)
        stateObj:GetObject("PanelFull").gameObject:SetActiveEx(isFull)
        stateObj:GetObject("PanelNotFull").gameObject:SetActiveEx(not isFull)
    end

    -- 5. 进度文本
    self.BtnOverrunSkill:SetName(reachedDot .. "/" .. totalDot)
end

-- 设置指定位置的共鸣特效显隐
function XUiEquipDetailWeaponPanel:SetResonanceEffectActive(pos, active)
    local node = self["GridEquipResonanceEffect" .. pos]
    if node then
        node.gameObject:SetActiveEx(active)
    end
end

-- 设置超限 blind 特效显隐
function XUiEquipDetailWeaponPanel:SetOverrunBlindEffectActive(active)
    if self.OverrunBlindEffect then
        self.OverrunBlindEffect.gameObject:SetActiveEx(active)
    end
end

-- 刷新超限场景特效
function XUiEquipDetailWeaponPanel:UpdateOverrunSceneEffect()
    local imgEffectOverrun = self.Parent.ImgEffectOverrun
    imgEffectOverrun.gameObject:SetActiveEx(false)
    if self.Parent.IsPreview then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.Parent.EquipId)
    local level = equip and equip:GetOverrunLevel() or 0
    if level < 1 then
        return
    end

    imgEffectOverrun.gameObject:SetActiveEx(true)
    local sceneLoopEffectPath = self.Parent._Control:GetWeaponDeregulateUISceneLoopEffectPath(level)
    if sceneLoopEffectPath then
        imgEffectOverrun:LoadPrefab(sceneLoopEffectPath)
    end
end

-- 加载武器模型
function XUiEquipDetailWeaponPanel:LoadWeaponModel()
    local parent = self.Parent
    parent.ScenePanelWeapon.gameObject:SetActiveEx(true)
    local breakthroughTimes = not parent.IsPreview and XMVCA.XEquip:GetEquipBreakthroughTimes(parent.EquipId) or 0
    local resonanceCount = not parent.IsPreview and XMVCA.XEquip:GetEquipResonanceCount(parent.EquipId) or 0
    local modelTransformName = "UiEquipDetail"
    local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(parent.TemplateId, modelTransformName, breakthroughTimes, resonanceCount)
    if modelConfig then
        XModelManager.LoadWeaponModel(
            modelConfig.ModelId,
            parent.ScenePanelWeapon,
            modelConfig.TransformConfig,
            modelTransformName,
            nil,
            { gameObject = parent.GameObject, usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW, IsDragRotation = true, AntiClockwise = true },
            parent.PanelDrag
        )
    end
end

function XUiEquipDetailWeaponPanel:OnRelease()
    -- 武器路径下隐藏了场景 Plane，由本面板对称恢复
    local plane = self.Parent and self.Parent.ScenePanelWeaponPlane
    if plane then
        plane.gameObject:SetActiveEx(true)
    end
end

return XUiEquipDetailWeaponPanel
