local XUiBigWorldMapPinTag = require("XUi/XUiBigWorld/XMap/XUiBigWorldMapPinTag")

---@class XUiBigWorldMapPin : XUiNode
---@field BtnPin XUiComponent.XUiButton
---@field PanelTagList UnityEngine.RectTransform
---@field TagNode UnityEngine.RectTransform
---@field UpUp UnityEngine.RectTransform
---@field UpDown UnityEngine.RectTransform
---@field FloorOn UnityEngine.RectTransform
---@field FloorOff UnityEngine.RectTransform
---@field BtnSelect XUiComponent.XUiButton
---@field CanvasGroup UnityEngine.CanvasGroup
---@field _Target UnityEngine.RectTransform
---@field Parent XUiBigWorldMap
local XUiBigWorldMapPin = XClass(XUiNode, "XUiBigWorldMapPin")

function XUiBigWorldMapPin:OnStart(target, targetParent, isAssistedPosition)
    ---@type XBWMapPinData
    self._PinData = false
    self._LevelId = 0
    self._IsAssistedPosition = isAssistedPosition or false
    self._IsPlayerTagActive = false

    self._CurrentSelectTagId = 0

    ---@type table<number, XUiBigWorldMapPinTag>
    self._TagMap = {}
    ---@type XUiBigWorldMapPinTag[]
    self._TagList = {}

    ---@type XUiBigWorldMapPinTag
    self._PlayerTag = XUiBigWorldMapPinTag.New(self.TagNode, self, true)
    self._PlayerTag:Close()

    ---@type XBWMapInterfaceBase
    self._Interface = false

    self._AreaGroupType = XMVCA.XBigWorldMap.AreaGroupType.Vertical

    self._TargetPrefab = target
    self._TargetPrefabParent = targetParent
    self:_RegisterButtonClick()
    self:_InitUi()
end

function XUiBigWorldMapPin:OnBtnPinClick()
    if self._PinData and XTool.IsNumberValid(self._LevelId) then
        if not self._PinData.IsInteract then
            return
        end

        local axisConversion = self._Interface:GetAxisConversion()
        local mousePosition = axisConversion:UIToScreenPosition2D(self.Transform)
        local pinDatas = self:_GetNearPinDatas(mousePosition)

        if XTool.IsTableEmpty(pinDatas) or #pinDatas <= 1 then
            self:AnchorToAndSelect()
        else
            self:AnchorTo(true)
            self._Interface:OpenPinSelectList(pinDatas, self.Transform)
        end
    end
end

function XUiBigWorldMapPin:OnBtnSelectClick()
    if self._PinData and XTool.IsNumberValid(self._LevelId) then
        local mousePosition = CS.UnityEngine.Input.mousePosition
        local pinDatas = self:_GetNearPinDatas(mousePosition)

        self._Interface:OpenPinSelectList(pinDatas, self.Transform)
    end
end

function XUiBigWorldMapPin:SetRangeSelectable(isSelect)
    self.BtnSelect.gameObject:SetActiveEx(isSelect)
end

function XUiBigWorldMapPin:SetSelect(isSelect)
    if isSelect then
        self.BtnPin:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnPin:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldMapPin:SetPlayerTagActive(isActive)
    self._IsPlayerTagActive = isActive
    self:_SetPlayerTagActive(isActive)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:SetPinData(levelId, pinData)
    self._LevelId = levelId or 0
    self._PinData = pinData
    self._AreaGroupType = XMVCA.XBigWorldMap:GetMapAreaGroupTypeByLevelId(levelId)
end

function XUiBigWorldMapPin:SetInterface(interface)
    if interface then
        self._Interface = interface
    end
end

function XUiBigWorldMapPin:SetShow(isShow)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = isShow and 1 or 0
        self.CanvasGroup.blocksRaycasts = isShow or false
        self.CanvasGroup.interactable = isShow or false
    end
end

function XUiBigWorldMapPin:SelectTag(pinId)
    self:CancelSelectTag()
    self:_SetTagSelect(pinId, true)
    self._CurrentSelectTagId = pinId
end

