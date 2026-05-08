---@class XUiPanelTheatre6SkilBagDetail : XUiNode 技能背包详情面板
---@field _Control XTheatre6Control
---@field PanelUsing UiObject
---@field PanelBag UiObject
---@field BtnClose XUiComponent.XUiButton
local XUiPanelTheatre6SkilBagDetail = XClass(XUiNode, "XUiPanelTheatre6SkilBagDetail")
local XUiBagGrid = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6SkillBag")
local slotTypes = XEnumConst.Theatre6.SlotType
local slotTypeInitOrder = {
    slotTypes.Active,
    slotTypes.Insert,
    slotTypes.Special,
    slotTypes.Bag,
}
function XUiPanelTheatre6SkilBagDetail:OnStart()
    self:InitComponents()
end

function XUiPanelTheatre6SkilBagDetail:OnEnable()
    self:Refresh()
end

function XUiPanelTheatre6SkilBagDetail:InitComponents()
    if self.BtnClose then
        self.BtnClose:AddEventListener(handler(self, self.OnClickClose))
    end
    self.UsingSkillUi = {}
    self.BagSkillUi = {}
    XTool.InitUiObjectByUi(self.UsingSkillUi, self.PanelUsing)
    XTool.InitUiObjectByUi(self.BagSkillUi, self.PanelBag)
    self.UsingSkillUi.GridSkillUsing.gameObject:SetActiveEx(false)
    self.BagSkillUi.GridSkillBag.gameObject:SetActiveEx(false)
    self:CreateSkillGrid()
end

function XUiPanelTheatre6SkilBagDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_UPDATE_SKILL,
        XEventId.EVENT_THEATRE6_BUY_GOOD,
        XEventId.EVENT_THEATRE6_SKILL_BUBBLE_CLOSE,
        XEventId.EVENT_THEATRE6_SHOP_REFRESH,
    }
end

function XUiPanelTheatre6SkilBagDetail:OnNotify(evt, ...)
    if  evt == XEventId.EVENT_THEATRE6_BUY_GOOD or evt == XEventId.EVENT_THEATRE6_SHOP_REFRESH then
        self:Refresh()
    end
    if evt == XEventId.EVENT_THEATRE6_SKILL_BUBBLE_CLOSE then
        self:ClearCurrentSelect()
    end
    if evt == XEventId.EVENT_THEATRE6_UPDATE_SKILL then
        local addedIdsBySlot, upgradeIds = ...
        self:Refresh()
        self:DispatchSkillEffects(addedIdsBySlot, upgradeIds)
    end
end


function XUiPanelTheatre6SkilBagDetail:ShowSkillBag()
    self.PanelUsing.gameObject:SetActiveEx(false)
    self.PanelBag.gameObject:SetActiveEx(true)
end

function XUiPanelTheatre6SkilBagDetail:Refresh()
    self:ClearCurrentSelect()
    self._BagSkillIds = self._Control:GetCharacterSkillBagIds()
    local bagSkillCount = XTool.GetTableCount(self._BagSkillIds)
    local bagSlotMaxLimit = self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Bag)
    if self.BagSkillUi.FullBg then
        self.BagSkillUi.FullBg.gameObject:SetActiveEx(bagSkillCount == bagSlotMaxLimit)
    end

    self.BagSkillUi.TxtMaxCount.text = "/" .. bagSlotMaxLimit
    self.BagSkillUi.TxtCurCount.text = bagSkillCount
    self:RefreshSkillBagGrids()
    self:RefreshUsingSkillGrids()
end

function XUiPanelTheatre6SkilBagDetail:RefreshSkillBagGrids()
    local isInShop = self.Parent and self.Parent._IsInShop
    local taskUpgradeIds = self.Parent and self.Parent._TaskUpgradeSkillIds
    for index = 1, self._Control:GetSlotMaxLimit(XEnumConst.Theatre6.SlotType.Bag) do
        local skillId = self._Control:GetCharacterSkillBagIds()[index]
        self.SkillGrids[slotTypes.Bag][index]:ClearData()
        self.SkillGrids[slotTypes.Bag][index]:Refresh(index, slotTypes.Bag, skillId)
        if isInShop and XTool.IsNumberValid(skillId) then
            self.SkillGrids[slotTypes.Bag][index]:CanUpgrade(self._Control:CharacterHasCanUpGradeSkills(skillId))
        end
        if taskUpgradeIds and XTool.IsNumberValid(skillId) and taskUpgradeIds[skillId] then
            self.SkillGrids[slotTypes.Bag][index]:CanUpgrade(true)
        end
        self:InitGridClick(self.SkillGrids[slotTypes.Bag][index], slotTypes.Bag)
        if XTool.IsNumberValid(skillId) then
            self:InitGridDrag(self.SkillGrids[slotTypes.Bag][index])
        end
    end
