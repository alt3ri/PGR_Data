local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XLineArithmetic2Agency : XFubenActivityAgency
---@field private _Model XLineArithmetic2Model
local XLineArithmetic2Agency = XClass(XFubenActivityAgency, "XLineArithmetic2Agency")
function XLineArithmetic2Agency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XLineArithmetic2Agency:InitRpc()
    --实现服务器事件注册
    -- XRpc.NotifyLineArithmeticActivity = handler(self, self.NotifyLineArithmeticActivity)
end

function XLineArithmetic2Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XLineArithmetic2Agency:RequestStart(stageId)
    --if XMain.IsZlbDebug then
    --    local gameData = {
    --        StageId = stageId,
    --        StageStartTime = XTime.GetServerNowTimestamp(),
    --        OperatorRecords = {}
    --    }
    --    self._Model:SetCurrentGameData(gameData)
    --    return
    --end
    self._Model:SetRequesting(true)
    XNetwork.Call("LineArithmeticStartRequest", { StageId = stageId }, function(res)
        self._Model:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local gameData = {
            StageId = stageId,
            StageStartTime = XTime.GetServerNowTimestamp(),
            OperatorRecords = {}
        }
        self._Model:SetEditorGameData(gameData)
    end)
end

function XLineArithmetic2Agency:RequestOperation(stageId, round, star, points)
    self._Model:SetRequesting(true)
    local content = {
        StageId = stageId,
        Round = round,
        FinishTargetCount = star,
    }
    XNetwork.Call("LineArithmeticOperatorRequest", content, function(res)
        self._Model:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)

    if XMain.IsEditorDebug then
        local gameData = self._Model:GetEditorGameData()
        if gameData then
            gameData.OperatorRecords[#gameData.OperatorRecords + 1] = { Points = points, Round = round }
            self._Model:SetEditorGameData(gameData)
        end
    end
end

---@param game XLineArithmetic2Game
function XLineArithmetic2Agency:RequestSettle(game)
    if game:IsRequestSettle() then
        return
    end
    local stageId = game:GetStageId()
    local useHelp = game:IsUseHelp()
    local star, byteCode = game:GetCompleteConditionAmount(true)
    local operationRecord = game:GetOperationRecord()
    local operationCount = #operationRecord
    local records = {}
    for i = 1, operationCount do
        local operation = operationRecord[i]
        records[i] = operation:GetRecord()
    end
    --local Json = require("XCommon/Json")
    --local jsonRecord = Json.encode({
    --    Record = records,
    --    StarByte = byteCode,
    --})
    local record = {
        Record = records,
        StarByte = byteCode,
    }

    star = self._Model:HideExtraStar(star)
    local content = {
        StageId = stageId,
        SettleType = 1,
        FinishTargetCount = star,
        LineCount = operationCount,
        TipType = useHelp and 1 or 0,
        --GridInfo = jsonRecord,
        GridInfo = record,
        Score = game:GetScore(),
    }
    game:SetRequestSettle()
    self._Model:SetRequesting(true)
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        self._Model:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        --XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
        -- 结算时，关闭提示界面
        XLuaUiManager.SafeClose("UiLineArithmetic2PopupTips")
        XLuaUiManager.SafeClose("UiPopupTeach")
        XLuaUiManager.Open("UiLineArithmetic2PopupSettlement")
        self._Model:SetEditorGameData(false)
    end)
end

function XLineArithmetic2Agency:RequestRestart(stageId)
    self._Model:SetRequesting(true)
    local content = {
        StageId = stageId,
        SettleType = 2,
        FinishTargetCount = 0,
        Score = 0
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        self._Model:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
    self._Model:SetEditorGameData(false)
end

function XLineArithmetic2Agency:RequestAbandon(stageId)
    local content = {
        StageId = stageId,
        SettleType = 3,
        FinishTargetCount = 0,
        Score = 0,
    }
    XNetwork.Call("LineArithmeticSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetEditorGameData(false)
        XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_STAGE)
    end)
end

function XLineArithmetic2Agency:NotifyLineArithmeticActivity(data)
    self._Model:SetDataFromServer(data)
end

--function XLineArithmetic2Agency:OpenMainUi()
--    if not self._Model:CheckInTime() then
--        XUiManager.TipText("FubenRepeatNotInActivityTime")
--        return
--    end
--    if not XFunctionManager.DetectionFunction(self:ExGetFunctionNameType()) then
--        return
--    end
--    XLuaUiManager.Open("UiLineArithmeticMain")
--end

function XLineArithmetic2Agency:ExCheckInTime()
    return self._Model:CheckInTime()
end

function XLineArithmetic2Agency:ExGetProgressTip()
    local chapters = self._Model:GetAllChaptersCurrentActivity()
    local starAmount = 0
    local maxStarAmount = 0
    for i, chapterConfig in pairs(chapters) do
        local chapterId = chapterConfig.Id
        starAmount = starAmount + self._Model:GetStarAmount(chapterId)
        maxStarAmount = maxStarAmount + self._Model:GetMaxStarAmount(chapterId)
    end
    return XUiHelper.GetText("LineArithmeticProgress", math.floor(starAmount / maxStarAmount * 100) .. "%")
end

function XLineArithmetic2Agency:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.LineArithmetic
end

function XLineArithmetic2Agency:IsShowRedDot()
    if not self._Model:GetActivityId() then
        return false
    end
    
    if self:ExGetIsLocked() then
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

function XLineArithmetic2Agency:SaveCurrentGameData2Config()
    self._Model:SaveCurrentGameData2Config()
end

function XLineArithmetic2Agency:IsOnStage(stageId)
    if self._Model:IsOnGame(stageId) then
        return true
    end
    return false
end

function XLineArithmetic2Agency:ExOnSkip()
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
    XLuaUiManager.Open("UiLineArithmetic2Main")
    return true
end

function XLineArithmetic2Agency:IsDebugLog()
    return true
end

function XLineArithmetic2Agency:CheckScore(score)
    return true
end

function XLineArithmetic2Agency:GetTaskList()
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

return XLineArithmetic2Agency