function XUiBigWorldMapPin:CancelSelectTag()
    if XTool.IsNumberValid(self._CurrentSelectTagId) then
        self:_SetTagSelect(self._CurrentSelectTagId, false)
        self._CurrentSelectTagId = 0
    end
end

function XUiBigWorldMapPin:AnchorTo(isCenter, isIgnoreTween)
    if not XTool.UObjIsNil(self._Target) then
        local posX = self._Target.transform.position.x
        local posY = self._Target.transform.position.y

        self._Interface:AnchorToPosition(posX, posY, isCenter, isIgnoreTween)
    end
end

function XUiBigWorldMapPin:AnchorToAndSelect(isIgnoreTween)
    self:SetSelect(true)
    self._Interface:OpenPinDetail(self, self._LevelId, self._PinData)
    self:AnchorTo(false, isIgnoreTween)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:AnchorToAndSelectTag(pinData, isIgnoreTween)
    if not pinData.IsInteract then
        return
    end

    self:AnchorTo(false, isIgnoreTween)
    self:SelectTag(pinData.PinId)
    self._Interface:OpenTagPinDetail(self, pinData.LevelId, pinData)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:Refresh(levelId, pinData, interface)
    if XTool.UObjIsNil(self.GameObject) then
        XLog.Warning("XUiBigWorldMapPin:Refresh self.GameObject is nil")
        return
    end
    self:SetPinData(levelId, pinData)
    self:SetInterface(interface)
    self:_InitTarget()
    self:RefreshStyle(pinData)
    self:_RefreshPosition(pinData)
    self:_RefreshTag(pinData)
end

function XUiBigWorldMapPin:RefreshOriginalPosition()
    if self._PinData then
        self:_RefreshPosition(self._PinData)
    end
end

function XUiBigWorldMapPin:RefreshPosition(x, y)
    if XTool.UObjIsNil(self._Target) then return end
    self._Target:SetAnchoredPosition(x, y)
end

function XUiBigWorldMapPin:RefreshOriginalStyle()
    if self._PinData then
        self:RefreshStyle(self._PinData)
        self:_RefreshTag(self._PinData)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:RefreshStyle(pinData)
    local icon = XMVCA.XBigWorldMap:GetPinIconByStyleId(pinData.StyleId, pinData:IsActive())

    if not string.IsNilOrEmpty(icon) then
        self.BtnPin:SetSprite(icon)
    else
        XLog.Error("Pin Icon is INVALID! PinId = " .. tostring(pinData.PinId) .. ", LevelId = " .. tostring(pinData.LevelId) .. ", NpcPlaceId = " .. tostring(pinData.NpcPlaceId) .. ", SceneObjectId = " .. tostring(pinData.SceneObjectPlaceId))
    end

    self:RefreshFloor(pinData, self._Interface:GetCurrentSelectFloorIndex())
    self.BtnPin:ShowTag(pinData:IsTracking())
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:RefreshFloor(pinData, currentIndex)
    local groupId = pinData:GetAreaGroupId(self._IsAssistedPosition)
    local isVertical = self._AreaGroupType == XMVCA.XBigWorldMap.AreaGroupType.Vertical

    --- 跨关卡追踪图钉特殊处理
    if pinData:IsVirtual() then
        local bindPinId = pinData.BindPinId
        local levelId = pinData:GetValidLevelId()
        local bindPinData = XMVCA.XBigWorldMap:GetPinDataByLevelIdAndPinId(levelId, bindPinId)

        if bindPinData then
            groupId = bindPinData:GetAreaGroupId(self._IsAssistedPosition)
        end
    end

    local groupIndex = XMVCA.XBigWorldMap:GetFloorIndexByGroupId(groupId)
    local isActive = pinData:IsActive()

    self.UpUp.gameObject:SetActiveEx(groupIndex > currentIndex and isVertical)
    self.UpDown.gameObject:SetActiveEx(groupIndex < currentIndex and isVertical)
    if self.FloorOn then
        self.FloorOn.gameObject:SetActiveEx(groupIndex ~= currentIndex and not isVertical and isActive)
    end
    if self.FloorOff then
        self.FloorOff.gameObject:SetActiveEx(groupIndex ~= currentIndex and not isVertical and not isActive)
    end
