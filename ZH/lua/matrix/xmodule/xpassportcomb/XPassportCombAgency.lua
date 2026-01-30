---@class XPassportCombAgency : XAgency
---@field private _Model XPassportCombModel
local XPassportCombAgency = XClass(XAgency, "XPassportCombAgency")
function XPassportCombAgency:OnInit()
end

function XPassportCombAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyCombPassportData = Handler(self, self.NotifyCombPassportData)
    XRpc.NotifyCombPassportBaseInfo = handler(self, self.NotifyCombPassportBaseInfo)
    XRpc.NotifyCombPassportAutoGetTaskReward = Handler(self, self.NotifyCombPassportAutoGetTaskReward)
end

function XPassportCombAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--登录推送数据
function XPassportCombAgency:NotifyCombPassportData(data)
    self._Model:NotifyPassportData(data)
end

function XPassportCombAgency:NotifyCombPassportBaseInfo(data)
    self._Model:NotifyPassportBaseInfo(data)
end

function XPassportCombAgency:NotifyCombPassportAutoGetTaskReward(data)
    self._Model:NotifyPassportAutoGetTaskReward(data)
end

function XPassportCombAgency:CheckPassportRewardRedPoint()
    return self._Model:CheckPassportRewardRedPoint()
end

function XPassportCombAgency:GetPassportBaseInfo()
    return self._Model:GetBaseInfo()
end

function XPassportCombAgency:CheckPassportAchievedTaskRedPoint(...)
    return self._Model:CheckPassportAchievedTaskRedPoint(...)
end

function XPassportCombAgency:IsActivityClose()
    return self._Model:IsActivityClose()
end

function XPassportCombAgency:OpenMainUi()
    if not self._Model:CheckActivityIsOpen(true) then
        return
    end
    XUiHelper.OpenPassport()
end

function XPassportCombAgency:GetPassportActivityTimeId()
    return self._Model:GetPassportActivityTimeId()
end

function XPassportCombAgency:GetPassportMaxLevel()
    return self._Model:GetPassportMaxLevel()
end

return XPassportCombAgency