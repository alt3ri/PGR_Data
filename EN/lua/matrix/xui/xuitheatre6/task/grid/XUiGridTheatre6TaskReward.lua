---@class XUiGridTheatre6TaskReward : XUiNode 任务奖励
---@field _Control XTheatre6Control
local XUiGridTheatre6TaskReward = XClass(XUiNode, "XUiGridTheatre6TaskReward")

local EventRewardType = XEnumConst.Theatre6.EventRewardType

function XUiGridTheatre6TaskReward:OnStart()
    ---@type XUiGridTheatre6BossRewardResource
    self._GridResource = require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossRewardResource").New(self.GridResource, self)

    ---@type XUiGridTheatre6Buff
    self._GridBuff = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff").New(self.GridBuff, self)
    self._GridBuff:SetCustomClickCb(function()
        self._Control:OpenBuffTip(self._Id, self.GridBuff)
    end)

    ---@type XUiGridTheatre6Relic
    self._GridRelic = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Relic").New(self.GridRelic, self)
    self._GridRelic:SetClickCb(function()
        self._Control:OpenRelicTip(self._Id, self.GridRelic)
    end)

    ---@type XUiGridTheatre6Skill
    self._GridSkill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill").New(self.GridSkill, self)
    -- self._GridSkill:SetClickCb(function()
    --     self._Control:OpenSkillTip(self._Id, self.GridSkill)
    -- end)

    if self.UiPanelFinish then
        self.UiPanelFinish.gameObject:SetActiveEx(false)
    end
    if self.UiPanelUnFinish then
        self.UiPanelUnFinish.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre6TaskReward:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_UPDATE_SKILL,
        XEventId.EVENT_THEATRE6_TAG_HIGHLIGHT_SOURCE_CHANGE,
    }
end

function XUiGridTheatre6TaskReward:OnNotify(evt)
    if evt == XEventId.EVENT_THEATRE6_UPDATE_SKILL then
        self:RefreshCanUpgrade()
        -- self:RefreshTagHightLight()
    elseif evt == XEventId.EVENT_THEATRE6_TAG_HIGHLIGHT_SOURCE_CHANGE then
        self:RefreshTagHightLight()
    end
end

function XUiGridTheatre6TaskReward:RefreshCanUpgrade()
    if self._IsFinished then return end
    if not self._IsSkillReward then return end
    self._GridSkill:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(self._Id))
end

function XUiGridTheatre6TaskReward:RefreshTagHightLight()
    local highlightSourceTagIds = self._Control:GetEffectiveTagHighlightSourceTagIds(
        self._Control:GetTagHighlightSourceTagIds()
    )
    if self._IsRelicReward then
        if not self._EnableTagHighlight then
            self._GridRelic:ShowTagHightLight(nil)
            return
        end
        local relicCfg = self._Control:GetAttrPackCfgById(self._Id)
        self._GridRelic:ShowTagHightLight(
            self._Control:CalcSkillHighlightTagsBySource(relicCfg, highlightSourceTagIds)
        )
        return
    end
    if not self._IsSkillReward then return end
    if not self._EnableTagHighlight then
        self._GridSkill:ShowTagHightLight(nil)
        return
    end
    local skillCfg = self._Control:GetSkillCfgById(self._Id)
    self._GridSkill:ShowTagHightLight(
        self._Control:CalcSkillHighlightTagsBySource(skillCfg, highlightSourceTagIds)
    )
end

---XTool.UpdateDynamicItem调用
---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:Update(data)
    self._EnableTagHighlight = self.Parent and self.Parent.IsChooseMode and self.Parent:IsChooseMode() == true
    self._Id = data.TemplateId
    self._IsSkillReward = false
    self._IsRelicReward = false
    self._IsFinished = false
    if self.UiPanelFinish then
        self.UiPanelFinish.gameObject:SetActiveEx(false)
    end
    if self.UiPanelUnFinish then
        self.UiPanelUnFinish.gameObject:SetActiveEx(false)
    end
    self._GridResource:Close()
    self._GridBuff:Close()
    self._GridRelic:Close()
    self._GridSkill:Close()

    if self:SetResourceData(data) then
        return
    end

    if self:SetBuffData(data) then
        return
    end

    if self:SetRelicData(data) then
        return
    end

    if self:SetSkillData(data) then
        return
    end

    XLog.Error(string.format("未知奖励类型：%s", data.RewardType))
end

---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:SetResourceData(data)
    if data.RewardType == EventRewardType.Goods then
        self._GridResource:Open()
        self._GridResource:RefreshGoods(data.TemplateId, data.Amount)
        return true
    end

    if data.RewardType == EventRewardType.Coin then
        self._GridResource:Open()
        self._GridResource:RefreshGold(data.Amount)
        return true
    end

    return false
end

---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:SetBuffData(data)
    if data.RewardType == EventRewardType.BuffPool then
        self._GridBuff:Open()
        self._GridBuff:Update(data.TemplateId)
        return true
    end

    return false
end

---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:SetRelicData(data)
    if XTool.IsNumberValid(data.AttrPack) then
        self._Id = data.AttrPack
        self._IsRelicReward = true
        self._GridRelic:Open()
        self._GridRelic:Update(data.AttrPack)
        self:RefreshTagHightLight()
        return true
    end

    return false
end

---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:SetSkillData(data)
    if XTool.IsNumberValid(data.SkillId) then
        self._Id = data.SkillId
        self._IsSkillReward = true
        self._GridSkill:Open()
        self._GridSkill:Update(data.SkillId)
        self._GridSkill:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(data.SkillId))
        self:RefreshTagHightLight()
        return true
    end

    return false
end

function XUiGridTheatre6TaskReward:SetFinish(isFinish)
    self._IsFinished = isFinish
    self.UiPanelFinish.gameObject:SetActiveEx(isFinish)
    self.UiPanelUnFinish.gameObject:SetActiveEx(not isFinish)
    if isFinish then
        self._GridSkill:CanUpgrade(false)
    end
end

function XUiGridTheatre6TaskReward:ShowFinish(data, isFinish)
    self._IsFinished = isFinish
    if self._GridSkill then
        if isFinish then
            self._GridSkill:CanUpgrade(false)
        else
            self._GridSkill:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(data.SkillId))
        end
    end
end


return XUiGridTheatre6TaskReward
