--- 聊天文本内容复制功能
---@class XUiChatMsgCopy: XUiNode
---@field protected _Control
---@field Parent
local XUiChatMsgCopy = XClass(XUiNode, "XUiChatMsgCopy")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

local ShowBubblePivot = CS.UnityEngine.Vector2(0.5, 0)
local ChatMsgCopyClickScaleTarget = CS.XGame.ClientConfig:GetFloat('ChatMsgCopyClickScaleTarget')
local LongClickUpTime = CS.XGame.ClientConfig:GetFloat('ChatMsgCopyLongClickTime')
local ChatMsgCopyClickScaleDuration = CS.XGame.ClientConfig:GetFloat('ChatMsgCopyClickScaleDuration')

local ChatMsgCopyClickScaleTargetVec3 = CS.UnityEngine.Vector3(ChatMsgCopyClickScaleTarget, ChatMsgCopyClickScaleTarget, ChatMsgCopyClickScaleTarget)
local ChatMsgOriginScaleVec3 = CS.UnityEngine.Vector3.one

function XUiChatMsgCopy:OnStart()
    if self.Content then
        -- 需要转化为毫秒
        local longClickUpTime = math.floor(XScheduleManager.SECOND * LongClickUpTime)
        
        ---@type XUiButtonLongClick
        self.ContentPointer = XUiButtonLongClick.New(self.Content, nil, self, nil, self.OnLongClickUpEvent, nil, nil, nil, true, true, longClickUpTime)
    end
    
    ---@type XUiPointer
    local uiPointer = self.ContentPointer.Widget

    if uiPointer then
        uiPointer:AddPointerDownListener(handler(self, self.OnBtnDown))
        uiPointer:AddPointerUpListener(handler(self, self.OnBtnUp))
    end
end

function XUiChatMsgCopy:OnDestroy()
    self:StopUniqueDoTweenTimerId()
end

function XUiChatMsgCopy:SetMsg(msg)
    self.Msg = msg;
end

function XUiChatMsgCopy:OnLongClickUpEvent()
    local showPivot = self.CopyPoint and self.CopyPoint.transform.pivot or ShowBubblePivot
    local position = self.CopyPoint and self.CopyPoint.transform.position or self.Content.transform.position
    
    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_MSG_COPY_SHOW, self.Msg, position, showPivot)
end

function XUiChatMsgCopy:OnBtnDown()
    self:StopUniqueDoTweenTimerId()
    
    self.DoTweenTimerId = XUiHelper.DoScale(self.Content.transform, self.Content.transform.localScale, ChatMsgCopyClickScaleTargetVec3, ChatMsgCopyClickScaleDuration)
end

function XUiChatMsgCopy:OnBtnUp()
    self:StopUniqueDoTweenTimerId()
    
    self.DoTweenTimerId = XUiHelper.DoScale(self.Content.transform, self.Content.transform.localScale, ChatMsgOriginScaleVec3, ChatMsgCopyClickScaleDuration)
end

function XUiChatMsgCopy:StopUniqueDoTweenTimerId()
    if self.DoTweenTimerId then
        XScheduleManager.UnSchedule(self.DoTweenTimerId)
        self.DoTweenTimerId = nil
    end
end

return XUiChatMsgCopy