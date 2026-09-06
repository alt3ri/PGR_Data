---@class XFlowTreeActionPartnerOneKeyLvExpUp : XFlowTreeAction 升级行为节点：一个 MO 对应一次喂经验请求
---@field private _NeedList table 拷贝的材料列表 { {Id, Count} }
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _ProgressPopup XUiEquipPartnerEnhanceProgressPopup
local XFlowTreeActionPartnerOneKeyLvExpUp = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyLvExpUp")

---@param mo XPartnerOneKeyCultureBaseCostItemMO
function XFlowTreeActionPartnerOneKeyLvExpUp:Ctor(mo)
    self._NeedList = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(self._NeedList, { Id = item.Id, Count = item.Count })
    end
end

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyLvExpUp:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._ProgressPopup = context

    self:_SetEvent(true)

    local partnerId = mainControl:GetCurPartnerId()

    -- 从拷贝的 NeedList 提取经验道具
    local useItems = {}
    local expItemIds = {}
    local expItemList = XDataCenter.PartnerManager.GetExpItemList()
    for _, item in ipairs(expItemList) do
        expItemIds[item.Id] = true
    end
    for _, item in ipairs(self._NeedList) do
        if expItemIds[item.Id] then
            useItems[item.Id] = (useItems[item.Id] or 0) + item.Count
        end
    end

    -- 防御：空 MO（无经验道具可喂）不发协议，直接成功跳过
    if not next(useItems) then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    self._NetControl:SendLevelUpRequest(partnerId, useItems)
end

function XFlowTreeActionPartnerOneKeyLvExpUp:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeyLvExpUp:OnDestroy()
    self.Super.OnDestroy(self)
    self._NeedList = nil
    self._NetControl = nil
    self._Control = nil
    self._ProgressPopup = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeyLvExpUp:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_LEVEL_UP, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_LEVEL_UP, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeyLvExpUp:_OnReply(isSuccess)
    if not isSuccess then
        self:_OnFailLog()
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    self._ProgressPopup:SetHasCultureSuccess(true)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyLvExpUp:_OnFailLog()
    local sb = {}
    table.insert(sb, "[LvExpUp] 失败!")
    table.insert(sb, "所需材料:")
    for _, item in ipairs(self._NeedList) do
        local have = XDataCenter.ItemManager.GetCount(item.Id)
        table.insert(sb, string.format("  Id=%d need=%d have=%d", item.Id, item.Count, have))
    end
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeyLvExpUp
