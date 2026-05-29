local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")

---@class XBWMapQuestPinData : XBWMapPinData
local XBWMapQuestPinData = XClass(XBWMapPinData, "XBWMapQuestPinData")

function XBWMapQuestPinData:UpdateData(pinId, data)
    local questId = data.QuestId

    self.QuestId = questId
    self.QuestState = data.QuestState or -1
    self.QuestObjectiveId = data.QuestObjectiveId or 0
    self.IsOptionalQuestObjective = data.IsOptionalQuestObjective or false
    self.TargetSceneObjectPlaceId = data.SceneObjPlaceId or 0
    self.TargetNpcPlaceId = data.NpcPlaceId or 0
    self.DisplayType = data.ShowType or XMVCA.XBigWorldMap.MapPinDisplayType.Point
    self.Radius = data.Radius or 0
    self:UpdateDisplay(data.Active or false)
    self.Super.UpdateData(self, 0, data.LevelId, {
        Id = pinId,
        StyleId = 0,
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
        CanInteract = true,
    }, {
        Name = XMVCA.XBigWorldQuest:GetQuestText(questId),
        Desc = XMVCA.XBigWorldQuest:GetQuestDesc(questId),
    })
end

function XBWMapQuestPinData:UpdateOther()
    local questType = XMVCA.XBigWorldQuest:GetQuestTypeByQuestId(self.QuestId)

    if self.QuestState == XMVCA.XBigWorldQuest.QuestState.Ready then
        self.StyleId = XMVCA.XBigWorldMap:GetReadyQuestPinStyleIdByQuestType(questType)
    elseif self.IsOptionalQuestObjective then
        self.StyleId = XMVCA.XBigWorldMap:GetOptionalQuestPinStyleIdByQuestType(questType)
    else
        self.StyleId = XMVCA.XBigWorldMap:GetQuestPinStyleIdByQuestType(questType)
    end
end

return XBWMapQuestPinData
