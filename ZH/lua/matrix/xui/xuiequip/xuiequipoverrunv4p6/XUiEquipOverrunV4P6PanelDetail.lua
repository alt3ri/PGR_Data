local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiEquipOverrunV4P6PanelDetail : XUiNode
---@field _Control XEquipControl
---@field Parent XUiEquipOverrunV4P6
---@field BtnLeft CS.XUIButton
---@field BtnRight CS.XUIButton
---@field BtnPreview CS.XUIButton
---@field BtnSuitUnChoice CS.XUIButton
---@field BtnSuitChoice CS.XUIButton
---@field BtnOverrun CS.XUIButton
---@field PanelLevel UnityEngine.GameObject
---@field PanelDot UnityEngine.GameObject
---@field PanelSuit UnityEngine.GameObject
---@field PanelSuitLock UnityEngine.GameObject
---@field PanelSkill UnityEngine.GameObject
---@field PanelCost UnityEngine.GameObject
---@field ImgBgLevelOn UnityEngine.GameObject
---@field ImgBgLevelOff UnityEngine.GameObject
---@field ImgBgDotOn UnityEngine.GameObject
---@field ImgBgDotOff UnityEngine.GameObject
---@field ImgSkill UnityEngine.UI.Image
---@field ImgSkillUp UnityEngine.GameObject
---@field ImgCharacter UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtLevel UnityEngine.UI.Text
---@field TxtSuitDesc UnityEngine.UI.Text
---@field TxtAwarenessName UnityEngine.UI.Text
---@field TxtSkillTitle UnityEngine.UI.Text
---@field TxtSkillDesc UnityEngine.UI.Text
---@field TxtSkillName UnityEngine.UI.Text
---@field TxtActivate UnityEngine.GameObject
---@field TxtUnableActivate UnityEngine.UI.Text
---@field RImgAwareness CS.XUiRawImage
---@field GridCostItem UnityEngine.RectTransform
local XUiEquipOverrunV4P6PanelDetail = XClass(XUiNode, "UiEquipOverrunV4P6PanelDetail")

function XUiEquipOverrunV4P6PanelDetail:OnStart()
    self.EquipId = self.Parent.EquipId
    self.Equip = self.Parent.Equip
    self:InitComponents()
end

function XUiEquipOverrunV4P6PanelDetail:OnEnable()
    self:Refresh()
end

function XUiEquipOverrunV4P6PanelDetail:OnDisable()
    self:ReleaseTimer()
end

function XUiEquipOverrunV4P6PanelDetail:InitComponents()
    self.BtnLeft:AddEventListener(function() self:OnBtnLeftClick() end)         
    self.BtnRight:AddEventListener(function() self:OnBtnRightClick() end)
    self.BtnPreview:AddEventListener(function() self:OnBtnPreviewClick() end)
    self.BtnSuitUnChoice:AddEventListener(function() self:OnClickChangeBind() end)
    self.BtnSuitChoice:AddEventListener(function() self:OnClickChangeBind() end)
    self.BtnOverrun:AddEventListener(function() self:OnBtnOverrunClick() end)
end

function XUiEquipOverrunV4P6PanelDetail:OnBtnLeftClick()
    local selectIndex = self.Parent:GetSelectIndex()
    if selectIndex > 1 then
        self.Parent:OnClickGridOverrun(selectIndex - 1)
    end
end

function XUiEquipOverrunV4P6PanelDetail:OnBtnRightClick()
    local selectIndex = self.Parent:GetSelectIndex()
    local gridOverrunCount = self.Parent:GetGridOverrunCount()
    if selectIndex < gridOverrunCount then
        self.Parent:OnClickGridOverrun(selectIndex + 1)
    end
end

function XUiEquipOverrunV4P6PanelDetail:OnBtnPreviewClick()
    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, nil, true)
end

function XUiEquipOverrunV4P6PanelDetail:OnClickChangeBind()
    if not self.Equip:IsOverrunCanBlindSuit() then
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.EquipId, function()
        self.Parent:Refresh()
    end)
end

function XUiEquipOverrunV4P6PanelDetail:OnBtnOverrunClick()
    if not self.CanLevelUp then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    -- 二次确认
    local equipName = XMVCA.XEquip:GetEquipName(self.Equip.TemplateId)
    local content = XUiHelper.GetText("EquipOverrunLevelUpTips", equipName)
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XEquip:EquipWeaponOverrunLevelUpRequest(self.EquipId, function()
            self:OnOverrunLevelUpSuccess()
        end)
    end)
end

