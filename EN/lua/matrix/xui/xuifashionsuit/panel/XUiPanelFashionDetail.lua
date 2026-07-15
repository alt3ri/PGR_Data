---@class XUiPanelFashionDetail: XUiNode
---@field Parent   XUiFashionSuitDetail
---@field _Control XFashionSuitControl
local XUiPanelFashionDetail = XClass(XUiNode, "XUiPanelFashionDetail")

function XUiPanelFashionDetail:OnStart(fashionSuitId)
    self._ItemPools = {}

    self._ButtonGroup = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionSuitButtonGroup").New(self.PanelBtnGroup, self)
    self._Helper = self.Parent:GetHelper()
    self._Context = self.Parent:GetContextUi()
    self._SuitConfig = self._Control:GetFashionSuitById(fashionSuitId)
    self._SuitId = fashionSuitId
    self._UiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
    self:InitComponent()
end

function XUiPanelFashionDetail:OnGetLuaEvents()
    return { XEventId.EVENT_WEAPOM_SYM, XEventId.EVENT_CHARACTER_SYN }
end

function XUiPanelFashionDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_WEAPOM_SYM or evt == XEventId.EVENT_CHARACTER_SYN then
        self:UpdateBuyBtn()
    end
end

function XUiPanelFashionDetail:InitComponent()
    self.Grid256New.gameObject:SetActiveEx(false)
    self._ButtonGroup:InitContext(self._Context, self._Helper)
end

function XUiPanelFashionDetail:UpdateGroupSales(id)
    local isVisible = XMVCA.XFashionSuit:IsAllowGroupSales(id)
    local skipUpdateView = true
    if self._RecordId then
        skipUpdateView = self._RecordId == id
    end
    self._RecordId = id
    self._ButtonGroup:SetBtnBuySuitVisible(isVisible, skipUpdateView)
end

function XUiPanelFashionDetail:UpdateFashionDetail()
    self.TxtFashionName.text = self._Helper:GetName()
    self.TxtCharacterName.text = self._Helper:GetCharacterName()
    self.ImgTagNew.gameObject:SetActiveEx(self._Helper:IsTagNewVisible())
    self.TxtSuitName.text = self._SuitConfig.Name
    self.RImgSuitIcon:SetRawImage(self._UiConfig.SuitBanner)
    self.TxtStoryTips.text = self._Helper:GetDesc()
end

function XUiPanelFashionDetail:ShowGift()
    local goodIdList = self._Helper:GetRewards()
    if XTool.IsTableEmpty(goodIdList) then
        self.PanelGift.gameObject:SetActiveEx(false)
    else
        self.PanelGift.gameObject:SetActiveEx(true)
        local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
        XUiHelper.CreateTemplates(
            self,
            self._ItemPools,
            goodIdList,
            XUiGridCommon.New,
            self.Grid256New,
            self.Grid256New.parent,
            function (grid, data)
                local params = { ShowReceived = data.ShowReceived, Disable = data.Disable }
                grid:Refresh(data, params)
            end
        )
    end
end

function XUiPanelFashionDetail:ApplyGroupSalesState(isVisible, isEnable)
    local isOpen = isVisible and isEnable
    if isOpen then
        self._Context:SwitchToGroup()
    else
        self._Context:SwitchToSingle()
    end
    self._Helper:SetGroupSales(isOpen)
    self:UpdateBuyBtn()
end

function XUiPanelFashionDetail:SetGroupSales(isVisible, isEnable)
    self:ApplyGroupSalesState(isVisible, isEnable)
    self.Parent:UpdateView()
end

function XUiPanelFashionDetail:UpdateBuyBtn()
    self._ButtonGroup:UpdateBuyBtn()
end

function XUiPanelFashionDetail:RegisterTimerFun(id, fun)
    self.Parent:RegisterTimerFun(id, fun)
end

function XUiPanelFashionDetail:RemoveTimerFun(id)
    self.Parent:RemoveTimerFun(id)
end
return XUiPanelFashionDetail
