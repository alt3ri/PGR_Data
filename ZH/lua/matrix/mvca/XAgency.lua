---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:29
---
local IsWindowsEditor = XMain.IsWindowsEditor

---@class XAgency : XMVCAEvent
XAgency = XClass(XMVCAEvent, "XAgency")

function XAgency:Ctor(id, mainAgency)
    self._Id = id
    ---@type table<string, XAgency>
    self._SubAgencys = {} --子Agency
    self._MainAgency = mainAgency
    self._Model = XMVCA:_GetOrRegisterModel(self._Id)
    self._RpcNameDict = {}
    --Agency分两步，注册跟初始化，该标记用于保证子Agency正常生命周期
    self._IsInit = nil
    --self:OnInit()
end

function XAgency:GetId()
    return self._Id
end

---初始化接口, 提供给子类重写
function XAgency:OnInit()

end

---实现服务器事件注册, 提供给子类重写
function XAgency:InitRpc()
end

function XAgency:AddRpc(name, handler)
    self._RpcNameDict[name] = true
    XRpc[name] = handler
end

function XAgency:_InitAgencyEvent()
    self:InitEvent()
    self:AfterInitManager()
    for _, subAgency in pairs(self._SubAgencys) do
        subAgency:_InitAgencyEvent()
    end
    self._IsInit = true
end

---实现跨模块Agency事件注册
function XAgency:InitEvent()
    --跨模块监听统一在xmvca
    --XMVCA:AddEventListener()
end

---为了兼容老的manager
function XAgency:AfterInitManager()

end

--动态注册后的添加
function XAgency:InitDynamicRegister()
    self:InitRpc()
    self:InitEvent()
end

---移除rpc
function XAgency:RemoveRpc()
    for name, _ in pairs(self._RpcNameDict) do
        XRpc.RemoveRpc(name)
        self._RpcNameDict[name] = nil
    end
end

---移除跨模块事件
function XAgency:RemoveEvent()

end

function XAgency:_CallResetAll()
    for _, subAgency in pairs(self._SubAgencys) do
        subAgency:_CallResetAll()
    end
    self:ResetAll()
    self:RemoveEvent()
    if self._MainAgency == nil then
        self._Model:CallResetAll()
    end
    self._IsInit = false     
end

---与model一致, 重登账号来一个resetAll
function XAgency:ResetAll()

end

function XAgency:OnRelease()

end

function XAgency:Release()
    --子的持有父的，初始化先父后子，释放先子后父
    if self._SubAgencys then
        for _, subAgency in pairs(self._SubAgencys) do
            subAgency:Release()
        end
        self._SubAgencys = nil
    end    
    self:RemoveRpc()
    self:RemoveEvent()
    self:Clear()
    self:OnRelease()
    self._MainAgency = nil
    self._IsInit = nil
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Agency, self)
    end
end

--region 子Agency

---增加一个subAgency,支持在mainAgency中注册添加，和游戏中动态添加
---@param cls any
---@return XAgency
function XAgency:AddSubAgency(cls)
    if not self._SubAgencys[cls] then
        local agency = cls.New(self._Id, self)
        self._SubAgencys[cls] = agency
        agency:OnInit()
        agency:InitRpc()
        if self._IsInit then
            agency:_InitAgencyEvent()
        end    
        return agency
    else
        XLog.Error("请勿重复添加子agency!")
    end
end

---删除一个子agency, 注意业务层要主动释放Rpc,推荐使用AddRpc()接口，该接口的Rpc注册无需业务层主动释放
---@param agency XAgency
function XAgency:RemoveSubAgency(agency)
    if self._SubAgencys[agency.__class] then
        self._SubAgencys[agency.__class] = nil
        agency:ResetAll()
        agency:Release()
    else
        XLog.Error("移除不存在的子agency: " .. agency.__cname)
    end
end

---获取一个子agency
---@return XAgency
function XAgency:GetSubAgency(cls)
    return self._SubAgencys[cls]
end
--endregion

---保留函数, 热重载model
---@param model XModel
function XAgency:_HotReloadModel(model)
    if self._Model then
        self._Model = model
    end
    for _, subAgency in pairs(self._SubAgencys) do
        subAgency:_HotReloadModel(model)
    end
end

---发送当前Agency事件,基于XEventManager
function XAgency:SendAgencyEvent(eventId, ...)
    --XMVCA:DispatchEvent(eventId, ...)
    XEventManager.DispatchEvent(eventId, ...) --先使用原来的接口
end

---添加监听其他Agency事件,基于XEventManager
function XAgency:AddAgencyEvent(eventId, func, obj)
    --XMVCA:AddEventListener(eventId, func, obj)
    XEventManager.AddEventListener(eventId, func, obj) --先使用原来的接口
end

---移除监听其他Agency事件,基于XEventManager
function XAgency:RemoveAgencyEvent(eventId, func, obj)
    --XMVCA:RemoveEventListener(eventId, func, obj)
    XEventManager.RemoveEventListener(eventId, func, obj) --先使用原来的接口
end
