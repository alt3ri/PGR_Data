---@class XFlowTreeActionPartnerOneKeySkillUp : XFlowTreeAction 技能升级行为节点：一个 MO 对应一次技能升级请求
---@field private _SkillId number
---@field private _TargetLevel number
---@field private _NeedList table 拷贝的材料列表 { {Id, Count} }
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _ProgressPopup XUiEquipPartnerEnhanceProgressPopup
local XFlowTreeActionPartnerOneKeySkillUp = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeySkillUp")

---@param mo XPartnerOneKeyCultureBaseCostItemMO
function XFlowTreeActionPartnerOneKeySkillUp:Ctor(mo)
    local skillId, targetLevel = mo:GetTargetSkillUpData()
    self._SkillId = skillId
    self._TargetLevel = targetLevel
    self._NeedList = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(self._NeedList, { Id = item.Id, Count = item.Count })
    end
end

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeySkillUp:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._ProgressPopup = context

    self:_SetEvent(true)

    -- 防御：材料/螺母不足时不发请求，避免底层 PartnerSkillUpRequest 内的 DoNotEnoughBuyAsset 弹出螺母购买弹窗
    for _, item in ipairs(self._NeedList) do
        if XDataCenter.ItemManager.GetCount(item.Id) < item.Count then
            self:_OnFailLog("ItemNotEnough")
            self:OnDone(self.XFlowTreeEnum.Result.Fail)
            return
        end
    end

    local partnerId = mainControl:GetCurPartnerId()
    self._NetControl:SendSkillUpRequest(partnerId, self._SkillId, 1)
end

function XFlowTreeActionPartnerOneKeySkillUp:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeySkillUp:OnDestroy()
    self.Super.OnDestroy(self)
    self._NeedList = nil
    self._NetControl = nil
    self._Control = nil
    self._ProgressPopup = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeySkillUp:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_SKILL_UP, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_SKILL_UP, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeySkillUp:_OnReply(isSuccess, errorCode)
    if not isSuccess then
        self:_OnFailLog(errorCode)
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    self._ProgressPopup:SetHasCultureSuccess(true)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeySkillUp:_OnFailLog(errorCode)
    local partner = self._Control:GetOneKeyCultureMainControl():GetCurPartnerEntity()
    local gap = partner and partner:GetSkillLevelGap() or -1
    local sb = {}
    table.insert(sb, string.format("[SkillUp] 失败! skillId=%d targetLevel=%d skillGap=%d errorCode=%s", self._SkillId, self._TargetLevel, gap, tostring(errorCode)))
    table.insert(sb, "所需材料:")
    for _, item in ipairs(self._NeedList) do
        local have = XDataCenter.ItemManager.GetCount(item.Id)
        table.insert(sb, string.format("  Id=%d need=%d have=%d", item.Id, item.Count, have))
    end
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeySkillUp
