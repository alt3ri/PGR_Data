local XUiGridActivityBriefConstReward = require('XUi/XUiActivityBrief/XUiGridActivityBriefConstReward')

--- 活动面板通用商品固定UI
---@class XUiPanelActivityBriefConstShowGoods
local XUiPanelActivityBriefConstShowGoods = XClass(nil, 'XUiPanelActivityBriefConstShowGoods')

function XUiPanelActivityBriefConstShowGoods:Ctor(ui, activityRewardId)
    XTool.InitUiObjectByUi(self, ui)
    self._ActivityRewardId = activityRewardId
    self:InitShowGoods()
end

function XUiPanelActivityBriefConstShowGoods:Open()

end

function XUiPanelActivityBriefConstShowGoods:InitShowGoods()
    self.GridRewardRoot.gameObject:SetActiveEx(false)
    --通用处理
    if XTool.IsNumberValid(self._ActivityRewardId) then
        local showItems = XRewardManager.GetRewardListNotCount(self._ActivityRewardId)
        XUiHelper.RefreshCustomizedList(self.GridRewardRoot.transform.parent, self.GridRewardRoot, showItems and #showItems or 0, function(index, obj)
            local gridCommont = XUiGridActivityBriefConstReward.New(nil, obj)
            gridCommont:Refresh(showItems[index])
        end)
    end
end

return XUiPanelActivityBriefConstShowGoods