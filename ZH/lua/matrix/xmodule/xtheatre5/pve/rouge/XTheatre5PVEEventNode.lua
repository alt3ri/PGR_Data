local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEEventNode
local XTheatre5PVEEventNode = XClass(XTheatre5PVENode, "XTheatre5PVEEventNode")

function XTheatre5PVEEventNode:Ctor()
    self._EventId = nil
end

function XTheatre5PVEEventNode:SetData(eventId)
    self._EventId = eventId
end

function XTheatre5PVEEventNode:_OnEnter()
    self:OpenUiPanel("UiTheatre5PVEEvent", self._EventId, handler(self, self.ChapterBattlePromote))       
end

function XTheatre5PVEEventNode:_OnExit()
    self._EventId = nil
end

return XTheatre5PVEEventNode