-- 谐振升级成功
function XUiEquipOverrunV4P6PanelDetail:OnOverrunLevelUpSuccess()
    -- 播放升级特效和页签蓝点
    self.Parent.ParentUi:PlayOverrunLevelUpEffect()
    self.Parent.ParentUi:UpdateBtnOverrunRed()
    -- 整体刷新（含详情面板、谐振格、进度）
    self.Parent:Refresh()

    -- 延迟刷新场景特效 + 升级弹窗
    local level = self.Equip:GetOverrunLevel()
    local equipId = self.EquipId
    local waitTime = self._Control:GetWeaponDeregulateUISceneStartEffectTime(level) or 0
    XLuaUiManager.SetMask(true)
    self:ReleaseTimer()
    self.LevelRefreshTimer = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        self.LevelRefreshTimer = nil
        self.Parent.ParentUi:UpdateOverrunSceneEffect()

        -- 弹窗
        XLuaUiManager.Open("UiEquipOverrunLevel", equipId, level, self.Parent.ParentUi.CharacterId)
    end , waitTime)
end

function XUiEquipOverrunV4P6PanelDetail:ReleaseTimer()
    if self.LevelRefreshTimer then
        XScheduleManager.UnSchedule(self.LevelRefreshTimer)
        self.LevelRefreshTimer = nil
    end
end

function XUiEquipOverrunV4P6PanelDetail:Refresh()
    local selectOverrunCfgId = self.Parent:GetSelectOverrunCfgId()
    local overrunConfig = self._Control:GetWeaponOverrunConfigById(selectOverrunCfgId)
    local lv = self.Equip:GetOverrunLevel()
    self:RefreshTitle(overrunConfig, lv)
    self:RefreshPanelSuit(overrunConfig)
    self:RefreshPanelSkill(overrunConfig)
    self:RefreshCost(overrunConfig, lv)
    self:RefreshSwitchBtn()
end

-- 刷新标题
function XUiEquipOverrunV4P6PanelDetail:RefreshTitle(overrunConfig, lv)
    local isActive = lv >= overrunConfig.Level
    local isLevelStyle = overrunConfig.OverrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT or overrunConfig.OverrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.ATTR

    -- 等级样式 / 点样式 二选一
    self.PanelLevel.gameObject:SetActiveEx(isLevelStyle)
    self.PanelDot.gameObject:SetActiveEx(not isLevelStyle)

    if isLevelStyle then
        self.ImgBgLevelOn.gameObject:SetActiveEx(isActive)
        self.ImgBgLevelOff.gameObject:SetActiveEx(not isActive)
        self.TxtLevel.text = overrunConfig.Level
        self.UiTxtLevelImg1.gameObject:SetActiveEx(overrunConfig.Level == XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL1)
        self.UiTxtLevelImg2.gameObject:SetActiveEx(overrunConfig.Level == XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL2)
    else
        self.ImgBgDotOn.gameObject:SetActiveEx(isActive)
        self.ImgBgDotOff.gameObject:SetActiveEx(not isActive)
    end

    -- 等级名称
    self.TxtTitle.text = overrunConfig.Name
end

-- 刷新套装属性
function XUiEquipOverrunV4P6PanelDetail:RefreshPanelSuit(overrunConfig)
    local isShowSuit = overrunConfig.OverrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.SUIT
    self.PanelSuit.gameObject:SetActiveEx(isShowSuit)
    if not isShowSuit then return end

    -- 描述
    self.TxtSuitDesc.text = overrunConfig.Desc

    local canBind = self.Equip:IsOverrunCanBlindSuit()
    local choseSuit = canBind and self.Equip:GetOverrunChoseSuit() or 0

    -- 三态：未解锁 / 解锁未绑定 / 解锁已绑定
    self.PanelSuitLock.gameObject:SetActiveEx(not canBind)
    self.BtnSuitUnChoice.gameObject:SetActiveEx(canBind and choseSuit == 0)
    self.BtnSuitChoice.gameObject:SetActiveEx(canBind and choseSuit ~= 0)

    if canBind and choseSuit ~= 0 then
        self:RefreshSuitChoiceBtn(choseSuit)
    end
end

-- 刷新已绑定套装按钮
function XUiEquipOverrunV4P6PanelDetail:RefreshSuitChoiceBtn(choseSuit)
    -- 套装名称
    self.TxtAwarenessName.text = XMVCA.XEquip:GetSuitName(choseSuit)

    -- 套装大图
    local bigIconPath = XMVCA.XEquip:GetEquipSuitWaferBagPath(choseSuit)
    self.RImgAwareness:SetRawImage(bigIconPath)

    -- 不匹配标签
    local isMatch = self.Equip:IsOverrunBlindMatch(self.Parent.ParentUi.CharacterId)
    self.BtnSuitChoice:ShowTag(not isMatch)
