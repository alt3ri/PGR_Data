local XUiGridDlcRelinkSettlementCharacter = require("XUi/XUiDlcRelink/Settlement/XUiGridDlcRelinkSettlementCharacter")

local MAX_PLAYER_COUNT = 3

local GRID_VISIBILITY_CONFIG = {
    [1] = { true, false, false }, -- 1人：只显示中间位置
    [2] = { false, true, true }, -- 2人：显示左右两侧
    [3] = { true, true, true }, -- 3人：全部显示
}

local PLAYER_POSITION_CONFIG = {
    [2] = { 2, 3 }, -- 2人：自己在右侧，队友在左侧
    [3] = { 1, 2 }, -- 3人：自己在中间，队友在两侧
}

---@class XUiPanelDlcRelinkSettlementCharacter : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkSettlementNew
local XUiPanelDlcRelinkSettlementCharacter = XClass(XUiNode, "XUiPanelDlcRelinkSettlementCharacter")

function XUiPanelDlcRelinkSettlementCharacter:OnStart()
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.BtnNext:AddEventListener(handler(self, self.OnBtnNextClick))

    ---@type XUiGridDlcRelinkSettlementCharacter[]
    self.CharacterGridList = {}
end

---@param playerSettleResults XDlcRelinkPlayerSettleResult[]
---@param customData table<number, table<number, number>>
function XUiPanelDlcRelinkSettlementCharacter:Refresh(playerSettleResults, customData)
    if XTool.IsTableEmpty(playerSettleResults) then
        return
    end
    self.PlayerSettleResults = playerSettleResults
    self.CustomData = customData

    self:SetGridVisibility(#playerSettleResults)

    local maxSource = 0
    local maxSourceIndex = 0
    local newPlayerSettleResults = self:PreprocessPlayerSettleResults(playerSettleResults, XPlayer.Id)
    for index, playerSettleResult in pairs(newPlayerSettleResults) do
        local grid = self.CharacterGridList[index]
        if not grid then
            local parent = self[string.format("GridCharacter%s", index)]
            if not parent then
                XLog.Error(string.format("XUiPanelDlcRelinkSettlementCharacter:Refresh error: not find GridCharacter%s", index))
                return
            end
            local go = XUiHelper.Instantiate(self.GridCharacter, parent)
            grid = XUiGridDlcRelinkSettlementCharacter.New(go, self)
            self.CharacterGridList[index] = grid
        end

        local playerCustomData = not XTool.IsTableEmpty(self.CustomData) and self.CustomData[playerSettleResult.PlayerId] or nil
        local fixedScore = self._Control:GetFixedScore(playerCustomData)

        grid:Open()
        grid:Refresh(playerSettleResult, self.CustomData, fixedScore)
        grid:SetTagBest(false)

        if fixedScore > maxSource then
            maxSource = fixedScore
            maxSourceIndex = index
        end
    end

    if maxSourceIndex > 0 then
        local grid = self.CharacterGridList[maxSourceIndex]
        if grid then
            grid:SetTagBest(true)
        end
    end
end

-- 根据玩家数量设置网格可见性
function XUiPanelDlcRelinkSettlementCharacter:SetGridVisibility(playerCount)
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
---@param playerSettleResults XDlcRelinkPlayerSettleResult[]
---@param myPlayerId number
---@return XDlcRelinkPlayerSettleResult[]
function XUiPanelDlcRelinkSettlementCharacter:PreprocessPlayerSettleResults(playerSettleResults, myPlayerId)
    if XTool.IsTableEmpty(playerSettleResults) or not XTool.IsNumberValid(myPlayerId) then
        return playerSettleResults
    end

    local playerCount = #playerSettleResults
    if playerCount == 1 then
        return playerSettleResults
    end

    local config = PLAYER_POSITION_CONFIG[playerCount]
    if not config then
        -- 没有配置则保持原顺序
        return playerSettleResults
    end

    -- 分离自己和其他玩家
    local myResult
    local others = {}
    for _, playerSettleResult in pairs(playerSettleResults) do
        if playerSettleResult.PlayerId == myPlayerId then
            myResult = playerSettleResult
        else
            others[#others + 1] = playerSettleResult
        end
    end
    if not myResult then
        XLog.Error("XUiPanelDlcRelinkSettlementCharacter:PreprocessPlayerSettleResults error: not find my player settle result")
        return playerSettleResults
    end

    -- 根据配置重新排列
    local newPlayerSettleResults = {}
    newPlayerSettleResults[config[1]] = myResult
    -- 放置其他玩家
    for i, result in pairs(others) do
        newPlayerSettleResults[config[2] + i - 1] = result
    end

    return newPlayerSettleResults
end

function XUiPanelDlcRelinkSettlementCharacter:OnBtnNextClick()
    self.Parent:RefreshPanelReward()
    self:Close()
end

return XUiPanelDlcRelinkSettlementCharacter
