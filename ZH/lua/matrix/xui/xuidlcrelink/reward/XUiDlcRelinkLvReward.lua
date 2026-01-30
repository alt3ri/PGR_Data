local XUiGridDlcRelinkShopPanel = require("XUi/XUiDlcRelink/Reward/XUiGridDlcRelinkShopPanel")
local XUiGridDlcRelinkTaskPanel = require("XUi/XUiDlcRelink/Reward/XUiGridDlcRelinkTaskPanel")
---@class XUiDlcRelinkLvReward : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelBtnGroup XUiButtonGroup
local XUiDlcRelinkLvReward = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkLvReward")

function XUiDlcRelinkLvReward:OnAwake()
    self:RegisterUiEvents()
    self.BtnTab.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)
    self.PanelTaskStory.gameObject:SetActiveEx(false)
    self.PanelItemList.gameObject:SetActiveEx(false)

    local itemIds = { XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin }
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self, nil, function(data, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", itemId)
    end)
end

function XUiDlcRelinkLvReward:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.CurSelectIndex = 0
    self.DefaultSelectIndex = nil
    self:InitBtnTab()
end

function XUiDlcRelinkLvReward:OnEnable()
    self.Super.OnEnable(self)
    self.PanelBtnGroup:SelectIndex(self.DefaultSelectIndex)
end

function XUiDlcRelinkLvReward:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_FINISH_MULTI,
    }
end

function XUiDlcRelinkLvReward:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_FINISH_MULTI then
        self:RefreshRedPoint()
    end
end

function XUiDlcRelinkLvReward:OnDisable()
    self.Super.OnDisable(self)
end

function XUiDlcRelinkLvReward:InitBtnTab()
    local firstTags = { XEnumConst.DlcRelink.ShopTaskType.Shop, XEnumConst.DlcRelink.ShopTaskType.Task }

    local btnIndex = 0
    self.TabIndexToConfigId = {}
    ---@type XUiComponent.XUiButton[]
    self.TabBtnList = {}

    -- 一级标题
    for _, tag in ipairs(firstTags) do
        local configIds = self._Control:GetShopTaskConfigIdsByType(tag)
        if not XTool.IsTableEmpty(configIds) then
            local btn = XUiHelper.Instantiate(self.BtnTab, self.PanelBtnGroup.transform)
            btn.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, self._Control:GetClientConfig("ShopTaskTagName", tag))

            btnIndex = btnIndex + 1
            self.TabBtnList[btnIndex] = btn

            -- 二级标题
            local firstIndex = btnIndex
            for _, configId in ipairs(configIds) do
                local btnChild = XUiHelper.Instantiate(self.BtnChild, self.PanelBtnGroup.transform)
                btnChild.gameObject:SetActiveEx(true)
                btnChild:SetNameByGroup(0, self._Control:GetShopTaskName(configId))
                btnChild.SubGroupIndex = firstIndex
                btnIndex = btnIndex + 1
                self.TabBtnList[btnIndex] = btnChild
                self.TabIndexToConfigId[btnIndex] = configId
                -- 默认选中第一个
                if self.DefaultSelectIndex == nil then
                    self.DefaultSelectIndex = btnIndex
                end
            end
        end
    end

    self.PanelBtnGroup:Init(self.TabBtnList, handler(self, self.OnTabBtnClick))
end

function XUiDlcRelinkLvReward:OnTabBtnClick(index)
    if self.CurSelectIndex == index then
        return
    end

    self.CurSelectIndex = index
    local configId = self.TabIndexToConfigId[index]
    if not XTool.IsNumberValid(configId) then
        return
    end

    self:RefreshShopTask(configId)
    self:RefreshRedPoint()
end

function XUiDlcRelinkLvReward:RefreshShopTask(configId)
    local type = self._Control:GetShopTaskType(configId)
    if type == XEnumConst.DlcRelink.ShopTaskType.Shop then
        self:CloseTaskPanel()
        local shopId = self._Control:GetShopTaskShopId(configId)
        if XTool.IsNumberValid(shopId) then
            XShopManager.GetShopInfo(shopId, function()
                self:OpenShopPanel(shopId)
            end)
        end
    elseif type == XEnumConst.DlcRelink.ShopTaskType.Task then
        self:CloseShopPanel()
        self:OpenTaskPanel(configId)
    else
        self:CloseShopPanel()
        self:CloseTaskPanel()
    end

    -- 标题
    self.TxtTitle.text = self._Control:GetClientConfig("ShopTaskTagName", type)
end

function XUiDlcRelinkLvReward:OpenShopPanel(shopId)
    if not self.PanelShopUi then
        ---@type XUiGridDlcRelinkShopPanel
        self.PanelShopUi = XUiGridDlcRelinkShopPanel.New(self.PanelItemList, self)
    end
    self.PanelShopUi:Open()
    self.PanelShopUi:Refresh(shopId)
end

function XUiDlcRelinkLvReward:CloseShopPanel()
    if self.PanelShopUi then
        self.PanelShopUi:Close()
    end
end

function XUiDlcRelinkLvReward:OpenTaskPanel(configId)
    if not self.PanelTaskUi then
        ---@type XUiGridDlcRelinkTaskPanel
        self.PanelTaskUi = XUiGridDlcRelinkTaskPanel.New(self.PanelTaskStory, self)
    end
    self.PanelTaskUi:Open()
    self.PanelTaskUi:Refresh(configId)
end

function XUiDlcRelinkLvReward:CloseTaskPanel()
    if self.PanelTaskUi then
        self.PanelTaskUi:Close()
    end
end

function XUiDlcRelinkLvReward:RefreshRedPoint()
    if XTool.IsTableEmpty(self.TabIndexToConfigId) then
        return
    end
    local firstIndexList = {} -- 一级标题红点记录
    -- 二级标题红点
    for index, configId in pairs(self.TabIndexToConfigId) do
        local btn = self.TabBtnList[index]
        if btn then
            local isShowRedPoint = self._Control:CheckShopTaskRedPointByConfigId(configId)
            btn:ShowReddot(isShowRedPoint)

            local subGroupIndex = btn.SubGroupIndex
            if XTool.IsNumberValid(subGroupIndex) then
                firstIndexList[subGroupIndex] = firstIndexList[subGroupIndex] or isShowRedPoint
            end
        end
    end
    -- 一级标题红点
    for firstIndex, isShow in pairs(firstIndexList) do
        local firstBtn = self.TabBtnList[firstIndex]
        if firstBtn then
            firstBtn:ShowReddot(isShow)
        end
    end
end

function XUiDlcRelinkLvReward:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiDlcRelinkShopItem", self, data, function()
        if cb then
            cb()
        end
        self:RefreshRedPoint()
    end)
end

function XUiDlcRelinkLvReward:GetCurShopId()
    local configId = self.TabIndexToConfigId[self.CurSelectIndex]
    return self._Control:GetShopTaskShopId(configId)
end

function XUiDlcRelinkLvReward:RefreshBuy()
    if self.PanelShopUi then
        self.PanelShopUi:SetupDynamicTable()
    end
end

function XUiDlcRelinkLvReward:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
end

function XUiDlcRelinkLvReward:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkLvReward:OnBtnMainUiClick()
    self._Control:CommonRunMainUiHandle()
end

return XUiDlcRelinkLvReward
