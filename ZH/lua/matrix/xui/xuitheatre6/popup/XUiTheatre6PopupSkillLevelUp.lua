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
---@param levelUpLevel number 升级等级
---@param levelUpLimit number 升级等级限制 无则不限制
---@param levelUpQuality number 升级品质限制 无则不限制
function XUiTheatre6PopupSkillLevelUp:OnStart(levelUpCount, levelUpLevel, levelUpLimit, levelUpQuality)
    self._LevelUpCount = 0
    self.LevelUpCount = levelUpCount
    self.LevelUpLevel = levelUpLevel
    self.LevelUpLimit = levelUpLimit or 0
    self.LevelUpQuality = levelUpQuality or 0

    self.TxtNumRight.text = "/"..self.LevelUpCount
end

function XUiTheatre6PopupSkillLevelUp:OnEnable()
    self._SkillId = self._SkillId or self:GetDefaultSkill()
    self:Refresh(self._SkillId)
end

function XUiTheatre6PopupSkillLevelUp:GetDefaultSkill()
    for _, slotType in pairs(XEnumConst.Theatre6.SlotType) do
        local defaultSkill = self._Control:GetDefaultSkill(slotType)

        local skillId = defaultSkill and defaultSkill.SkillId or nil
        if XTool.IsNumberValid(skillId) then
            self.PanelUiSkill:ClickGrid(skillId, slotType)
            return skillId
        end
    end
    return nil
end

function XUiTheatre6PopupSkillLevelUp:Refresh(skillId)
    self.TxtNumLeft.text = self._LevelUpCount
    self._SkillId = skillId
    self.UiTxtSkillName.text = self._Control:GetSkillCfgById(self._SkillId).Name
    self.UiTxtDescNow.text = self._Control:GetSkillDesc(self._SkillId, false)
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
    local nextLevelSkillId = self._Control:GetNextLevelSkillId(self._SkillId)
    local nextLevelSkillConfig  = self._Control:GetSkillCfgById(nextLevelSkillId)
    self.UiTxtDescAfter.text = self._Control:GetSkillDesc(nextLevelSkillId, false)
    self.UiTheatre6GridSkill:Update(self._SkillId)
    self.BtnLevelUp:SetDisable(not self:ConditionLevelUp(self._SkillId))

    self.PanelUiSkill:SetGridDisable(handler(self, self.NotLevelUp))
    
    self.TxtTitleSc.text =  XUiHelper.GetText("Theatre6OverClockEfficiency")
    self.TxtTitleAfterSc.text = XUiHelper.GetText("Theatre6OverClockEfficiency")
    self.TxtDescSc.text = string.format("%s%%", math.floor(skillConfig.CSMag / 100))
    self.TxtDescAfterSc.text = string.format("%s%%", math.floor(nextLevelSkillConfig.CSMag / 100))
end

function XUiTheatre6PopupSkillLevelUp:InitComponents()
    self.BtnClose:AddEventListener(handler(self, self.ConditionExit))
    self.PanelUiSkill = XUiPanelTheatre6SkilBagDetail.New(self.PanelSkill, self)

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
        XUiManager.TipMsg("当前技能无法升级")
        return
    end
    self:Refresh(skillId)
end

function XUiTheatre6PopupSkillLevelUp:OnBtnLevelUpClick()
    if not self:ConditionLevelUp(self._SkillId) then
        return
    end
    self._Control:BuffLevelUpSkillRequest(self._SkillId, function()
        self._LevelUpCount = self._LevelUpCount + 1
        self:Refresh(self._SkillId)
    end)
end

function XUiTheatre6PopupSkillLevelUp:ConditionExit()
    if self._LevelUpCount <= self.LevelUpCount then
        XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6PopupSkillLevelUpCancel"), nil, handler(self, self.Close))
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
    local level = self.LevelUpLimit == 0 and true or skillCfg.Level <= self.LevelUpLimit
    local quality = self.LevelUpQuality == 0 and true or skillCfg.Quality <= self.LevelUpQuality
    return count and level and quality
end

return XUiTheatre6PopupSkillLevelUp
