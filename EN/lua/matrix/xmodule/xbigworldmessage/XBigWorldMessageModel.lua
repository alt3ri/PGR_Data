local XBigWorldMessageConfigModel = require("XModule/XBigWorldMessage/XBigWorldMessageConfigModel")
local XBWMessageData = require("XModule/XBigWorldMessage/XData/XBWMessageData")

---@class XBigWorldMessageModel : XBigWorldMessageConfigModel
local XBigWorldMessageModel = XClass(XBigWorldMessageConfigModel, "XBigWorldMessageModel")

function XBigWorldMessageModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type XBWMessageData[]
    self._UnReadMessageList = {}
    ---@type table<number, XBWMessageData>
    self._MessageMap = {}

    ---@type XQueue
    self._ForceMessageQueue = XQueue.New()

    self._PlayerHeadIcon = false

    self._MessageReadRecord = false

    self._IsShieldUnReadMessage = false

    self:_InitTableKey()
end

function XBigWorldMessageModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
    self:__CacheReadRecord()
end

function XBigWorldMessageModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._UnReadMessageList = {}
    self._MessageMap = {}

    self._ForceMessageQueue:Clear()

    self._PlayerHeadIcon = false

    self._MessageReadRecord = false

    self._IsShieldUnReadMessage = false
end

---@type XBWMessageData[]
function XBigWorldMessageModel:GetUnReadMessageList()
    return self._UnReadMessageList
end

---@type table<number, XBWMessageData>
function XBigWorldMessageModel:GetMessageMap()
    return self._MessageMap
end

function XBigWorldMessageModel:CheckMessageStepFinish(messageId, stepId)
    if self._MessageMap[messageId] then
        return self._MessageMap[messageId].StepIdMap[stepId]
    end

    return false
end

function XBigWorldMessageModel:CheckMessageStepIdEnd(stepId)
    local nextStepIds = self:GetBigWorldMessageStepNextStepById(stepId)

    return XTool.IsTableEmpty(nextStepIds)
end

function XBigWorldMessageModel:CheckFirstStepId(messageId, stepId)
    local firstStepId = self:GetBigWorldMessageFirstStepIdById(messageId)

    return stepId == firstStepId
end

function XBigWorldMessageModel:CheckMessageFinish(messageId)
    if self._MessageMap[messageId] then
        return self._MessageMap[messageId].State == XEnumConst.BWMessage.MessageState.Finish
    end

    return false
end

function XBigWorldMessageModel:AddReadMessageStep(messageId, stepId, isFinish)
    if self._MessageMap[messageId] then
        self._MessageMap[messageId]:AddStepId(stepId)
        self._MessageMap[messageId]:UpdateFinishState(isFinish)
    end
    if isFinish then
        local forceQueue = XQueue.New()

        self:TryRemoveUnReadMessageData(messageId)
        while not self._ForceMessageQueue:IsEmpty() do
            local messageData = self._ForceMessageQueue:Dequeue()

            if messageData.MessageId ~= messageId then
                forceQueue:Enqueue(messageData)
            end
        end
        self._ForceMessageQueue = forceQueue
    end
end

function XBigWorldMessageModel:AddUnReadMessage(data)
    ---@type XBWMessageData
    local messageData = XBWMessageData.New(data)

    messageData:UpdateCreateTime()
    if not self:CheckFirstStepId(data.MessageId, data.StepId) then
        messageData:AddStepId(data.StepId)
    end

    if not self._MessageMap[messageData.MessageId] then
        table.insert(self._UnReadMessageList, messageData)
        self._MessageMap[messageData.MessageId] = messageData
    else
        XLog.Warning("[短信][NotifyBigWorldNotReadMessage] : " .. "Repeat Notify Message => MessageId = " ..
                       messageData.MessageId)
    end
end

function XBigWorldMessageModel:AddForceMessage(data)
    ---@type XBWMessageData
    local messageData = XBWMessageData.New(data)

    messageData:UpdateCreateTime()
    if not self:CheckFirstStepId(data.MessageId, data.StepId) then
        messageData:AddStepId(data.StepId)
    end

    if not self._MessageMap[messageData.MessageId] then
        self._ForceMessageQueue:Enqueue(messageData)
        self._MessageMap[messageData.MessageId] = messageData
        table.insert(self._UnReadMessageList, messageData)
    else
        XLog.Warning("[短信][NotifyBigWorldNotReadMessage] : " .. "Repeat Notify Message => MessageId = " ..
                       messageData.MessageId)
    end
end

function XBigWorldMessageModel:UpdateMessageData(messageId, stepId, isFinish)
    if not self._MessageMap[messageId] then
        self._MessageMap[messageId] = XBWMessageData.New({
            MessageId = messageId,
            CreateTime = XTime.GetServerNowTimestamp(),
        })
    end

    self._MessageMap[messageId]:UpdateFinishState(isFinish)
    self._MessageMap[messageId]:AddStepId(stepId)
end

