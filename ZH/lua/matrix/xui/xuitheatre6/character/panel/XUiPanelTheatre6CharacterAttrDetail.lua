local XUiPanelTheatre6SkilBagDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6SkilBagDetail")
local XUiGridTheatre6SkillBag = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6SkillBag")
local XUiCommonRollingNumber = require("XUi/XUiCommon/XUiCommonRollingNumber")
---每帧分批初始化的拖拽数,避免 ShowSkill 一次性创建大量 XUiSimpleDrag 造成卡顿
local DRAG_INIT_BATCH = 4

---@class XUiPanelTheatre6CharacterAttrDetail : XUiNode 角色详情面板
---@field _Control XTheatre6Control
local XUiPanelTheatre6CharacterAttrDetail = XClass(XUiNode, "XUiPanelTheatre6CharacterAttrDetail")

function XUiPanelTheatre6CharacterAttrDetail:OnStart(data, mode, isInShop, taskUpgradeSkillIds)
    self._Mode = mode or self._Control:GetCurPlayMode()
    self._IsInShop = isInShop or false
    self._MaxRelicCount = self._Control:GetIntClientConfigValue("MaxRelicCount")
    self._MaxBuffCount = self._Control:GetIntClientConfigValue("MaxBuffCount")
    self._AttrIds = {}
    self._ExternalAreas = {}
    self._TaskUpgradeSkillIds = taskUpgradeSkillIds
    self._OnScrollCb = handler(self, self.CheckScoreTopVisible)

    self.PanelSkillBag.gameObject:SetActiveEx(false)
    self.BtnAttribute:AddEventListener(handler(self, self.OnBtnAttributeClick))
    self.BtnBackpack:AddEventListener(handler(self, self.ShowSkillBag))
    self.ListRoleDetail.onValueChanged:AddListener(self._OnScrollCb)

    self:InitScoreTopCheck()

    self:SetData(data)
    self:UpdateReddot()
end

---切换数据并刷新视图，可在面板创建后多次调用
---@param data Theatre6FileData|nil
function XUiPanelTheatre6CharacterAttrDetail:SetData(data)
    self._IsUseParamData = data ~= nil
    self._ModelData = (data and data.CharacterId) and data or self._Control:GetPlayModeData(self._Mode)

    self:CacheSkillData()
    self:CacheBuffData()

    local characterConfig = self._Control:GetCharacterConfig(self._ModelData.CharacterId)
    self.UiTxtName.text = characterConfig.Name
    if self._IsUseParamData then
        local defaultFashion = self._Control:GetFashionConfig(characterConfig.FashionIds[1]).BigPortrait
        self.RImgRole:SetRawImage(defaultFashion)
        self:HideBtnBackpack()
    else
        self.RImgRole:SetRawImage(self._Control:GetBigHeadIconByMode(self._Mode))
    end

    self:RefreshRoleDetail()
    self:UpdateView()
end

function XUiPanelTheatre6CharacterAttrDetail:OnEnable()
    self:CacheSkillData()
    self:CacheBuffData()
    if self._IsDirty then
        self._IsDirty = false
    end
    self:UpdateReddot()
end


function XUiPanelTheatre6CharacterAttrDetail:CacheSkillData()
    if self._IsUseParamData then
        local activeSkillIds, insertSkillIds, specialSkillIds, skillBagIds = {}, {}, {}, {}
        local SlotType = XEnumConst.Theatre6.SlotType
        for _, data in ipairs(self._ModelData.Skills or table.empty) do
            if data.SlotType == SlotType.Active then
                activeSkillIds[data.Position] = data.SkillId
            elseif data.SlotType == SlotType.Insert then
                insertSkillIds[data.Position] = data.SkillId
            elseif data.SlotType == SlotType.Special then
                specialSkillIds[data.Position] = data.SkillId
            elseif data.SlotType == SlotType.Bag then
                skillBagIds[data.Position] = data.SkillId
            end
        end
        self._ActiveSkillIds = activeSkillIds
        self._InsertSkillIds = insertSkillIds
        self._SpecialSkillIds = specialSkillIds
        self._SkillBagIds = skillBagIds
    else
        self._ActiveSkillIds = self._Control:GetActiveSkillIds()
        self._InsertSkillIds = self._Control:GetInsertSkillIds()
        self._SpecialSkillIds = self._Control:GetSpecialSkillIds()
        self._SkillBagIds = self._Control:GetCharacterSkillBagIds()
    end
    self._ActiveSlotMax = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Active)
    self._InsertSlotMax = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Insert)
    self._SpecialSlotMax = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Special)
    self._BagSlotMax = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Bag)
