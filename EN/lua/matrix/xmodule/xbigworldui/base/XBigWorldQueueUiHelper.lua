local XBigWorldUiData = require("XModule/XBigWorldUI/Data/XBigWorldUiData")

---@class XBigWorldQueueUiHelper 队列打开UI
local XBigWorldQueueUiHelper = XClass(nil, "XBigWorldQueueUiHelper")

local UiNameIndex = 0

function XBigWorldQueueUiHelper:Ctor()
    ---@type XBigWorldUiData[]
    self._AwaitUiQueue = {}
    ---@type table<string, XBigWorldUiData> 队列中正在展示的UI
    self._ShowingUiMap = {}
    ---@type XBigWorldUiData[]
    self._UiDataPool = {}

    self._OpeningUiName = false

    self._IsRegistering = false

    self:_RegisterListenEvent()
end

function XBigWorldQueueUiHelper:OnFunctionEventEnd()
    if self:IsEmpty() then
        return
    end
    --界面还在展示中
    if self._OpeningUiName then
        return
    end
    self:_OpenNext()
end

---@param event string 事件Id
---@param args System.Object[] 参数
function XBigWorldQueueUiHelper:OnUiDestroy(event, args)
    local uiName = self:_GetUiName(args)

    if XMVCA.XBigWorldUI:IsVirtual(uiName) then
        return
    end

    if self._OpeningUiName == uiName then
        self._OpeningUiName = false
    end
    
    self:_TryOpenNext(uiName)
end

---@param event string 事件Id
---@param args System.Object[] 参数
function XBigWorldQueueUiHelper:OnUiAllowOperate(event, args)
    --if self:CheckOpening() then
    --    local uiName = self:_GetUiName(args)
    --
    --    if XMVCA.XBigWorldUI:IsVirtual(uiName) then
    --        return
    --    end
    --
    --    if self._OpeningUiName == uiName then
    --        self._OpeningUiName = false
    --        self:_TryOpenUi()
    --    end
    --end
end

function XBigWorldQueueUiHelper:Open(uiName, ...)
    local data = self:_FetchUiData(uiName, ...)

    -- 队列为空，直接打开UI
    if self:CheckOpenDirectly(uiName) and not self:CheckOpening() then
        self:_OpenUi(data)
        return
    end

    self:_EnqueueData(data)
end

function XBigWorldQueueUiHelper:InsertHeaderAwaitUi(uiName, ...)
    local uiData = self:_FetchUiData(uiName, ...)

    table.insert(self._AwaitUiQueue, uiData)
end

function XBigWorldQueueUiHelper:ChangeUiDataArgByIndex(uiName, index, value)
    if self:CheckUiShowing(uiName) then
        local uiData = self._ShowingUiMap[uiName]

        if not uiData:IsEmpty() then
            uiData:SetArgByIndex(index, value)
        end
    end
end

function XBigWorldQueueUiHelper:CheckOpenDirectly(uiName)
    if not XTool.IsTableEmpty(self._ShowingUiMap) then
        for _, uiData in pairs(self._ShowingUiMap) do
            if uiData:IsModality() or uiData:IsSpecificModality(uiName) then
                return false
            end
        end
    end

    return XTool.IsTableEmpty(self._AwaitUiQueue)
end

function XBigWorldQueueUiHelper:CheckUiShowing(uiName)
    return self._ShowingUiMap[uiName]
end

function XBigWorldQueueUiHelper:CheckOpening()
    return self._OpeningUiName
end

function XBigWorldQueueUiHelper:IsEmpty()
    return XTool.IsTableEmpty(self._AwaitUiQueue)
end

function XBigWorldQueueUiHelper:Init()
    self:Release()
    self._UiDestroyHandler = Handler(self, self.OnUiDestroy)
    --self._UiAllowOperateHandler = Handler(self, self.OnUiAllowOperate)
    self:_RegisterListenEvent()
end

function XBigWorldQueueUiHelper:Release()
    self._IsRegistering = false
    self._OpeningUiName = false
    self:_ClearQueue()
    self:_UnRegisterStopListenEvent()
end

