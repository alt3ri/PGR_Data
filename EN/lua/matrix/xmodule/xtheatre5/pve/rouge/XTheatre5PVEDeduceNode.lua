local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEDeduceNode
local XTheatre5PVEDeduceNode = XClass(XTheatre5PVENode, "XTheatre5PVEDeduceNode")

function XTheatre5PVEDeduceNode:Ctor()

end

function XTheatre5PVEDeduceNode:_OnEnter()
    local storyLineContentCfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)
    XLuaUiManager.Open("UiTheatre5PVEReasoning", storyLineContentCfg.ContentId, function()
        XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId)
    end)   
end

function XTheatre5PVEDeduceNode:_OnExit()

end

return XTheatre5PVEDeduceNode