end

-- 刷新技能面板
function XUiEquipOverrunV4P6PanelDetail:RefreshPanelSkill(overrunConfig)
    local overrunType = overrunConfig.OverrunType
    local isAttr = overrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.ATTR
    local isUpSkill = overrunType == XEnumConst.EQUIP.WEAPON_OVERRUN_UNLOCK_TYPE.UP_SKILL
    local isShowSkill = isAttr or isUpSkill
    self.PanelSkill.gameObject:SetActiveEx(isShowSkill)
    if not isShowSkill then return end

    -- 谐振等级名称和描述
    self.TxtSkillTitle.text = isUpSkill and CS.XTextManager.GetText("EquipOverrunSkillTitleUnlock") or CS.XTextManager.GetText("EquipOverrunSkillTitleStrength")
    -- 技能图标
    if isUpSkill then
        local character = XMVCA.XCharacter:GetCharacter(overrunConfig.CharacterId)
        local skillId = character:GetGroupCurSkillId(overrunConfig.UpSkillGroupId)
        local skillLevel = character:GetSkillLevel(overrunConfig.UpSkillGroupId)
        local skillDetailCfg = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
        self.ImgSkill:SetSprite(skillDetailCfg.Icon)
        self.TxtSkillName.text = skillDetailCfg.Name
        self.TxtSkillDesc.text = overrunConfig.Desc
    else
        local skillCfg = XMVCA.XEquip:GetWeaponOverrunSkillConfigById(overrunConfig.ShowOverrunSkillId)
        self.ImgSkill:SetSprite(skillCfg.Icon)
        self.TxtSkillName.text = skillCfg.Name
        self.TxtSkillDesc.text = skillCfg.Desc
    end
    self.ImgSkillUp.gameObject:SetActiveEx(isUpSkill)

    -- 角色图标
    local characterIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(overrunConfig.CharacterId)
    self.ImgCharacter:SetSprite(characterIcon)
end

-- 刷新升级消耗
function XUiEquipOverrunV4P6PanelDetail:RefreshCost(overrunConfig, lv)
    local isActive = lv >= overrunConfig.Level
    local isNextActive = lv + 1 == overrunConfig.Level
    local isShowCost = not isActive and isNextActive
    self.CanLevelUp = isShowCost

    self.PanelTxtActivate.gameObject:SetActiveEx(isActive)
    self.PanelTxtUnableActivate.gameObject:SetActiveEx(not isActive and not isNextActive)
    if not isActive and not isNextActive then
        local tips = CS.XTextManager.GetText("EquipOverrunUnlockBeforeSkillTips")
        local lastOverrunCfgId = self.Parent:GetOverrunCfgIdByLevel(overrunConfig.Level - 1)
        local lastOverrunCfg = self._Control:GetWeaponOverrunConfigById(lastOverrunCfgId)
        self.TxtUnableActivate.text = string.format(tips, lastOverrunCfg.Name)
    end

    self.PanelCost.gameObject:SetActiveEx(isShowCost)
    self.BtnOverrun.gameObject:SetActiveEx(isShowCost)

    if not isShowCost then return end
    self.CostGridList = self.CostGridList or {}
    local itemIds = overrunConfig.ConsumeItemIds
    local itemCounts = overrunConfig.ConsumeItemCounts
    XUiHelper.RefreshCustomizedList(self.GridCostItem.transform.parent, self.GridCostItem, #itemIds, function(index, child)
        local grid = self.CostGridList[index]
        if not grid then
            grid = XUiGridCommon.New(self, child)
            self.CostGridList[index] = grid
        end
        local count = XDataCenter.ItemManager.GetCount(itemIds[index])
        if count < itemCounts[index] then
            self.CanLevelUp = false 
        end
        grid:Refresh({ TemplateId = itemIds[index], CostCount = itemCounts[index], Count = count })
    end)

    self.BtnOverrun:SetDisable(not self.CanLevelUp)
end

function XUiEquipOverrunV4P6PanelDetail:RefreshSwitchBtn()
    local selectIndex = self.Parent:GetSelectIndex()
    local gridOverrunCount = self.Parent:GetGridOverrunCount()
    self.BtnLeft:SetDisable(selectIndex == 1)
    self.BtnRight:SetDisable(selectIndex == gridOverrunCount)
end

return XUiEquipOverrunV4P6PanelDetail
