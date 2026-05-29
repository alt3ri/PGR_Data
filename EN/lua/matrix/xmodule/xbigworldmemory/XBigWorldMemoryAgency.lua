---@class XBigWorldMemoryAgency : XAgency
---@field private _Model XBigWorldMemoryModel
---@field private _HookUiOpenMap table<string, number> uiName -> EHandleType（UI 打开时触发的 handler）
---@field private _HookUiCloseMap table<string, number> uiName -> EHandleType（UI 关闭时触发的 handler）
---@field private _HandlerMap table<number, fun(self:XBigWorldMemoryAgency, uiName:string):boolean>
---@field private _HandlerTriggerMap table<number, number> EHandleType -> ETrigger
local XBigWorldMemoryAgency = XClass(XAgency, "XBigWorldMemoryAgency")
--- 面板 Hook 响应类型枚举（注册时决定该 uiName 命中后走哪种处理）
local EHandleType = {
    ReleaseFightResource = 1, -- 调用 FightResourceManager:ReleaseMemory()
    ResumeMemoryOnClose = 2, -- 调用 FightResourceManager:ResumeMemory()
}
XBigWorldMemoryAgency.EHandleType = EHandleType

--- handler 触发时机
local ETrigger = {
    OnOpen = 1,
    OnClose = 2,
}

function XBigWorldMemoryAgency:OnInit()
    self._HookUiOpenMap = {}
    self._HookUiCloseMap = {}
    self._HandlerMap = {
        [EHandleType.ReleaseFightResource] = self.TryReleaseFightResource,
        [EHandleType.ResumeMemoryOnClose] = self.ResumeMemoryOnClose,
    }
    self._HandlerTriggerMap = {
        [EHandleType.ReleaseFightResource] = ETrigger.OnOpen,
        [EHandleType.ResumeMemoryOnClose] = ETrigger.OnClose,
    }
end

function XBigWorldMemoryAgency:ResetAll()
    self._HookUiOpenMap = {}
    self._HookUiCloseMap = {}
end

function XBigWorldMemoryAgency:InitRpc()
end

function XBigWorldMemoryAgency:InitEvent()
    self._OnLuaUiOpeningHandler = handler(self, self.OnLuaUiOpening)
    self._OnLuaUiDestroyHandler = handler(self, self.OnLuaUiDestroy)

    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_OPENING, self._OnLuaUiOpeningHandler)
    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DESTROY, self._OnLuaUiDestroyHandler)
end

function XBigWorldMemoryAgency:RemoveEvent()
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_OPENING, self._OnLuaUiOpeningHandler)
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DESTROY, self._OnLuaUiDestroyHandler)
end

---@param uiName string
---@param handleType number EHandleType
function XBigWorldMemoryAgency:AddHookUi(uiName, handleType)
    if not uiName then
        return
    end
    if not self._HandlerMap[handleType] then
        XLog.Error("[XBigWorldMemoryAgency] AddHookUi invalid handleType: " .. tostring(handleType) .. ", uiName=" ..
                       tostring(uiName))
        return
    end
    local map = self:_GetHookMapByHandleType(handleType)
    local old = map[uiName]
    if old and old ~= handleType then
        XLog.Debug("[XBigWorldMemoryAgency] AddHookUi override: uiName=" .. tostring(uiName) .. ", old=" ..
                       tostring(old) .. ", new=" .. tostring(handleType))
    end
    map[uiName] = handleType
end

---@param uiNameList string[]
---@param handleType number EHandleType
function XBigWorldMemoryAgency:AddHookUiList(uiNameList, handleType)
    if not uiNameList then
        return
    end
    for _, name in ipairs(uiNameList) do
        self:AddHookUi(name, handleType)
    end
end

---@param uiName string
function XBigWorldMemoryAgency:RemoveHookUi(uiName)
    if not uiName then
        return
    end
    self._HookUiOpenMap[uiName] = nil
    self._HookUiCloseMap[uiName] = nil
end

---@param uiNameList string[]
function XBigWorldMemoryAgency:RemoveHookUiList(uiNameList)
    if not uiNameList then
        return
    end
    for _, name in ipairs(uiNameList) do
        self._HookUiOpenMap[name] = nil
        self._HookUiCloseMap[name] = nil
    end
end

function XBigWorldMemoryAgency:ClearHookUi()
    self._HookUiOpenMap = {}
    self._HookUiCloseMap = {}
end

---@private
---@param handleType number EHandleType
---@return table<string, number>
function XBigWorldMemoryAgency:_GetHookMapByHandleType(handleType)
    local trigger = self._HandlerTriggerMap[handleType]
    if trigger == ETrigger.OnClose then
        return self._HookUiCloseMap
    end
    return self._HookUiOpenMap
end

--- C# XGameEventManager 回调签名: (string evt, object[] args)
---@param event string
---@param args any[] args[0] = uiName
function XBigWorldMemoryAgency:OnLuaUiOpening(event, args)
    local uiName = args and args[0]
    if not uiName then
        return
    end
    self:_DispatchHandler(self._HookUiOpenMap, uiName)
end

--- EVENT_UI_DESTROY 回调：args[0] 为 XUi 对象，UiName 在 ui.UiData.UiName
---@param event string
---@param args any[]
function XBigWorldMemoryAgency:OnLuaUiDestroy(event, args)
    if not args or args.Length <= 0 then
        return
    end
    local ui = args[0]
    if not ui or not ui.UiData then
        return
    end
    local uiName = ui.UiData.UiName
    if not uiName then
        return
    end
    self:_DispatchHandler(self._HookUiCloseMap, uiName)
end

---@private
---@param map table<string, number>
---@param uiName string
function XBigWorldMemoryAgency:_DispatchHandler(map, uiName)
    local handleType = map[uiName]
    if not handleType then
        return
    end
    local handlerFn = self._HandlerMap[handleType]
    if not handlerFn then
        XLog.Error("[XBigWorldMemoryAgency] no handler for type: " .. tostring(handleType) .. ", uiName=" ..
                       tostring(uiName))
        return
    end
    handlerFn(self, uiName)
end

--- 释放战斗资源缓存（低内存机型后台 GC 用）
---@param uiName string 触发的面板名（用于日志，可空）
---@return boolean 是否真正调用到 FightResourceManager:ReleaseMemory()
function XBigWorldMemoryAgency:TryReleaseFightResource(uiName)
    local resMgr = self:_GetFightResourceManager()
    if not resMgr then
        return false
    end
    resMgr:ReleaseMemory()
    return true
end

---@private
---@return StatusSyncFight.XFightResourceManager|nil
function XBigWorldMemoryAgency:_GetFightResourceManager()
    local fightInst = CS.StatusSyncFight and CS.StatusSyncFight.XFightClient and
                          CS.StatusSyncFight.XFightClient.FightInstance
    if not fightInst then
        return nil
    end
    return fightInst.FightResourceManager
end

--- 面板关闭后触发：仅在大世界中时调用 FightResourceManager:ResumeMemory()，恢复内存占用
---@param uiName string 触发的面板名（用于日志，可空）
---@return boolean 是否真正调用到 FightResourceManager:ResumeMemory()
function XBigWorldMemoryAgency:ResumeMemoryOnClose(uiName)
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return false
    end
    local resMgr = self:_GetFightResourceManager()
    if not resMgr then
        return false
    end
    resMgr:ResumeMemory()
    return true
end

return XBigWorldMemoryAgency
