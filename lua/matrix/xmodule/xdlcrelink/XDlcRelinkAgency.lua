local XDlcSimulationChallengeAgency = require("XModule/XBase/XDlcSimulationChallengeAgency")
local XDlcRelinkRoom = require("XModule/XDlcRelink/XEntity/XDlcRelinkRoom")
local XDlcRelinkWorldFight = require("XModule/XDlcRelink/XEntity/XDlcRelinkWorldFight")
---@class XDlcRelinkAgency : XDlcSimulationChallengeAgency
---@field private _Model XDlcRelinkModel
local XDlcRelinkAgency = XClass(XDlcSimulationChallengeAgency, "XDlcRelinkAgency")
function XDlcRelinkAgency:OnInit()
    --初始化一些变量
    self:DlcRegisterChapter()
end

function XDlcRelinkAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDlcRelinkData = handler(self, self.NotifyDlcRelinkData)
    XRpc.NotifyDlcRelinkNewEquip = handler(self, self.NotifyDlcRelinkNewEquip)
    XRpc.NotifyRelinkEquipAbsorb = handler(self, self.NotifyRelinkEquipAbsorb)
end

function XDlcRelinkAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region 服务端信息更新

function XDlcRelinkAgency:NotifyDlcRelinkData(data)
    if not data or not XTool.IsNumberValid(data.ActivityId) then
        return
    end
    self._Model:NotifyActivityData(data)
end

function XDlcRelinkAgency:NotifyDlcRelinkNewEquip(data)
    if not data then
        return
    end
    if not self._Model.ActivityData then
        return
    end
    for _, v in pairs(data.EquipDatas) do
        self._Model.ActivityData:AddEquipsData(v)
    end
end

function XDlcRelinkAgency:NotifyRelinkEquipAbsorb(data)
    -- TODO
end

--endregion

--region 通用

function XDlcRelinkAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DlcRelink, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText('CommonActivityNotStart')
        end
        return false
    end
    return true
end

function XDlcRelinkAgency:OpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkMain")
end

--endregion

--region Dlc

function XDlcRelinkAgency:DlcGetRoomProxy()
    return XDlcRelinkRoom.New()
end

function XDlcRelinkAgency:DlcGetFightEvent()
    return XDlcRelinkWorldFight.New()
end

function XDlcRelinkAgency:DlcGetWorldType()
    return XEnumConst.DlcWorld.WorldType.Relink
end

function XDlcRelinkAgency:DlcCheckActivityInTime()
    return true
end

function XDlcRelinkAgency:DlcReconnect()
    local title = XUiHelper.GetText("TipTitle")
    local message = XUiHelper.GetText("OnlineInstanceReconnect")

    XUiManager.DialogTip(title, message, XUiManager.DialogType.Normal, function()
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end, function()
        self:DlcInitFight()
        XMVCA.XDlcRoom:ReconnectToWorld()
    end)
end

function XDlcRelinkAgency:DlcOpenInviteUi(inviteData)
    -- TODO 需要修改
    XLuaUiManager.Open("UiDlcMultiPlayerInvitationPopup", inviteData)
end

function XDlcRelinkAgency:DlcCheckInviteUiShow()
    -- TODO 需要修改
    return XLuaUiManager.IsUiShow("UiDlcMultiPlayerInvitationPopup")
end

--endregion

--region 副本扩展入口

function XDlcRelinkAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.DlcRelink
end

function XDlcRelinkAgency:ExGetProgressTip()
    return CS.XTextManager.GetLuaText("XDlcRelinkAgency.lua_97")
end

function XDlcRelinkAgency:ExCheckIsShowRedPoint()
    return false
end

--endregion

return XDlcRelinkAgency
