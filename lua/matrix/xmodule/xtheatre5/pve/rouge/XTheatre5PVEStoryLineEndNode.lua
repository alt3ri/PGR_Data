local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEStoryLineEndNode
local XTheatre5PVEStoryLineEndNode = XClass(XTheatre5PVENode, "XTheatre5PVEStoryLineEndNode")

function XTheatre5PVEStoryLineEndNode:_OnEnter()
    XLuaUiManager.Open("UiTheatre5PVEStoryEnding", self._StoryLineId, self._StoryLineContentId)  
    XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId)
end

function XTheatre5PVEStoryLineEndNode:_OnExit()
    self._StoryLineContentId = nil
end

return XTheatre5PVEStoryLineEndNode