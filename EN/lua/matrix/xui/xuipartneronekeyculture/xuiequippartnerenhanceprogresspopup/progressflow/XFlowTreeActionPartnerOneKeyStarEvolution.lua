---@class XFlowTreeActionPartnerOneKeyStarEvolution : XFlowTreeAction 进化节点：发送进化请求，提升品质
---@field private _NeedList table 拷贝的材料列表 { {Id, Count} }
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _OneKeyCultureMainControl XPartnerOneKeyCultureControl
---@field private _ProgressPopup XUiEquipPartnerEnhanceProgressPopup
local XFlowTreeActionPartnerOneKeyStarEvolution = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyStarEvolution")

---@param mo XPartnerOneKeyCultureBaseCostItemMO
function XFlowTreeActionPartnerOneKeyStarEvolution:Ctor(mo)
    self._NeedList = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(self._NeedList, { Id = item.Id, Count = item.Count })
    end
end

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyStarEvolution:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._OneKeyCultureMainControl = mainControl
    self._ProgressPopup = context

    self:_SetEvent(true)

    local partnerId = mainControl:GetCurPartnerId()
    self._NetControl:SendEvolutionRequest(partnerId)
end

function XFlowTreeActionPartnerOneKeyStarEvolution:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeyStarEvolution:OnDestroy()
    self.Super.OnDestroy(self)
    self._NeedList = nil
    self._NetControl = nil
    self._OneKeyCultureMainControl = nil
    self._Control = nil
    self._ProgressPopup = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeyStarEvolution:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_EVOLUTION, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_EVOLUTION, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeyStarEvolution:_OnReply(isSuccess)
    if not isSuccess then
        self:_OnFailLog()
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    self._ProgressPopup:SetHasCultureSuccess(true)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyStarEvolution:_OnFailLog()
    local sb = {}
    table.insert(sb, "[StarEvolution] 失败!")
    table.insert(sb, "所需材料:")
    for _, item in ipairs(self._NeedList) do
        local have = XDataCenter.ItemManager.GetCount(item.Id)
        table.insert(sb, string.format("  Id=%d need=%d have=%d", item.Id, item.Count, have))
    end
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeyStarEvolution
