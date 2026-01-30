---@class XCloudGameControl : XControl
---@field private _Model XCloudGameModel
local XCloudGameControl = XClass(XControl, "XCloudGameControl")
function XCloudGameControl:OnInit()
    --初始化内部变量
end

function XCloudGameControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCloudGameControl:RemoveAgencyEvent()

end

function XCloudGameControl:OnRelease()
end

function XCloudGameControl:GetUiData()
    local uiData = {
        Title1 = self._Model:GetConfig("Title").ParamsString,
        Text1 = self._Model:GetConfig("Text1").ParamsString,
        Text2 = self._Model:GetConfig("Text2").ParamsString,
        Text3 = self._Model:GetConfig("Text3").ParamsString,
        Reward = self._Model:GetConfig("Reward").ParamsInt,
    }
    return uiData
end

return XCloudGameControl