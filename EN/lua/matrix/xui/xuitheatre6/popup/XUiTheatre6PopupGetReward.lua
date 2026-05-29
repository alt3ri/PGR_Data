---@class XUiTheatre6PopupGetReward : XLuaUi
local XUiTheatre6PopupGetReward = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupGetReward")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--local XUiTheatre6GetPVERewardItem = require("XUi/XUiTheatre6/OutSider/Grid/XUiTheatre6GetPVERewardItem")

function XUiTheatre6PopupGetReward:OnAwake()
    self._rouge6ItemGridList = {}
    ---@type XUiGridCommon[]
    self._RewardGoodItems = {}
    self._CloseCb = nil
    self:AddUIListener()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridTheatre5Item.gameObject:SetActiveEx(false)
    self.PanelRewardList.gameObject:SetActiveEx(true)
end

---@deprecated rewardGoodsList 通用奖励列表
---@deprecated itemList 肉鸽6物品列表
---@deprecated closeCb 关闭回调
---@param itemList { Id:number, Type:number, Count:number, IsTag:bool }[]
function XUiTheatre6PopupGetReward:OnStart(rewardGoodsList, itemList, closeCb)
    self._CloseCb = closeCb
    self:Refresh(rewardGoodsList, itemList)
end

function XUiTheatre6PopupGetReward:AddUIListener()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiTheatre6PopupGetReward:Refresh(rewardGoodsList, itemList)
    if not XTool.IsTableEmpty(rewardGoodsList) then
        -- 合并奖励
        rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)

        for i, v in pairs(rewardGoodsList) do
            local item = self._RewardGoodItems[i]
            if not item then
                local go = XUiHelper.Instantiate(self.GridCommon, self.Content)
                item = XUiGridCommon.New(self, go)
                self._RewardGoodItems[i] = item
            end
            item:Refresh(v)
            item:SetProxyClickFunc(function()
                XLuaUiManager.Open("UiTheatre6PopupRewardDetail", item.TemplateId)
            end)
        end
    end
    --if not XTool.IsTableEmpty(itemList) then
        --XTool.UpdateDynamicItem(self._rouge6ItemGridList, itemList, self.GridTheatre6Item, XUiTheatre6GetPVERewardItem, self)
    --end

    self:RefreshPosition()
end

function XUiTheatre6PopupGetReward:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self._CloseCb)
end

function XUiTheatre6PopupGetReward:RefreshPosition()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)

    local contentWidth = self.Content.rect.width
    local viewportWidth = self.Viewport.rect.width

    if contentWidth > viewportWidth then
        local y = self.Content.anchoredPosition.y

        self.Content.anchoredPosition = Vector2(contentWidth / 2, y)
    end
end

function XUiTheatre6PopupGetReward:OnDestroy()
    self._rouge6ItemGridList = nil
    self._RewardGoodItems = nil
    self._CloseCb = nil
end


return XUiTheatre6PopupGetReward