end

function XUiPanelTheatre6CharacterAttrDetail:CacheBuffData()
    if self._IsUseParamData then
        local rawBuffs = self._ModelData.Buffs or table.empty
        local filtered = {}
        for _, data in ipairs(rawBuffs) do
            local config = self._Control:GetBuffConfig(data.BuffId)
            if config and config.IsNotShow == 0 then
                table.insert(filtered, data)
            end
        end
        self._BuffDatas = filtered
    else
        self._BuffDatas = self._Control:GetSortCharacterShowBuffs()
    end
end

function XUiPanelTheatre6CharacterAttrDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_UPDATE_SKILL,
        XEventId.EVENT_THEATRE6_BUY_GOOD,
        XEventId.EVENT_THEATRE6_SKILL_NOT_NEW,
        XEventId.EVENT_THEATRE6_SHOP_REFRESH,
        XEventId.EVENT_THEATRE6_SCORE_CHANGE,
        XEventId.EVENT_THEATRE6_TAG_HIGHLIGHT_SOURCE_CHANGE,
    }
end

function XUiPanelTheatre6CharacterAttrDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE6_UPDATE_SKILL then
        local addedIdsBySlot, upgradeIds = ...
        self:CacheSkillData()
        if not self.ListRoleDetail.gameObject.activeInHierarchy then
            self._IsDirty = true
            return
        end
        self:ShowSkill()
        self:DispatchSkillEffects(addedIdsBySlot, upgradeIds)
        self:UpdateReddot()
    elseif evt == XEventId.EVENT_THEATRE6_SHOP_REFRESH then
        self:CacheSkillData()
        if not self.ListRoleDetail.gameObject.activeInHierarchy then
            self._IsDirty = true
            return
        end
        self:ShowSkill()
        self:UpdateReddot()
    elseif evt == XEventId.EVENT_THEATRE6_BUY_GOOD then
        self:CacheSkillData()
        self:CacheBuffData()
        self:UpdateView()
        self:UpdateReddot()
    elseif evt == XEventId.EVENT_THEATRE6_SKILL_NOT_NEW then
        self:UpdateReddot()
    elseif evt == XEventId.EVENT_THEATRE6_SCORE_CHANGE then
        local oldScore, newScore = ...
        self.IsUp = newScore > oldScore
        if not self.RollingNumber then
            self.RollingNumber = XUiCommonRollingNumber.New(
                handler(self, self.RollingStart),
                handler(self, self.RollingRefresh),
                handler(self, self.RollingEnd)
            )
        end
        if self.ImgBgScoreTop.gameObject.activeInHierarchy then
            self.RollingNumber:Play(oldScore, newScore, 1)
        else
            self:RefreshRoleDetail()
        end

    elseif evt == XEventId.EVENT_THEATRE6_TAG_HIGHLIGHT_SOURCE_CHANGE then
        self:RefreshAllTagHighLight()
    end
end

function XUiPanelTheatre6CharacterAttrDetail:RollingStart()
    if self.ImgArrowUpTopEnable and self.ImgArrowDownTopEnable then
        self.ImgArrowUpTopEnable.gameObject:SetActiveEx(self.IsUp)
        self.ImgArrowDownTopEnable.gameObject:SetActiveEx(not self.IsUp)
    end
