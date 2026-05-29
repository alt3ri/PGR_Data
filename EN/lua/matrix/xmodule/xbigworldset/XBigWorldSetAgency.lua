---@class XBigWorldSetAgency : XAgency
---@field private _Model XBigWorldSetModel
local XBigWorldSetAgency = XClass(XAgency, "XBigWorldSetAgency")
function XBigWorldSetAgency:OnInit()
    --初始化一些变量
end

function XBigWorldSetAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBigWorldSetAgency:InitEvent()
    self:AddAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_AFTER_ENTER_GAME, self._OnAfterEnterGame, self)
end

function XBigWorldSetAgency:RemoveEvent()
    self:RemoveAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_AFTER_ENTER_GAME, self._OnAfterEnterGame, self)
end

function XBigWorldSetAgency:_OnAfterEnterGame()
    local setting = self._Model:GetSettingBySetType(XEnumConst.BWSetting.SetType.Graphics)
    if setting then
        setting:TryRecordDailyBigWorldSetting()
    end
end

function XBigWorldSetAgency:GetDefaultSetTypes()
    return {
        XEnumConst.BWSetting.SetType.Voice,
        XEnumConst.BWSetting.SetType.Graphics,
        XEnumConst.BWSetting.SetType.Other,
        XEnumConst.BWSetting.SetType.Input,
    }
end

function XBigWorldSetAgency:OpenSettingUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldSet")
end

function XBigWorldSetAgency:SetSpecialScreenOff(value)
    self._Model:SetSpecialScreenOff(value)
end

function XBigWorldSetAgency:GetBigWorldShowInputMapIds()
    return self._Model:GetBigWorldShowInputMapIds()
end

return XBigWorldSetAgency