local XUiGridRelinkLoadingPlater = require("XUi/XUiDlcRelink/Loading/XUiGridRelinkLoadingPlater")
---@class XUiRelinkLoading : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiRelinkLoading = XLuaUiManager.Register(XLuaUi, "UiRelinkLoading")

function XUiRelinkLoading:OnAwake()
    self.GridPlayer.gameObject:SetActiveEx(false)
    self.CurrentTipIndex = 1
    self.CurrentFinishCount = 0
    self.AllPlayerCount = 0

    ---@type table<number, XUiGridRelinkLoadingPlater>
    self.OnLoadingPlayerMap = {}
end

function XUiRelinkLoading:OnStart()
    self.Tips = self._Control:GetLoadingTips()
    self:InitItemList()
end

function XUiRelinkLoading:OnEnable()
    self:RefreshTips()
    self:RegisterTipsTimer()
end

function XUiRelinkLoading:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_FIGHT_LOADING,
        XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS,
    }
end

function XUiRelinkLoading:OnNotify(event, ...)
    local args = { ... }
    self:OnRefreshProcess(args[1], args[2])
end

function XUiRelinkLoading:OnDisable()
    self:RemoveTipsTimer()
end

function XUiRelinkLoading:InitItemList()
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()
    local worldData = (not fightBeginData:IsWorldClear()) and fightBeginData:GetWorldData() or nil
    local playerDataList = (worldData and worldData:GetPlayerDataList()) or {}

    self.OnLoadingPlayerMap = {}
    for _, playerData in ipairs(playerDataList) do
        local go = XUiHelper.Instantiate(self.GridPlayer, self.ListPlayer)
        ---@type XUiGridRelinkLoadingPlater
        local grid = XUiGridRelinkLoadingPlater.New(go, self)
        self.OnLoadingPlayerMap[playerData:GetPlayerId()] = grid
        grid:Open()
        grid:Refresh(playerData)
    end

    self.TxtTitle.text = self._Control:GetCurrentWorldArtName()
    self.Bg:SetRawImage(self._Control:GetCurrentWorldLoadingBackground())
    self.AllPlayerCount = #playerDataList
    self:InitProgress()
    self:RefreshFinishCount()
end

function XUiRelinkLoading:InitProgress()
    if not XMVCA.XDlcRoom:IsReconnect() then
        return
    end
    for playerId, grid in pairs(self.OnLoadingPlayerMap) do
        if playerId ~= XPlayer.Id then
            grid:RefreshProgress(100)
        end
    end
end

function XUiRelinkLoading:RefreshTips()
    if self.CurrentTipIndex > #self.Tips then
        self.CurrentTipIndex = 1
    end

    self.TxtTips.text = self.Tips[self.CurrentTipIndex] or ""
    self.CurrentTipIndex = self.CurrentTipIndex + 1
end

function XUiRelinkLoading:OnRefreshProcess(playerId, progress)
    local grid = self.OnLoadingPlayerMap[playerId]
    if not grid then
        return
    end
    grid:RefreshProgress(progress)
end

function XUiRelinkLoading:RefreshFinishCount()
    if self.CurrentFinishCount > self.AllPlayerCount then
        self.CurrentFinishCount = self.AllPlayerCount
    end

    self.TxtNum.text = string.format("(%s/%s)", self.CurrentFinishCount, self.AllPlayerCount)
    self.CurrentFinishCount = self.CurrentFinishCount + 1
end

function XUiRelinkLoading:RegisterTipsTimer()
    self:RemoveTipsTimer()
    if XTool.IsTableEmpty(self.Tips) then
        return
    end

    local interval = tonumber(self._Control:GetClientConfig("LoadingTipsScrollingTime")) or 1
    self.TipsTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:RemoveTipsTimer()
            return
        end
        self:RefreshTips()
    end, interval * XScheduleManager.SECOND)
end

function XUiRelinkLoading:RemoveTipsTimer()
    if self.TipsTimer then
        XScheduleManager.UnSchedule(self.TipsTimer)
        self.TipsTimer = nil
    end
end

return XUiRelinkLoading
