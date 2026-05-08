---@class XBigWorldMemoryAgency : XAgency
---@field private _Model XBigWorldMemoryModel
---@field private _HookUiSet table<string, boolean>
local XBigWorldMemoryAgency = XClass(XAgency, "XBigWorldMemoryAgency")

function XBigWorldMemoryAgency:OnInit()
    self._HookUiSet = {}
    self._OnLuaUiOpeningHandler = handler(self, self.OnLuaUiOpening)
end

function XBigWorldMemoryAgency:InitRpc()
end

function XBigWorldMemoryAgency:InitEvent()
    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_OPENING, self._OnLuaUiOpeningHandler)
end

function XBigWorldMemoryAgency:RemoveEvent()
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_OPENING, self._OnLuaUiOpeningHandler)
end

---@param uiName string
function XBigWorldMemoryAgency:AddHookUi(uiName)
    if not uiName then return end
    self._HookUiSet[uiName] = true
end

---@param uiNameList string[]
function XBigWorldMemoryAgency:AddHookUiList(uiNameList)
    if not uiNameList then return end
    for _, name in ipairs(uiNameList) do
        self._HookUiSet[name] = true
    end
end

---@param uiNameList string[]
function XBigWorldMemoryAgency:RemoveHookUiList(uiNameList)
    if not uiNameList then return end
    for _, name in ipairs(uiNameList) do
        self._HookUiSet[name] = nil
    end
end

---@param uiName string
function XBigWorldMemoryAgency:RemoveHookUi(uiName)
    self._HookUiSet[uiName] = nil
end

function XBigWorldMemoryAgency:ClearHookUi()
    self._HookUiSet = {}
end

--- C# XGameEventManager 回调签名: (string evt, object[] args)
---@param event string
---@param args any[] args[0] = uiName
function XBigWorldMemoryAgency:OnLuaUiOpening(event, args)
    local uiName = args and args[0]
    -- XLog.Debug("[XBigWorldMemoryAgency] OnLuaUiOpening: uiName=" .. tostring(uiName))
    if not uiName then
        return
    end
    if not self._HookUiSet[uiName] then
        return
    end
    self:TryReleaseFightResource()
end

--- 释放战斗资源缓存（低内存机型后台 GC 用）
---@return boolean 是否真正调用到 FightResourceManager:TryUnloadAllRes()
function XBigWorldMemoryAgency:TryReleaseFightResource()
    local fightInst = CS.StatusSyncFight
        and CS.StatusSyncFight.XFightClient
        and CS.StatusSyncFight.XFightClient.FightInstance
    if not fightInst then
        XLog.Debug("[XBigWorldMemoryAgency] TryReleaseFightResource skip: FightInstance is nil")
        return false
    end
    local resMgr = fightInst.FightResourceManager
    if not resMgr then
        XLog.Debug("[XBigWorldMemoryAgency] TryReleaseFightResource skip: FightResourceManager is nil")
        return false
    end
    resMgr:TryUnloadAllRes()
    XLog.Debug("[XBigWorldMemoryAgency] TryReleaseFightResource done: FightResourceManager:TryUnloadAllRes called")
    return true
end

return XBigWorldMemoryAgency
