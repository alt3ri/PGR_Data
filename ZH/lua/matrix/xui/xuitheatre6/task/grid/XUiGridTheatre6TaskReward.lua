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
    -- self._GridRelic:SetClickCb(function()
    --     self._Control:OpenRelicTip(self._Id, self.GridRelic)
    -- end)

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

---XTool.UpdateDynamicItem调用
---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:Update(data)
    self._Id = data.TemplateId
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
        self._GridRelic:Open()
        self._GridRelic:Update(data.AttrPack)
        return true
    end

    return false
end

---@param data Theatre6PreviewRewardGoodsProtocol
function XUiGridTheatre6TaskReward:SetSkillData(data)
    if XTool.IsNumberValid(data.SkillId) then
        self._Id = data.SkillId
        self._GridSkill:Open()
        self._GridSkill:Update(data.SkillId)
        self._GridSkill:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(data.SkillId))
        self._GridSkill:ShowTagEffect(self:GetSameBuildTagIdsWithEquipped(data.SkillId))
        return true
    end

    return false
end

---@param skillId number
---@return number[] 与角色同槽位已装备技能 BuildTag 的交集 Id 列表(剔除背包中同 SkillId 的技能;不同槽位的同 tag 不计入)
function XUiGridTheatre6TaskReward:GetSameBuildTagIdsWithEquipped(skillId)
    local skillCfg = self._Control:GetSkillCfgById(skillId)
    local selfTags = skillCfg and skillCfg.BuildTags
    if not selfTags or #selfTags == 0 then
        return {}
    end
    local installSlots = self._Control:GetSkillInstallSlots(skillId)
    if not installSlots or #installSlots == 0 then
        return {}
    end
    local equippedTagSet = {}
    for _, slotType in ipairs(installSlots) do
        local ownedIds = self._Control:GetCharacterDressSkillIds(slotType)
        if ownedIds then
            for _, ownedSkillId in pairs(ownedIds) do
                if XTool.IsNumberValid(ownedSkillId) and ownedSkillId ~= skillId then
                    local ownedCfg = self._Control:GetSkillCfgById(ownedSkillId)
                    if ownedCfg and ownedCfg.BuildTags then
                        for _, tagId in ipairs(ownedCfg.BuildTags) do
                            equippedTagSet[tagId] = true
                        end
                    end
                end
            end
        end
    end
    local result = {}
    for _, tagId in ipairs(selfTags) do
        if equippedTagSet[tagId] then
            table.insert(result, tagId)
        end
    end
    return result
end

function XUiGridTheatre6TaskReward:SetFinish(isFinish)
    self.UiPanelFinish.gameObject:SetActiveEx(isFinish)
    self.UiPanelUnFinish.gameObject:SetActiveEx(not isFinish)
    if isFinish then
        self._GridSkill:CanUpgrade(false)
    end
end

return XUiGridTheatre6TaskReward
