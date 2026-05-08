---@class XLowMemoryAgency : XAgency
---@field private _Model XLowMemoryModel
local XLowMemoryAgency = XClass(XAgency, "XLowMemoryAgency")

-- 低内存机型下，打开这些 UI 会触发战斗资源 GC（XBigWorldMemoryAgency:TryReleaseFightResource）
local LOW_MEMORY_HOOK_UI_LIST = {
    "UiBigWorldCollegeBanner",
}

function XLowMemoryAgency:OnInit()
end

function XLowMemoryAgency:InitRpc()
end

function XLowMemoryAgency:InitEvent()
    local isLow = self:IsLowMemoryDevice()
    if not isLow then
        return
    end
    XMVCA.XBigWorldMemory:AddHookUiList(LOW_MEMORY_HOOK_UI_LIST)
end

function XLowMemoryAgency:RemoveEvent()
    if not self:IsLowMemoryDevice() then
        return
    end
    if XMVCA:IsRegisterAgency(ModuleId.XBigWorldMemory) then
        XMVCA.XBigWorldMemory:RemoveHookUiList(LOW_MEMORY_HOOK_UI_LIST)
    end
end

--- 是否低内存机型
function XLowMemoryAgency:IsLowMemoryDevice()
    return CS.XHardwareManager.LowMemoryDevice
end

--- 低内存机型需要 hook 的 UI 名列表（非低内存机型返回空）
---@return string[]
function XLowMemoryAgency:GetBigWorldHookUiList()
    if not self:IsLowMemoryDevice() then
        return table.empty
    end
    return LOW_MEMORY_HOOK_UI_LIST
end

return XLowMemoryAgency