end

function XUiPanelTheatre6SkilBagDetail:RefreshUsingSkillGrids()
    local isInShop = self.Parent and self.Parent._IsInShop
    local taskUpgradeIds = self.Parent and self.Parent._TaskUpgradeSkillIds
    for slotType, grid in pairs(self.SkillGrids) do
        if slotType == XEnumConst.Theatre6.SlotType.Bag then
            goto continue
        end
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            grid[index]:ClearData()
            local skillId = self._Control:GetCharacterDressSkillIds(slotType)[index]
            grid[index]:Refresh(index, slotType, skillId)
            if isInShop and XTool.IsNumberValid(skillId) then
                grid[index]:CanUpgrade(self._Control:CharacterHasCanUpGradeSkills(skillId))
            end
            if taskUpgradeIds and XTool.IsNumberValid(skillId) and taskUpgradeIds[skillId] then
                grid[index]:CanUpgrade(true)
            end
            self:InitGridClick(grid[index], slotType)
            if XTool.IsNumberValid(skillId) then
                self:InitGridDrag(grid[index])
            end
        end
        ::continue::
    end
end

function XUiPanelTheatre6SkilBagDetail:DispatchSkillEffects(addedIdsBySlot, upgradeIds)
    if not addedIdsBySlot and not upgradeIds then return end
    for _, slotType in ipairs({ slotTypes.Active, slotTypes.Insert, slotTypes.Special, slotTypes.Bag }) do
        for _, grid in pairs(self.SkillGrids[slotType] or {}) do
            if addedIdsBySlot then grid:TryShowTagEffect(addedIdsBySlot) end
            if upgradeIds then grid:TryShowUpgradeEffect(upgradeIds) end
        end
    end
end

function XUiPanelTheatre6SkilBagDetail:CreateSkillGrid()
    self.SkillGridsParentChildPairs = {
        [slotTypes.Active] = { self.UsingSkillUi.GridSkillUsing.transform.parent, self.UsingSkillUi.GridSkillUsing },
        [slotTypes.Insert] = { self.UsingSkillUi.GridSkillUsing.transform.parent, self.UsingSkillUi.GridSkillUsing },
        [slotTypes.Special] = { self.UsingSkillUi.GridSkillUsing.transform.parent, self.UsingSkillUi.GridSkillUsing },
        [slotTypes.Bag] = { self.BagSkillUi.GridSkillBag.transform.parent, self.BagSkillUi.GridSkillBag },
    }
    self.SkillGrids = {
        [slotTypes.Active] = {},
        [slotTypes.Insert] = {},
        [slotTypes.Special] = {},
        [slotTypes.Bag] = {},
    }

    for _, slotType in ipairs(slotTypeInitOrder) do
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            local go = XUiHelper.Instantiate(self.SkillGridsParentChildPairs[slotType][2],
                self.SkillGridsParentChildPairs[slotType][1])
            self.SkillGrids[slotType][index] = XUiBagGrid.New(go, self)
            self.SkillGrids[slotType][index]:Open()
        end
    end

    self.AllAreaGo = {}
    self.AllAreaData = {}
    for _, slotType in ipairs(slotTypeInitOrder) do
        for index = 1, self._Control:GetSlotMaxLimit(slotType) do
            local grid = self.SkillGrids[slotType][index]
            table.insert(self.AllAreaGo, grid.GameObject)
            table.insert(self.AllAreaData, { slotType = slotType, position = index })
        end
    end
end

function XUiPanelTheatre6SkilBagDetail:SetCloseCb(closeCb)
    self.CloseCb = closeCb
end

function XUiPanelTheatre6SkilBagDetail:OnClickClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

--region 交互事件

function XUiPanelTheatre6SkilBagDetail:SetGridClickCb(slotType, cb)
    if not self._GridClickCb then
        self._GridClickCb = {}
    end
    self._GridClickCb[slotType] = cb
end

--region 拖拽事件
function XUiPanelTheatre6SkilBagDetail:InitGridDrag(grid)
    local startCb = function()
        self:OnStartDrag(grid)
    end
    local endCb = function(id)
        self:OnEndDrag(grid, id)
    end
    grid:SetDragCb(self.AllAreaGo, self.Transform, startCb, endCb)
end

