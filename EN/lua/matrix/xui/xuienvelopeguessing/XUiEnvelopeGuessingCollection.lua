local XUiEnvelopeGuessingCollectionCharacterCard = require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingCollectionCharacterCard")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiEnvelopeGuessingCollection : XLuaUi
---@field private _Control XEnvelopeGuessingControl
local XUiEnvelopeGuessingCollection = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingCollection")

-- 卡片入场动画间隔（0.02s）
local ENTER_ANIM_INTERVAL = 20

function XUiEnvelopeGuessingCollection:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")

    self._OnGridClickHandler = handler(self, self._OnGridClick)

    self.GridCollection.gameObject:SetActiveEx(false)

    self._DynTable = XDynamicTableNormal.New(self.PanelList.gameObject)
    self._DynTable:SetProxy(XUiEnvelopeGuessingCollectionCharacterCard, self)
    self._DynTable:SetDelegate(self)

    local allCharConf = self._Control:GetAllCharacterConfigs()

    self._Collection = XTool.Clone(allCharConf)

    -- 设置自动关闭
    self:SetAutoCloseInfo(XMVCA.XEnvelopeGuessing:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
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
    -- 排序后角色位置会变，定位到上次查看的角色
    self._DynTable:ReloadDataASync(self:_GetLastViewedIndex())
end

-- 上次查看角色在排序后列表中的下标
function XUiEnvelopeGuessingCollection:_GetLastViewedIndex()
    if not XTool.IsNumberValid(self._LastViewedCharacterId) then
        return -1
    end

    for index, characterConf in ipairs(self._Collection) do
        if characterConf.Id == self._LastViewedCharacterId then
            return index
        end
    end

    return -1
end

function XUiEnvelopeGuessingCollection:OnEnable()
    self:_Refresh()
end

function XUiEnvelopeGuessingCollection:OnDisable()
    self:_StopGridsEnterAnimation()
end

---@param grid XUiEnvelopeGuessingCollectionCharacterCard
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

    local visibleGrids = {}
    local grids = self._DynTable:GetGrids()
    for _, grid in pairs(grids or {}) do
        table.insert(visibleGrids, grid)
    end

    local count = #visibleGrids
    if count == 0 then
        return
    end

    table.sort(visibleGrids, function(a, b)
        return a.Index < b.Index
    end)

    XLuaUiManager.SetMask(true, self.Name)

    -- 播放前先隐藏所有卡片
    for i = 1, count do
        local grid = visibleGrids[i]
        if grid then
            grid:HideForEnterAnimation()
        end
    end

    local index = 0
    self._EnterAnimTimerId = XScheduleManager.Schedule(function()
        index = index + 1
        local grid = visibleGrids[index]
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
        -- 缓存查看的角色
        self._LastViewedCharacterId = characterConf.Id
        XLuaUiManager.Open("UiEnvelopeGuessingDetail", characterConf)
    else
        XUiManager.TipText("EnvelopeGuessingCollectionUiClickLockedCharacterTips")
    end
end

function XUiEnvelopeGuessingCollection:OnReleaseInst()
    return self._LastViewedCharacterId
end

function XUiEnvelopeGuessingCollection:OnResume(value)
    if XTool.IsNumberValid(value) then
        self._LastViewedCharacterId = value
    end
end

return XUiEnvelopeGuessingCollection
