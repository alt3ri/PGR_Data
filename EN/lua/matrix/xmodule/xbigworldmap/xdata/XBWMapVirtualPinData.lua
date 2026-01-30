local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")

---@class XBWMapVirtualPinData : XBWMapPinData
local XBWMapVirtualPinData = XClass(XBWMapPinData, "XBWMapVirtualPinData")

---@param pinData XBWMapPinData
function XBWMapVirtualPinData:UpdateData(pinId, bindLevelId, bindPinId, pinData)
    self.QuestId = pinData.QuestId
    self.ReferPinId = pinData.PinId
    self.BindPinId = bindPinId
    self.BindLevelId = bindLevelId
    self.ForceDisplay = pinData.ForceDisplay
    self.QuestObjectiveId = pinData.QuestObjectiveId or 0
    self.TargetSceneObjectPlaceId = pinData.TargetSceneObjectPlaceId or 0
    self.TargetNpcPlaceId = pinData.TargetNpcPlaceId or 0
    self.NearbyPinId = bindPinId
    self.Super.UpdateData(self, pinData.WorldId, pinData.LevelId, {
        Id = pinId,
        StyleId = pinData.StyleId,
        ActivityId = pinData.ActivityId,
        MapAreaGroupId = pinData.MapAreaGroupId,
        WorldPosition = pinData.WorldPosition,
        TeleportLevelId = pinData.TeleportLevelId,
        TeleportEnable = pinData.TeleportEnable,
        TeleportPosition = pinData.TeleportPosition,
        TeleportEulerAngleY = pinData.TeleportEulerAngleY,
        SceneObjectPlaceId = pinData.SceneObjectPlaceId,
        NpcPlaceId = pinData.NpcPlaceId,
        ConditionId = pinData.ConditionId,
    }, {
        Name = pinData.Name,
        Desc = pinData.Desc,
    })
end

return XBWMapVirtualPinData
