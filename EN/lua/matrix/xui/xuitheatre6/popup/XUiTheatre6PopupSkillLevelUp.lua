---@class XUiTheatre6PopupSkillLevelUp : XLuaUi
---@field _Control XTheatre6Control
---@field TxtName UnityEngine.UI.Text
---@field BtnTanchuangCloseWhite XUiComponent.XUiButton
---@field ListSkillUsing UnityEngine.RectTransform
---@field GridSkillUsing UiObject
---@field UiTxtLeft UnityEngine.UI.Text
---@field ListSkillBag UnityEngine.RectTransform
---@field GridSkillBag UiObject
---@field PanelDetail UiObject
---@field BtnLevelUp XUiComponent.XUiButton
local XUiTheatre6PopupSkillLevelUp = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupSkillLevelUp")
local XUiPanelTheatre6SkilBagDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6SkilBagDetail")
local XUiGridTheatre6Skill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill")
function XUiTheatre6PopupSkillLevelUp:OnAwake()
    self:InitComponents()
end

---@param levelUpCount number 升级次数
---@param levelUpLevel number 本次请求后升级的级数 无则默认1级
---@param levelUpLimit number 升级等级限制 无则不限制
---@param levelUpQuality number 升级品质限制 无则不限制
function XUiTheatre6PopupSkillLevelUp:OnStart(buffId, levelUpCount, levelUpLevel, levelUpLimit, levelUpQuality)
    self.BuffId = buffId
    self._LevelUpCount = 0
    self.LevelUpCount = levelUpCount
    self.LevelUpLevel = levelUpLevel or 0
    self.LevelUpLimit = levelUpLimit or 0
    self.LevelUpQuality = levelUpQuality or 0
    self.TxtNumRight.text = "/" .. self.LevelUpCount
end

function XUiTheatre6PopupSkillLevelUp:OnEnable()
    self._SkillId = self._SkillId or self:GetDefaultSkill()
    self:Refresh(self._SkillId)
end

function XUiTheatre6PopupSkillLevelUp:GetSlotOrder()
    local SlotType = XEnumConst.Theatre6.SlotType
    return { SlotType.Active, SlotType.Insert, SlotType.Special, SlotType.Bag }
end

function XUiTheatre6PopupSkillLevelUp:GetSkillIdsBySlot(slotType)
    return slotType == XEnumConst.Theatre6.SlotType.Bag
        and self._Control:GetCharacterSkillBagIds()
        or self._Control:GetCharacterDressSkillIds(slotType)
end

function XUiTheatre6PopupSkillLevelUp:FindSkillSlot(skillId)
    for _, slotType in ipairs(self:GetSlotOrder()) do
        local ids = self:GetSkillIdsBySlot(slotType)
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            local id = ids and ids[index]
            if id == skillId then return slotType, index end
        end
    end
end

function XUiTheatre6PopupSkillLevelUp:FindLatestSkillByKey(skillKey, preferSlotType, preferPos)
    if not skillKey then
        return nil
    end
    local preferIds = preferSlotType and self:GetSkillIdsBySlot(preferSlotType)
    local preferSkillId = preferIds and preferIds[preferPos]
    if XTool.IsNumberValid(preferSkillId) then
        local preferCfg = self._Control:GetSkillCfgById(preferSkillId)
        if preferCfg and preferCfg.SkillKey == skillKey then
            return preferSkillId, preferSlotType, preferPos
        end
    end

    local latestSkillId, latestSlotType, latestPos, latestLevel
    for _, slotType in ipairs(self:GetSlotOrder()) do
        local skillIds = self:GetSkillIdsBySlot(slotType)
        for pos = 1, self._Control:GetSlotMaxLimit(slotType) do
            local skillId = skillIds and skillIds[pos]
            if XTool.IsNumberValid(skillId) then
                local cfg = self._Control:GetSkillCfgById(skillId)
                if cfg and cfg.SkillKey == skillKey and (not latestLevel or cfg.Level > latestLevel) then
                    latestSkillId = skillId
                    latestSlotType = slotType
                    latestPos = pos
                    latestLevel = cfg.Level
                end
            end
        end
    end
    return latestSkillId, latestSlotType, latestPos
end

function XUiTheatre6PopupSkillLevelUp:GetPreviewLevelSkillId(skillId)
    local previewSkillId = skillId
    local levelUpLevel = XTool.IsNumberValid(self.LevelUpLevel) and self.LevelUpLevel or 1
    for _ = 1, levelUpLevel do
        local nextSkillId = self._Control:GetNextLevelSkillId(previewSkillId)
        if not XTool.IsNumberValid(nextSkillId) then
            break
        end
        previewSkillId = nextSkillId
    end
    return previewSkillId
