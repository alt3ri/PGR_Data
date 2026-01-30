---@class XLevelScript4008
---@field _proxy XDlcCSharpFuncs
local XLevelScript4008 = XDlcScriptManager.RegLevelPresentScript(4008)
---@param proxy XDlcCSharpFuncs
function XLevelScript4008:Ctor(proxy)
end

function XLevelScript4008:Init()
    -- 结算Npc
    self._settleNpcPlaceId = 1
    
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.MainMenu, false)      --隐藏主菜单，暂时是反的不到为啥
    self._proxy:ControlSystemFunction(ESystemFunctionType.Message, { true })       --隐藏短信
    self._proxy:ControlSystemFunction(ESystemFunctionType.Map, { true })           --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, { 1, 1002, true }) --任务不能点击
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Task, false)          --隐藏任务按钮
end

---@param dt number delta time
function XLevelScript4008:Update(dt)
    
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4008:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            if eventArgs.TargetPlaceId == self._settleNpcPlaceId then
                self._proxy:RequestLeaveInstanceLevel(false)
            end
        end
    end
end

function XLevelScript4008:Terminate()
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.MainMenu, true)      --隐藏主菜单，暂时是反的不到为啥
    self._proxy:ControlSystemFunction(ESystemFunctionType.Message, { false })  --隐藏短信
    self._proxy:ControlSystemFunction(ESystemFunctionType.Map, { false })         --地图不能点击
    self._proxy:ControlSystemFunction(ESystemFunctionType.Task, { 0 })            --任务不能点击
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Task, true)          --隐藏任务按钮
end


return XLevelScript4008
