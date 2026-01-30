local XUiGridDlcRelinkLoadingCharacter = require("XUi/XUiDlcRelink/Loading/XUiGridDlcRelinkLoadingCharacter")
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
end

function XUiDlcRelinkLoadingNew:OnEnable()
    self:RefreshInfo()
    self:RefreshCharacter()
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
            grid:RefreshProgress(100)
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
    if self.PanelTips then
        self.PanelTips.gameObject:SetActiveEx(not XTool.IsTableEmpty(tips))
    end
    if not XTool.IsTableEmpty(tips) then
        local tipIndex = math.random(1, #tips)
        self.TxtTips.text = tips[tipIndex] or ""
    end
end

function XUiDlcRelinkLoadingNew:RefreshCharacter()
    local playerDataList = self.WorldData:GetPlayerDataList()
    local newPlayerDataList = self:PreprocessPlayerData(playerDataList, XPlayer.Id)

    for index, playerData in ipairs(newPlayerDataList) do
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

-- 将自己的数据放在第一位
function XUiDlcRelinkLoadingNew:PreprocessPlayerData(playerDataList, myPlayerId)
    if XTool.IsTableEmpty(playerDataList) or not XTool.IsNumberValid(myPlayerId) then
        return playerDataList
    end

    local myIndex = 0
    for index, playerData in pairs(playerDataList) do
        if playerData:GetPlayerId() == myPlayerId then
            myIndex = index
            break
        end
    end

    if myIndex <= 0 or myIndex == 1 then
        return playerDataList
    end

    local newPlayerDataList = {}
    newPlayerDataList[1] = playerDataList[myIndex]

    local newIndex = 2
    for index, playerData in pairs(playerDataList) do
        if index ~= myIndex then
            newPlayerDataList[newIndex] = playerData
            newIndex = newIndex + 1
        end
    end

    return newPlayerDataList
end

return XUiDlcRelinkLoadingNew
