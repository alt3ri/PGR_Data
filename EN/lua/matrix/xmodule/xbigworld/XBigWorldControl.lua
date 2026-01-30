---@class XBigWorldControl : XControl
---@field private _Model XBigWorldModel
---@field private _Agency XBigWorldAgency
local XBigWorldControl = XClass(XControl, "XBigWorldControl")
function XBigWorldControl:OnInit()
    
end

function XBigWorldControl:AddAgencyEvent()
end

function XBigWorldControl:RemoveAgencyEvent()
end

function XBigWorldControl:OnRelease()
end

--region 主界面跳转

function XBigWorldControl:OpenMenu()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenMenu()
end

function XBigWorldControl:OpenQuest()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest()
end

function XBigWorldControl:OpenBackpack()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenBackpack()
end

function XBigWorldControl:OpenMessage()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenMessage()
end

function XBigWorldControl:OpenTeam()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenTeam()
end

function XBigWorldControl:OpenExplore()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenExplore()
end

function XBigWorldControl:OpenPhoto(isSequence, ...)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenPhoto(isSequence, ...)
end

function XBigWorldControl:OpenTeaching()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenTeaching()
end

function XBigWorldControl:OpenSetting()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenSetting()
end

function XBigWorldControl:OpenMap()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenMap()
end

function XBigWorldControl:OpenFashion(characterId, typeIndex)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenFashion(characterId, typeIndex)
end

function XBigWorldControl:Exit()
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():Exit()
end

--endregion 主界面跳转

return XBigWorldControl