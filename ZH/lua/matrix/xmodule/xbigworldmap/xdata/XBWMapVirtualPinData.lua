local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")

---@class XBWMapVirtualPinData : XBWMapPinData
local XBWMapVirtualPinData = XClass(XBWMapPinData, "XBWMapVirtualPinData")

---@param pinData XBWMapPinData
function XBWMapVirtualPinData:UpdateData(pinId, bindLevelId, bindPinId, pinData)
    self.QuestId = pinData.QuestId
    self.QuestState = pinData.QuestState
    self.ReferPinId = pinData.PinId
    self.BindPinId = bindPinId
    self.BindLevelId = bindLevelId
    self.QuestObjectiveId = pinData.QuestObjectiveId or 0
    self.IsOptionalQuestObjective = pinData.IsOptionalQuestObjective
    self.TargetSceneObjectPlaceId = pinData.TargetSceneObjectPlaceId or 0
    self.TargetNpcPlaceId = pinData.TargetNpcPlaceId or 0
    self.NearbyPinId = bindPinId
    self:UpdateDisplay(pinData.Active or pinData.IsDisplay or false)
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
        CanInteract = pinData.IsInteract,
    }, {
        Name = pinData.Name,
        Desc = pinData.Desc,
    })
end

function XBWMapVirtualPinData:UpdateOther()
    self.Super.UpdateOther(self)

    if not self:IsQuest() then
        return
    end

    local questType = XMVCA.XBigWorldQuest:GetQuestTypeByQuestId(self.QuestId)

    if self.QuestState == XMVCA.XBigWorldQuest.QuestState.Ready then
        self.StyleId = XMVCA.XBigWorldMap:GetReadyQuestPinStyleIdByQuestType(questType)
    elseif self.IsOptionalQuestObjective then
        self.StyleId = XMVCA.XBigWorldMap:GetOptionalQuestPinStyleIdByQuestType(questType)
    else
        self.StyleId = XMVCA.XBigWorldMap:GetQuestPinStyleIdByQuestType(questType)
    end
end

return XBWMapVirtualPinData
