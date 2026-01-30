local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")

--- 流程分支
---@class XTheatre5BranchNode: XTheatre5PVENode
---@field private _MainControl XTheatre5FlowController
---@field _MainModel XTheatre5Model
local XTheatre5BranchNode = XClass(XTheatre5PVENode, 'XTheatre5BranchNode')

function XTheatre5BranchNode:_OnEnter()
    ---@type XTableTheatre5PveStoryLineContent
    local cfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)
    
    --todo: 临时用通用弹窗
    if cfg then
        XLuaUiManager.Open('UiTheatre5PopupChoose', cfg)
    end
end

function XTheatre5BranchNode:_OnExit()
    
end

function XTheatre5BranchNode:_OnRelease()

end

return XTheatre5BranchNode