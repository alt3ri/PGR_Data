local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

---@class XUiEquipDetailAwarenessPanel : XUiNode
---@field Parent XUiEquipDetailChildV2P6
---@field _Control XEquipControl
local XUiEquipDetailAwarenessPanel = XClass(XUiNode, "XUiEquipDetailAwarenessPanel")

function XUiEquipDetailAwarenessPanel:OnStart()
    self._ResonanceSkillDic = {}

    -- 接管 PanelAdd / PanelAdd2 / PanelExtend 的 UI 初始化
    local parent = self.Parent
    parent.PanelExtend.gameObject:SetActiveEx(false)
    self.PanelAddEffect = parent.PanelAdd.transform:Find("Effect")
    self.PanelAdd2Effect = parent.PanelAdd2.transform:Find("Effect")

    self:SetButtonCallBack()
end

function XUiEquipDetailAwarenessPanel:SetButtonCallBack()
    local parent = self.Parent
    parent:RegisterClickEvent(parent.BtnLeft, function() self:OnBtnLeft() end)
    parent:RegisterClickEvent(parent.BtnRight, function() self:OnBtnRight() end)
    parent:RegisterClickEvent(parent.GridAwarenessResonance1:GetObject("PanelEmptySkill"):GetObject("BtnClick"),
        function() self:OnBtnResonanceSkill(1) end)
    parent:RegisterClickEvent(parent.GridAwarenessResonance2:GetObject("PanelEmptySkill"):GetObject("BtnClick"),
        function() self:OnBtnResonanceSkill(2) end)
    parent:RegisterClickEvent(parent.BtnResonanceEquip1, function() self:OnBtnOverClocking(1) end)
    parent:RegisterClickEvent(parent.BtnResonanceEquip2, function() self:OnBtnOverClocking(2) end)

    parent:RegisterClickEvent(parent.PanelAdd, function() self:ShowPanelExtend() end)
    parent:RegisterClickEvent(parent.PanelAdd2, function() self:ShowPanelSkill() end)

    local btns = {}
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        table.insert(btns, parent["BtnNumber" .. index])
    end
    parent.BtnGridGroup:Init(btns, function(index)
        self:OnClickSwitchAwareness(index)
    end)
end

-- 共鸣槽点击（意识）
function XUiEquipDetailAwarenessPanel:OnBtnResonanceSkill(pos)
    local parent = self.Parent
    if parent.IsPreview then
        return
    end
    XLuaUiManager.Open("UiEquipDetailV2P6", parent.EquipId, nil, parent.CharacterId,
        parent.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
end

function XUiEquipDetailAwarenessPanel:OnEnable()
    local parent = self.Parent
    parent.PanelAdd.gameObject:SetActiveEx(true)
    parent.PanelAdd2.gameObject:SetActiveEx(true)

    -- 折叠/展开动画切到末帧
    local anim = self.IsShowExtend and parent.AnimFold or parent.AnimUnFold
    anim:Play()
    anim.time = anim.duration
    anim:Evaluate()
    anim:Stop()
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
end

function XUiEquipDetailAwarenessPanel:OnDisable()
    self:ReleaseLihuiTimer()
    local parent = self.Parent
    parent.PanelAdd.gameObject:SetActiveEx(false)
    parent.PanelAdd2.gameObject:SetActiveEx(false)
    parent.PanelExtendTitle.gameObject:SetActiveEx(false)
end

function XUiEquipDetailAwarenessPanel:OnRelease()
    self:ReleaseLihuiTimer()
    self._ResonanceSkillDic = nil
end

-- 显示技能面板
function XUiEquipDetailAwarenessPanel:ShowPanelSkill()
    self.IsShowExtend = false
    self.Parent:PlayAnimation("AnimUnFold")
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(true)
end

-- 显示扩展面板
function XUiEquipDetailAwarenessPanel:ShowPanelExtend()
    self.IsShowExtend = true
    self.Parent:PlayAnimation("AnimFold")
    self.PanelAddEffect.gameObject:SetActiveEx(true)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
end

-- 装备切换时由父类调用，更新 SelectAwarenessIndex
function XUiEquipDetailAwarenessPanel:InitOnEquipChanged(equipId, isShowExtend)
    self.SelectAwarenessIndex = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
    if isShowExtend ~= nil then
        self.IsShowExtend = isShowExtend == true
    end
end

-- 刷新意识面板
function XUiEquipDetailAwarenessPanel:Refresh()
    self:UpdateSwitchBtn()
    self:UpdatePainter()
    self:UpdateSuitSkillDesc()
    self:UpdateResonance()
    self:LoadLihui()
    self:UpdateExtendTitle()
end

-- 扩展标题显隐 + 名称
function XUiEquipDetailAwarenessPanel:UpdateExtendTitle()
    local parent = self.Parent
    local isShow = self:IsResonanceActive()
    parent.PanelExtendTitle.gameObject:SetActiveEx(isShow)
    if isShow then
        self:UpdateExtendName()
    end
    if not isShow and self.IsShowExtend then
        self:ShowPanelSkill()
    end
end

-- 刷新扩展按钮名称
function XUiEquipDetailAwarenessPanel:UpdateExtendName()
    local parent = self.Parent
    local nameKey = self:GetExtendNameKey() or "EquipResonanceName"
    local btnName = XUiHelper.GetText(nameKey)
    parent.PanelAdd2:SetName(btnName)
    parent.TxtExtendTitleNormal.text = btnName
end

-- 加载意识立绘
function XUiEquipDetailAwarenessPanel:LoadLihui()
    local parent = self.Parent
    parent.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    local breakthroughTimes = not parent.IsPreview and XMVCA.XEquip:GetEquipBreakthroughTimes(parent.EquipId) or 0
    local resPath = XMVCA.XEquip:GetEquipLiHuiPath(parent.TemplateId, breakthroughTimes)
    -- Loader 是 framework 级资源管理器，必须挂在 XLuaUi（父类）上以匹配其生命周期
    parent.Loader = parent.Loader or parent.Transform:GetLoader()
    local texture = parent.Loader:Load(resPath)
    parent.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)

    self:ReleaseLihuiTimer()
    self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
        parent.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
        self.LihuiTimer = nil
    end, 500)
