---@class XUiBigWorldPopupDelivery : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
---@field PanelBag XUiPanelBWDeliveryBag
---@field PanelDelivery XUiPanelBWDelivery
local XUiBigWorldPopupDelivery = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupDelivery")

function XUiBigWorldPopupDelivery:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPopupDelivery:OnStart(objectiveId)
    self._ObjectiveId = objectiveId
    self._DeliverType = XMVCA.XBigWorldQuest:GetObjectiveItemsDeliverType(objectiveId)
    self:InitView()
end

function XUiBigWorldPopupDelivery:InitUi()
    self.PanelBag = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWDeliveryBag").New(self.PanelLeft, self)
    self.PanelDelivery = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWDelivery").New(self.PanelRight, self)

    self.PanelBag:Close()
    self.PanelDelivery:Close()

    self._DeliverList = {}
end

function XUiBigWorldPopupDelivery:InitCb()
end

function XUiBigWorldPopupDelivery:InitView()
    local bagItems = {}
    local deliveryItems = {}
    local deliveryDict = XMVCA.XBigWorldQuest:GetObjectiveDeliveryItemDict(self._ObjectiveId)
    if not XTool.IsTableEmpty(deliveryDict) then
        for itemId, itemCount in pairs(deliveryDict) do
            deliveryItems[#deliveryItems + 1] = {
                Id = itemId,
                Count = 0,
                NeedCount = itemCount,
                Sort = 0,
            }
            bagItems[#bagItems + 1] = {
                Id = itemId,
                Count = XMVCA.XBigWorldService:GetQuestItemCount(itemId),
                Consume = 0
            }
        end

        table.sort(deliveryItems, function(a, b)
            return a.Id < b.Id
        end)

        table.sort(bagItems, function(a, b)
            return a.Id < b.Id
        end)
    end

    self.BagItems = bagItems
    self.DeliveryItems = deliveryItems

    if self:IsManualDeliver() then
        self.PanelBag:Open()
    else
        self:AutoDeliver()
    end
    self.PanelDelivery:Open()

    self:RefreshPanel()
end

function XUiBigWorldPopupDelivery:DoDeliver()
    local list = self:ClearDeliverList()
    for _, itemData in pairs(self.DeliveryItems) do
        if itemData.Count < itemData.NeedCount then
            XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("DeliveryNotEnough"))
            return
        end
        list[#list + 1] = {
            QuestItemId = itemData.Id,
            Count = itemData.Count
        }
    end

    self:DoClose()
    local sendData = {
        ObjectiveId = self._ObjectiveId,
        DeliverItemList = list
    }
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_ITEMS_DELIVERY_CONFIRM, sendData)
end

function XUiBigWorldPopupDelivery:AutoDeliver()
    local bagDict = {}
    for _, bag in pairs(self.BagItems) do
        bagDict[bag.Id] = bag
    end
    local index = 1
    for _, delivery in pairs(self.DeliveryItems) do
        local bag = bagDict[delivery.Id]
        local consume = math.min(bag.Count, delivery.NeedCount)
        delivery.Count = consume
        bag.Consume = consume
        delivery.Sort = consume > 0 and index or 0
    end
end

function XUiBigWorldPopupDelivery:DoBagToDeliver(data)
    if not data then
        return
    end

    local id = data.Id
    local count = data.Count
    -- 没有道具
    if count <= 0 or count <= data.Consume then
        return
    end
    for _, item in pairs(self.DeliveryItems) do
        if item.Id == id then
            count = math.min(count, item.NeedCount - data.Consume)
            data.Consume = data.Consume + count
            item.Count = data.Consume
            if item.Sort <= 0 then
                item.Sort = XTime.GetServerNowTimestamp()
            end
            break
        end
    end
    self:RefreshPanel()
end

function XUiBigWorldPopupDelivery:DoDeliverToBag(data, isBag)
    if not data then
        return
    end
    local id
    if isBag then --点击了背包的删除按钮
        id = data.Id
        for _, item in pairs(self.DeliveryItems) do
            if item.Id == id then
                local count = item.Count
                item.Count = 0
                data.Consume = math.max(0, data.Consume - count)
                item.Sort = 0
                break
            end
        end
    else --点击了交付的删除按钮
        id = data.Id
        local count = data.Count
        for _, item in pairs(self.BagItems) do
            if item.Id == id then
                item.Consume = math.max(0, item.Consume - count)
                data.Count = 0
                data.Sort = 0 
                break
            end
        end
    end

    self:RefreshPanel()
end

function XUiBigWorldPopupDelivery:RefreshPanel()
    if self:IsManualDeliver() then
        self.PanelBag:Refresh(self._ObjectiveId, self.BagItems)
    end
    self.PanelDelivery:Refresh(self._ObjectiveId, self.DeliveryItems)
end

function XUiBigWorldPopupDelivery:IsManualDeliver()
    return self._DeliverType == XMVCA.XBigWorldQuest.EItemsDeliverType.Manual
end

function XUiBigWorldPopupDelivery:ClearDeliverList()
    for i = #self._DeliverList, 1, -1 do
        table.remove(self._DeliverList, i)
    end
    return self._DeliverList
end

function XUiBigWorldPopupDelivery:DoClose()
    if self.PanelBag:IsNodeShow() then
        self:PlayAnimation("PanelLeftDisable")
    end
    self:PlayAnimationWithMask("PanelRightDisable", function()
        self:Close()
    end)
end
