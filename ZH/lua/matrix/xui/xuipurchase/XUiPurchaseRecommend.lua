local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiPanelRecommendBase = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendBase")

--######################## XUiRecommendGrid ########################
---@class XUiRecommendGrid
local XUiRecommendGrid = XClass(nil, "XUiRecommendGrid")

local RecommendUiProxy = {
    [CS.XGame.ClientConfig:GetInt(XEnumConst.Purchase.Recommend.Luna)] = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendLuna"),
    [CS.XGame.ClientConfig:GetInt(XEnumConst.Purchase.Recommend.CompanyPackage)] = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendCompanyPackage"),
    [CS.XGame.ClientConfig:GetInt(XEnumConst.Purchase.Recommend.ComboPackage)] = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendComboPackage/XUiPanelRecommendComboPackage")
}

function XUiRecommendGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    ---@type XUiPanelRecommendBase
    self.UiPanelRecommend = nil
end

---@param data XPurchaseRecommend
function XUiRecommendGrid:SetData(data, skipFunc, buyFinished)
    self:SetUiProxy(data:GetPurchasePackageId())
    local go
    if self.Transform.childCount > 0 then
        go = self.Transform:GetChild(0):LoadPrefab(data:GetAssetPath())
    else
        go = self.GameObject:LoadPrefab(data:GetAssetPath())
    end
    self.UiPanelRecommend:SetUi(go)
    self.UiPanelRecommend:SetData(data, skipFunc, buyFinished)
end

function XUiRecommendGrid:PlayEnableAnim()
    if self.UiPanelRecommend then
        self.UiPanelRecommend:PlayEnableAnim()
    end
end

function XUiRecommendGrid:SetUiProxy(purchaseId)
    local cls = RecommendUiProxy[purchaseId]
    if cls then
        self.UiPanelRecommend = cls.New()
    else
        self.UiPanelRecommend = XUiPanelRecommendBase.New()
    end
end

--######################## XUiPurchaseRecommend ########################
---@class XUiPurchaseRecommend
---@field GameObject UnityEngine.GameObject
---@field RootUi XUiPurchase
local XUiPurchaseRecommend = XClass(nil, "XUiPurchaseRecommend")

function XUiPurchaseRecommend:Ctor(ui, rootUi, skipFunc)
    --- 页签切换索引偏差，超过这个偏差不滑动到目标而是直接重新加载
    self._IndexOffsetLimitForReload = CS.XGame.ClientConfig:GetInt('PurchaseRecommendReloadIndexOffset')

    if not XTool.IsNumberValidEx(self._IndexOffsetLimitForReload) then
        self._IndexOffsetLimitForReload = 2
    end
    
    XUiHelper.InitUiClass(self, ui)
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.RecommendManager = self.PurchaseManager.GetRecommendManager()
    ---@type XPurchaseRecommend[]
    self.Recommends = nil
    self.CurrentIndex = 1
    self.CurrentSelectId = nil
    self.RootUi = rootUi
    self.SkipFunc = skipFunc
    ---@type XDynamicTableCurve
    self.DynamicTable = XDynamicTableCurve.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiRecommendGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridPanel.gameObject:SetActiveEx(false)
end

function XUiPurchaseRecommend:OnRefresh(uiType, childTabIndex)
    if self.RootUi.TabGroup.CurSelectId == self.RootUi:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Recommend) then
        self:ShowPanel(uiType, childTabIndex)
    else
        self:UpdateRecommend(uiType, childTabIndex)
    end
end

function XUiPurchaseRecommend:UpdateRecommend(uiType, childTabIndex)
    -- 页签按钮
    self.Recommends = self.RecommendManager:GetRecommends()
    if #self.Recommends <= 0 then
        local index = self.RootUi:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Recommend)
        local button = self.RootUi.TabGroup:GetButtonByIndex(index)
        button.gameObject:SetActiveEx(false)
        self:HidePanel()
        self.SkipFunc(XPurchaseConfigs.TabsConfig.LB)
        return
    end

    -- 选中子页签
    if childTabIndex then
        for i = 1, #self.Recommends do
            if self.Recommends[i]:GetPurchasePackageId() == childTabIndex then
                self.CurrentIndex = i
                break
            end
        end
    end
    
    local btns = {}
    XUiHelper.RefreshCustomizedList(self.PanelTabGroup.transform, self.BtnTab, #self.Recommends, function(index, child)
        local button = child:GetComponent("XUiButton")
        local uiObject = child:GetComponent("UiObject")
        local recommend = self.Recommends[index]
        local timeTip = recommend:GetLeaveTimeTip()
        button:SetNameByGroup(0, recommend:GetName())
        button:SetNameByGroup(1, timeTip)
        button:SetNameByGroup(2, timeTip)
        local isRare = recommend:GetIsRare()
        local isShowTimeTip = recommend:GetIsShowTimeTip()
        
        local stateName = 'StateEmpty'
        
        if isShowTimeTip then
            stateName = 'State'..tostring(isRare)
        end

        uiObject:GetObject("StateControl"):ChangeState(stateName)
        
        button:ShowReddot(recommend:GetIsShowRedPoint())
        table.insert(btns, button)
    end)
    self.PanelTabGroup:Init(btns, function(tabIndex)
        self:OnBtnTabClicked(tabIndex)
    end)
    self.CurrentIndex = self:GetCurrentSelectIndex()
    if #btns > 0 then
        -- 数组越界处理
        if self.CurrentIndex > #btns then self.CurrentIndex = #btns end
        self.PanelTabGroup:SelectIndex(self.CurrentIndex)
        
        XScheduleManager.ScheduleNextFrame(function()
            -- 判断自己有没销毁
            if not self or not self.GameObject:Exist() then
                return
            end
            
            local button = self.PanelTabGroup:GetButtonByIndex(self.CurrentIndex)
            -- 尝试滑动聚焦到该按钮
            self:TryFocusStage(button)
        end)
    end
    -- 刷新推荐
    self.DynamicTable:SetDataSource(self.Recommends)
    self.DynamicTable:ReloadData(self.CurrentIndex - 1)
