---@class XUiPanelFashionSuitNormal: XUiNode
---@field Parent   XUiFashionSuitMain
---@field _Control XFashionSuitControl
local XUiPanelFashionSuitNormal = XClass(XUiNode, "XUiPanelFashionSuitNormal")

function XUiPanelFashionSuitNormal:OnStart(suitId)
    ---@type XUiGridCommon[]
    self._RewardGrids = {}
    self._Dots = {}
    ---@type XUiGridFashionSuitFashion
    self._SingleFashionGrid = nil
    self._SelectIndex = 0
    self._OldSuit = false
    self:SetSuitId(suitId)

    self:ClearFashionGrids()
    if not self._OldSuit and self._UiConfig then
        -- 延迟显示动态表
        XScheduleManager.ScheduleOnce(function ()
            if XTool.UObjIsNil(self.GameObject) then return end
            self:ShowDynamicTable()
        end, self._UiConfig.EnableAnimDelay)
    else
        self:ShowDynamicTable()
    end
end

function XUiPanelFashionSuitNormal:SpecialSuitInit(suitId)
    local oldSuitId = self._Control:GetClientConfig("TempSuitIdV41")
    if tonumber(oldSuitId) == suitId then
        self._OldSuit = true
    end
    if self._OldSuit then
        if not self.FullScreenBackground then
            self.FullScreenBackground = self.Transform:FindTransform("FullScreenBackground")
        end
        if not XTool.UObjIsNil(self.FullScreenBackground) then
            self.FullScreenBackground:SetParent(self.Parent.FullScreenBackground)
            self.FullScreenBackground.name = "Clone"
        end
    end
end

function XUiPanelFashionSuitNormal:OnEnable()
    self:PlayAnimation("AnimEnable")
    self.GridFashion.gameObject:SetActiveEx(false)
    if self.InitDynamic then
        self:HideDynamicRootGO()
        if not self._OldSuit and self._UiConfig then
            -- 延迟显示动态表
            XScheduleManager.ScheduleOnce(function ()
                if XTool.UObjIsNil(self.GameObject) then return end
                self:ShowDynamicRootGO()
            end, self._UiConfig.EnableAnimDelay)
        else
            self:ShowDynamicRootGO()
        end
    end
end

function XUiPanelFashionSuitNormal:OnDestroy()
    self:ClearFashionGrids()
end

function XUiPanelFashionSuitNormal:SetSuitId(id)
    self:SpecialSuitInit(id)

    self._Id = id
    self._Config = self._Control:GetFashionSuitById(id)
    self._UiConfig = self._Control:GetFashionSuitUiConfigById(id)
    self._FashionIds = self._Config.FashionIds
    self.RImgIcon:SetRawImage(self._UiConfig.SuitBanner)
    self.TxtSeriesName.text = self._Config.Name
    self.TxtSeriesDetail.text = XUiHelper.ReplaceTextNewLine(self._Config.SuitDescription)

    if self._Config.IsComplete then
        local rewards = XRewardManager.GetRewardList(self._Config.RewardId)
        for i = 1, #rewards do
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.Grid256New.parent)
            ---@type XUiGridCommon
            local grid = require("XUi/XUiObtain/XUiGridCommon").New(self.Parent, go)
            grid:Refresh(rewards[i])
            grid.BtnRewardGain.CallBack = handler(self, self.GainReward)
            table.insert(self._RewardGrids, grid)
        end
    end

end

function XUiPanelFashionSuitNormal:ShowDynamicRootGO()
    local count = #self._FashionIds
    if count == 1 then
        self:HideDynamicRootGO()
    else
        self.PanelFashionListSmall.gameObject:SetActiveEx(count == 2)
        self.PanelFashionListBig.gameObject:SetActiveEx(count > 2)
    end
end

function XUiPanelFashionSuitNormal:HideDynamicRootGO()
    self.PanelFashionListSmall.gameObject:SetActiveEx(false)
    self.PanelFashionListBig.gameObject:SetActiveEx(false)
end