function XBigWorldMessageModel:UpdateAllMessageData(messages)
    self._MessageMap = {}
    self._UnReadMessageList = {}
    self._ForceMessageQueue:Clear()

    if not XTool.IsTableEmpty(messages) then
        for messageId, message in pairs(messages) do
            if not self._MessageMap[messageId] then
                local recordList = message.StepRecordList

                if not XTool.IsTableEmpty(recordList) then
                    local completeStepIds = {}
                    local firstStepId = self:GetBigWorldMessageFirstStepIdById(messageId)
                    ---@type XStack
                    local resultStack = XStack.New()

                    for _, stepRecord in pairs(recordList) do
                        resultStack:Clear()
                        _, firstStepId = self:__PopulateCompleteStepRecordList(firstStepId, stepRecord, resultStack)

                        if not resultStack:IsEmpty() then
                            while not resultStack:IsEmpty() do
                                table.insert(completeStepIds, self:__CreateStepRecord(resultStack:Pop()))
                            end
                        end
                        if not firstStepId then
                            break
                        end
                    end

                    table.insert(completeStepIds, self:__CreateStepRecord(firstStepId))
                    message.StepRecordList = completeStepIds
                end

                ---@type XBWMessageData
                local messageData = XBWMessageData.New(message)

                self._MessageMap[messageId] = messageData

                if messageData.State ~= XEnumConst.BWMessage.MessageState.Finish then
                    local messageType = self:GetBigWorldMessageTypeById(messageId)

                    if messageType == XEnumConst.BWMessage.MessageType.ForcePlay then
                        self._ForceMessageQueue:Enqueue(messageData)
                    end

                    table.insert(self._UnReadMessageList, messageData)
                end
            else
                XLog.Error("[短信]Repeat Notify Message => MessageId = " .. messageId)
            end
        end
    end
end

function XBigWorldMessageModel:TryRemoveUnReadMessageData(messageId)
    if not XTool.IsTableEmpty(self._UnReadMessageList) then
        for i, messageData in pairs(self._UnReadMessageList) do
            if messageData.MessageId == messageId then
                table.remove(self._UnReadMessageList, i)
                return
            end
        end
    end
end

---@return XBWMessageData
function XBigWorldMessageModel:GetForceMessageData(isUnDequeue)
    if isUnDequeue then
        return self._ForceMessageQueue:Peek()
    end

    return self._ForceMessageQueue:Dequeue()
end

function XBigWorldMessageModel:PeekForceMessageData()
    return self._ForceMessageQueue:Peek()
end

function XBigWorldMessageModel:DequeueForceMessageData()
    return self._ForceMessageQueue:Dequeue()
end

function XBigWorldMessageModel:HasForceMessageData()
    return not self._ForceMessageQueue:IsEmpty()
end

function XBigWorldMessageModel:GetMessageCreateTime(messageId)
    local messageMap = self:GetMessageMap()

    if messageMap[messageId] then
        return messageMap[messageId].CreateTime
    end

    return 0
end

function XBigWorldMessageModel:SetIsShieldUnReadMessage(isShield)
    self._IsShieldUnReadMessage = isShield or false
end

function XBigWorldMessageModel:GetIsShieldUnReadMessage()
    return self._IsShieldUnReadMessage
end

function XBigWorldMessageModel:SetMessageRecord(messageId)
    self:__InitReadRecord()

    self._MessageReadRecord[messageId] = true
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_RECORD_MESSAGE_NOTIFY)
end

function XBigWorldMessageModel:GetMessageReadRecord(messageId)
    self:__InitReadRecord()

    return self._MessageReadRecord[messageId] or false
end

function XBigWorldMessageModel:GetPlayerHeadIcon()
    if not self._PlayerHeadIcon then
        self._PlayerHeadIcon = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetString("MessagePlayerHeadIcon")
    end

    return self._PlayerHeadIcon
end

---@param stepStack XStack
function XBigWorldMessageModel:__PopulateCompleteStepRecordList(firstStepId, stepRecord, stepStack)
    if not XTool.IsNumberValid(firstStepId) then
        return false
    end
    if firstStepId == stepRecord.LatestStepId then
        return true, firstStepId
    end

    stepStack:Push(firstStepId)

    if not self:CheckMessageStepIdEnd(firstStepId) then
        local nextStepIds = self:GetBigWorldMessageStepNextStepById(firstStepId)

        if not XTool.IsTableEmpty(nextStepIds) then
            for _, nextStepId in pairs(nextStepIds) do
                local isSuccess, lastStepId = self:__PopulateCompleteStepRecordList(nextStepId, stepRecord, stepStack)

                if isSuccess then
                    return true, lastStepId
                end
            end
        end
    end

    stepStack:Pop()

    return false
end

function XBigWorldMessageModel:__CreateStepRecord(stepId)
    return {
        LatestStepId = stepId,
    }
end

function XBigWorldMessageModel:__InitReadRecord()
    if not self._MessageReadRecord then
        local recordData = XSaveTool.GetData(self:__GetReadRecordKey())

        self._MessageReadRecord = {}
        if recordData then
            local recordIds = string.ToIntArray(recordData, "|")

            if not XTool.IsTableEmpty(recordIds) then
                for _, recordId in pairs(recordIds) do
                    self._MessageReadRecord[recordId] = true
                end
            end
        end
    end
end

function XBigWorldMessageModel:__CacheReadRecord()
    if self._MessageReadRecord and not XTool.IsTableEmpty(self._MessageReadRecord) then
        local records = {}

        for messageId, _ in pairs(self._MessageReadRecord) do
            table.insert(records, messageId)
        end

        XSaveTool.SaveData(self:__GetReadRecordKey(), table.concat(records, "|"))
    end
end

function XBigWorldMessageModel:__GetReadRecordKey()
    return "BW_MESSAGE_READ_%d" .. tostring(XPlayer.Id)
end

return XBigWorldMessageModel