function XUiPanelTheatre6SkilBagDetail:OnStartDrag(grid)
    local curSkillId = grid:GetSkillId()
    local canEquipType = self._Control:GetSkillInstallSlots(curSkillId)
    for slotType, grids in pairs(self.SkillGrids) do
        if table.contains(canEquipType, slotType) or slotType == XEnumConst.Theatre6.SlotType.Bag then
            for _, posGrid in pairs(grids) do
                posGrid:SetHighlightEffect(true)
            end
        end
    end
    for _, areaData in ipairs(self.AllAreaData) do
        if areaData.dragStateCb then
            areaData.dragStateCb(true, curSkillId)
        end
    end
end

function XUiPanelTheatre6SkilBagDetail:OnEndDrag(grid, targetAreaId)
    for _, areaData in ipairs(self.AllAreaData) do
        if areaData.dragStateCb then
            areaData.dragStateCb(false)
        end
    end
    local curSkillId = grid:GetSkillId()
    local canEquipType = self._Control:GetSkillInstallSlots(curSkillId)
    if XTool.IsNumberValid(targetAreaId) then
        local areaData = self.AllAreaData[targetAreaId]
        if areaData and areaData.externalCb then
            areaData.externalCb(grid:GetSkillId())
        elseif areaData ~= nil then
            if table.contains(canEquipType, areaData.slotType) or areaData.slotType == XEnumConst.Theatre6.SlotType.Bag then
                XLuaUiManager.SetMask(true)
                self._Control:SkillMoveOrSwapRequest(grid:GetSkillId(), areaData.slotType, areaData.position, function()
                    XLuaUiManager.SetMask(false)
                end)
            end
        end
    end
    for slotType, grids in pairs(self.SkillGrids) do
        for _, posGrid in pairs(grids) do
            posGrid:SetHighlightEffect(false)
        end
    end
end

---注册外部拖拽目标区域
---@param areaGo UnityEngine.GameObject 区域 GameObject
---@param endCb function(skillId) 拖拽到此区域松手时的回调
---@param dragStateCb function(isDragging, skillId) 拖拽状态变化时回调，isDragging=true 表示开始，false 表示结束
function XUiPanelTheatre6SkilBagDetail:AddExternalDragArea(areaGo, endCb, dragStateCb)
    table.insert(self.AllAreaGo, areaGo)
    table.insert(self.AllAreaData, { externalCb = endCb, dragStateCb = dragStateCb })
    local areaId = #self.AllAreaGo
    for _, slotType in ipairs(slotTypeInitOrder) do
        for _, grid in pairs(self.SkillGrids[slotType]) do
            grid:AddDragTargetArea(areaGo.transform, areaId)
        end
    end
end

--endregion

--选中逻辑
function XUiPanelTheatre6SkilBagDetail:InitGridClick(uiGrid, slotType)
    uiGrid:SetClickCb(function(skillId,slotType, pos)
        self:ClickGrid(skillId,slotType, pos)
        if self._GridClickCb and self._GridClickCb[slotType] then
            self._GridClickCb[slotType](skillId,slotType, pos,uiGrid:IsBaseSkill())
            return
        end
        self._Control:OpenSkillTip(skillId, uiGrid.Transform, { SlotType = slotType, ReadOnly = false,IsBaseSkill = uiGrid:IsBaseSkill() }) --默认为点击打开详情
    end)
end

function XUiPanelTheatre6SkilBagDetail:ClearCurrentSelect()
    if self._CurrentGrid then
        self._CurrentGrid:SetButtonSelect(false)
        self._CurrentGrid = nil
    end
end

--ui选中表现
function XUiPanelTheatre6SkilBagDetail:ClickGrid(skillId,slotType, pos)
    if not XTool.IsNumberValid(skillId) then
        return
    end
    if not self.SkillGrids[slotType][pos] then
        return
    end
    if self.SkillGrids[slotType][pos]:IsDisable() then
        return
    end
    self:ClearCurrentSelect()
    for _, grid in pairs(self.SkillGrids[slotType]) do
        if grid:GetSkillId() == skillId then
            self._CurrentGrid = grid
            self._CurrentGrid:SetButtonSelect(true)
            return
        end
    end
end

--设置技能格子禁用
function XUiPanelTheatre6SkilBagDetail:SetGridDisable(conditionFunc)
    for slotType, grids in pairs(self.SkillGrids) do
        for index = 1, #grids do
            local skillId = grids[index]:GetSkillId()
            local isBaseSkill = grids[index]:IsBaseSkill()
            if not XTool.IsNumberValid(skillId) or isBaseSkill == true then
               grids[index]:SetDisable(true)
               goto continue
            end
            grids[index]:SetDisable(conditionFunc(skillId))
     
        ::continue::
        end
    end
end

--endregion
return XUiPanelTheatre6SkilBagDetail