end

---@param grid XUiRecommendGrid
function XUiPurchaseRecommend:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index + 1], self.SkipFunc, function()
            if XTool.UObjIsNil(self.RootUi.TabGroup) then
                return
            end
            self:OnRefresh()
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if self.DynamicTable:GetTweenIndex() == self.CurrentIndex - 1 then
            return
        end
        self.CurrentIndex = self.DynamicTable:GetTweenIndex() + 1
        self.PanelTabGroup:SelectIndex(self.CurrentIndex)
    end
end

function XUiPurchaseRecommend:ShowPanel(uiType, childTabIndex)
    self.GameObject:SetActiveEx(true)
    if self.RootUi.PanelTjTabEx then
        self.RootUi.PanelTjTabEx.gameObject:SetActiveEx(true)
    end
    self:UpdateRecommend(uiType, childTabIndex)
end

function XUiPurchaseRecommend:HidePanel()
    self.GameObject:SetActiveEx(false)
    if self.RootUi.PanelTjTabEx then
        self.RootUi.PanelTjTabEx.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseRecommend:OnBtnTabClicked(index)
    local indexOffset = math.abs(index - self.CurrentIndex)
    
    self.CurrentIndex = index
    local recommend = self.Recommends[index]
    recommend:SetShowRedPoint()
    self.CurrentSelectId = recommend:GetPurchasePackageId()

    if indexOffset <= self._IndexOffsetLimitForReload then
        self.DynamicTable:TweenToIndex(index - 1)
    else
        self.DynamicTable:SetDataSource(self.Recommends)
        self.DynamicTable:ReloadData(index - 1)
    end

    local button = self.PanelTabGroup:GetButtonByIndex(index)
    button:ShowReddot(false)
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASE_RECOMMEND_RED)
    --[[
    local isActiveSellOut = recommend:GetIsSellOut()
    if isActiveSellOut then
        self.RootUi.ImgSellOutDisable:Stop()
        self.RootUi.ImgSellOutEnable.time = 0
        self.RootUi.ImgSellOutEnable:Play()
    else
        if self._LastActiveSellOut then
            self.RootUi.ImgSellOutEnable:Stop()
            self.RootUi.ImgSellOutDisable.time = 0
            self.RootUi.ImgSellOutDisable:Play()
        end
    end
    self._LastActiveSellOut = isActiveSellOut
    ]]
    local grid = self.DynamicTable:GetGridByIndex(index - 1)
    if grid then
        grid:PlayEnableAnim()
    end
end

function XUiPurchaseRecommend:RefreshTimeData()
    if self.Recommends == nil then return end
    for i, _ in ipairs(self.Recommends) do
        local button = self.PanelTabGroup:GetButtonByIndex(i)
        local timeTip = self.Recommends[i]:GetLeaveTimeTip()
        button:SetNameByGroup(1, timeTip)
        button:SetNameByGroup(2, timeTip)
        if not self.Recommends[i]:GetIsInTime() then
            self:OnRefresh()
            break
        end
    end
end

function XUiPurchaseRecommend:GetCurrentSelectIndex()
    if XTool.IsTableEmpty(self.Recommends) or not XTool.IsNumberValid(self.CurrentSelectId) then
        return self.CurrentIndex
    end

    for i = #self.Recommends, 1, -1 do
        local recommend = self.Recommends[i]

        if recommend and recommend:GetPurchasePackageId() == self.CurrentSelectId then
            return i
        end
    end

    return self.CurrentIndex
end

--region -------------------- 滚动视图 --------------------

function XUiPurchaseRecommend:PlayScrollViewMoveBack(tarPosY, isElastic)
    local moveDuration = CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration')
    local tarPos = self.PanelGroupList.content.localPosition
    tarPos.y = tarPosY

    XLuaUiManager.SetMask(true)
    self._FocusScrollMoving = true
    self.PanelGroupList.inertia = false
    XUiHelper.DoMove(self.PanelGroupList.content, tarPos, moveDuration, XUiHelper.EaseType.Sin, function()
        if isElastic then
            self.PanelGroupList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        else
            self.PanelGroupList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XLuaUiManager.SetMask(false)
        self._FocusScrollMoving = false
        self.PanelGroupList.inertia = true
    end)
end

function XUiPurchaseRecommend:TryFocusStage(selectGrid)
    if not self.PanelGroupList then
        return
    end
    
    if selectGrid then
        local halfScreenHeight = self.PanelGroupList.viewport.rect.height / 2
        local moveMinY = halfScreenHeight
        local moveMaxY = self.PanelGroupList.content.rect.height - halfScreenHeight
        
        -- 无法滑动
        if moveMaxY <= moveMinY then
            moveMaxY = moveMinY
        end

        local tarPosY = - selectGrid.transform.localPosition.y
        local fixedPositionY = CS.UnityEngine.Mathf.Clamp(tarPosY, moveMinY, moveMaxY)
        self:PlayScrollViewMoveBack(fixedPositionY, true)
    end
end

--endregion

return XUiPurchaseRecommend