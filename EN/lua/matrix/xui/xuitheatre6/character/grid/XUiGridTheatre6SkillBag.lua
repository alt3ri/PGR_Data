local XUiGridTheatre6Skill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill")

---@class XUiGridTheatre6SkillBag : XUiNode 技能背包详情面板格子
---@field _Control XTheatre6Control
---@field UiTheatre6GridSkill UiObject
---@field ImgIconAttack UnityEngine.UI.Image
---@field Highlight UnityEngine.UI.RectTransform
local XUiGridTheatre6SkillBag = XClass(XUiNode, "XUiGridTheatre6SkillBag")
local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg",
}
local SkillTypeHighlightConfig = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4LightMask",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3LightMask",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1LightMask",
}
local TagEffectSlotTypes = {
    [XEnumConst.Theatre6.SlotType.Active] = true,
    [XEnumConst.Theatre6.SlotType.Insert] = true,
    [XEnumConst.Theatre6.SlotType.Special] = true,
}
function XUiGridTheatre6SkillBag:OnStart()
    self._IsBaseSkill = false
    self.GameObject:SetActiveEx(true)
    ---@type XUiGridTheatre6Skill
    self.UiSkillGrid = XUiGridTheatre6Skill.New(self.UiTheatre6GridSkill, self)
    self:SetHighlightEffect(false)
end

function XUiGridTheatre6SkillBag:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_SKILL_ON_DRAG,
        XEventId.EVENT_THEATRE6_SKILL_ON_DRAG_END,
        XEventId.EVENT_THEATRE6_SKILL_BUBBLE_OPEN,
        XEventId.EVENT_THEATRE6_SKILL_BUBBLE_CLOSE,
    }
end

function XUiGridTheatre6SkillBag:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_THEATRE6_SKILL_ON_DRAG then
        local skillId = args[1]
        local slotType, positions = self._Control:GetEmptyPositionsByCfg(skillId)
        if not slotType then
            return
        end
        self:SetHighlightEffect(slotType == self._SlotType, true)
    end
    if evt == XEventId.EVENT_THEATRE6_SKILL_ON_DRAG_END then
        self:SetHighlightEffect(false)
    end
    if evt == XEventId.EVENT_THEATRE6_SKILL_BUBBLE_OPEN then
        local skillId = args[1]
        local slotTypes = self._Control:GetSkillInstallSlots(skillId)
        for i, slotType in ipairs(slotTypes) do
            if slotType == XEnumConst.Theatre6.SlotType.Bag then
                return
            end
            if slotType == self._SlotType then
                self:SetHighlightEffect(true)
            end
        end
    end
    if evt == XEventId.EVENT_THEATRE6_SKILL_BUBBLE_CLOSE then
        self:SetHighlightEffect(false)
    end
end

---刷新参数
---@param pos number 槽位位置
---@param slotType number 槽位类型
---@param skillId number 技能id，无=nil
---@param dragArea Transform[] 拖拽响应区域
---@param readOnly boolean 是否只读(参数/存档模式下不查询实时玩法数据)
function XUiGridTheatre6SkillBag:Refresh(pos, slotType, skillId, characterId, readOnly)
    self._SlotType = slotType
    self._SkillId = skillId
    self._Pos = pos
    self._Disable = false
    self:SetBaseSkill(characterId)
    self:SetHighlightEffect(false)
    self.UiSkillGrid:ShowSelected(false)
    self.UiSkillGrid.BtnGridSkill:SetDisable(false)

    if self._SkillId ~= nil then
        self.UiSkillGrid:Update(self._SkillId, readOnly)
        self.UiSkillGrid:Open()
    else
        if not self._SkillId then
            self.UiSkillGrid:Close()
        end
    end

    if self._IsBaseSkill or not XTool.IsNumberValid(skillId) then
        self:ClearDrag()
    end
    if self.ImgIconAttack then
        self.ImgIconAttack.gameObject:SetActiveEx(self._SlotType == XEnumConst.Theatre6.SlotType.Attack)
    end

    if self.PanelAtk then
        self.PanelAtk.gameObject:SetActiveEx(self._SlotType == XEnumConst.Theatre6.SlotType.Attack)
    end

    if self.RImgBg then
        self.RImgBg:SetRawImage(self._Control:GetClientConfigValue(SkillTypeBgConfigName[self._SlotType]))
    end
end

function XUiGridTheatre6SkillBag:SetBaseSkill(characterId)
    if self._SkillId then
        return
    end
    local baseSkillId = self._Control:GetBaseSkillForSlot(self._SlotType, self._Pos, characterId)
    if not XTool.IsNumberValid(baseSkillId) then
        return
    end
    self._SkillId = baseSkillId
    self._IsBaseSkill = true
end

function XUiGridTheatre6SkillBag:SetHighlightEffect(isShow, isDrag)
    -- if self._SkillId then
    --     return
    -- end


    if self.Highlight then
        self.Highlight.gameObject:SetActiveEx(isShow)
        if not SkillTypeHighlightConfig[self._SlotType] then
            return
        end
        if isDrag and isShow then
            self.Highlight:SetRawImage(self._Control:GetClientConfigValue(SkillTypeHighlightConfig[self._SlotType]))
        elseif isShow then
            self.Highlight:SetRawImage(self._Control:GetClientConfigValue(SkillTypeHighlightConfig[self._SlotType], 2))
        end
    end
end

function XUiGridTheatre6SkillBag:GetSkillId()
    return self._SkillId
end

