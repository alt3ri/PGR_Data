local XUiPanelDlcRelinkSettlementResult = require("XUi/XUiDlcRelink/Settlement/XUiPanelDlcRelinkSettlementResult")
local XUiPanelDlcRelinkSettlementCharacter = require("XUi/XUiDlcRelink/Settlement/XUiPanelDlcRelinkSettlementCharacter")
local XUiPanelDlcRelinkSettlementReward = require("XUi/XUiDlcRelink/Settlement/XUiPanelDlcRelinkSettlementReward")
---@class XUiDlcRelinkSettlementNew : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkSettlementNew = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkSettlementNew")

function XUiDlcRelinkSettlementNew:OnAwake()
    self.PanelResult.gameObject:SetActiveEx(false)
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.PanelCharacter.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(false)
end

---@param settleData XDlcFightSettleData
function XUiDlcRelinkSettlementNew:OnStart(settleData)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    ---@type XDlcFightResultData
    self.ResultData = settleData.ResultData
    ---@type XWorldData
    self.WorldData = self.ResultData.WorldData
    ---@type XDlcRelinkSettleResult
    self.RelinkSettleResult = settleData.RelinkSettleResult
end

function XUiDlcRelinkSettlementNew:OnEnable()
    if not self.RelinkSettleResult then
        XLog.Error("XUiDlcRelinkSettlementNew:OnStart error: RelinkSettleResult is nil")
        return
    end
    self:RefreshPanelResult()
end

function XUiDlcRelinkSettlementNew:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_LIKE_NOTIFY,
    }
end

function XUiDlcRelinkSettlementNew:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_RELINK_LIKE_NOTIFY then
        local fromPlayerId = args[1]
        local toPlayerId = args[2]
        if XPlayer.Id == toPlayerId then
            local playerName = self:GetPlayerNameById(fromPlayerId)
            local desc = string.format(self._Control:GetClientConfig("LikeSuccessDesc"), playerName)
            self._Control:OpenCommonLeftTipDialog(desc)
        end
    end
end

function XUiDlcRelinkSettlementNew:RefreshPanelResult()
    if not self.PanelResultNode then
        ---@type XUiPanelDlcRelinkSettlementResult
        self.PanelResultNode = XUiPanelDlcRelinkSettlementResult.New(self.PanelResult, self)
    end
    self.PanelResultNode:Open()
    self.PanelResultNode:Refresh(self.ResultData, self.RelinkSettleResult)
end

function XUiDlcRelinkSettlementNew:RefreshPanelTitle()
    self.PanelTitle.gameObject:SetActiveEx(true)
    -- 关卡章节
    local levelId = self.WorldData.LevelId
    local chapterId = self._Control:GetLevelChapterId(levelId)
    local chapterName = self._Control:GetChapterName(chapterId)
    local levelName = self._Control:GetLevelName(levelId)
    -- 关卡名称
    self.TxtName.text = string.format("%s-%s", levelName, chapterName)
    -- 是否通关
    local isWin = self.ResultData.IsPlayerWin
    self.TxtTime.gameObject:SetActiveEx(isWin)
    self.TxtFail.gameObject:SetActiveEx(not isWin)
    if isWin then
        -- 通关时间
        self.TxtTime.text = XUiHelper.GetTime(self.ResultData.FinishTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    end
    -- 新纪录
    self.GridTag.gameObject:SetActiveEx(isWin and self.RelinkSettleResult.IsNewRecord)
end

function XUiDlcRelinkSettlementNew:RefreshPanelCharacter()
    self:RefreshPanelTitle()
    if not self.PanelCharacterNode then
        ---@type XUiPanelDlcRelinkSettlementCharacter
        self.PanelCharacterNode = XUiPanelDlcRelinkSettlementCharacter.New(self.PanelCharacter, self)
    end
    self.PanelCharacterNode:Open()
    self.PanelCharacterNode:Refresh(self.RelinkSettleResult.SettleResults, self.ResultData.CustomData)
end

function XUiDlcRelinkSettlementNew:RefreshPanelReward()
    if not self.PanelRewardNode then
        ---@type XUiPanelDlcRelinkSettlementReward
        self.PanelRewardNode = XUiPanelDlcRelinkSettlementReward.New(self.PanelReward, self)
    end
    self.PanelRewardNode:Open()

    -- 只显示自己的数据
    local myPlayerSettleResult
    for _, playerSettleResult in pairs(self.RelinkSettleResult.SettleResults) do
        if playerSettleResult.PlayerId == XPlayer.Id then
            myPlayerSettleResult = playerSettleResult
            break
        end
    end
    -- 刷新奖励
    self.PanelRewardNode:Refresh(myPlayerSettleResult, self.RelinkSettleResult.RewardGoodsList, self.WorldData.LevelId)
end

-- 通过玩家Id获取玩家名称
---@param playerId number
---@return string
function XUiDlcRelinkSettlementNew:GetPlayerNameById(playerId)
    if not XTool.IsNumberValid(playerId) then
        return ""
    end

    if self.RelinkSettleResult.SettleResults then
        for _, playerSettleResult in pairs(self.RelinkSettleResult.SettleResults) do
            if playerSettleResult.PlayerId == playerId then
                return playerSettleResult.Name
            end
        end
    end
    return ""
end

return XUiDlcRelinkSettlementNew
