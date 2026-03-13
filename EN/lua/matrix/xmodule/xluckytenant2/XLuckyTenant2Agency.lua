local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XLuckyTenant2DebugLog = require("XModule/XLuckyTenant2/XLuckyTenant2DebugLog")

---@class XLuckyTenant2Agency : XFubenActivityAgency
---@field private _Model XLuckyTenant2Model
local XLuckyTenant2Agency = XClass(XFubenActivityAgency, "XLuckyTenant2Agency")

function XLuckyTenant2Agency:OnInit()
    self:RegisterActivityAgency()
    self._IsDebugLog = XMain.IsEditorDebug
    --初始化一些变量
    if self._IsDebugLog then
        self._Log = {}
    end
    self._IsRequesting = false
    -- 离线模式，debug阶段使用
    self._IsOffline = false
    -- if XMain.IsEditorDebug then
    --     self._IsOffline = true
    -- end
    self._IsPlaying = false
    -- 请求队列，确保请求按顺序执行
    self._RequestQueue = {}
end

function XLuckyTenant2Agency:InitRpc()
    --实现服务器事件注册
    XRpc.LuckyTenantStagesNotify = Handler(self, self.LuckyTenantStagesNotify)
end

function XLuckyTenant2Agency:ResetAll()
    self._IsRequesting = false
    self._IsPlaying = false
    self._RequestQueue = {}
end

---处理请求队列中的下一个请求
function XLuckyTenant2Agency:ProcessNextRequest()
    if self._IsRequesting then
        return -- 还有请求在进行中，等待
    end

    if not self._RequestQueue or #self._RequestQueue == 0 then
        return -- 队列为空
    end

    -- 取出队列中的第一个请求并执行
    local request = table.remove(self._RequestQueue, 1)
    if request and request.func then
        request.func()
    end
end

function XLuckyTenant2Agency:LuckyTenantStagesNotify(data)
    self._Model:SetDataFromServer(data)
end

function XLuckyTenant2Agency:ClearAfterLeavingTheGame()
    if self._IsRequesting then
        XLog.Error("[XLuckyTenant2Agency] 强制解除请求中状态，有问题")
    end
    self._IsRequesting = false
end

function XLuckyTenant2Agency:InitEvent()
    self._IsRequesting = false
end

---收集回合结算数据
---@param game XLuckyTenant2Game 游戏对象
---@return table RoundSettleData 回合结算数据 {SpendTime, BondInfos}
function XLuckyTenant2Agency:CollectRoundSettleData(game)
    if not game then
        return nil
    end

    local data = {}

    -- 1. 收集当前回合耗时（单位：秒）
    local roundStartTime = game:GetRoundStartTime() or 0
    local currentTime = XTime.GetServerNowTimestamp()
    data.SpendTime = math.max(1, currentTime - roundStartTime)

    -- 2. 收集羁绊详情 {羁绊Id: 棋子数量}（从背包收集）
    data.BondInfos = {}

    local bag = game:GetBag()
    if bag then
        local pieces = bag:GetAllPieces()
        for _, piece in pairs(pieces) do
            if piece and not piece:IsDeleted() then
                local bondIdStr = piece:GetBondId()
                if bondIdStr and bondIdStr ~= "" then
                    -- 羁绊ID可能是多个，用|分隔，例如 "1|2|3"
                    local bondIds = string.Split(bondIdStr, "|")
                    for _, bondIdStr in ipairs(bondIds) do
                        local bondId = tonumber(bondIdStr)
                        if bondId and bondId > 0 then
                            data.BondInfos[bondId] = (data.BondInfos[bondId] or 0) + 1
                        end
                    end
                end
            end
        end
    end

    XMessagePack.MarkAsTable(data.BondInfos)
    return data
end

