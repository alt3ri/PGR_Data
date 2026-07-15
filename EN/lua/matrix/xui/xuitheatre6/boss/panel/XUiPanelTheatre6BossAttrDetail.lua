---@class XUiPanelTheatre6BossAttrDetail : XUiNode 怪物属性详情
---@field _Control XTheatre6Control
local XUiPanelTheatre6BossAttrDetail = XClass(XUiNode, "XUiPanelTheatre6BossAttrDetail")

function XUiPanelTheatre6BossAttrDetail:OnStart()
    self._MaxRelicCount = self._Control:GetIntClientConfigValue("MaxRelicCount")
    self.BtnAttribute:AddEventListener(handler(self, self.OnBtnAttributeClick))
    self.PanelSkillBag.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6BossAttrDetail:SetData(monsterId)
    self._MonsterConfig = self._Control:GetMonsterCfgById(monsterId)
    self._AttrIds = {}

    local characterConfig = self._Control:GetCharacterConfig(self._MonsterConfig.CharacterId)
    local fashionConfig = self._Control:GetFashionConfig(characterConfig.FashionIds[1])
    self.RImgRole:SetRawImage(fashionConfig.Portrait)
    self.UiTxtName.text = characterConfig.Name
    self.UiTxtScore.text = self._Control:GetMonsterScore(monsterId)

    --属性
    self:ShowAttribute()
    --技能
    self:ShowSkill()
    --遗物
    self:ShowRelic()
end

function XUiPanelTheatre6BossAttrDetail:ShowAttribute()
    ---@type XTableTheatre6Attr[]
    local attrConfigs = {}
    for attrId in pairs(self._MonsterConfig.AttrTypes) do
        local attrConfig = self._Control:GetAttrConfig(attrId)
        if XTool.IsNumberValid(attrConfig.Priority) then
            table.insert(attrConfigs, attrConfig)
        end
    end
    table.sort(attrConfigs, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        return a.Id > b.Id
    end)
    XUiHelper.RefreshCustomizedList(self.GridAttribute.parent, self.GridAttribute, #attrConfigs, function(i, go)
        local attrConfig = attrConfigs[i]
        local attrId = attrConfig.Id
        local attrValue = self._MonsterConfig.AttrTypes[attrId]
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.UiImgIcon:SetRawImage(attrConfig.Icon)
        uiObject.UiTxtNum.text = self._Control:FormatNumberWithUnit(attrValue) 
        table.insert(self._AttrIds, attrId)
    end)
end

function XUiPanelTheatre6BossAttrDetail:ShowSkill()
    -- local skillCount = self._Control:GetSlotCapacity(XEnumConst.Theatre6.SkillType.Active)
    -- XLog.Error(self._MonsterConfig.SkillIds, "技能列表")
    local sortedSkillIds = self:SortBossSkillBySlotType()
    self.GridSkillUis = {}
    XUiHelper.RefreshCustomizedList(self.GridSkill.parent, self.GridSkill, #sortedSkillIds, function(i, go)
        local skillId = sortedSkillIds[i]
        local isExistSkill = skillId ~= nil
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.UiTheatre6GridSkill.gameObject:SetActiveEx(isExistSkill)
        local isLast = i == #sortedSkillIds
        local isActiveSkillLast = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Active) == i
        uiObject.ImgIconArrow.gameObject:SetActiveEx(not isLast and not isActiveSkillLast)
        if isExistSkill then
            if not self.GridSkillUis[i] then
                ---@type XUiGridTheatre6Skill
                self.GridSkillUis[i] = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill").New(uiObject.UiTheatre6GridSkill, self)
            end
            self.GridSkillUis[i]:Update(skillId,true)
        end
    end)
end

function XUiPanelTheatre6BossAttrDetail:SortBossSkillBySlotType()
    local skillIds = {}
    for _, skillId in ipairs(self._MonsterConfig.SkillIds) do
        local slotType = self._Control:GetSkillInstallSlots(skillId)[1]
        skillIds[slotType] = skillIds[slotType] or {}
        table.insert(skillIds[slotType], skillId)
    end

    local sortedSkillIds = {}
    local sortGroup = {XEnumConst.Theatre6.SlotType.Active, XEnumConst.Theatre6.SlotType.Insert, XEnumConst.Theatre6.SlotType.Special}
    for _, slotType in ipairs(sortGroup) do
        local ids = skillIds[slotType]
        if ids then
            for _, id in ipairs(ids) do
                table.insert(sortedSkillIds, id)
            end
        end
    end
    return sortedSkillIds
end

function XUiPanelTheatre6BossAttrDetail:ShowRelic()
    ---@type XTableTheatre6AttrPack[]
    local attrPacks = {}
    local attrPackNums = {}
    for i, id in ipairs(self._MonsterConfig.AttrPacks) do
        local config = self._Control:GetAttrPackCfgById(id)
        if not config.IsHide then
            table.insert(attrPacks, config)
            attrPackNums[id] = self._MonsterConfig.AttrPackNums[i] or 1
        end
    end

    --优先级＞数量＞Id
    table.sort(attrPacks, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        local aNum = attrPackNums[a.Id]
        local bNum = attrPackNums[b.Id]
        if aNum ~= bNum then
            return aNum > bNum
        end
        return a.Id > b.Id
    end)

    local totalCount = #attrPacks
    local showCount = math.min(self._MaxRelicCount, totalCount)
    local extraCount = totalCount - self._MaxRelicCount
    self.GridRelicUis = {}
    XUiHelper.RefreshCustomizedList(self.GridRelic.parent, self.GridRelic, showCount, function(i, go)
        if not self.GridRelicUis[i] then
             ---@type XUiGridTheatre6Relic
            self.GridRelicUis[i] = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Relic").New(go, self)
        end
        local relicId = attrPacks[i].Id
        self.GridRelicUis[i]:SetRelic(relicId, attrPackNums[relicId])
        if i == showCount and extraCount > 0 then
            self.GridRelicUis[i]:ShowMore(extraCount)
        end
        self.GridRelicUis[i]:SetClickCb(function()
            local ids, counts = {}, {}
            for k, v in ipairs(attrPacks) do
                table.insert(ids, v.Id)
                table.insert(counts, attrPackNums[v.Id])
            end
            XLuaUiManager.Open("UiTheatre6PopupRelicDetail", ids, counts)
        end)
    end)
    self.TxtRelicEmpty.gameObject:SetActiveEx(showCount == 0)
end

function XUiPanelTheatre6BossAttrDetail:OnBtnAttributeClick()
    if self.Parent.OpenAttrBubble then
        self.Parent:OpenAttrBubble(self._AttrIds)
    end
end

return XUiPanelTheatre6BossAttrDetail
