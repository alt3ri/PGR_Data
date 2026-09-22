---@class XFlowTreeActionPartnerOneKeyLvBreakUp : XFlowTreeAction 突破行为节点：一个 MO 对应一次突破请求
---@field private _NeedList table 拷贝的材料列表 { {Id, Count} }
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _ProgressPopup XUiEquipPartnerEnhanceProgressPopup
local XFlowTreeActionPartnerOneKeyLvBreakUp = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyLvBreakUp")

---@param mo XPartnerOneKeyCultureBaseCostItemMO
function XFlowTreeActionPartnerOneKeyLvBreakUp:Ctor(mo)
    self._NeedList = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(self._NeedList, { Id = item.Id, Count = item.Count })
    end
end

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyLvBreakUp:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._ProgressPopup = context

    self:_SetEvent(true)

    local partnerId = mainControl:GetCurPartnerId()
    self._NetControl:SendBreakThroughRequest(partnerId)
end

function XFlowTreeActionPartnerOneKeyLvBreakUp:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeyLvBreakUp:OnDestroy()
    self.Super.OnDestroy(self)
    self._NeedList = nil
    self._NetControl = nil
    self._Control = nil
    self._ProgressPopup = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeyLvBreakUp:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_BREAK_THROUGH, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_BREAK_THROUGH, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeyLvBreakUp:_OnReply(isSuccess)
    if not isSuccess then
        self:_OnFailLog()
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    self._ProgressPopup:SetHasCultureSuccess(true)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyLvBreakUp:_OnFailLog()
    local sb = {}
    table.insert(sb, "[LvBreakUp] 失败!")
    table.insert(sb, "所需材料:")
    for _, item in ipairs(self._NeedList) do
        local have = XDataCenter.ItemManager.GetCount(item.Id)
        table.insert(sb, string.format("  Id=%d need=%d have=%d", item.Id, item.Count, have))
    end
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeyLvBreakUp
