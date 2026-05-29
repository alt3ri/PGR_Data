---@class XUiBigWorldMapTrackPin : XUiNode
---@field ImgPin UnityEngine.UI.Image
---@field BtnAnchor XUiComponent.XUiButton
---@field ImgPlayer UnityEngine.UI.Image
---@field Pointer UnityEngine.RectTransform
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapTrackPin = XClass(XUiNode, "XUiBigWorldMapTrackPin")

function XUiBigWorldMapTrackPin:OnStart()
    self._LevelId = 0
    self._PinId = 0

    self.ImgPlayer.gameObject:SetActiveEx(false)
    self.ImgPin.gameObject:SetActiveEx(true)
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapTrackPin:OnBtnAnchorClick()
    if XTool.IsNumberValid(self._PinId) then
        self.Parent:AnchorToPin(self._PinId)
    end
end

function XUiBigWorldMapTrackPin:Refresh(levelId, pinId)
    self._LevelId = levelId
    self._PinId = pinId

    self:_RefreshPin(self._Control:GetPinDataByLevelIdAndPinId(levelId, pinId))
end

function XUiBigWorldMapTrackPin:SetPosition(position, direction, angle, rect)
    local axisConversion = self.Parent:GetAxisConversion()
    local width = self.Transform.rect.width
    local height = self.Transform.rect.height
    local xAxis = (rect.width * 0.95) / 2
    local yAxis = (rect.height * 0.7) / 2
    local x = position.x - width / 2 * direction.x
    local y = position.y - height / 2 * direction.y

    local posX, posY = axisConversion:ConstrainingPointWithinEllipse(x, y, xAxis, yAxis)
    self.Transform:SetAnchoredPosition(posX, posY)
    self.Pointer:SetEulerRotation(0, 0, angle)
end

function XUiBigWorldMapTrackPin:SetSiblingIndex(index)
    self.Transform:SetSiblingIndex(index)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapTrackPin:_RefreshPin(pinData)
    if pinData then
        local icon = self._Control:GetPinIconByStyleId(pinData.StyleId, pinData:IsActive())

        if not string.IsNilOrEmpty(icon) then
            self.ImgPin:SetSprite(icon)
        else
            XLog.Error("Pin Icon is INVALID! PinId = " .. tostring(pinData.PinId) .. ", LevelId = " .. tostring(pinData.LevelId) .. ", NpcPlaceId = " .. tostring(pinData.NpcPlaceId) .. ", SceneObjectId = " .. tostring(pinData.SceneObjectPlaceId))
        end
    end
end

function XUiBigWorldMapTrackPin:_RegisterButtonClicks()
    self.BtnAnchor:AddEventListener(handler(self, self.OnBtnAnchorClick))
end

return XUiBigWorldMapTrackPin