function XUiGridTheatre6SkillBag:GetGridData()
    return self._SlotType, self._Pos
end

function XUiGridTheatre6SkillBag:SetDragCb(area, cloneParent, startCb, endCb, enterCb, leaveCb)
    if self._IsBaseSkill then
        self:ClearDrag()
        return
    end
    self.UiSkillGrid:SetDragCb(area, cloneParent, startCb, endCb, enterCb, leaveCb)
end

function XUiGridTheatre6SkillBag:AddDragTargetArea(rectTransform, areaId)
    if self._IsBaseSkill then
        return
    end
    self.UiSkillGrid:AddDragTargetArea(rectTransform, areaId)
end

function XUiGridTheatre6SkillBag:SetClickCb(cb)
    self.UiSkillGrid:SetClickCb(function(skillId)
        self:ClickGrid(skillId, cb)
    end)
end

function XUiGridTheatre6SkillBag:ClickGrid(skillId, cb)
    if self:IsDisable() then
        return
    end

    if cb then
        cb(skillId, self._SlotType, self._Pos)
    end
    if self._SlotType == XEnumConst.Theatre6.SlotType.Bag and self._SkillId then
        --设置已读状态
        self._Control:SetNewSkillViewed(self._SkillId)
    end
end

function XUiGridTheatre6SkillBag:SetButtonSelect(value)
    if not XTool.IsNumberValid(self._SkillId) then
        return
    end

    self.UiSkillGrid:ShowSelected(value)
end

function XUiGridTheatre6SkillBag:SetDisable(value)
    if not XTool.IsNumberValid(self._SkillId) then
        return
    end
    self._Disable = value
    self.UiSkillGrid.BtnGridSkill:SetDisable(value)
end

function XUiGridTheatre6SkillBag:IsDisable()
    return self._Disable
end

function XUiGridTheatre6SkillBag:CanUpgrade(value)
    if not XTool.IsNumberValid(self._SkillId) then
        return
    end
    self.UiSkillGrid:CanUpgrade(value)
end

---@param addedIdsBySlot table<number, table<number, true>> 按槽位分组的本次新增技能 set
function XUiGridTheatre6SkillBag:TryShowTagEffect(addedIdsBySlot)
    if not addedIdsBySlot then return end
    if not TagEffectSlotTypes[self._SlotType] then return end
    if not XTool.IsNumberValid(self._SkillId) then return end
    local addedIds = addedIdsBySlot[self._SlotType]
    if not addedIds or not next(addedIds) then return end
    local selfCfg = self._Control:GetSkillCfgById(self._SkillId)
    local selfTags = selfCfg and selfCfg.BuildTags
    if not selfTags or #selfTags == 0 then return end
    if addedIds[self._SkillId] then
        local intersect = self:GetEquippedTagIntersect(selfTags)
        if intersect and #intersect > 0 then
            self.UiSkillGrid:ShowTagEffect(intersect)
        end
        return
    end
    for addedId in pairs(addedIds) do
        local addedCfg = self._Control:GetSkillCfgById(addedId)
        local addedTags = addedCfg and addedCfg.BuildTags
        if addedTags and self:HasIntersect(selfTags, addedTags) then
            self.UiSkillGrid:ShowTagEffect(addedTags)
            return
        end
    end
end

---取同槽位其他已装备技能 tag 与 selfTags 的交集
function XUiGridTheatre6SkillBag:GetEquippedTagIntersect(selfTags)
    local equippedIds = self._Control:GetCharacterDressSkillIds(self._SlotType)
    if not equippedIds then return nil end
    local equippedTagSet = {}
    for _, ownedId in pairs(equippedIds) do
        if XTool.IsNumberValid(ownedId) and ownedId ~= self._SkillId then
            local cfg = self._Control:GetSkillCfgById(ownedId)
            if cfg and cfg.BuildTags then
                for _, tagId in ipairs(cfg.BuildTags) do
                    equippedTagSet[tagId] = true
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

---@param upgradeIds table<number, true> 本次升级技能 set
function XUiGridTheatre6SkillBag:TryShowUpgradeEffect(upgradeIds)
    self.UiSkillGrid:ShowUpgradeEffect(false)
    if not upgradeIds or not next(upgradeIds) then return end
    if not XTool.IsNumberValid(self._SkillId) then return end
    if upgradeIds[self._SkillId] then
        self.UiSkillGrid:ShowUpgradeEffect(true)
    end
end

function XUiGridTheatre6SkillBag:HasIntersect(arr1, arr2)
    for _, a in ipairs(arr1) do
        for _, b in ipairs(arr2) do
            if a == b then return true end
        end
    end
    return false
end

function XUiGridTheatre6SkillBag:ClearNewFlag()
    if not XTool.IsNumberValid(self._SkillId) then
        return
    end
    self.UiSkillGrid:ClearNewFlag()
end

function XUiGridTheatre6SkillBag:IsBaseSkill()
    return self._IsBaseSkill
end

function XUiGridTheatre6SkillBag:ClearDrag()
    if self.UiSkillGrid then
        self.UiSkillGrid:ClearDrag()
    end
end

function XUiGridTheatre6SkillBag:ClearData()
    self._SkillId = nil
    self._Pos = nil
    self._SlotType = nil
    self._IsBaseSkill = false
    self._Disable = false
end

function XUiGridTheatre6SkillBag:OnDestroy()
    if self.UiSkillGrid then
        self.UiSkillGrid:OnDestroy()
        self.UiSkillGrid = nil
    end
    self:ClearData()
end

return XUiGridTheatre6SkillBag