end

function XUiPanelTheatre6CharacterAttrDetail:RollingRefresh(value)
    self.UiTxtScoreTop.text = value
end

function XUiPanelTheatre6CharacterAttrDetail:RollingEnd()
    self:RefreshRoleDetail()
end

function XUiPanelTheatre6CharacterAttrDetail:UpdateReddot()
    if self._IsUseParamData or not self.BtnBackpackTipsEffect then
        return
    end
    local hasNewSkill = self._Control:BagHasNewSkill()
    self.BtnBackpackTipsEffect.gameObject:SetActiveEx(hasNewSkill)
end

function XUiPanelTheatre6CharacterAttrDetail:RefreshRoleDetail()
    if self.ImgArrowUpTopEnable then
        self.ImgArrowUpTopEnable.gameObject:SetActiveEx(false)
    end
    if self.ImgArrowDownTopEnable then
        self.ImgArrowDownTopEnable.gameObject:SetActiveEx(false)
    end
    local score = self._ModelData.Score or self._ModelData.ScoreTotal or 0
    self.UiTxtScore.text = score
    self.UiTxtScoreTop.text = score
    self:ShowScoreChange(false, false)
end

function XUiPanelTheatre6CharacterAttrDetail:UpdateView()
    --属性
    self:ShowAttribute()
    --技能
    if not self.ListRoleDetail.gameObject.activeInHierarchy then
        self._IsDirty = true
        return
    end
    self:ShowSkill()
    --遗物
    self:ShowRelic()
    --Buff
    self:ShowBuff()
end

---设置战力上升/下降
function XUiPanelTheatre6CharacterAttrDetail:ShowScoreChange(isUp, isDown)
    self.ImgArrowUp.gameObject:SetActiveEx(isUp)
    self.ImgArrowDown.gameObject:SetActiveEx(isDown)
end

function XUiPanelTheatre6CharacterAttrDetail:ShowAttribute()
    ---@type XTableTheatre6Attr[]
    local attrConfigs = {}
    local attrValues = {}
    self._AttrIds = {}
    for _, data in pairs(self._ModelData.Attrs) do
        local attrId, attrValue = data.AttrId, data.Value
        local attrConfig = self._Control:GetAttrConfig(attrId)
        if XTool.IsNumberValid(attrConfig.Priority) then
            table.insert(attrConfigs, attrConfig)
            attrValues[attrId] = attrValue
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
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.UiImgIcon:SetRawImage(attrConfig.Icon)
        uiObject.UiTxtNum.text = self._Control:FormatNumberWithUnit(attrValues[attrId])
        table.insert(self._AttrIds, attrId)
    end)
end

function XUiPanelTheatre6CharacterAttrDetail:GetSkillSlotInfo(index)
    local skillId = nil
    local slotType = nil
    local pos = index
    if index <= self._ActiveSlotMax then
        skillId = self._ActiveSkillIds[index]
        slotType = XEnumConst.Theatre6.SlotType.Active
    elseif index <= self._InsertSlotMax + self._ActiveSlotMax then
        skillId = self._InsertSkillIds[index - self._ActiveSlotMax]
        slotType = XEnumConst.Theatre6.SlotType.Insert
        pos = index - self._ActiveSlotMax
    else
        skillId = self._SpecialSkillIds[index - self._ActiveSlotMax - self._InsertSlotMax]
        slotType = XEnumConst.Theatre6.SlotType.Special
        pos = index - self._ActiveSlotMax - self._InsertSlotMax
    end
    return skillId, slotType, pos
end

function XUiPanelTheatre6CharacterAttrDetail:EnsureSkillGrids(skillsCount)
    if self.SkillGrids and #self.SkillGrids >= skillsCount then
        return
    end
    ---@type XUiGridTheatre6SkillBag[]
    self.SkillGrids = self.SkillGrids or {}
    self.AreaGo = self.AreaGo or {}
    self.AreaData = self.AreaData or {}
    self.GridSkill.gameObject:SetActiveEx(false)

    for i = #self.SkillGrids + 1, skillsCount do
        local go = XUiHelper.Instantiate(self.GridSkill, self.GridSkill.parent)
        local uiObject = XUiGridTheatre6SkillBag.New(go, self)
        uiObject:Open()
        self.SkillGrids[i] = uiObject
        self.AreaGo[i] = go
    end
