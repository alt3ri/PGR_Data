---@class XUiPanelFashionSuitNormal : XUiNode
---@field Parent XUiFashionSuitMain
---@field _Control XFashionSuitControl
local XUiPanelFashionSuitNormal = XClass(XUiNode, "XUiPanelFashionSuitNormal")

function XUiPanelFashionSuitNormal:OnStart()
    ---@type XUiGridCommon[]
    self._RewardGrids = {}
    self._Dots = {}
    self._SelectIndex = 0

    if not self.FullScreenBackground then
        self.FullScreenBackground = self.Transform:FindTransform("FullScreenBackground")
    end
    if not XTool.UObjIsNil(self.FullScreenBackground) then
        self.FullScreenBackground:SetParent(self.Parent.FullScreenBackground)
        self.FullScreenBackground.name = "Clone"
    end
end

function XUiPanelFashionSuitNormal:SetSuitId(id)
    self._Id = id
    self._Config = self._Control:GetFashionSuitById(id)
    self._FashionIds = self._Config.FashionIds
    self.RImgIcon:SetRawImage(self._Config.SuitBanner)
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

    if self._Config.SuitBackground then
        self.RImgBg:SetRawImage(self._Config.SuitBackground)
    end

    self:ShowDynamicTable()
end

function XUiPanelFashionSuitNormal:ShowDynamicTable()
    local count = #self._FashionIds
    if count == 1 then
        self.GridFashion.gameObject:SetActiveEx(true)
        self.PanelFashionListSmall.gameObject:SetActiveEx(false)
        self.PanelFashionListBig.gameObject:SetActiveEx(false)
        self.PanelDot.gameObject:SetActiveEx(false)
        ---@type XUiGridFashionSuitFashion
        local fashionGrid = require("XUi/XUiFashionSuit/Grid/XUiGridFashionSuitFashion").New(self.GridFashion, self)
        fashionGrid:Refresh(self._Id, self._FashionIds[1])
        fashionGrid:UpdateSelect(true)
        fashionGrid:AddClickEvt()
    elseif count >= 2 then
        --self:SetAutoTweenToIndex()
        local list = count == 2 and self.PanelFashionListSmall or self.PanelFashionListBig
        self.PanelFashionListSmall.gameObject:SetActiveEx(count == 2)
        self.PanelFashionListBig.gameObject:SetActiveEx(count > 2)
        ---@type XDynamicTableCurve
        self.DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve").New(list)
        self.DynamicTable:SetProxy(require("XUi/XUiFashionSuit/Grid/XUiGridFashionSuitFashion"), self)
        self.DynamicTable:SetDelegate(self)
        self.DynamicTable:SetDataSource(self._FashionIds)
        self.DynamicTable:ReloadData(self._SelectIndex)
        self.GridFashion.gameObject:SetActiveEx(false)
        self.PanelDot.gameObject:SetActiveEx(true)
        for i = 1, count do
            local dot = i == 1 and self.Dot or XUiHelper.Instantiate(self.Dot, self.Dot.parent)
            local uiObj = {}
            XUiHelper.InitUiClass(uiObj, dot)
            self._Dots[i] = uiObj
        end
        self:UpdateFashionSelect(1)
    else
        self.GridFashion.gameObject:SetActiveEx(false)
        self.PanelFashionListSmall.gameObject:SetActiveEx(false)
        self.PanelFashionListBig.gameObject:SetActiveEx(false)
        self.PanelDot.gameObject:SetActiveEx(false)
    end
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
        self._SelectIndex = selectIndex
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
    self._Control:RequestGetSuitReward(self._Id, function()
        self:UpdateView()
    end)
end

return XUiPanelFashionSuitNormal
