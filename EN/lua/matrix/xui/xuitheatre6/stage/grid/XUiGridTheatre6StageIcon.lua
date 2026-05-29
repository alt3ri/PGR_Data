---@class XUiGridTheatre6StageIcon : XUiNode 房间顶部的房间Icon
---@field _Control XTheatre6Control
local XUiGridTheatre6StageIcon = XClass(XUiNode, "XUiGridTheatre6StageIcon")

function XUiGridTheatre6StageIcon:OnStart()
    self:SetLineVisible(false)
end

function XUiGridTheatre6StageIcon:SetRoomData(roomIndex, roomId)
    local roomConfig = self._Control:GetStageRoomConfig(roomId)
    local roomType = roomConfig.Type
    local roomIcon = self._Control:GetRoomIcon(roomType)

    self.UiRImgIcon:SetRawImage(roomIcon)

    local roomData = self._Control:GetCurRoomData()
    local curRoomIdx = roomData.RoomIdx + 1
    self.UiPanelFinish.gameObject:SetActiveEx(roomIndex < curRoomIdx)
    self.UiPanelUnfinished.gameObject:SetActiveEx(roomIndex == curRoomIdx)
end

function XUiGridTheatre6StageIcon:SetLineVisible(isVisible)
    self.ImgLine.gameObject:SetActiveEx(isVisible)
end

return XUiGridTheatre6StageIcon