end

function XUiBigWorldMapPin:RefreshEmptyTag()
    self._TagMap = {}

    for _, tagNode in pairs(self._TagList) do
        tagNode:Close()
    end
end

---@return XBWMapPinData
function XUiBigWorldMapPin:GetPinData()
    return self._PinData
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:_RefreshPosition(pinData)
    if not XTool.UObjIsNil(self._Target) then
        local worldPosition = pinData:GetWorldPosition(self._IsAssistedPosition)
        local axisConversion = self._Interface:GetAxisConversion()
        local x, y = axisConversion:WorldToMapPosition2D(worldPosition.x, worldPosition.z)
        self:RefreshPosition(x, y)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:_RefreshTag(pinData)
    local pinDatas = XMVCA.XBigWorldMap:GetPinDatasByBindId(pinData.PinId, true)
    local index = 1

    self._TagMap = {}
    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            if pinData:IsDisplaying() then
                local tagNode = self._TagList[index]

                if not tagNode then
                    local tag = XUiHelper.Instantiate(self.TagNode, self.PanelTagList)

                    tagNode = XUiBigWorldMapPinTag.New(tag, self)
                    self._TagList[index] = tagNode
                end

                index = index + 1
                tagNode:Open()
                tagNode:Refresh(pinData)
                self._TagMap[pinData.PinId] = tagNode
            end
        end
    end
    for i = index, #self._TagList do
        self._TagList[i]:Close()
    end
end

function XUiBigWorldMapPin:_SetTagSelect(pinId, isSelect)
    local tagNode = self._TagMap[pinId]

    if tagNode then
        tagNode:SetSelect(isSelect)
    end
end

function XUiBigWorldMapPin:_SetTagActive(isActive)
    if self._TagMap then
        self.PanelTagList.gameObject:SetActiveEx(isActive)
        for _, tagNode in pairs(self._TagMap) do
            if isActive then
                tagNode:Open()
            else
                tagNode:Close()
            end
        end
    end
end

function XUiBigWorldMapPin:_SetPlayerTagActive(isActive)
    if isActive then
        self._PlayerTag:Open()
    else
        self._PlayerTag:Close()
    end
end

function XUiBigWorldMapPin:_GetNearPinDatas(mousePosition)
    local axisConversion = self._Interface:GetAxisConversion()
    local pinDatas = axisConversion:FilterScreenPointNearPinDataList(mousePosition, self._Interface:GetPinNodeMap(),
        self._Interface:GetCurrentSelectGroupId())
    local tagPinNode = self._TagMap
    local result = {}

    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            table.insert(result, pinData)
        end
    end
    if not XTool.IsTableEmpty(tagPinNode) then
        for _, tagNode in pairs(tagPinNode) do
            table.insert(result, tagNode:GetPinData())
        end
    end

    return result
end

function XUiBigWorldMapPin:_InitUi()
    self.BtnSelect.gameObject:SetActiveEx(false)
end

function XUiBigWorldMapPin:_InitTransformBind()
    if XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind = self.GameObject:AddComponent(typeof(CS.XTransformBind))
    end
end

function XUiBigWorldMapPin:_InitTarget()
    self:_InitTransformBind()

    -- 小地图的data和绑定数据可能不一致
    self._Target = self.Parent:GetOrCreateTarget(self._PinData.PinId, self._TargetPrefab, self._TargetPrefabParent)
    -- if XTool.UObjIsNil(self._Target) then
    --     self._Target = self.Parent:GetOrCreateTarget(self._PinData.PinId, self._TargetPrefab, self._TargetPrefabParent)
    --     self._Target.name = self._PinData.PinId .. " " .. self._PinData.Name
    -- end
    if not XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind:SetTarget(self._Target)
    end
end

function XUiBigWorldMapPin:_RegisterButtonClick()
    self.BtnPin:AddEventListener(handler(self, self.OnBtnPinClick))
    self.BtnSelect:AddEventListener(handler(self, self.OnBtnSelectClick))
end

return XUiBigWorldMapPin
