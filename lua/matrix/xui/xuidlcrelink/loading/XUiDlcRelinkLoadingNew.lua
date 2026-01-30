local XUiGridDlcRelinkLoadingCharacter = require("XUi/XUiDlcRelink/Loading/XUiGridDlcRelinkLoadingCharacter")

local MAX_PLAYER_COUNT = 3
local FULL_PROGRESS = 100

local GRID_VISIBILITY_CONFIG = {
    [1] = { true, false, false }, -- 1人：只显示中间位置
    [2] = { false, true, true }, -- 2人：显示左右两侧
    [3] = { true, true, true }, -- 3人：全部显示
}

local PLAYER_POSITION_CONFIG = {
    [2] = { 2, 3 }, -- 2人：自己在右侧，队友在左侧
    [3] = { 1, 2 }, -- 3人：自己在中间，队友在两侧
}

---@class XUiDlcRelinkLoadingNew : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkLoadingNew = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkLoadingNew")

function XUiDlcRelinkLoadingNew:OnAwake()
    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiDlcRelinkLoadingNew:OnStart()
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()
    self.WorldData = (not fightBeginData:IsWorldClear()) and fightBeginData:GetWorldData() or nil
    if not self.WorldData then
        XLog.Error("XUiDlcRelinkLoadingNew:OnStart error: worldData is nil")
        return
    end
    ---@type table<number, XUiGridDlcRelinkLoadingCharacter> playerId -> grid
    self.CharacterGridList = {}

    -- 清理点赞的缓存数据
    self._Control:ClearLikeInfoCache()
end

function XUiDlcRelinkLoadingNew:OnEnable()
    self:RefreshInfo()
    self:RefreshCharacter()
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        -- 重置引导，避免引导残留进入战斗
        if XDataCenter.GuideManager.CheckIsInGuide() then
            XDataCenter.GuideManager.ResetGuide()
        end
    end, 500)
end

function XUiDlcRelinkLoadingNew:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_FIGHT_LOADING,
        XEventId.EVENT_DLC_SELF_RECONNECT_LOADING_PROCESS,
    }
end

function XUiDlcRelinkLoadingNew:OnNotify(event, ...)
    local args = { ... }
    self:OnRefreshProcess(args[1], args[2])
end

function XUiDlcRelinkLoadingNew:OnRefreshProcess(playerId, progress)
    local grid = self.CharacterGridList[playerId]
    if grid then
        grid:RefreshProgress(progress)
    end
end

function XUiDlcRelinkLoadingNew:InitProgress()
    if not XMVCA.XDlcRoom:IsReconnect() then
        return
    end
    for playerId, grid in pairs(self.CharacterGridList) do
        if playerId ~= XPlayer.Id then
            grid:RefreshProgress(FULL_PROGRESS)
        end
    end
end

function XUiDlcRelinkLoadingNew:RefreshInfo()
    local levelId = self.WorldData:GetLevelId()
    local chapterId = self._Control:GetLevelChapterId(levelId)
    local chapterName = self._Control:GetChapterName(chapterId)
    local levelName = self._Control:GetLevelName(levelId)
    -- 关卡名称
    self.TxtName.text = string.format("%s-%s", levelName, chapterName)
    -- 关卡提示
    local tips = self._Control:GetLevelLoadingTips(levelId)
    local hasTips = not XTool.IsTableEmpty(tips)
    if self.PanelTips then
        self.PanelTips.gameObject:SetActiveEx(hasTips)
    end
    if hasTips then
        local tipIndex = math.random(1, #tips)
        self.TxtTips.text = tips[tipIndex] or ""
    end
    -- 缓存关卡数据结算时使用
    self._Control:SetSettlementCacheLevelData(levelId)
end

function XUiDlcRelinkLoadingNew:RefreshCharacter()
    local playerDataList = self.WorldData:GetPlayerDataList()
    self:SetGridVisibility(#playerDataList)
    local newPlayerDataList = self:PreprocessPlayerData(playerDataList, XPlayer.Id)

    for index, playerData in pairs(newPlayerDataList) do
        local playerId = playerData:GetPlayerId()
        local grid = self.CharacterGridList[playerId]
        if not grid then
            local parent = self[string.format("GridCharacter%d", index)]
            if not parent then
                XLog.Error("XUiDlcRelinkLoadingNew:RefreshCharacter error: can not find parent for index:" .. index)
                return
            end
            local go = XUiHelper.Instantiate(self.GridCharacter, parent)
            grid = XUiGridDlcRelinkLoadingCharacter.New(go, self)
            self.CharacterGridList[playerId] = grid
        end
        grid:Open()
        grid:Refresh(playerData)
    end

    self:InitProgress()
end

-- 设置角色网格的可见性
function XUiDlcRelinkLoadingNew:SetGridVisibility(playerCount)
    local visibility = GRID_VISIBILITY_CONFIG[playerCount] or GRID_VISIBILITY_CONFIG[MAX_PLAYER_COUNT]
    for i = 1, MAX_PLAYER_COUNT do
        local gridName = string.format("GridCharacter%d", i)
        local grid = self[gridName]
        if grid then
            grid.gameObject:SetActiveEx(visibility[i])
        end
    end
end

-- 根据人数调整玩家数据的位置索引
-- 布局规则：
--   1人：index=1 中间位置
--   2人：自己=2(右侧), 队友=3(左侧)
--   3人：自己=1(中间), 队友=2,3(两侧)
function XUiDlcRelinkLoadingNew:PreprocessPlayerData(playerDataList, myPlayerId)
    if XTool.IsTableEmpty(playerDataList) or not XTool.IsNumberValid(myPlayerId) then
        return playerDataList
    end

    local playerCount = #playerDataList
    if playerCount == 1 then
        return playerDataList
    end

    local config = PLAYER_POSITION_CONFIG[playerCount]
    if not config then
        -- 没有配置则保持原顺序
        return playerDataList
    end

    -- 分离自己和其他玩家
    local myPlayerData
    local otherPlayers = {}
    for _, playerData in pairs(playerDataList) do
        if playerData:GetPlayerId() == myPlayerId then
            myPlayerData = playerData
        else
            otherPlayers[#otherPlayers + 1] = playerData
        end
    end
    if not myPlayerData then
        XLog.Error("XUiDlcRelinkLoadingNew:PreprocessPlayerData error: myPlayerData is nil")
        return playerDataList
    end

    -- 根据配置重新排列
    local newPlayerDataList = {}
    newPlayerDataList[config[1]] = myPlayerData
    -- 放置其他玩家
    for i, playerData in pairs(otherPlayers) do
        newPlayerDataList[config[2] + i - 1] = playerData
    end

    return newPlayerDataList
end

return XUiDlcRelinkLoadingNew
