---@class XLowMemoryAgency : XAgency
---@field private _Model XLowMemoryModel
local XLowMemoryAgency = XClass(XAgency, "XLowMemoryAgency")

-- 低内存机型下，打开这些 UI 会触发战斗资源 GC（XBigWorldMemoryAgency:TryReleaseFightResource）
local LOW_MEMORY_RELEASE_RES_UI_LIST = {
    "UiBigWorldCollegeBanner",
}
-- 低内存机型下，关闭这些 UI 后若还在大世界中，触发 FightResourceManager:ResumeMemory()（XBigWorldMemoryAgency:ResumeMemoryOnClose）
local LOW_MEMORY_GC_ON_CLOSE_UI_LIST = {
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
    local memAgency = XMVCA.XBigWorldMemory
    memAgency:AddHookUiList(
        LOW_MEMORY_RELEASE_RES_UI_LIST,
        memAgency.EHandleType.ReleaseFightResource
    )
    memAgency:AddHookUiList(
        LOW_MEMORY_GC_ON_CLOSE_UI_LIST,
        memAgency.EHandleType.ResumeMemoryOnClose
    )
end

function XLowMemoryAgency:RemoveEvent()
    if not self:IsLowMemoryDevice() then
        return
    end
    if XMVCA:IsRegisterAgency(ModuleId.XBigWorldMemory) then
        local memAgency = XMVCA.XBigWorldMemory
        memAgency:RemoveHookUiList(LOW_MEMORY_RELEASE_RES_UI_LIST)
        memAgency:RemoveHookUiList(LOW_MEMORY_GC_ON_CLOSE_UI_LIST)
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
    local list = {}
    for _, name in ipairs(LOW_MEMORY_RELEASE_RES_UI_LIST) do
        list[#list + 1] = name
    end
    for _, name in ipairs(LOW_MEMORY_GC_ON_CLOSE_UI_LIST) do
        list[#list + 1] = name
    end
    return list
end

return XLowMemoryAgency