---@param uiData XBigWorldUiData
function XBigWorldQueueUiHelper:_EnqueueData(uiData)
    if uiData and not uiData:IsEmpty() then
        for i, data in ipairs(self._AwaitUiQueue) do
            if data:GetPriority() > uiData:GetPriority() then
                table.insert(self._AwaitUiQueue, i, uiData)
                return
            end
        end

        table.insert(self._AwaitUiQueue, uiData)
    end
end

---@return XBigWorldUiData
function XBigWorldQueueUiHelper:_DequeueData()
    local count = table.nums(self._AwaitUiQueue)
    local uiData = table.remove(self._AwaitUiQueue, count)

    return uiData
end

---@return XBigWorldUiData
function XBigWorldQueueUiHelper:_PeekData()
    if XTool.IsTableEmpty(self._AwaitUiQueue) then
        return nil
    end

    local count = table.nums(self._AwaitUiQueue)

    return self._AwaitUiQueue[count]
end

---@return XBigWorldUiData
function XBigWorldQueueUiHelper:_FetchUiData(uiName, ...)
    local count = table.nums(self._UiDataPool)
    local data = false

    if count > 0 then
        data = table.remove(self._UiDataPool, count)
        data:SetUiName(uiName)
        data:SetArgs(...)
    else
        data = XBigWorldUiData.New(uiName, ...)
    end

    return data
end

---@param data XBigWorldUiData
function XBigWorldQueueUiHelper:_RecycleUiData(data)
    data:Clear()
    self._UiDataPool[#self._UiDataPool + 1] = data
end

function XBigWorldQueueUiHelper:_RegisterListenEvent()
    if not self._IsRegistering then
        self._IsRegistering = true
        CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DESTROY, self._UiDestroyHandler)
        XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_END, self.OnFunctionEventEnd, self)
        --CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, self._UiAllowOperateHandler)
    end
end

function XBigWorldQueueUiHelper:_UnRegisterStopListenEvent()
    if self._IsRegistering then
        CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DESTROY, self._UiDestroyHandler)
        XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_END, self.OnFunctionEventEnd, self)
        --CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, self._UiAllowOperateHandler)
        self._IsRegistering = false
    end
end

function XBigWorldQueueUiHelper:_GetUiName(args)
    if not args or args.Length <= 0 then
        return ""
    end

    local ui = args[UiNameIndex]

    if not ui or not ui.UiData then
        return ""
    end

    return ui.UiData.UiName or ""
end

---@param uiData XBigWorldUiData
function XBigWorldQueueUiHelper:_OpenUi(uiData)
    if not uiData or uiData:IsEmpty() then
        return
    end

    local uiName = uiData:GetUiName()

    self._OpeningUiName = uiName
    self._ShowingUiMap[uiName] = uiData
    XMVCA.XBigWorldUI:ImpactUiOpening(uiName)
    XLuaUiManager.Open(uiName, uiData:GetArgs(true))
end

function XBigWorldQueueUiHelper:_TryOpenUi()
    local data = self:_PeekData()

    if not data or data:IsEmpty() then
        return
    end

    local uiName = data:GetUiName()

    if self:CheckOpenDirectly(uiName) and not self:CheckOpening() then
        self:_DequeueData()
        self:_OpenUi(data)
        self:_RecycleUiData(data)
    end
end

function XBigWorldQueueUiHelper:_OpenNext()
    if XTool.IsTableEmpty(self._AwaitUiQueue) then
        self:_ClearQueue()
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CHECK_FUNCTION_POPUP)
        return
    end

    ---@type XUiManager
    local instance = CS.XUiManager.Instance

    if instance.ClosingAll then
        self:_ClearQueue()
        return
    end

    ---@type XBigWorldUiData
    local data = self:_DequeueData()

    self:_OpenUi(data)
    self:_RecycleUiData(data)
end

function XBigWorldQueueUiHelper:_TryOpenNext(uiName)
    if not self:CheckUiShowing(uiName) then
        return
    end

    self._ShowingUiMap[uiName] = nil
    self:_OpenNext()
end

function XBigWorldQueueUiHelper:_ClearQueue()
    self._AwaitUiQueue = {}
    self._ShowingUiMap = {}
end

return XBigWorldQueueUiHelper
