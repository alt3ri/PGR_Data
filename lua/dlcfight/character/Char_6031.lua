local Base = require("Common/XBigWorldCharBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local XNpcGuideController = require("Character/Common/XNpcGuideController")

local GuideAIMode = {
    None = 0,
    FollowPlayer = 1,   -- 向导跟随玩家模式
    RouteGuide = 2,     -- 向导给玩家带路
}

---历程任务向导AI
---@class Char_6031 : XBigWorldCharBase
---@field _AIMode number AI模式, 模式详看 GuideAIMode
---@field _guideController XNpcGuideController 向导组件
---@field _guideIsPlayedCaption boolean 向导是否播放过提示字幕
---@field _guideTipCaptionId number 用以向导提示的简易字幕
---@field _followController XNpcFollowController 跟随组件
---@field _followPlayerNpcUUID number 跟随的当前玩家操控角色NpcId
local Char_6031 = XDlcScriptManager.RegCharScript(6031, "Char_6031", Base)

---@param proxy XDlcCSharpFuncs
function Char_6031:Ctor(proxy)
end

---@protected
function Char_6031:Init()
    Base.Init(self)
    self._AIMode = GuideAIMode.None
    self:InitFollowMode()
    self:InitGuideMode()
end

---@protected
---@param dt number @ delta time
function Char_6031:Update(dt)
    self:CheckModeChange()
    
    if self._AIMode == GuideAIMode.FollowPlayer then
        self:UpdateFollowAI(dt)
    elseif self._AIMode == GuideAIMode.RouteGuide then
        self:UpdateGuideAI(dt)
    end
end

---@protected
---@param eventType number
---@param eventArgs userdata
function Char_6031:HandleEvent(eventType, eventArgs) end

---@protected
function Char_6031:Terminate()
    self:TerminateFollow()
    self:TerminateGuide()
    Base.Terminate(self)
end

---@protected
function Char_6031:CheckModeChange()
    local AIModeInNpcNode = self._proxy:GetNpcNoteInt(self._uuid, NGuideAINoteKey.AIMode)
    if AIModeInNpcNode == GuideAIMode.FollowPlayer then
        local followIdleLimit = self._proxy:GetNpcNoteFloat(self._uuid, NGuideAINoteKey.FollowIdleLimit)
        local followRunLimit = self._proxy:GetNpcNoteFloat(self._uuid, NGuideAINoteKey.FollowRunLimit)
        self._followController:SetIdleLimit(followIdleLimit)
        self._followController:SetRunLimit(followRunLimit)
        if AIModeInNpcNode == self._AIMode then
            return
        end
        self._guideController:CancelGuide()
        self:StartFollowPlayer()
    elseif AIModeInNpcNode == GuideAIMode.RouteGuide then
        local guideTargetPosId = self._proxy:GetNpcNoteFloat3(self._uuid, NGuideAINoteKey.GuideTargetPos)
        local guideTipCaptionId = self._proxy:GetNpcNoteInt(self._uuid, NGuideAINoteKey.GuideCaptionId)
        local guideOutOfRouteDistance = self._proxy:GetNpcNoteFloat(self._uuid, NGuideAINoteKey.GuideOutOfRouteDistance)
        local isHaveGuidePos = self._guideController:IsHaveTarget()
        -- 更换简易字幕, 清空首次偏离路径标记, 可重新触发
        if self._guideTipCaptionId ~= guideTipCaptionId then
            self._guideTipCaptionId = guideTipCaptionId
            self._guideIsPlayedCaption = false
            self._guideController:ClearFirstOutOfRoute()
        end
        if guideOutOfRouteDistance ~= self._guideController:GetOutOfRouteDistance() then
            self._guideController:SetOutOfRouteDistance(guideOutOfRouteDistance)
        end
        -- AI模式一致, 带路目标一致(两次目标距离超过1米视为目标点不一致), 则不重新设置目标点
        if AIModeInNpcNode == self._AIMode and isHaveGuidePos and XScriptTool.Distance(guideTargetPosId, self._guideController:GetTargetPosition()) < 1 then
            return
        end
        self._followController:CancelFollow()
        self._guideController:SetTargetPosition(guideTargetPosId, true)
    elseif AIModeInNpcNode == GuideAIMode.None then
        if AIModeInNpcNode == self._AIMode then
            return
        end
        self._followController:CancelFollow()
        self._guideController:CancelGuide()
    end
    self._AIMode = AIModeInNpcNode
end

--region AI Follow 跟随模式
---@protected
function Char_6031:UpdateFollowAI(dt)
    -- 检查玩家是否切换了角色
    if self._proxy:GetLocalPlayerNpcId() ~= self._followPlayerNpcUUID then
        self:StartFollowPlayer()
    end
    self._followController:Update(dt)
end

---初始化跟随组件
---@protected
function Char_6031:InitFollowMode()
    self._followPlayerNpcUUID = 0
    self._followController = XNpcFollowController.New(self._proxy, self._uuid)
    self._followController:OpenOutOfRangeThenTeleport(20)
end

---开始跟随
---@protected
function Char_6031:StartFollowPlayer()
    self._followPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()
    self._followController:SetFollowTargetNpc(self._followPlayerNpcUUID, 5, 10, 0.2)
end

---卸载跟随
---@protected
function Char_6031:TerminateFollow()
    self._followController:Terminate()
end
--endregion

--region AI Guide 带路模式
---初始化向导组件
---@protected
function Char_6031:InitGuideMode()
    self._guideIsPlayedCaption = false
    self._guideController = XNpcGuideController.New(self._proxy, self._uuid)
end

---@protected
function Char_6031:UpdateGuideAI(dt)
    self._guideController:Update(dt)
    if not self._guideIsPlayedCaption and not self._guideTipCaptionId and self._guideController:IsFirstOutOfRoute() then
        self._proxy:PlayDramaCaption(self._guideTipCaptionId)
        self._guideIsPlayedCaption = true
    end
end

---@protected
function Char_6031:TerminateGuide()
    self._guideController:Terminate()
end
--endregion

return Char_6031