end

function XUiPanelTheatre6CharacterAttrDetail:ShowSkill()
    local bagSkillCount = XTool.GetTableCount(self._SkillBagIds)
    if self.FullBg then
        self.FullBg.gameObject:SetActiveEx(bagSkillCount == self._BagSlotMax)
    end
    self.BtnBackpack:SetNameByGroup(0, bagSkillCount)
    self.BtnBackpack:SetNameByGroup(1, "/" .. self._BagSlotMax)
    local skillsCount = self._ActiveSlotMax + self._InsertSlotMax + self._SpecialSlotMax
    self._SkillsCount = skillsCount
    self._CurrentGrid = nil
    self:EnsureSkillGrids(skillsCount)
    self:_CancelPendingDragInit()
    local pendingDragIndices = {}
    for i = 1, skillsCount do
        local uiObject = self.SkillGrids[i]
        local skillId, slotType, pos = self:GetSkillSlotInfo(i)

        uiObject:Open()
        uiObject:ClearData()
        uiObject:Refresh(pos, slotType, skillId, self._ModelData.CharacterId, self._IsUseParamData)
        if self._IsInShop and XTool.IsNumberValid(skillId) then
            uiObject:CanUpgrade(self._Control:CharacterHasCanUpGradeSkills(skillId))
        end
        if self._TaskUpgradeSkillIds and XTool.IsNumberValid(skillId) and self._TaskUpgradeSkillIds[skillId] then
            uiObject:CanUpgrade(true)
        end
        uiObject.ImgIconArrow.gameObject:SetActiveEx(slotType == XEnumConst.Theatre6.SlotType.Active and
            i < self._ActiveSlotMax)
        self.AreaGo[i] = uiObject.GameObject
        self.AreaData[i] = { slotType = slotType, position = pos }
        self:SetGridClick(uiObject, slotType)

        if not self._IsUseParamData and XTool.IsNumberValid(uiObject:GetSkillId()) and not uiObject:IsBaseSkill() then
            table.insert(pendingDragIndices, i)
        else
            uiObject:ClearDrag()
        end
    end
    for i = skillsCount + 1, #self.SkillGrids do
        self.SkillGrids[i]:ClearDrag()
        self.SkillGrids[i]:Close()
        self.AreaGo[i] = nil
        self.AreaData[i] = nil
    end
    if #pendingDragIndices > 0 then
        self._PendingDragInitIndices = pendingDragIndices
        self:_ScheduleApplyDrag(1)
    end
end

---对单个 grid 完成拖拽相关的初始化(仅由分帧调度回调调用)
function XUiPanelTheatre6CharacterAttrDetail:_ApplyDragForIndex(i)
    local grid = self.SkillGrids and self.SkillGrids[i]
    if not grid then return end
    if not XTool.IsNumberValid(grid:GetSkillId()) or grid:IsBaseSkill() then
        grid:ClearDrag()
        return
    end
    self:SetGridDrag(grid, self.AreaGo)
    self:_ApplyExternalAreasToGrid(grid)
end

