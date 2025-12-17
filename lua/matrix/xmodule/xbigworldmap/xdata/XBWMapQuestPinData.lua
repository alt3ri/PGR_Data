local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")

---@class XBWMapQuestPinData : XBWMapPinData
local XBWMapQuestPinData = XClass(XBWMapPinData, "XBWMapQuestPinData")

function XBWMapQuestPinData:UpdateData(pinId, data)
    local questId = data.QuestId

    self.QuestId = questId
    self.ForceDisplay = data.ForceActive
    self.QuestObjectiveId = data.QuestObjectiveId or 0
    self.TargetSceneObjectPlaceId = data.SceneObjPlaceId or 0
    self.TargetNpcPlaceId = data.NpcPlaceId or 0
    self.Super.UpdateData(self, 0, data.LevelId, {
        Id = pinId,
        StyleId = XMVCA.XBigWorldMap:GetQuestPinStyleIdByQuestId(questId),
        ActivityId = 0,
        MapAreaGroupId = data.MapAreaGroupId or 0,
        WorldPosition = {
            x = data.PositionX,
            y = data.PositionY,
            z = data.PositionZ,
        },
        TeleportLevelId = 0,
        TeleportEnable = false,
        TeleportPosition = {
            x = 0,
            y = 0,
            z = 0,
        },
        TeleportEulerAngleY = 0,
        SceneObjectPlaceId = 0,
        NpcPlaceId = 0,
        ConditionId = 0,
    }, {
        Name = XMVCA.XBigWorldQuest:GetQuestText(questId),
        Desc = XMVCA.XBigWorldQuest:GetQuestDesc(questId),
    })
end

function XBWMapQuestPinData:UpdateOther()
end

return XBWMapQuestPinData
