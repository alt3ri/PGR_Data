--- 选关界面特殊交互相关的控制器
---@class XMainLine2MessageControl : XControl
---@field private _Model XMainLine2Model
---@field _MainControl XMainLine2Control
local XMainLine2MessageControl = XClass(XControl, "XMainLine2MessageControl", true)

XClassPartialRequire("XModule/XMainLine2/SubModules/Message/XMainLine2MessageControlConfig", "XMainLine2MessageControl")

function XMainLine2MessageControl:OnInit()
    self:_InitConfigs()
    
    self.EnumConst = {
        UIInputTypes = {
            SelectChoice = 1,
        },
        
        -- 交互内容整体的类型，主要用于入口表现
        MessageType = {
            OnlyText = 1, -- 纯文本
            WithAudio = 2, -- 带有音频
        },
        
        -- 交互内容实际各展示的类型
        MessageContentType = {
            Normal = 1, -- 普通文本显示
            
        },
        
        MessageState = {
            None = 0, -- 未点开过
            HadRead = 1, -- 浏览过，但还剩下内容
            AllRead = 2, -- 所有选项分支都浏览过
        }
    }
    
    self.EventIds = {
        MessageStateChaned = 1, -- 关卡状态改变，arg：messasgeId, newState
    }
end

function XMainLine2MessageControl:AddAgencyEvent()

end

function XMainLine2MessageControl:RemoveAgencyEvent()

end

function XMainLine2MessageControl:OnRelease()

end

--region Condition

--- 判断指定章节是否存在信息内容
--- 作为章节界面信息相关初始化的开关
---@return boolean
function XMainLine2MessageControl:CheckChapterHasMessage(chapterId)
    local cfg = self:GetTableMainLine2MessageGroupsCfgById(chapterId, true)

    return not XTool.IsTableEmpty(cfg)
end

function XMainLine2MessageControl:CheckMessageCanShowById(messagePosId)
    local cfg = self:GetTableMainLine2MessagePositionCfgById(messagePosId)

    if cfg then
        if XTool.IsTableEmpty(cfg.Conditions) then
            return true
        end

        -- conditions是“且”逻辑
        for i, v in pairs(cfg.Conditions) do
            if not XConditionManager.CheckCondition(v) then
                return false
            end
        end

        return true
    end

    return false
end

--- 检查选项是否选择过
--- 本地缓存记录
function XMainLine2MessageControl:CheckContentChoiceHasSelected(contentId, index)
    return self._Model.MessageModel:GetContentChoiceMark(contentId, index)
end
--endregion

function XMainLine2MessageControl:SetContentChoiceHasSelected(contentId, index)
    self._Model.MessageModel:SetContentChoiceMark(contentId, index)
end

function XMainLine2MessageControl:GetMessageStateById(messageId)
    return self._Model.MessageModel:GetMessageStateById(messageId)
end

--- 根据本都缓存判断是否全部选项都选完
function XMainLine2MessageControl:CheckMessageAllReadFromCache(messageId)
    local beginContentId = self:GetCfgMessageBeginContentIdById(messageId)

    if not XTool.IsNumberValidEx(beginContentId) then
        return false
    end
    
    -- 广度优先遍历
    ---@type XQueue
    local queue = XQueue.New()
    
    queue:Enqueue(beginContentId)
    
    while queue:Count() > 0 do
        local id = queue:Dequeue()
        
        local messsageCfg = self:GetTableMainLine2MessageContentsCfgById(id)

        --- 按照显示的选项文本来判断，而不是跳转Id
        if messsageCfg and not XTool.IsTableEmpty(messsageCfg.ConfirmContent)then
            -- 先判断当前内容的选项是否都选过
            for index, v in pairs(messsageCfg.ConfirmContent) do
                -- 任意一个选项未选择过，则返回
                if not self:CheckContentChoiceHasSelected(id, index) then
                    return false
                end
            end

            if not XTool.IsNumberValidEx(messsageCfg.NextMessageIds) then
                for i, nextId in ipairs(messsageCfg.NextMessageIds) do
                    queue:Enqueue(nextId)
                end
            end
        end
    end
    
    return true
end

--region Network

function XMainLine2MessageControl:DoMainLine2MessageStateUpdateRequest(id, state, cb)
    XNetwork.Call("MainLine2MessageStateUpdateRequest", { Id = id, State = state }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end
            
            return
        end

        if not self:GetIsRelease() then
            -- 更新缓存
            self._Model.MessageModel:UpdateMessageStateById(id, state)

            if cb then
                cb(true)
            end
            
            self:DispatchEvent(self.EventIds.MessageStateChaned, id, state)
        end
    end)
end

--endregion

return XMainLine2MessageControl