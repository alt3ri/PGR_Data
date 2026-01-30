local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRiftRankingGrid = require("XUi/XUiRift/Grid/XUiRiftRankingGrid")

---@class XUiRiftRanking:XLuaUi 大秘境排行榜
---@field _Control XRiftControl
local XUiRiftRanking = XLuaUiManager.Register(XLuaUi, "UiRiftRanking")

function XUiRiftRanking:OnAwake()
    self._RankDatas = {}
    self:RegisterEvent()
    self:InitDynamicTable()
    self:InitMyRankPanel()
    self:InitTimes()
    self:InitRankGroup()
    self.TxtAndroid.gameObject:SetActive(false) --排行榜没有分安卓苹果，这里先隐藏
    self.PlayerRank.gameObject:SetActive(false)
end

function XUiRiftRanking:OnEnable()
    self.Super.OnEnable(self)
    self.PanelTabBtn:SelectIndex(1)
end

function XUiRiftRanking:RegisterEvent()
    self.BtnMainUi.CallBack = handler(self, function() XLuaUiManager.RunMain() end)
    self.BtnBack.CallBack = handler(self, self.Close)
end

function XUiRiftRanking:InitRankGroup()
    local index = 1
    local btns = {}
    self.BtnLockTips = {}
    local chapters = self._Control:GetEntityChapter()
    ---@param data XRiftChapter
    self:RefreshTemplateGrids(self.BtnRank, chapters, self.BtnRank.parent, nil, "", function(grid, data)
        table.insert(btns, grid.BtnRank)
        local chapterName = data:GetConfig().Name
        local isLock = data:CheckTimeLock()
        grid.BtnRank:SetButtonState(isLock and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
        grid.BtnRank:SetNameByGroup(0, chapterName)
        if isLock then
            self.BtnLockTips[index] = XUiHelper.GetText("RiftChapterRankLock", chapterName)
        end
        index = index + 1
    end)
    self.PanelTabBtn:Init(btns, function(index)
        self:OnTabSelected(index)
    end)
end

function XUiRiftRanking:OnTabSelected(index)
    if self.BtnLockTips[index] then
        XUiManager.TipError(self.BtnLockTips[index])
        return
    end

    if self.CurSelectIdx == index then
        return
    end

    self.CurSelectIdx = index
    self._IsPlayTween = true

    if self._RankDatas[index] then
        self:UpdateRank()
    else
        self._Control:RequireRanking(function(res)
            self._RankDatas[index] = res
            self:UpdateRank()
        end, index)
    end
end

function XUiRiftRanking:UpdateRank()
    self:RefreshDynamicTable()
    self:RefreshMyRank()
    if self._IsPlayTween then
        self:PlayAnimation("QieHuan")
    end
end

function XUiRiftRanking:IsCurTabEndless()
    return self._Control:GetEntityChapterById(self.CurSelectIdx):IsEndless()
end

function XUiRiftRanking:InitMyRankPanel()
    ---@type XUiRiftRankingGrid
    self.MyRank = XUiRiftRankingGrid.New(self.PanelMyRank, self)
    self.MyRank:Init()
end

function XUiRiftRanking:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiRiftRanking:RefreshMyRank()
    local hasRank = self:IsHasRank()
    self.PanelInfo.gameObject:SetActiveEx(hasRank)
    self.Bg.gameObject:SetActiveEx(hasRank)
    if hasRank then
        local rankInfo = self:GetMyRankInfo()
        self.MyRank:Refresh(rankInfo)
    end
end

---------------------------------------- 动态列表 start ----------------------------------------
function XUiRiftRanking:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiRiftRankingGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftRanking:RefreshDynamicTable()
    self.DataList = self:GetRankingList()
    self.PanelNoRank.gameObject:SetActiveEx((not next(self.DataList)))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiRiftRankingGrid
function XUiRiftRanking:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end
---------------------------------------- 动态列表 end ----------------------------------------

function XUiRiftRanking:GetRankingList()
    local rankData = self._RankDatas[self.CurSelectIdx]
    return rankData and rankData.RankPlayerInfos or nil
end

function XUiRiftRanking:IsHasRank()
    local rankData = self._RankDatas[self.CurSelectIdx]
    return rankData and XTool.IsNumberValid(rankData.Rank) or false
end

function XUiRiftRanking:GetMyRankInfo()
    local rankData = self._RankDatas[self.CurSelectIdx]
    if not rankData then
        return nil
    end
    local myRank = {}
    local percentRank = 100 -- 101名及以上显示百分比
    local rank = rankData.Rank
    if rankData.Rank > percentRank then
        rank = math.max(1, math.floor(rankData.Rank * 100 / rankData.TotalCount)) .. "%" -- 最小显示1%
    elseif rankData.Rank == 0 then
        rank = XUiHelper.GetText("ExpeditionNoRanking")
    end
    myRank["Rank"] = rank
    myRank["Id"] = XPlayer.Id
    myRank["Name"] = XPlayer.Name
    myRank["HeadPortraitId"] = XPlayer.CurrHeadPortraitId
    myRank["HeadFrameId"] = XPlayer.CurrHeadFrameId
    myRank["Score"] = rankData.Score
    myRank["CharacterIds"] = rankData.CharacterIds
    return myRank
end

return XUiRiftRanking