end

function XUiTheatre6PopupSkillLevelUp:GetDefaultSkill()
    local SlotType = XEnumConst.Theatre6.SlotType
    -- 优先选中第一个可升星的技能
    for _, slotType in ipairs(self:GetSlotOrder()) do
        local skillIds = self:GetSkillIdsBySlot(slotType)
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            local skillId = skillIds and skillIds[index]
            if self:ConditionLevelUp(skillId) then
                self.PanelUiSkill:ClickGrid(skillId, slotType, index)
                return skillId
            end
        end
    end
    -- 兜底:保持原有逻辑,取第一个槽位的默认技能
    for _, slotType in pairs(SlotType) do
        local defaultSkill = self._Control:GetDefaultSkill(slotType)
        local skillId = defaultSkill and defaultSkill.SkillId or nil
        if XTool.IsNumberValid(skillId) then
            self.PanelUiSkill:ClickGrid(skillId, slotType, 1)
            return skillId
        end
    end
    return nil
end

function XUiTheatre6PopupSkillLevelUp:HasAnyUpgradableSkill()
    return XTool.IsNumberValid(self:FindFirstUpgradableSkill())
end

function XUiTheatre6PopupSkillLevelUp:FindFirstUpgradableSkill()
    for _, slotType in ipairs(self:GetSlotOrder()) do
        local skillIds = self:GetSkillIdsBySlot(slotType)
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            local skillId = skillIds and skillIds[index]
            if self:ConditionLevelUp(skillId) then
                return skillId, slotType, index
            end
        end
    end
end

function XUiTheatre6PopupSkillLevelUp:Refresh(skillId)
    self.TxtNumLeft.text     = self._LevelUpCount
    self._SkillId            = skillId
    self.UiTxtSkillName.text = self._Control:GetSkillCfgById(self._SkillId).Name
    self.UiTxtDescNow.text   = self._Control:GetSkillDesc(self._SkillId, false)
    local skillConfig        = self._Control:GetSkillCfgById(self._SkillId)
    local previewSkillId     = self:GetPreviewLevelSkillId(self._SkillId)
    local previewSkillConfig = previewSkillId and self._Control:GetSkillCfgById(previewSkillId)
    self.UiTxtDescAfter.text = previewSkillId and self._Control:GetSkillDesc(previewSkillId, false) or ""
    self.UiTheatre6GridSkill:Update(self._SkillId)
    self.UiTheatre6GridSkill:ShowPreLevelUpEffect()
    self.BtnLevelUp:SetDisable(not self:ConditionLevelUp(self._SkillId))

    self.PanelUiSkill:SetGridDisable(handler(self, self.NotLevelUp))

    self.TxtTitleSc.text = XUiHelper.GetText("Theatre6OverClockEfficiency")
    self.TxtTitleAfterSc.text = XUiHelper.GetText("Theatre6OverClockEfficiency")
    self.TxtDescSc.text = string.format("%s%%", math.floor(skillConfig.CSMag / 100))
    self.TxtDescAfterSc.text = previewSkillConfig
        and string.format("%s%%", math.floor(previewSkillConfig.CSMag / 100))
        or self.TxtDescSc.text
end

function XUiTheatre6PopupSkillLevelUp:InitComponents()
    self.BtnClose:AddEventListener(handler(self, self.ConditionExit))
    ---@type XUiPanelTheatre6SkilBagDetail
    self.PanelUiSkill = XUiPanelTheatre6SkilBagDetail.New(self.PanelSkill, self, true)

    self.UiTheatre6GridSkill = XUiGridTheatre6Skill.New(self.UiTheatre6GridSkill, self)
    self.BtnLevelUp:AddEventListener(handler(self, self.OnBtnLevelUpClick))
    self:SetGridClickCb()

    self.UiTxtDescNow.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.UiTxtDescAfter.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

function XUiTheatre6PopupSkillLevelUp:SetGridClickCb()
    -- 设置技能背包格子点击回调
    self.PanelUiSkill:SetGridClickCb(XEnumConst.Theatre6.SlotType.Bag, handler(self, self.ClickFunc))
    self.PanelUiSkill:SetGridClickCb(XEnumConst.Theatre6.SlotType.Special, handler(self, self.ClickFunc))
    self.PanelUiSkill:SetGridClickCb(XEnumConst.Theatre6.SlotType.Insert, handler(self, self.ClickFunc))
    self.PanelUiSkill:SetGridClickCb(XEnumConst.Theatre6.SlotType.Active, handler(self, self.ClickFunc))