function XLuckyTenant2Agency:Print(...)
    if self._IsDebugLog then
        local params = { ... }
        -- 将所有参数转换为字符串
        local stringParams = {}
        for i = 1, #params do
            stringParams[i] = tostring(params[i])
        end
        local log = table.concat(stringParams, " ")
        self._Log[#self._Log + 1] = log
        -- 写入日志到文件
        XLuckyTenant2DebugLog.Log(log)
    end
end

function XLuckyTenant2Agency:Error(...)
    if self._IsDebugLog then
        XLog.Error(...)
    end
end

function XLuckyTenant2Agency:ClearLog()
    if self._IsDebugLog then
        self._Log = {}
        XLuckyTenant2DebugLog.Clear()
    end
end

function XLuckyTenant2Agency:LogHistory()
    if self._IsDebugLog then
        local str = table.concat(self._Log, "\n")
        XLog.Debug("以下为日志:", str)
    end
end

function XLuckyTenant2Agency:ExCheckInTime()
    return true
end

function XLuckyTenant2Agency:CheckRequestingAndOffline(callback)
    if self._IsRequesting then
        XLog.Warning("[XLuckyTenant2Agency] request too frequently")
        return true
    end
    if self._IsOffline then
        if callback then
            callback()
        end
        return true
    end
    return false
end

function XLuckyTenant2Agency:IsOffline()
    return self._IsOffline
end

function XLuckyTenant2Agency:SetPlaying(value)
    self._IsPlaying = value
end

function XLuckyTenant2Agency:IsRequesting()
    return self._IsRequesting
end

function XLuckyTenant2Agency:SetRequesting(value)
    self._IsRequesting = value
end

function XLuckyTenant2Agency:OpenMain()
    -- 离线模式，debug阶段使用
    -- local activityConfig = self._Model:GetActivityConfig()
    -- if not activityConfig then
    --     if self._IsOffline then
    --         XLog.Error("[XLuckyTenant2Agency] 离线模式，设置活动ID为1, 等待服务端提交代码")
    --         self._Model._ActivityId = 1
    --     end
    -- else
    --     -- 服务端已经提交了, 不需要离线模式了
    --     self._IsOffline = false
    -- end

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LuckyTenant2, false, true) then
        return false
    end
    if not self._Model:IsActivityOpen() then
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    XLuaUiManager.Open("UiLuckyTenant2Main")
    return true
end

-- ==================== 网络请求方法 ====================