function XUiPanelFashionSuitNormal:ShowDynamicTable()
    local count = #self._FashionIds
    if count == 1 then
        self.GridFashion.gameObject:SetActiveEx(true)
        self.PanelDot.gameObject:SetActiveEx(false)
        ---@type XUiGridFashionSuitFashion
        self._SingleFashionGrid = require
            ("XUi/XUiFashionSuit/Grid/XUiGridFashionSuitFashion")
            .New(self.GridFashion, self)
        self._SingleFashionGrid:AddClickEvt()
        self._SingleFashionGrid:Refresh(self._Id, self._FashionIds[1])
        self._SingleFashionGrid:UpdateSelect(true)
    elseif count >= 2 then
        -- self:SetAutoTweenToIndex()
        local list = count == 2 and self.PanelFashionListSmall or self.PanelFashionListBig

        ---@type XDynamicTableCurve
        self.DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve").New(list)
        self.DynamicTable:SetProxy(require("XUi/XUiFashionSuit/Grid/XUiGridFashionSuitFashion"), self)
        self.DynamicTable:SetDelegate(self)
        self.DynamicTable:SetDataSource(self._FashionIds)
        self.DynamicTable:ReloadData(self._SelectIndex)
        self.GridFashion.gameObject:SetActiveEx(false)
        self.PanelDot.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.PanelDot, self.Dot, count, function (index, go)
            local uiObj = {}
            XUiHelper.InitUiClass(uiObj, go)
            self._Dots[index] = uiObj
        end, false
        )

        self:UpdateFashionSelect(1)
    else
        self.GridFashion.gameObject:SetActiveEx(false)
        self.PanelDot.gameObject:SetActiveEx(false)
    end
    self.InitDynamic = true
end

function XUiPanelFashionSuitNormal:SetAutoTweenToIndex()
    for i, id in ipairs(self._FashionIds) do
        if not self._Control:IsFashionViewed(id) then
            self._SelectIndex = i - 1
            return
        end
    end
end

function XUiPanelFashionSuitNormal:UpdateView()
    local total = #self._FashionIds
    local own = self._Control:GetCollectCount(self._Id)
    self._IsAllFashionGain = total == own
    if self.PanelCollectionStatus then
        self.PanelCollectionStatus.gameObject:SetActiveEx(self._Config.IsComplete)
    end
    if self._Config.IsComplete then
        self.PanelReward.gameObject:SetActiveEx(true)
        self.PanelTips.gameObject:SetActiveEx(false)
        self.ImgTag.gameObject:SetActiveEx(self._IsAllFashionGain)
        self.TxtProgress.text = XUiHelper.GetText("FashionSuitProgress", own, total)

        local isRewardGain = self._Control:IsSuitRewardGain(self._Id)
        for _, grid in pairs(self._RewardGrids) do
            local bo = self._IsAllFashionGain and not isRewardGain
            grid:SetReceived(isRewardGain)
            grid.Effect.gameObject:SetActiveEx(bo)
            grid.BtnRewardGain.gameObject:SetActiveEx(bo)
        end
    else
        self.Grid256New.gameObject:SetActiveEx(false)
        self.PanelReward.gameObject:SetActiveEx(false)
        self.PanelTips.gameObject:SetActiveEx(true)
        self.TxtNum.text = own
    end
end

---@param grid XUiGridFashionSuitFashion
function XUiPanelFashionSuitNormal:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index % self.DynamicTable.Imp.TotalCount + 1
        grid:Refresh(self._Id, self._Config.FashionIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount + 1
        self._SelectIndex = selectIndex - 1
        self:UpdateFashionSelect(selectIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.DynamicTable.Imp:TweenToIndex(index)
        if self.DynamicTable.Imp.StartIndex == index then
            grid:OpenDetail()
        end
    end
end

function XUiPanelFashionSuitNormal:UpdateFashionSelect(startIndex)
    ---@type XUiGridFashionSuitFashion[]
    local grids = self.DynamicTable:GetGrids()
    local index = self.DynamicTable.Imp.StartIndex
    for i, grid in pairs(grids) do
        grid:UpdateSelect(i == index)
    end
    for i, grid in ipairs(self._Dots) do
        grid.ImgDotNormal.gameObject:SetActiveEx(i ~= startIndex)
        grid.ImgDotSelect.gameObject:SetActiveEx(i == startIndex)
    end
end

function XUiPanelFashionSuitNormal:GainReward()
    self._Control:RequestGetSuitReward(self._Id, function ()
        self:UpdateView()
    end)
end

function XUiPanelFashionSuitNormal:ClearFashionGrids()
    if self._SingleFashionGrid then
        self:RemoveChildNode(self._SingleFashionGrid)
        self:ReleaseFashionGrid(self._SingleFashionGrid)
        self._SingleFashionGrid = nil
    end

    if self.DynamicTable then
        local grids = self.DynamicTable:GetGrids()
        for _, grid in pairs(grids or {}) do
            self:RemoveChildNode(grid)
            self:ReleaseFashionGrid(grid)
        end
        self.DynamicTable:Clear()
        self.DynamicTable = nil
    end

    self._Dots = {}
    self.InitDynamic = false
end

---@param grid XUiGridFashionSuitFashion
function XUiPanelFashionSuitNormal:ReleaseFashionGrid(grid)
    if not grid then
        return
    end

    grid:OnDestroyUi()
    grid:Release()
end

return XUiPanelFashionSuitNormal
