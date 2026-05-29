---@class XMainLine2MessageModel: XModel
---@field _MainModel XMainLine2Model
local XMainLine2MessageModel = XClass(XModel, 'XMainLine2MessageModel')

function XMainLine2MessageModel:OnInit()

end

function XMainLine2MessageModel:ClearPrivate()

end

function XMainLine2MessageModel:ResetAll()

end

---@param data XFubenMainLine2DataDb
function XMainLine2MessageModel:UpdateServerData(data)
    -- 缓存服务端原始数据
    self._MessageState = data.MessageState
end

function XMainLine2MessageModel:GetMessageStateById(messageId)
    if XTool.IsTableEmpty(self._MessageState) then
        return 0
    end
    
    return self._MessageState[messageId] or 0
end

function XMainLine2MessageModel:UpdateMessageStateById(messageId, state)
    if self._MessageState == nil then
        self._MessageState = {}
    end
    
    local oldState = self._MessageState[messageId]

    if not oldState or state > oldState then
        self._MessageState[messageId] = state
    end
end

--region 本地缓存记录

function XMainLine2MessageModel:_GetContentChoiceMarkKey(contentId, index)
    return "MessageContentChoiceMark" .. contentId .. '_' .. index
end

--- 检查选项是否选择过
function XMainLine2MessageModel:GetContentChoiceMark(contentId, index)
    local key = self:_GetContentChoiceMarkKey(contentId, index)
    
    return self._MainModel._SaveUtil:GetData(key)
end

function XMainLine2MessageModel:SetContentChoiceMark(contentId, index, isMark)
    -- 默认记录
    if isMark == nil then
        isMark = true
    end
    
    local key = self:_GetContentChoiceMarkKey(contentId, index)

    self._MainModel._SaveUtil:SaveData(key, isMark)
end

--endregion

return XMainLine2MessageModel