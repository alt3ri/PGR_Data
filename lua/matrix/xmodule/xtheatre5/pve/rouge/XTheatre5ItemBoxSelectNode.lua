local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5ItemBoxSelectNode
local XTheatre5ItemBoxSelectNode = XClass(XTheatre5PVENode, "XTheatre5ItemBoxSelectNode")

function XTheatre5ItemBoxSelectNode:Ctor()
    self._ItemBoxSelectData = nil
end

function XTheatre5ItemBoxSelectNode:_OnEnter()
    self:OpenUiPanel("UiTheatre5PVEPopupChooseReward", XMVCA.XTheatre5.EnumConst.ChooseRewardType.Item, handler(self, self.ChapterBattlePromote))
end

function XTheatre5ItemBoxSelectNode:_OnExit()

end

return XTheatre5ItemBoxSelectNode