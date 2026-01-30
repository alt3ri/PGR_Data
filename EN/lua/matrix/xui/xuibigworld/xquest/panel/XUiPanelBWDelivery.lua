local XUiGridBWDelivery = require("XUi/XUiBigWorld/XQuest/Grid/XUiGridBWDelivery")
---@class XUiPanelBWDelivery : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldPopupDelivery
---@field _GirdItems XUiGridBWDelivery[]
local XUiPanelBWDelivery = XClass(XUiNode, "XUiPanelBWDelivery")

function XUiPanelBWDelivery:OnStart()
    self._GirdItems = {}
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnRequire:AddEventListener(handler(self, self.OnBtnRequireClick))
end

function XUiPanelBWDelivery:OnEnable()
    self.Parent:PlayAnimation("PanelRightEnable")
end

function XUiPanelBWDelivery:InitCb()
end

function XUiPanelBWDelivery:InitView()
end

function XUiPanelBWDelivery:Refresh(objectiveId, itemList)
    self.TxtTitle.text = XMVCA.XBigWorldQuest:GetObjectiveDeliveryTitle(objectiveId)
    self.TxtDesc.text = XMVCA.XBigWorldQuest:GetObjectiveDeliveryDesc(objectiveId)
    
    XTool.UpdateDynamicItem(self._GirdItems, self:SortDeliver(itemList), self.GridItem, XUiGridBWDelivery, self)
end

function XUiPanelBWDelivery:OnBtnCloseClick()
    self.Parent:DoClose()
end

function XUiPanelBWDelivery:OnBtnRequireClick()
    self.Parent:DoDeliver()
end

function XUiPanelBWDelivery:DoDeliverToBag(data, isBag)
    self.Parent:DoDeliverToBag(data, isBag)
end

function XUiPanelBWDelivery:DoBagToDeliver(data)
    self.Parent:DoBagToDeliver(data)
end

function XUiPanelBWDelivery:IsManualDeliver()
    return self.Parent:IsManualDeliver()
end

function XUiPanelBWDelivery:SortDeliver(list)
    if XTool.IsTableEmpty(list) or #list == 1 then
        return list
    end
    table.sort(list, function(a, b)
        local sortA = a.Sort or 0
        local sortB = b.Sort or 0
        if sortA ~= 0 and sortB ~= 0 then
            return sortA < sortB
        end
        return sortA > sortB
    end)
    return list
end

return XUiPanelBWDelivery