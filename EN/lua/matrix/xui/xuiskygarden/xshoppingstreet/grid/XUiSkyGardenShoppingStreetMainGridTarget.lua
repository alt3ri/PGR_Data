---@class XUiSkyGardenShoppingStreetMainGridTarget : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetMainGridTarget = XClass(XUiNode, "XUiSkyGardenShoppingStreetMainGridTarget")
local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiSkyGardenShoppingStreetMainGridTarget:OnStart()
    self._GridCommon = XUiGridBWItem.New(self.UiBigWorldItemGrid, self)
end

--region 刷新逻辑
function XUiSkyGardenShoppingStreetMainGridTarget:Update(showData)
    if showData.ConditionDesc then
        self.TxtTargetDetail.text = showData.ConditionDesc
    end
    local rewards = XRewardManager.GetRewardList(showData.RewardId)
    self._GridCommon:Refresh(rewards[1])

    local PanelReceive = self._GridCommon.PanelReceive
    if PanelReceive then
        PanelReceive.gameObject:SetActive(showData.IsGet)
    end
end
--endregion

return XUiSkyGardenShoppingStreetMainGridTarget