---开始游戏
---@param stageId number 关卡ID
---@param callback function 回调函数
function XLuckyTenant2Agency:RequestStart(stageId, callback)
    if self:CheckRequestingAndOffline(callback) then
        return
    end
    self._IsRequesting = true
    XNetwork.Call("LuckyTenantStageBeginRequest", {
        StageId = stageId,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetPlayingStageId(stageId)
        self._Model:SetPlayingStageRound(1)
        if callback then
            callback(res.PlayingStage)
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---补充棋子的选项
---@param game XLuckyTenant2Game
---@param useProp boolean 是否使用道具
function XLuckyTenant2Agency:RequestSupplyPieces(game, useProp)
    -- 如果有正在进行的请求，加入队列等待
    if self._IsRequesting then
        table.insert(self._RequestQueue, {
            func = function()
                self:RequestSupplyPieces(game, useProp)
            end
        })
        return
    end

    if self:CheckRequestingAndOffline() then
        return
    end

    local stageId = game:GetStageId()
    local options = game:GetOptionsThisRound(self._Model)
    local pieces = {}
    for i = 1, #options do
        local pieceId = options[i]:GetId()
        pieces[#pieces + 1] = pieceId
    end

    local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
    local refreshChess
    if useProp then
        local piece = game:GetBag():GetProp(XLuckyTenant2Enum.Item.RefreshProp)
        if piece then
            refreshChess = piece:GetEncodeMessage()
            self:Print("刷新道具剩余数量:" .. piece:GetAmount())
        else
            XLog.Error("[XLuckyTenant2Agency] 刷新棋子道具不存在")
        end
    end

    -- 在第一回合, 需要发送初始背包内容
    local message
    if game:GetRound() == 1 then
        local log
        if XMain.IsEditorDebug then
            log = {}
        end
        message = game:GetBag():GetEncodeMessage(log)
        if log then
            XLog.Debug("打印LuckyTenantSuppleChessRequest", {
                StageId = stageId,
                SuppleChess = pieces,
                Chess = refreshChess,
                Grids = log,
            })
        end
    end

    self._IsRequesting = true
    XNetwork.Call("LuckyTenantSuppleChessRequest", {
        StageId = stageId,
        SuppleChess = pieces,
        Chess = refreshChess,
        Grids = message,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---下回合开始
---@param game XLuckyTenant2Game
---@param callback function|nil 成功回调
function XLuckyTenant2Agency:RequestNextRound(game, callback)
    if self:CheckRequestingAndOffline(callback) then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local logGrids
    if self._IsDebugLog then
        logGrids = {}
    end
    local grids = game:GetBag():GetEncodeMessage(logGrids)
    if logGrids then
        XLog.Debug("打印LuckyTenantRoundBeginRequest", {
            StageId = stageId,
            Grids = logGrids,
        })
    end
    XNetwork.Call("LuckyTenantRoundBeginRequest", {
        StageId = stageId,
        Grids = grids,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 服务器请求成功后，调用回调（用于推进状态等操作）
        if callback then
            callback()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---分数变化
---@param game XLuckyTenant2Game
function XLuckyTenant2Agency:RequestUpdateScore(game)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local logGrids
    if self._IsDebugLog then
        logGrids = {}
    end

    local record = game:GetRecord4Server()
    local suppleChess = record.SelectPiece
    record.SelectPiece = {}
    local deleteChess = record.DeletePiece
    record.DeletePiece = {}

    local chessboard = game:GetChessBoard():GetEncodeMessage()
    local grids = game:GetBag():GetEncodeMessage(logGrids)
    if logGrids then
        XLog.Debug("打印LuckyTenantRoundEndRequest", {
            StageId = stageId,
            AddScore = game:GetScoreThisRound(),
            Grids = logGrids,
            ChessBoard = chessboard,
            SuppleChess = suppleChess,
            DeleteChess = deleteChess,
        })
    end
    local score = game:GetScoreThisRound()
    local round = game:GetRound()

    -- 收集回合结算数据
    local roundSettleData = self:CollectRoundSettleData(game)

    XNetwork.Call("LuckyTenantRoundEndRequest", {
        StageId = stageId,
        AddScore = score,
        Grids = grids,
        ChessBoard = chessboard,
        SuppleChess = suppleChess,
        DeleteChess = deleteChess,
        RoundSettleData = roundSettleData,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            -- 即使失败也要处理队列中的下一个请求
            self:ProcessNextRequest()
            return
        end
        -- 服务端结算，需要清空游戏中纪录
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        if res.RoundFin == 2 or res.RoundFin == 1 then
            if game:GetRound() > round then
                XLog.Error("[XLuckyTenant2Agency] 服务端认为已经结束了，但是客户端还在游戏中，强制终止")
                if res.RoundFin == 1 then
                    game:SetState(XLuckyTenant2Enum.GameState.PerfectClear)
                elseif res.RoundFin == 2 then
                    game:SetState(XLuckyTenant2Enum.GameState.GameOver)
                end
            end
            game:SetRoundFin(res.RoundFin)
            self._Model:ClearPlayingStage()
            -- 结算后，用本局数据构造通关记录并更新 Model（与 Model:OnStagePassed / 主界面 BestScore、IsStagePassed 使用字段一致）
            local record = res.Record
            if not record then
                record = {
                    StageId = stageId,
                    Score = game:GetTotalScore(),
                    Round = game:GetRound(),
                    IsNormalClear = (res.RoundFin == 1),  -- 1=完美通关 2=游戏结束
                }
            else
                record.StageId = stageId
                record.Score = record.Score or game:GetTotalScore()
                record.Round = record.Round or game:GetRound()
                record.IsNormalClear = record.IsNormalClear or (res.RoundFin == 1)
            end
            self._Model:OnStagePassed(record)
        end
        -- 处理队列中的下一个请求
        self:ProcessNextRequest()
    end, nil, function()
        self:SetRequesting(false)
        -- 网络错误时也要处理队列中的下一个请求
        self:ProcessNextRequest()
    end)
end

---结算
---@param stageId number 关卡ID
---@param game XLuckyTenant2Game|nil 游戏对象（可选，用于收集结算数据）
function XLuckyTenant2Agency:RequestSettle(stageId, game)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    -- 收集回合结算数据
    local roundSettleData = nil
    if game then
        roundSettleData = self:CollectRoundSettleData(game)
    end

    XNetwork.Call("LuckyTenantStageEndRequest", {
        StageId = stageId,
        RoundSettleData = roundSettleData,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        res.Record.StageId = stageId
        self._Model:OnStagePassed(res.Record)
        self._Model:ClearPlayingStage()
        -- TODO: 根据实际EventId修改
        -- XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_UPDATE_STAGE)
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---结束游戏（放弃当前进行中的游戏）
---@param stageId number 关卡ID
---@param game XLuckyTenant2Game|nil 游戏对象（可选，用于收集结算数据）
---@param callback function|nil 回调函数
function XLuckyTenant2Agency:RequestEndGame(stageId, game, callback)
    if self:CheckRequestingAndOffline(function()
            -- 离线模式下，清理进行中的游戏记录后再执行回调
            self._Model:ClearPlayingStage()
            if callback then
                callback(true)
            end
        end) then
        return
    end

    self._IsRequesting = true

    -- 收集回合结算数据
    local roundSettleData = nil
    if game then
        roundSettleData = self:CollectRoundSettleData(game)
    end

    XNetwork.Call("LuckyTenantStageEndRequest", {
        StageId = stageId,
        RoundSettleData = roundSettleData,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false)
            end
            return
        end
        -- 清理进行中的游戏记录
        self._Model:ClearPlayingStage()
        if callback then
            callback(true)
        end
        -- TODO: 根据实际EventId修改
        -- XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_UPDATE_STAGE)
    end, nil, function()
        self:SetRequesting(false)
        if callback then
            callback(false)
        end
    end)
end

---重开
---@param game XLuckyTenant2Game
---@param callback function 回调函数
function XLuckyTenant2Agency:RequestRestart(game, callback)
    if self:CheckRequestingAndOffline(callback) then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()

    -- 收集回合结算数据
    local roundSettleData = self:CollectRoundSettleData(game)

    XNetwork.Call("LuckyTenantStageRestartRequest", {
        StageId = stageId,
        RoundSettleData = roundSettleData,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        res.Record.StageId = stageId
        self._Model:OnStagePassed(res.Record)
        if callback then
            callback()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---删除或更新棋子
---@param game XLuckyTenant2Game
---@param deletePieces XLuckyTenant2Piece[]
---@param updatePieces XLuckyTenant2Piece[]
---@param callback function 回调函数
function XLuckyTenant2Agency:RequestDeleteOrUpdateChess(game, deletePieces, updatePieces, callback)
    if self:CheckRequestingAndOffline() then
        return
    end
    self._IsRequesting = true

    local toDelete
    if deletePieces and #deletePieces > 0 then
        toDelete = {}
        for i = 1, #deletePieces do
            local piece = deletePieces[i]
            toDelete[#toDelete + 1] = piece:GetEncodeMessage()
        end
    end

    local toUpdate
    if updatePieces and #updatePieces > 0 then
        toUpdate = {}
        for i = 1, #updatePieces do
            local piece = updatePieces[i]
            toUpdate[#toUpdate + 1] = piece:GetEncodeMessage()
        end
    end

    XNetwork.Call("LuckyTenantDeleteUpdateChessRequest", {
        DeleteChess = toDelete,
        UpdateChess = toUpdate,
        StageId = game:GetStageId(),
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback()
        end
    end, nil, function()
        self:SetRequesting(false)
    end)
end

---检查是否在指定关卡和回合
---@param stageId number 关卡ID（0表示任意关卡）
---@param round number 回合数（0表示任意回合）
---@return boolean
function XLuckyTenant2Agency:IsInStageAndRound(stageId, round)
    if not self._IsPlaying then
        return false
    end

    local playingStageId = self._Model:GetPlayingStageId()
    local playingRound = self._Model:GetPlayingStageRound()

    local isInStage = (stageId == 0 and playingStageId and playingStageId > 0) or (stageId ~= 0 and playingStageId == stageId)
    local isInRound = (round == 0 and playingRound and playingRound > 0) or (round ~= 0 and playingRound == round)

    return isInStage and isInRound
end

---该关卡是否已弹出过图文指引（由 SaveUtil 持久化，与 Control 内 TryShowStageTutorial 记录一致）
---@param stageId number 关卡ID
---@return boolean
function XLuckyTenant2Agency:IsStageTutorialShown(stageId)
    if not self._Model then
        return false
    end
    return self._Model:IsStageTutorialShown(stageId)
end

---获取关卡已游玩标记的Key
---@param stageId number 关卡ID
---@return string
function XLuckyTenant2Agency:GetKeyHasPlayed(stageId)
    return "LuckyTenant2NewStage" .. stageId .. "_" .. XPlayer.Id
end

function XLuckyTenant2Agency:SetTestCase(id)
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_SET_TEST_CASE, id)
end

function XLuckyTenant2Agency:TestClearBag()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_CLEAR_BAG)
end

return XLuckyTenant2Agency