end

function XUiTheatre6PopupSkillLevelUp:ClickFunc(skillId, slotType, pos, isBaseSkill)
    if not self:ConditionLevelUp(skillId, isBaseSkill) then
        XUiManager.TipMsg(XUiHelper.GetText("Theatre6PopupSkillLevelUpNotShow"))
        return
    end
    self:Refresh(skillId)
end

function XUiTheatre6PopupSkillLevelUp:OnBtnLevelUpClick()
    if not self:ConditionLevelUp(self._SkillId) then
        return
    end
    local skillId = self._SkillId
    local skillCfg = self._Control:GetSkillCfgById(skillId)
    local skillKey = skillCfg and skillCfg.SkillKey
    local oldSlotType, oldPos = self:FindSkillSlot(skillId)
    self._Control:BuffLevelUpSkillRequest(self.BuffId, skillId, function()
        self._LevelUpCount = self._LevelUpCount + 1
        local latestSkillId, slotType, pos = self:FindLatestSkillByKey(skillKey, oldSlotType, oldPos)
        latestSkillId = latestSkillId or skillId
        if not slotType or not pos then
            slotType, pos = self:FindSkillSlot(latestSkillId)
        end

        self.PanelUiSkill:Refresh()
        self:Refresh(latestSkillId)
        self.PanelUiSkill:DispatchSkillEffects(nil, { [latestSkillId] = true })
        --次数达到上限或者没有可升级的技能了就退出界面
        if self._LevelUpCount >= self.LevelUpCount then
            self:RequestExit()
            return
        end
        --无可升级的技能了就退出界面
        local nextSkillId, nextSlotType, nextPos
        if self:ConditionLevelUp(latestSkillId) then
            nextSkillId, nextSlotType, nextPos = latestSkillId, slotType, pos
            if not nextSlotType or not nextPos then
                nextSlotType, nextPos = self:FindSkillSlot(nextSkillId)
            end
        else
            nextSkillId, nextSlotType, nextPos = self:FindFirstUpgradableSkill()
        end
        if not XTool.IsNumberValid(nextSkillId) then
            self:RequestExit()
            return
        end
        self:PlayLevelUpEffect(latestSkillId, function()
            self:Refresh(nextSkillId)
            if nextSlotType and nextPos then
                self.PanelUiSkill:ClickGrid(nextSkillId, nextSlotType, nextPos, true)
            end
        end)
    end)
end

function XUiTheatre6PopupSkillLevelUp:PlayLevelUpEffect(nextSkillId, cb)
    XLuaUiManager.SetMask(true)
    self.UiTheatre6GridSkill:TriggerLevelUpEffect()
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        if cb then cb() end
    end, 500)
end

function XUiTheatre6PopupSkillLevelUp:ConditionExit()
    if self._LevelUpCount <= self.LevelUpCount then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6PopupSkillLevelUpCancel"), nil,
            handler(self, self.RequestExit))
    else
        self:RequestExit()
    end
end

function XUiTheatre6PopupSkillLevelUp:RequestExit()
    local count = self.LevelUpCount > self._LevelUpCount
    if count then
        self._Control:BuffLevelUpSkillRequest(self.BuffId, 0, function()
            self:Close()
        end)
    else
        self:Close()
    end
end

function XUiTheatre6PopupSkillLevelUp:NotLevelUp(skillId)
    return not self:ConditionLevelUp(skillId)
end

function XUiTheatre6PopupSkillLevelUp:ConditionLevelUp(skillId)
    if not skillId or not XTool.IsNumberValid(skillId) then
        return false
    end
    local count = self.LevelUpCount > self._LevelUpCount
    local skillCfg = self._Control:GetSkillCfgById(skillId)
    local nextLevelSkillId = self._Control:GetNextLevelSkillId(skillId)
    local notMax = XTool.IsNumberValid(nextLevelSkillId)
    local level = self.LevelUpLimit == 0 and true or skillCfg.Level < self.LevelUpLimit
    local quality = self.LevelUpQuality == 0 and true or skillCfg.Quality <= self.LevelUpQuality
    return count and level and quality and notMax
end

return XUiTheatre6PopupSkillLevelUp
