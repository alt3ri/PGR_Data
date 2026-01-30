---@class XRadioSignControl : XControl
---@field private _Model XRadioSignModel
local XRadioSignControl = XClass(XControl, "XRadioSignControl")
function XRadioSignControl:OnInit()
    --初始化内部变量
end

function XRadioSignControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRadioSignControl:RemoveAgencyEvent()

end

function XRadioSignControl:OnRelease()
end

function XRadioSignControl:GetContentConfigs()
    return self._Model:GetContentConfigs()
end

---@param groupId number
---@return XTableRadioSignClientConfig[]
function XRadioSignControl:GetClientConfigsByGroupId(groupId)
    local configs = self._Model:GetClientConfigs()
    local result = {}
    for _, config in pairs(configs) do
        if config.FmGroupId == groupId then
            table.insert(result, config)
        end
    end
    if #result == 0 then
        XLog.Error("GetClientConfigsByGroupId: %s, not found", groupId)
    end
    return result
end

function XRadioSignControl:IsRewardReceived(contentId)
    return self._Model:IsContentReceived(contentId)
end

return XRadioSignControl
