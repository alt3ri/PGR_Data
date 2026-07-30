local XUiEnvelopeGuessingCollectionCharacterCard =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingCollectionCharacterCard")

local XDynamicTableNormal =
    require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiEnvelopeGuessingSubUi =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingSubUi")

local XUiEnvelopeGuessingCollection =
    XLuaUiManager.Register(XUiEnvelopeGuessingSubUi, "UiEnvelopeGuessingCollection")

-- 卡片入场动画间隔（0.02s）
local ENTER_ANIM_INTERVAL = 20

function XUiEnvelopeGuessingCollection:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")

    self._OnGridClickHandler = handler(self, self._OnGridClick),

    self.GridCollection.gameObject:SetActiveEx(false)

    self._DynTable = XDynamicTableNormal.New(self.PanelList.gameObject)
    self._DynTable:SetProxy(XUiEnvelopeGuessingCollectionCharacterCard, self)
    self._DynTable:SetDelegate(self)

    local allCharConf = self._Control:GetAllCharacterConfigs()

    self._Collection = XTool.Clone(allCharConf)
end

function XUiEnvelopeGuessingCollection:_Refresh()
    local unlockedCharacters = self._Control:GetOpenedCharacterCount()
    self.TxtProgressNum.text = unlockedCharacters .. "/" .. #self._Collection

    table.sort(self._Collection, function(a, b)
        local aUnlocked = self._Control:IsCharacterOpened(a.Id)
        local bUnlocked = self._Control:IsCharacterOpened(b.Id)

        if aUnlocked and not bUnlocked then
            return true -- 已解锁的在前边
        end

        if not aUnlocked and bUnlocked then
            return false -- 未解锁的在后边
        end

        local aWatched = self._Control:IsCharacterStoryWatched(a.Id)
        local bWatched = self._Control:IsCharacterStoryWatched(b.Id)

        if aWatched and not bWatched then
            return false -- 已观看的在后边
        end

        if not aWatched and bWatched then
            return true -- 未观看的在前边
        end

        return a.Id < b.Id
    end)

    self._DynTable:SetDataSource(self._Collection)
    self._DynTable:ReloadDataASync()
end

function XUiEnvelopeGuessingCollection:OnEnable()
    self:_Refresh()
    self.Super.OnEnable(self)
end

function XUiEnvelopeGuessingCollection:OnDisable()
    self:_StopGridsEnterAnimation()
    self.Super.OnDisable(self)
end

function XUiEnvelopeGuessingCollection:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._Collection[index], self._OnGridClickHandler)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_PlayGridsEnterAnimation()
    end
end

-- 列表加载完成后，播放各卡片入场动画
function XUiEnvelopeGuessingCollection:_PlayGridsEnterAnimation()
    self:_StopGridsEnterAnimation()

    local grids = self._DynTable:GetGrids()
    local count = #grids
    if count == 0 then
        return
    end

    XLuaUiManager.SetMask(true, self.Name)

    -- 播放前先隐藏所有卡片
    for i = 1, count do
        grids[i]:HideForEnterAnimation()
    end

    local index = 0
    self._EnterAnimTimerId = XScheduleManager.Schedule(function()
        index = index + 1
        local grid = grids[index]
        if grid then
            grid:PlayEnterAnimation()
        end
        if index >= count then
            self:_StopGridsEnterAnimation()
        end
    end, ENTER_ANIM_INTERVAL, count, 500)
end

function XUiEnvelopeGuessingCollection:_StopGridsEnterAnimation()
    if self._EnterAnimTimerId then
        XScheduleManager.UnSchedule(self._EnterAnimTimerId)
        self._EnterAnimTimerId = nil
    end
    if XLuaUiManager.IsMaskShow(self.Name) then
        XLuaUiManager.SetMask(false, self.Name)
    end
end

function XUiEnvelopeGuessingCollection:_OnGridClick(characterConf)
    if self._Control:IsCharacterOpened(characterConf.Id) then
        XLuaUiManager.Open("UiEnvelopeGuessingDetail", characterConf)
    else
        XUiManager.TipText("EnvelopeGuessingCollectionUiClickLockedCharacterTips")
    end
end

return XUiEnvelopeGuessingCollection
