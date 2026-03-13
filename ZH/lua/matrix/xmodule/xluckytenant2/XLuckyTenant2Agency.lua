local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XLuckyTenant2Agency : XFubenActivityAgency
---@field private _Model XLuckyTenant2Model
local XLuckyTenant2Agency = XClass(XFubenActivityAgency, "XLuckyTenant2Agency")

function XLuckyTenant2Agency:OnInit()
    self:RegisterActivityAgency()
    self._IsRequesting = false
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

function XLuckyTenant2Agency:ExCheckInTime()
    return true
end

function XLuckyTenant2Agency:CheckRequesting()
    if self._IsRequesting then
        XLog.Warning("[XLuckyTenant2Agency] request too frequently")
        return true
    end
    return false
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
    if self:CheckRequesting() then
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

    if self:CheckRequesting() then
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
        else
            XLog.Error("[XLuckyTenant2Agency] 刷新棋子道具不存在")
        end
    end

    -- 在第一回合, 需要发送初始背包内容
    local message
    if game:GetRound() == 1 then
        message = game:GetBag():GetEncodeMessage()
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
    if self:CheckRequesting() then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local grids = game:GetBag():GetEncodeMessage()
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
    if self:CheckRequesting() then
        return
    end
    self._IsRequesting = true

    local stageId = game:GetStageId()
    local record = game:GetRecord4Server()
    local suppleChess = record.SelectPiece
    record.SelectPiece = {}
    local deleteChess = record.DeletePiece
    record.DeletePiece = {}

    local chessboard = game:GetChessBoard():GetEncodeMessage()
    local grids = game:GetBag():GetEncodeMessage()
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
    if self:CheckRequesting() then
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
    if self:CheckRequesting() then
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
        -- 更新通关最高分，即使游戏失败或者中途结束
        res.Record.StageId = stageId
        self._Model:OnStagePassed(res.Record)

        -- 清理进行中的游戏记录
        self._Model:ClearPlayingStage()

        if callback then
            callback(true)
        end
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
    if self:CheckRequesting() then
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

---删除或更新棋子（协议参数为单个对象，非数组）
---@param game XLuckyTenant2Game
---@param deletePieces XLuckyTenant2Piece[]
---@param updatePieces XLuckyTenant2Piece[]
---@param callback function 回调函数
function XLuckyTenant2Agency:RequestDeleteOrUpdateChess(game, deletePieces, updatePieces, callback)
    if self:CheckRequesting() then
        return
    end
    self._IsRequesting = true

    local toDelete
    if deletePieces and #deletePieces > 0 then
        toDelete = deletePieces[1]:GetEncodeMessage()
    end

    local toUpdate
    if updatePieces and #updatePieces > 0 then
        toUpdate = updatePieces[1]:GetEncodeMessage()
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

--- 红点：活动入口是否显示红点（任务或未游玩关卡）
---@return boolean
function XLuckyTenant2Agency:IsShowRedDot()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LuckyTenant2, false, true) then
        return false
    end
    if not self._Model:IsActivityOpen() then
        return false
    end
    if self:IsShowRedDotTask() then
        return true
    end
    local stages = self._Model:GetStages()
    for i = 1, #stages do
        local stage = stages[i]
        if self:IsShowRedDotStage(stage.Id) then
            return true
        end
    end
    return false
end

--- 红点：指定关卡是否显示红点（在时间范围内、前置通过、未游玩过）
---@param stageId number 关卡ID
---@return boolean
function XLuckyTenant2Agency:IsShowRedDotStage(stageId)
    local stageConfig = self._Model:GetLuckyTenant2StageConfigById(stageId)
    if not stageConfig then
        return false
    end
    if XFunctionManager.CheckInTimeByTimeId(stageConfig.TimeId)
            and (not stageConfig.PreStage or stageConfig.PreStage == 0 or self._Model:IsStagePassed(stageConfig.PreStage))
    then
        if XSaveTool.GetData(self:GetKeyHasPlayed(stageConfig.Id)) == nil then
            return true
        end
    end
    return false
end

--- 红点：是否有任务奖励可领取
---@return boolean
function XLuckyTenant2Agency:IsShowRedDotTask()
    local activityConfig = self._Model:GetActivityConfig()
    if activityConfig and activityConfig.TaskGroup then
        local taskGroups = activityConfig.TaskGroup
        for i = 1, #taskGroups do
            local groupId = taskGroups[i]
            if XDataCenter.TaskManager.CheckLimitTaskList(groupId) then
                return true
            end
        end
    end
    return false
end

---@param id number 测试用例ID
function XLuckyTenant2Agency:SetTestCase(id)
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_SET_TEST_CASE, id)
end

function XLuckyTenant2Agency:TestClearBag()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_CLEAR_BAG)
end

--- 红点：指定章节是否显示红点（时间范围内、章节已开启、且章节内有未游玩关卡）
---@param chapterId number 章节ID
---@return boolean
function XLuckyTenant2Agency:IsShowRedDotChapter(chapterId)
    local chapterConfig = self._Model:GetLuckyTenant2ChapterConfigById(chapterId)
    if not chapterConfig then
        return false
    end
    -- 时间范围内
    local timeId = chapterConfig.TimeId or 0
    if timeId > 0 and not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    -- 章节已开启（上一章所有关卡已通关）
    local chapterConfigs = self._Model:GetChapters()
    for chapterIdx, cfg in ipairs(chapterConfigs) do
        if cfg.Id == chapterId then
            if chapterIdx > 1 then
                local prevConfig = chapterConfigs[chapterIdx - 1]
                if prevConfig and prevConfig.StageId then
                    for _, sid in ipairs(prevConfig.StageId) do
                        if not self._Model:IsStagePassed(sid) then
                            return false
                        end
                    end
                end
            end
            break
        end
    end
    -- 章节内至少有一个关卡显示红点
    if chapterConfig.StageId then
        for _, stageId in ipairs(chapterConfig.StageId) do
            if self:IsShowRedDotStage(stageId) then
                return true
            end
        end
    end
    return false
end

return XLuckyTenant2Agency