end

-- 释放立绘定时器
function XUiEquipDetailAwarenessPanel:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipDetailAwarenessPanel:OnBtnLeft()
    self:_StepSwitch(-1)
end

function XUiEquipDetailAwarenessPanel:OnBtnRight()
    self:_StepSwitch(1)
end

-- 步进切换意识位置（step 为 +1/-1）
function XUiEquipDetailAwarenessPanel:_StepSwitch(step)
    local hi = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT
    local i = self.SelectAwarenessIndex + step
    while i >= 1 and i <= hi do
        if self:CheckCanSwitchAwareness(i) then
            self:OnClickSwitchAwareness(i)
            return
        end
        i = i + step
    end
end

-- 点击切换意识
function XUiEquipDetailAwarenessPanel:OnClickSwitchAwareness(index)
    if self.SelectAwarenessIndex == index then
        return
    end

    if not self:CheckCanSwitchAwareness(index) then
        return
    end

    self.SelectAwarenessIndex = index
    local equipId = XMVCA.XEquip:GetCharacterEquipId(self.Parent.CharacterId, index)
    self.Parent:SwitchToEquip(equipId)
end

-- 检查是否可以切换到对应位置的意识
function XUiEquipDetailAwarenessPanel:CheckCanSwitchAwareness(index)
    local equipId = XMVCA.XEquip:GetCharacterEquipId(self.Parent.CharacterId, index)
    return equipId ~= nil
end

-- 刷新意识切换按钮
function XUiEquipDetailAwarenessPanel:UpdateSwitchBtn()
    local parent = self.Parent
    local isShow = parent.CharacterId
        and (XMVCA.XEquip:GetCharacterAwarenessCnt(parent.CharacterId) > 1)
        and XMVCA.XEquip:IsEquipWearingByCharacterId(parent.EquipId, parent.CharacterId)

    parent.PanelTab.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    local canLast = false
    local canNext = false
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            if index < self.SelectAwarenessIndex then
                canLast = true
            end
            if index > self.SelectAwarenessIndex then
                canNext = true
            end

            local state = index == self.SelectAwarenessIndex and CS.UiButtonState.Select or CS.UiButtonState.Normal
            parent["BtnNumber" .. index]:SetButtonState(state)
        else
            parent["BtnNumber" .. index]:SetButtonState(CS.UiButtonState.Disable)
        end
    end

    parent.BtnLeft.gameObject:SetActiveEx(canLast)
    parent.BtnRight.gameObject:SetActiveEx(canNext)
end

-- 刷新画师
function XUiEquipDetailAwarenessPanel:UpdatePainter()
    local parent = self.Parent
    local breakthroughTimes = parent.IsPreview and 0 or XMVCA.XEquip:GetEquipBreakthroughTimes(parent.EquipId)
    parent.TxtPainter.text = XMVCA.XEquip:GetEquipPainterName(parent.TemplateId, breakthroughTimes)
    parent.PanelPainter.gameObject:SetActiveEx(true)
end

