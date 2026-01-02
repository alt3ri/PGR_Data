---@class XBWMapPinData
local XBWMapPinData = XClass(nil, "XBWMapPinData")

function XBWMapPinData:Ctor()
    self.LevelId = 0
    self.WorldId = 0
    self.PinId = 0
    self.QuestId = 0
    self.NearbyPinId = 0
    self.BindPinId = 0
    self.BindLevelId = 0
    self.ReferPinId = 0
    self.QuestObjectiveId = 0
    self.TargetSceneObjectPlaceId = 0
    self.TargetNpcPlaceId = 0
    self.IsDisplay = false
    self.Radius = 0
    self.DisplayType = XMVCA.XBigWorldMap.MapPinDisplayType.Point
    self.IsOptionalQuestObjective = false
end

function XBWMapPinData:UpdateDisplay(isDisplay)
    self.IsDisplay = isDisplay
end

function XBWMapPinData:UpdateData(worldId, levelId, config, textConfig)
    self.PinId = config.Id
    self.LevelId = levelId
    self.WorldId = worldId
    self.SceneObjectPlaceId = config.SceneObjectPlaceId
    self.NpcPlaceId = config.NpcPlaceId
    self.Name = textConfig and textConfig.Name or ""
    self.Desc = textConfig and textConfig.Desc or ""
    self.StyleId = config.StyleId
    self.ActivityId = config.ActivityId
    self.MapAreaGroupId = config.MapAreaGroupId
    self.WorldPosition = config.WorldPosition
    self.TeleportLevelId = config.TeleportLevelId
    self.TeleportEnable = config.TeleportEnable
    self.TeleportPosition = config.TeleportPosition
    self.TeleportEulerAngleY = config.TeleportEulerAngleY
    self.ConditionId = config.ConditionId or 0
    self.AiMemoryGroupId = config.AiMemoryGroupId or 0
    self.ControlledByMapSwitch = config.ControlledByMapSwitch or 0

    self:UpdateOther()
end

function XBWMapPinData:UpdateOther()
    local isDisplay = false

    if self:IsSceneObject() then
        isDisplay = XMVCA.XBigWorldMap:CheckSceneObjectMapPinDefalutDisplay(self.LevelId, self.SceneObjectPlaceId)
    elseif self:IsNpc() then
        isDisplay = XMVCA.XBigWorldMap:CheckNpcMapPinDefalutDisplay(self.LevelId, self.NpcPlaceId)
    end

    self:UpdateDisplay(isDisplay)
end

function XBWMapPinData:UpdateTrackPosition(trackPosition, areaGroupId)
    self.TrackPosition = trackPosition
    self.TrackAreaGroupId = areaGroupId
end

function XBWMapPinData:UpdateWorldPosition(position)
    self.WorldPosition.x = position.x
    self.WorldPosition.y = position.y
    self.WorldPosition.z = position.z
end

function XBWMapPinData:IsActive()
    if self:IsQuest() or self:IsNpc() then
        return true
    end

    return XMVCA.XBigWorldMap:CheckTeleporterActive(self.LevelId, self.SceneObjectPlaceId)
end

function XBWMapPinData:IsNpc()
    return XTool.IsNumberValid(self.NpcPlaceId)
end

function XBWMapPinData:IsSceneObject()
    return XTool.IsNumberValid(self.SceneObjectPlaceId)
end

function XBWMapPinData:IsNil()
    return not XTool.IsNumberValid(self.PinId)
end

function XBWMapPinData:IsActivity()
    return XTool.IsNumberValid(self.ActivityId)
end

function XBWMapPinData:IsQuest()
    return XTool.IsNumberValid(self.QuestId)
end

function XBWMapPinData:IsVirtual()
    return XTool.IsNumberValid(self.ReferPinId)
end

function XBWMapPinData:IsNearbyPin()
    return XTool.IsNumberValid(self.NearbyPinId)
end

function XBWMapPinData:IsBindOther()
    return XTool.IsNumberValid(self.BindPinId)
end

function XBWMapPinData:IsTeleportLevel()
    return XTool.IsNumberValid(self.TeleportLevelId) and self:IsCouldTeleport()
end

function XBWMapPinData:IsTeleportInLevel()
    return not XTool.IsNumberValid(self.TeleportLevelId) and self:IsCouldTeleport()
end

function XBWMapPinData:IsCouldTeleport()
    return self.TeleportEnable and self:IsActive() and self:IsDisplaying()
end

function XBWMapPinData:IsBindPlace()
    return XTool.IsNumberValid(self.TargetSceneObjectPlaceId) or XTool.IsNumberValid(self.TargetNpcPlaceId)
end

function XBWMapPinData:IsTracking()
    if self:IsVirtual() then
        return XMVCA.XBigWorldMap:CheckPinTracking(self.LevelId, self.ReferPinId)
    end

    return XMVCA.XBigWorldMap:CheckPinTracking(self.LevelId, self.PinId)
end

function XBWMapPinData:IsDisplaying()
    if XTool.IsNumberValid(self.ConditionId) then
        return XMVCA.XBigWorldService:CheckCondition(self.ConditionId)
    end
    
    return self.IsDisplay
end

function XBWMapPinData:IsAssistedTracking()
    if self:IsNil() then
        return false
    end

    return self.TrackPosition and self:IsTracking() and XTool.IsNumberValid(self.TrackAreaGroupId)
end

function XBWMapPinData:GetWorldPosition2D()
    return {
        x = self.WorldPosition.x,
        y = self.WorldPosition.z,
    }
end

function XBWMapPinData:GetAssistedPosition()
    if self:IsAssistedTracking() then
        return self.TrackPosition
    end

    return self.WorldPosition
end

function XBWMapPinData:GetAssistedAreaGroupId()
    if self:IsAssistedTracking() then
        return self.TrackAreaGroupId
    end

    return self.MapAreaGroupId
end

function XBWMapPinData:GetAreaGroupId(isAssisted)
    if isAssisted then
        return self:GetAssistedAreaGroupId()
    end

    return self.MapAreaGroupId
end

function XBWMapPinData:GetWorldPosition(isAssisted)
    if isAssisted then
        return self:GetAssistedPosition()
    end

    return self.WorldPosition
end

function XBWMapPinData:GetTeleportLevelId()
    if self:IsTeleportLevel() then
        return self.TeleportLevelId
    end

    return self.LevelId
end

function XBWMapPinData:GetValidLevelId()
    if self:IsVirtual() then
        return self.BindLevelId
    end

    return self.LevelId
end

function XBWMapPinData:IsOptionalQuestObjectiveState()
    return self.IsOptionalQuestObjective
end

function XBWMapPinData:IsAiMemoryGroup()
    return self.AiMemoryGroupId > 0
end

function XBWMapPinData:GetAiMemoryGroupId()
    return self.AiMemoryGroupId or 0
end

function XBWMapPinData:IsPointPin()
    return (self.DisplayType & XMVCA.XBigWorldMap.MapPinDisplayType.Point) ~= 0
end

function XBWMapPinData:IsRadiusPin()
    return (self.DisplayType & XMVCA.XBigWorldMap.MapPinDisplayType.Radius) ~= 0
end

function XBWMapPinData:SetDisplayType(value)
    self.DisplayType = value
end

return XBWMapPinData
