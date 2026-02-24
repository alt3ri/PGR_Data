local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiTaskActivity = require("XUi/XUiTask/XUiTaskActivity")

---@class XUiLuckyTenant2Task : XUiTaskActivity
---@field _Control XLuckyTenant2Control
local XUiLuckyTenant2Task = XLuaUiManager.Register(XUiTaskActivity, "UiLuckyTenant2Task")

function XUiLuckyTenant2Task:InitAssets()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin)
end

-- 任务分组ID列表
---@return number[]
function XUiLuckyTenant2Task:GetTaskGroupIds()
    return self._Control:GetTaskGroupIds() or {}
end

-- 活动结束时间
---@return number
function XUiLuckyTenant2Task:GetActivityEndTime()
    if XMVCA.XLuckyTenant2:IsOffline() then
        return XTime.GetServerNowTimestamp() + 1000000000
    end
    return self._Control:GetActivityEndTime()
end

return XUiLuckyTenant2Task
