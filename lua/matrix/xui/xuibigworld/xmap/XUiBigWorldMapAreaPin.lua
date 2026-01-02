
---@class XUiBigWorldMapAreaPin : XUiNode
---@field Parent XUiBigWorldMap
local XUiBigWorldMapAreaPin = XClass(XUiNode, "XUiBigWorldMapAreaPin")

function XUiBigWorldMapAreaPin:OnStart(target, targetParent, isAssistedPosition)
    self._TargetPrefab = target
    self._TargetPrefabParent = targetParent
end

function XUiBigWorldMapAreaPin:OnDisable()
    if self._TransformBind then
        self._TransformBind:SetTarget(nil)
    end
    self._Target = nil
end

function XUiBigWorldMapAreaPin:Refresh(levelId, pinData, interface)
    self:SetPinData(levelId, pinData)
    self:SetInterface(interface)
    self:_InitTarget()
    self:RefreshStyle(pinData)
    self:RefreshSize(pinData)
    self:_RefreshPosition(pinData)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapAreaPin:RefreshStyle(pinData)
    local strColor = XMVCA.XBigWorldMap:GetBigWorldMapPinStyleAreaColorByStyleId(pinData.StyleId)
    if not string.IsNilOrEmpty(strColor) then
        self.ImgArea.color = XUiHelper.Hexcolor2Color(strColor)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapAreaPin:RefreshSize(pinData)
    local radius = pinData.Radius
    if radius > 0 then
        local size = self.Parent:GetAxisConversion():GetPixelDisByWorldDis(radius * 2)
        self.ImgArea.transform.sizeDelta = Vector2(size, size)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapAreaPin:SetPinData(levelId, pinData)
    self._LevelId = levelId or 0
    self._PinData = pinData
end

---@param interface XBWBigMapInterface
function XUiBigWorldMapAreaPin:SetInterface(interface)
    self._Interface = interface
end

function XUiBigWorldMapAreaPin:AnchorTo(isCenter, isIgnoreTween)
    if not XTool.UObjIsNil(self._Target) then
        local posX = self._Target.transform.position.x
        local posY = self._Target.transform.position.y

        self._Interface:AnchorToPosition(posX, posY, isCenter, isIgnoreTween)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapAreaPin:_RefreshPosition(pinData)
    if not XTool.UObjIsNil(self._Target) then
        local worldPosition = pinData:GetWorldPosition(self._IsAssistedPosition)
        local axisConversion = self._Interface:GetAxisConversion()
        local x, y = axisConversion:WorldToMapPosition2D(worldPosition.x, worldPosition.z)
        self:RefreshPosition(x, y)
    end
end


function XUiBigWorldMapAreaPin:RefreshPosition(x, y)
    if XTool.UObjIsNil(self._Target) then return end
    self._Target:SetAnchoredPosition(x, y)
end

function XUiBigWorldMapAreaPin:_InitTransformBind()
    if XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind = self.GameObject:AddComponent(typeof(CS.XTransformBind))
    end
end

function XUiBigWorldMapAreaPin:_InitTarget()
    self:_InitTransformBind()

    if XTool.UObjIsNil(self._Target) then
        self._Target = self.Parent:GetOrCreateTarget(self._PinData.PinId, self._TargetPrefab, self._TargetPrefabParent)
    end
    if not XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind:SetTarget(self._Target)
        self._TransformBind.IsBindScale = true
    end
end

return XUiBigWorldMapAreaPin