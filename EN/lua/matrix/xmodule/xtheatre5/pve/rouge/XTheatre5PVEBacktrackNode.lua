local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")

--- 流程回溯
---@class XTheatre5PVEBacktrackNode: XTheatre5PVENode
---@field private _MainControl XTheatre5FlowController
---@field _MainModel XTheatre5Model
local XTheatre5PVEBacktrackNode = XClass(XTheatre5PVENode, 'XTheatre5PVEBacktrackNode')


function XTheatre5PVEBacktrackNode:_OnEnter()
    if not XLuaUiManager.IsUiShow('UiTheatre5ChooseCharacter') then
        self:OpenUiPanel("UiTheatre5ChooseCharacter", XMVCA.XTheatre5.EnumConst.GameMode.PVE)
    end

    ---@type XTableTheatre5PveStoryLineContent
    local cfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)

    if cfg then
        XLuaUiManager.Open('UiTheatre5PopupBacktrack', cfg)
    end
end

function XTheatre5PVEBacktrackNode:_OnExit()

end

function XTheatre5PVEBacktrackNode:_OnRelease()

end

return XTheatre5PVEBacktrackNode