-- 刷新意识套装技能详情
function XUiEquipDetailAwarenessPanel:UpdateSuitSkillDesc()
    local parent = self.Parent
    local suitId = XMVCA.XEquip:GetEquipSuitId(parent.TemplateId)
    local skillDesList = XMVCA.XEquip:GetEquipSuitSkillDescription(suitId)

    -- 套装索引 2/4/6 对应 2件/4件/6件激活效果
    local noSuitSkill = true
    for i = 1, XEnumConst.EQUIP.SUIT_MAX_SKILL_COUNT do
        local pieceCount = i * 2
        if skillDesList[pieceCount] then
            parent["TxtSkillDes" .. i].text = skillDesList[pieceCount]
            parent["TxtPos" .. i].text = XUiHelper.GetText("EquipSuitSkillPrefix" .. pieceCount)
            parent["TxtSkillDes" .. i].gameObject:SetActiveEx(true)
            noSuitSkill = false
        else
            parent["TxtSkillDes" .. i].gameObject:SetActiveEx(false)
        end
    end

    parent.PanelAwarenessSkillDes.gameObject:SetActiveEx(not noSuitSkill)
    parent.PanelNoAwarenessSkill.gameObject:SetActiveEx(noSuitSkill)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(parent.PanelAwarenessSkillDes:FindTransform("PaneContent"))
end

-- 刷新意识共鸣
function XUiEquipDetailAwarenessPanel:UpdateResonance()
    local parent = self.Parent
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(parent.TemplateId)
        or (parent.OpenUiType and parent.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI)
    parent.PanelAwarenessResonance.gameObject:SetActiveEx(canResonance)
    if not canResonance then
        return
    end

    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self:UpdateResonanceSkill(pos)
    end

    self.CanAwake = XMVCA.XEquip:CheckEquipStarCanAwake(parent.EquipId)
    parent.BtnResonanceEquip1.gameObject:SetActiveEx(self.CanAwake)
    parent.BtnResonanceEquip2.gameObject:SetActiveEx(self.CanAwake)
end

-- 刷新单个意识共鸣
function XUiEquipDetailAwarenessPanel:UpdateResonanceSkill(pos)
    local parent = self.Parent
    local isEquip = not parent.IsPreview and XMVCA.XEquip:CheckEquipPosResonanced(parent.EquipId, pos) ~= nil
    local uiObj = parent["GridAwarenessResonance" .. pos]
    local skillGo = uiObj:GetObject("GridResonanceSkill")
    skillGo.gameObject:SetActiveEx(isEquip)
    uiObj:GetObject("PanelEmptySkill").gameObject:SetActiveEx(not isEquip)

    if isEquip then
        local grid = self._ResonanceSkillDic[pos]
        if not grid then
            grid = XUiGridResonanceSkill.New(skillGo, parent.EquipId, pos, parent.CharacterId, function()
                self:OnBtnResonanceSkill(pos)
            end, nil, parent.ForceShowBindCharacter, true)
            self._ResonanceSkillDic[pos] = grid
        end
        grid:SetEquipIdAndPos(parent.EquipId, pos)
        grid:Refresh()
    end
end

-- 超频按钮点击
function XUiEquipDetailAwarenessPanel:OnBtnOverClocking(pos)
    local parent = self.Parent
    if parent.IsPreview then
        return
    end

    local canAwake = false
    for i = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        if XMVCA.XEquip:CheckEquipCanAwake(parent.EquipId, i) then
            canAwake = true
            break
        end
    end
    if not canAwake then
        XUiManager.TipText("SuperAwareness")
        return
    end

    -- 默认跳转到对应位置超频界面
    local posCanAwake = XMVCA.XEquip:CheckEquipCanAwake(parent.EquipId, pos)
    local isAwake = XMVCA.XEquip:IsEquipPosAwaken(parent.EquipId, pos)
    if isAwake or not posCanAwake then
        pos = nil
    end
    XLuaUiManager.Open("UiEquipDetailV2P6", parent.EquipId, nil, parent.CharacterId,
        parent.ForceShowBindCharacter, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING, nil, pos)
end

-- 处理选中装备事件
function XUiEquipDetailAwarenessPanel:OnEquipSelected(equipId)
    local parent = self.Parent
    if equipId == parent.EquipId then return end

    local equips = parent._Control:GetCharacterWearingAwarenesss(parent.CharacterId)
    for _, equip in ipairs(equips) do
        if equip.Id == equipId then
            local site = equip:GetEquipSite()
            self:OnClickSwitchAwareness(site)
            return
        end
    end
end

-- 扩展按钮名称 key
function XUiEquipDetailAwarenessPanel:GetExtendNameKey()
    return self.CanAwake and "EquipAwarenessBtnName" or nil
end

-- 意识共鸣区是否可见
function XUiEquipDetailAwarenessPanel:IsResonanceActive()
    return self.Parent.PanelAwarenessResonance.gameObject.activeSelf
end

return XUiEquipDetailAwarenessPanel
