local XLevelScript4015 = XDlcScriptManager.RegLevelPresentScript(4015, "XLevel4015") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript4015:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._tempLevelSwitcherPlaceId = 1

end

function XLevelScript4015:Init() --初始化逻辑
    self._tempLevelSwitcherUUID = self._proxy:GetSceneObjectUUID(self._tempLevelSwitcherPlaceId)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
end

---@param dt number @ delta time
function XLevelScript4015:Update(dt) --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4015:HandleEvent(eventType, eventArgs) --事件响应逻辑
    --if eventType == EWorldEvent.NpcInteractStart then
    --    if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
    --        if eventArgs.TargetId == self._tempLevelSwitcherUUID then
    --            local pos = { x = 678.715, y = 160.7299, z = 1129.907 }
    --            self._proxy:SwitchLevel(4001, pos)
    --        end
    --    end
    --end
end

function XLevelScript4015:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript4015