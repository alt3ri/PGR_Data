local XUiGridDlcRelinkSettlementCharacter = require("XUi/XUiDlcRelink/Settlement/XUiGridDlcRelinkSettlementCharacter")
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
        
        local customData = not XTool.IsTableEmpty(self.CustomData) and self.CustomData[playerSettleResult.PlayerId] or nil
        local fixedScore = self._Control:GetFixedScore(customData)

        grid:Open()
        grid:Refresh(playerSettleResult, customData, fixedScore)
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

-- 通过玩家Id获取玩家名称
---@param playerId number
---@return string
function XUiPanelDlcRelinkSettlementCharacter:GetPlayerNameById(playerId)
    if not XTool.IsNumberValid(playerId) then
        return ""
    end

    if self.PlayerSettleResults then
        for _, playerSettleResult in pairs(self.PlayerSettleResults) do
            if playerSettleResult.PlayerId == playerId then
                return playerSettleResult.Name
            end
        end
    end
    return ""
end

-- 将自己的结算结果放在第一位
---@param playerSettleResults XDlcRelinkPlayerSettleResult[]
---@param myPlayerId number
---@return XDlcRelinkPlayerSettleResult[]
function XUiPanelDlcRelinkSettlementCharacter:PreprocessPlayerSettleResults(playerSettleResults, myPlayerId)
    if XTool.IsTableEmpty(playerSettleResults) or not XTool.IsNumberValid(myPlayerId) then
        return playerSettleResults
    end

    local myIndex = 0
    for index, playerSettleResult in pairs(playerSettleResults) do
        if playerSettleResult.PlayerId == myPlayerId then
            myIndex = index
            break
        end
    end

    if myIndex <= 0 or myIndex == 1 then
        return playerSettleResults
    end

    local newPlayerSettleResults = {}
    newPlayerSettleResults[1] = playerSettleResults[myIndex]

    local newIndex = 2
    for index, playerSettleResult in pairs(playerSettleResults) do
        if index ~= myIndex then
            newPlayerSettleResults[newIndex] = playerSettleResult
            newIndex = newIndex + 1
        end
    end

    return newPlayerSettleResults
end

function XUiPanelDlcRelinkSettlementCharacter:OnBtnNextClick()
    self.Parent:RefreshPanelReward()
    self:Close()
end

return XUiPanelDlcRelinkSettlementCharacter
