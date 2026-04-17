local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XLineArithmetic3Agency : XFubenActivityAgency
---@field private _Model XLineArithmetic3Model
local XLineArithmetic3Agency = XClass(XFubenActivityAgency, "XLineArithmetic3Agency")

function XLineArithmetic3Agency:OnInit()
    -- 初始化变量
    self._Requesting = false
    self:RegisterActivityAgency()
end

function XLineArithmetic3Agency:InitRpc()
    -- 注册服务器通知
    XRpc.NotifyLineArithmeticActivity = handler(self, self.NotifyLineArithmeticActivity)
end

function XLineArithmetic3Agency:InitEvent()
    -- 实现跨Agency事件注册
end

----------public start----------

--- 是否正在请求中
---@return boolean
function XLineArithmetic3Agency:IsRequesting()
    return self._Requesting
end

--- 请求开始游戏
---@param stageId number 关卡ID
function XLineArithmetic3Agency:RequestStart(stageId)
    if self._Requesting then
        return
    end
    self._Requesting = true
    XNetwork.Call("LineArithmeticStartRequest", { StageId = stageId }, function(res)
        self._Requesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

--- 请求操作记录
---@param stageId number 关卡ID
---@param round number 回合数
---@param star number 星数
---@param points number 分数
function XLineArithmetic3Agency:RequestOperation(stageId, round, star, callback)
    if self._Requesting then
        return
    end
    self._Requesting = true
    local content = {
        StageId = stageId,
        Round = round,
        FinishTargetCount = star,
    }
    XNetwork.Call("LineArithmeticOperatorRequest", content, function(res)
        self._Requesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

--- 请求结算
---@param stageId number 关卡ID
---@param star number 星数
---@param record table 操作记录
---@param settleType number|nil 结算类型：1=普通结算，2=重新挑战后结算
function XLineArithmetic3Agency:RequestSettle(stageId, star, record, settleType)
    if self._Requesting then
        return
    end
    self._Requesting = true
    local analytics = record.Analytics or {}
    local content = {
        StageId = stageId,
        -- SettleType = settleType or 1,
        SettleType = 1, -- 默认普通结算，这一期重新挑战, 运营埋点认为，不需要区分
        FinishTargetCount = star,
        Score = 0,
        GridInfo = record,
        LineCount = #record.Record,
        -- 埋点字段
        -- 是否使用提示
        TipType = record.TipType or 0,
        -- 达成的终点数量
        EndCount = analytics.EndCount or 0,
        -- 关卡耗时
        Duration = analytics.Duration or 0,
        -- 是否只使用一笔完成
        OnlyOneLine = analytics.OnlyOneLine or 0,
        -- 回撤次数
        UndoCount = analytics.UndoCount or 0,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        self._Requesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 刷新通关记录
        self._Model:SetStagePassed(stageId, star)

        -- 结算时，关闭提示界面
        XLuaUiManager.SafeClose("UiLineArithmetic3PopupCommon")
        XLuaUiManager.SafeClose("UiPopupTeach")
        XLuaUiManager.Open("UiLineArithmetic3PopupSettlement")
    end)
end

--- 请求重新开始（参考 RequestStart，复用 LineArithmeticStartRequest）
---@param stageId number 关卡ID
function XLineArithmetic3Agency:RequestRestart(stageId)
    if self._Requesting then
        return
    end
    self._Requesting = true
    XNetwork.Call("LineArithmeticStartRequest", { StageId = stageId }, function(res)
        self._Requesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

--- 请求放弃关卡
---@param stageId number 关卡ID
function XLineArithmetic3Agency:RequestAbandon(stageId)
    if self._Requesting then
        return
    end
    self._Requesting = true
    local content = {
        StageId = stageId,
        SettleType = 3,
        FinishTargetCount = 0,
        Score = 0,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        self._Requesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_STAGE)
    end)
end

--- 服务器通知活动数据
---@param data table 活动数据
function XLineArithmetic3Agency:NotifyLineArithmeticActivity(data)
    self._Model:SetDataFromServer(data)
end

--- 获取任务列表
---@return table 任务数据列表
function XLineArithmetic3Agency:GetTaskList()
    local taskIdList = self._Model:GetTaskList()
    local taskDataList = {}
    for i = 1, #taskIdList do
        local taskId = taskIdList[i]
        local task = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if task then
            taskDataList[#taskDataList + 1] = task
        end
    end
    XDataCenter.TaskManager.SortTaskDatas(taskDataList)
    return taskDataList
end

--- 是否显示红点
---@return boolean 是否显示红点
function XLineArithmetic3Agency:IsShowRedDot()
    if not self._Model:CheckHasValidActivityId() then
        return false
    end

    local chapters = self._Model:GetAllChaptersCurrentActivity()
    for i, chapterConfig in pairs(chapters) do
        local chapterId = chapterConfig.Id
        if self._Model:IsChapterOpen(chapterId) then
            local isNewChapter = self._Model:IsNewChapter(chapterId)
            if isNewChapter then
                return true
            end
        end
    end

    local taskIdList = self._Model:GetTaskList()
    for i = 1, #taskIdList do
        local taskId = taskIdList[i]
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData then
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
    end

    return false
end

--- 保存当前游戏数据到配置
function XLineArithmetic3Agency:SaveCurrentGameData2Config()
    -- 暂无实现，Model中无对应方法
end

--- 是否在关卡中
---@param stageId number 关卡ID
---@return boolean 是否在关卡中
function XLineArithmetic3Agency:IsOnStage(stageId)
    if self._Model:IsOnGame(stageId) then
        return true
    end
    return false
end

--- 是否开启调试日志
---@return boolean 是否开启
function XLineArithmetic3Agency:IsDebugLog()
    return true
end

--- 检查分数
---@param score number 分数
---@return boolean 是否有效
function XLineArithmetic3Agency:CheckScore(score)
    return true
end

function XLineArithmetic3Agency:ExOnSkip()
    if not self:ExCheckInTime() then
        if self._Model:IsExpire() then
            XUiManager.TipText("ActivityMainLineEnd")
            return false
        end
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
    local functionOpen = XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.LineArithmetic)
    if not functionOpen then
        return false
    end
    XLuaUiManager.Open("UiLineArithmetic3Main")
    return true
end

function XLineArithmetic3Agency:ExCheckInTime()
    if not self._Model:CheckHasValidActivityId() then
        return false
    end
    
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local timeId = activityConfig.TimeId
    local inTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return inTime
end


--region ClientConfig

function XLineArithmetic3Agency:GetClientConfigText(key, index)
    return self._Model:GetClientConfigTextByKey(key, index)
end

function XLineArithmetic3Agency:GetClientConfigNumberByKey(key, index)
    return self._Model:GetClientConfigNumberByKey(key, index)
end
--endregion
----------public end----------

----------private start----------


----------private end----------

return XLineArithmetic3Agency
