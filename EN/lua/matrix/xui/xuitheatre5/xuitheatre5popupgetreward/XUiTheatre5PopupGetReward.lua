---@class XUiTheatre5PopupGetReward : XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PopupGetReward = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupGetReward")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiTheatre5GetPVERewardItem = require("XUi/XUiTheatre5/XUiTheatre5PopupGetReward/XUiTheatre5GetPVERewardItem")

function XUiTheatre5PopupGetReward:OnAwake()
    self._rouge5ItemGridList = {}
    self._RewardGoodItems = {}
    self._CloseCb = nil
    self:AddUIListener()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridTheatre5Item.gameObject:SetActiveEx(false)
    self.PanelRewardList.gameObject:SetActiveEx(true)
end

---@deprecated rewardGoodsList 通用奖励列表
---@deprecated itemList 肉鸽5物品列表
---@deprecated closeCb 关闭回调
---@param itemList { Id:number, Type:number, Count:number, IsTag:bool }[]
function XUiTheatre5PopupGetReward:OnStart(rewardGoodsList, itemList, closeCb)
    self._CloseCb = closeCb
    self:Refresh(rewardGoodsList, itemList)
end

function XUiTheatre5PopupGetReward:AddUIListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiTheatre5PopupGetReward:Refresh(rewardGoodsList, itemList)
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
            -- XUiHelper.RegisterClickEvent(item, item.BtnClick, function()
            --     local templateId = (v.TemplateId and v.TemplateId > 0) and v.TemplateId or v.Id
            --     XLuaUiManager.Open("UiTheatre5PopupItemDetail", templateId)
            -- end)
        end
    end
    if not XTool.IsTableEmpty(itemList) then
        XTool.UpdateDynamicItem(self._rouge5ItemGridList, itemList, self.GridTheatre5Item, XUiTheatre5GetPVERewardItem, self)
    end       

    self:RefreshPosition()
end

function XUiTheatre5PopupGetReward:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self._CloseCb)
end

function XUiTheatre5PopupGetReward:RefreshPosition()
    if self.Viewport then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)

        local contentWidth = self.Content.rect.width
        local viewportWidth = self.Viewport.rect.width
        
        if contentWidth > viewportWidth then
            local y = self.Content.anchoredPosition.y
            
            self.Content.anchoredPosition = Vector2(contentWidth / 2, y)
        end
    end
end

function XUiTheatre5PopupGetReward:OnDestroy()
    self._rouge5ItemGridList = nil
    self._RewardGoodItems = nil
    self._CloseCb = nil
end


return XUiTheatre5PopupGetReward