---分帧调度:每帧处理 DRAG_INIT_BATCH 个 pending 索引
function XUiPanelTheatre6CharacterAttrDetail:_ScheduleApplyDrag(startIndex)
    self._PendingDragInitTimerId = XScheduleManager.ScheduleNextFrame(function()
        self._PendingDragInitTimerId = nil
        if XTool.UObjIsNil(self.GameObject) then
            self._PendingDragInitIndices = nil
            return
        end
        local indices = self._PendingDragInitIndices
        if not indices then return end
        local endIndex = math.min(startIndex + DRAG_INIT_BATCH - 1, #indices)
        for k = startIndex, endIndex do
            self:_ApplyDragForIndex(indices[k])
        end
        if endIndex < #indices then
            self:_ScheduleApplyDrag(endIndex + 1)
        else
            self._PendingDragInitIndices = nil
        end
    end)
end

function XUiPanelTheatre6CharacterAttrDetail:_CancelPendingDragInit()
    if self._PendingDragInitTimerId then
        XScheduleManager.UnSchedule(self._PendingDragInitTimerId)
        self._PendingDragInitTimerId = nil
    end
    self._PendingDragInitIndices = nil
end

function XUiPanelTheatre6CharacterAttrDetail:DispatchSkillEffects(addedIdsBySlot, upgradeIds)
    if not addedIdsBySlot and not upgradeIds then return end
    if not self.SkillGrids or not self._SkillsCount then return end
    for i = 1, self._SkillsCount do
        local grid = self.SkillGrids[i]
        if grid then
            if addedIdsBySlot then grid:TryTriggerTagEffect(addedIdsBySlot) end
            if upgradeIds then grid:TryShowUpgradeEffect(upgradeIds) end
        end
    end
end

---刷新已展示的装备技能格子的 tag 高亮(商店/任务源 tag 集合变化时调用)
function XUiPanelTheatre6CharacterAttrDetail:RefreshAllTagHighLight()
    if not self.SkillGrids or not self._SkillsCount then return end
    for i = 1, self._SkillsCount do
        local grid = self.SkillGrids[i]
        if grid then grid:RefreshTagHightLight() end
    end
end

---把已注册的外部拖拽区域追加到指定 grid 的目标区域中
function XUiPanelTheatre6CharacterAttrDetail:_ApplyExternalAreasToGrid(grid)
    if not self._ExternalAreas or not grid then
        return
    end
    local baseId = self._SkillsCount or 0
    for index, area in ipairs(self._ExternalAreas) do
        if area.areaGo and area.areaGo.transform then
            grid:AddDragTargetArea(area.areaGo.transform, baseId + index)
        end
    end
end

---运行中追加外部区域时,把新增区域注册到当前所有有效 grid
function XUiPanelTheatre6CharacterAttrDetail:_ApplyExternalAreasToCurrentGrids()
    if not self.SkillGrids or not self._SkillsCount then
        return
    end
    for i = 1, self._SkillsCount do
        local grid = self.SkillGrids[i]
        if grid and XTool.IsNumberValid(grid:GetSkillId()) and not grid:IsBaseSkill() then
            self:_ApplyExternalAreasToGrid(grid)
        end
    end
end

---@param grid XUiGridTheatre6SkillBag
function XUiPanelTheatre6CharacterAttrDetail:SetGridDrag(grid, area)
    local startCb = function()
        self:OnStartDrag(grid)
        self.ListRoleDetail.enabled = false
    end
    local endCb = function(id)
        self:OnEndDrag(grid, id)
        self.ListRoleDetail.enabled = true
    end
    local enterCb = function(id)
        return self:IsAreaAcceptSkill(grid, id)
    end
    if not self._Control:IsCurModeSettle() then
        grid:SetDragCb(area, self.Transform, startCb, endCb, enterCb, nil, self.ListRoleDetail)
    end
end

---判断目标区域是否能接受当前拖拽的技能（用于拖拽中切换 cloneUi 遮罩）
function XUiPanelTheatre6CharacterAttrDetail:IsAreaAcceptSkill(grid, areaId)
    local baseId = self._SkillsCount or 0
    if areaId > baseId then return true end
    local areaData = self.AreaData and self.AreaData[areaId]
    if not areaData then return true end
    local skillId = grid:GetSkillId()
    local canEquipSlots = self._Control:GetSkillInstallSlots(skillId)
    if not (canEquipSlots and table.contains(canEquipSlots, areaData.slotType)) then
        return false
    end
    --交换场景:被挤走的目标技能必须能装回源装备槽
    local srcSlotType = grid:GetGridData()
    local dstGrid = self.SkillGrids[areaId]
    local dstSkillId = dstGrid and dstGrid:GetSkillId()
    if srcSlotType and XTool.IsNumberValid(dstSkillId) and dstSkillId ~= skillId then
        local dstSlots = self._Control:GetSkillInstallSlots(dstSkillId)
        if not (dstSlots and table.contains(dstSlots, srcSlotType)) then
            return false
        end
    end
    return true
end

function XUiPanelTheatre6CharacterAttrDetail:SetGridClick(grid, slotType)
    grid:SetClickCb(function(skillId)
        if XTool.IsNumberValid(skillId) then
            self._Control:OpenSkillTip(skillId, grid.Transform,
                { SlotType = slotType, ReadOnly = self._IsUseParamData, IsBaseSkill = grid:IsBaseSkill() })
        end
    end)
end

--region 拖拽事件
function XUiPanelTheatre6CharacterAttrDetail:OnStartDrag(grid)
    local skillId = grid:GetSkillId()
    local canEquipSlots = self._Control:GetSkillInstallSlots(skillId)
    for key, posGrid in pairs(self.SkillGrids) do
        local slotType = posGrid:GetGridData()
        if canEquipSlots and table.contains(canEquipSlots, slotType) then
            posGrid:SetHighlightEffect(true, true, skillId)
        end
    end
    if self._ExternalAreas then
        for _, area in ipairs(self._ExternalAreas) do
            if area.dragStateCb then
                area.dragStateCb(true, skillId)
            end
        end
    end
end

function XUiPanelTheatre6CharacterAttrDetail:OnEndDrag(grid, targetAreaId)
    if self._ExternalAreas then
        for _, area in ipairs(self._ExternalAreas) do
            if area.dragStateCb then
                area.dragStateCb(false)
            end
        end
    end
    local skillId = grid:GetSkillId()
    if XTool.IsNumberValid(targetAreaId) then
        local baseId = self._SkillsCount or 0
        if targetAreaId > baseId then
            local external = self._ExternalAreas and self._ExternalAreas[targetAreaId - baseId]
            if external and external.endCb then
                external.endCb(skillId)
            end
        else
            local areaData = self.AreaData[targetAreaId]
            if not areaData then return end
            local canEquipSlots = self._Control:GetSkillInstallSlots(skillId)
            if not canEquipSlots or not table.contains(canEquipSlots, areaData.slotType) then
                XUiManager.TipText("Theatre6SkillMoveError")
                for key, posGrid in pairs(self.SkillGrids) do
                    posGrid:SetHighlightEffect(false)
                end
                return
            end
            local dstGrid = self.SkillGrids[targetAreaId]
            local dstSkillId = dstGrid and dstGrid:GetSkillId()
            local srcSlotType = grid:GetGridData()
            if srcSlotType and XTool.IsNumberValid(dstSkillId) and dstSkillId ~= skillId then
                local dstSlots = self._Control:GetSkillInstallSlots(dstSkillId)
                if not dstSlots or not table.contains(dstSlots, srcSlotType) then
                    XUiManager.TipText("Theatre6SkillMoveError")
                    for key, posGrid in pairs(self.SkillGrids) do
                        posGrid:SetHighlightEffect(false)
                    end
                    return
                end
            end
            --打开遮罩
            self._Control:SkillMoveOrSwapRequest(skillId, areaData.slotType, areaData.position, function()
            end)
        end
    end
    for key, posGrid in pairs(self.SkillGrids) do
        posGrid:SetHighlightEffect(false)
    end
end

--endregion

---转发外部拖拽区域注册到技能背包，支持 UiPanelSkill 懒创建时的 pending 注册
---@param areaGo UnityEngine.GameObject 区域 GameObject
---@param endCb function(skillId) 拖拽到此区域松手时的回调
---@param dragStateCb function(isDragging, skillId) 拖拽状态变化时回调
function XUiPanelTheatre6CharacterAttrDetail:AddExternalDragAreaToSkillBag(areaGo, endCb, dragStateCb)
    if not self._ExternalAreas then
        self._ExternalAreas = {}
    end
    table.insert(self._ExternalAreas, { areaGo = areaGo, endCb = endCb, dragStateCb = dragStateCb })
    self:_ApplyExternalAreasToCurrentGrids()
    if self.UiPanelSkill then
        self.UiPanelSkill:AddExternalDragArea(areaGo, endCb, dragStateCb)
    end
end

function XUiPanelTheatre6CharacterAttrDetail:_CloseChildNodesUnderListRoleDetail()
    if not self._ChildNodes or not self.ListRoleDetail then return end
    local listTrans = self.ListRoleDetail.transform
    for _, child in ipairs(self._ChildNodes) do
        if child.IsNodeShow and child:IsNodeShow() and child.Transform
            and child.Transform:IsChildOf(listTrans) then
            child:Close()
        end
    end
end

function XUiPanelTheatre6CharacterAttrDetail:ShowSkillBag()
    self._Control:ClearBagNewSkillViewed()
    self:UpdateReddot()
    self:_CloseChildNodesUnderListRoleDetail()
    self._IsDirty = true
    self.ListRoleDetail.gameObject:SetActiveEx(false)
    self.PanelSkillBag.gameObject:SetActiveEx(true)
    self.ImgBgScoreTop.gameObject:SetActiveEx(true)

    if not self.UiPanelSkill then
        self.UiPanelSkill = XUiPanelTheatre6SkilBagDetail.New(self.PanelSkill, self)
        self.UiPanelSkill:SetCloseCb(function()
            local scoreBottom = self._ScoreCorners[0].y
            local viewportTop = self._ViewportCorners[1].y
            self.ImgBgScoreTop.gameObject:SetActiveEx(scoreBottom > viewportTop)
            self.ListRoleDetail.gameObject:SetActiveEx(true)
            self.PanelSkillBag.gameObject:SetActiveEx(false)
            if self._IsDirty then
                self._IsDirty = false
                self:ShowSkill()
                self:ShowRelic()
                self:ShowBuff()
            end
        end)
        self.UiPanelSkill:Open()
        if self._ExternalAreas then
            for _, data in ipairs(self._ExternalAreas) do
                self.UiPanelSkill:AddExternalDragArea(data.areaGo, data.endCb, data.dragStateCb)
            end
        end
    end
    self.UiPanelSkill:Open()
end

function XUiPanelTheatre6CharacterAttrDetail:ShowRelic()
    ---@type XTheatre6AttrPackProtocol[]
    local attrPackDict
    if self._IsUseParamData then
        attrPackDict = self._ModelData.AttrPacks
    else
        attrPackDict = self._Control:GetCharacterAttrPacks()
    end
    self.RelicGrids = {}

    ---@type XTableTheatre6AttrPack[]
    local attrPacks = {}
    local attrPackNums = {}
    for _, data in pairs(attrPackDict) do
        local config = self._Control:GetAttrPackCfgById(data.PackId)
        if not config.IsHide then
            table.insert(attrPacks, config)
            attrPackNums[data.PackId] = data.Num
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
    local isEmpty = showCount == 0

    if self.ListRelic then
        self.ListRelic.gameObject:SetActiveEx(not isEmpty)
    end

    if not self._GridRelics then
        ---@type XUiGridTheatre6Relic[]
        self._GridRelics = {}
    end

    XUiHelper.RefreshCustomizedList(self.GridRelic.parent, self.GridRelic, showCount, function(i, go)
        local grid = self._GridRelics[i]
        if not grid then
            grid = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Relic").New(go, self)
            self._GridRelics[i] = grid
        else
            grid:Open()
        end
        local relicId = attrPacks[i].Id
        grid:SetRelic(relicId, attrPackNums[relicId])
        if i == showCount and extraCount > 0 then
            grid:ShowMore(extraCount)
        end
        grid:SetClickCb(function()
            local ids, counts = {}, {}
            for k, v in ipairs(attrPacks) do
                table.insert(ids, v.Id)
                table.insert(counts, attrPackNums[v.Id])
            end
            XLuaUiManager.Open("UiTheatre6PopupRelicDetail", ids, counts, self._IsUseParamData)
        end)
        self.RelicGrids[i] = grid
    end)
    self.TxtRelicEmpty.gameObject:SetActiveEx(isEmpty)
end

function XUiPanelTheatre6CharacterAttrDetail:ShowBuff()
    local isEmpty = #self._BuffDatas == 0
    self.TxtBuffEmpty.gameObject:SetActiveEx(isEmpty)

    local totalCount = #self._BuffDatas
    local showCount = math.min(self._MaxBuffCount, totalCount)
    local extraCount = totalCount - self._MaxBuffCount

    XUiHelper.RefreshCustomizedList(self.GridBuff.parent, self.GridBuff, showCount, function(i, go)
        ---@type XUiGridTheatre6Buff
        local grid = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Buff").New(go, self)
        if self._IsUseParamData then
            grid:Update(self._BuffDatas[i].BuffId)
            grid:SetFileSaveBuffs(self._ModelData.Buffs)
        else
            grid:UpdateByInfo(self._BuffDatas[i])
            grid:ShowRemainingTimes()
            grid:CheckShowBuffDisable()
        end
        grid:IsCanClick(true)
        if i == showCount and extraCount > 0 then
            grid:ShowMore(extraCount)
        end
    end)
end

--region 分数置顶
function XUiPanelTheatre6CharacterAttrDetail:InitScoreTopCheck()
    local Array = CS.System.Array
    local Vector3Type = typeof(CS.UnityEngine.Vector3)
    self.ImgBgScoreTop.gameObject:SetActiveEx(false)
    self._ViewportCorners = Array.CreateInstance(Vector3Type, 4)
    self._ScoreCorners = Array.CreateInstance(Vector3Type, 4)
end

function XUiPanelTheatre6CharacterAttrDetail:CheckScoreTopVisible()
    local viewport = self.ListRoleDetail.viewport
    viewport:GetWorldCorners(self._ViewportCorners)
    self.ImgBgScore:GetWorldCorners(self._ScoreCorners)

    local scoreBottom = self._ScoreCorners[0].y
    local viewportTop = self._ViewportCorners[1].y
    XScheduleManager.ScheduleNextFrame(function()
        if XTool.UObjIsNil(self.GameObject) then return end
        self.ImgBgScoreTop.gameObject:SetActiveEx(scoreBottom > viewportTop)
    end)
end

--endregion

function XUiPanelTheatre6CharacterAttrDetail:OnBtnAttributeClick()
    if self.Parent.OpenAttrBubble then
        self.Parent:OpenAttrBubble(self._AttrIds)
    else
        XLuaUiManager.Open("UiTheatre6BubbleAttributeDetail", self._AttrIds, self.BtnAttribute.transform)
    end
end

function XUiPanelTheatre6CharacterAttrDetail:OnDestroy()
    self:_CancelPendingDragInit()
    self.ListRoleDetail.onValueChanged:RemoveListener(self._OnScrollCb)
    self._OnScrollCb = nil
    self.SkillGrids = nil
    self.AreaGo = nil
    self.AreaData = nil
    self.RelicGrids = nil
end

function XUiPanelTheatre6CharacterAttrDetail:ClearSkillNewFlag()
    for _, v in pairs(self.SkillGrids) do
        v:ClearNewFlag()
    end
end

function XUiPanelTheatre6CharacterAttrDetail:HideBtnBackpack()
    self.BtnBackpack.gameObject:SetActiveEx(false)
end

return XUiPanelTheatre6CharacterAttrDetail
