local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEStoryLineEndNode
local XTheatre5PVEStoryLineEndNode = XClass(XTheatre5PVENode, "XTheatre5PVEStoryLineEndNode")

function XTheatre5PVEStoryLineEndNode:_OnEnter()
    XLuaUiManager.OpenWithCloseCallback("UiTheatre5PVEStoryEnding", function()
        XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId, function() 
            -- 检查引导
            if not XDataCenter.GuideManager.CheckIsInGuide() then
                XDataCenter.GuideManager.CheckGuideOpen()
            end
        end)
    end, self._StoryLineId, self._StoryLineContentId)  
end

function XTheatre5PVEStoryLineEndNode:_OnExit()
    self._StoryLineContentId = nil
end

return XTheatre5PVEStoryLineEndNode