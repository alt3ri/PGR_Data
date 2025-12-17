local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5SelectRelicNode
local XTheatre5SelectRelicNode = XClass(XTheatre5PVENode, "XTheatre5SelectRelicNode")

function XTheatre5SelectRelicNode:Ctor()
    self._ItemBoxSelectData = nil
end

function XTheatre5SelectRelicNode:_OnEnter()
    self:OpenUiPanel("UiTheatre5PVEPopupChooseReward", XMVCA.XTheatre5.EnumConst.ChooseRewardType.Relic, handler(self, self.ChapterBattlePromote))
end

function XTheatre5SelectRelicNode:_OnExit()

end

return XTheatre5SelectRelicNode