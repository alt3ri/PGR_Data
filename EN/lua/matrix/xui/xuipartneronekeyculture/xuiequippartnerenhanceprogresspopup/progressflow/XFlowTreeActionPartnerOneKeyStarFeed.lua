---@class XFlowTreeActionPartnerOneKeyStarFeed : XFlowTreeAction 喂狗粮节点：检查当前星级进度，不足则从池中取狗粮喂养
---@field private _NeedList table 拷贝的材料列表 { {Id, Count} }
---@field private _IsTailFeed boolean 是否为尾喂养
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _OneKeyCultureMainControl XPartnerOneKeyCultureControl
---@field private _ProgressPopup XUiEquipPartnerEnhanceProgressPopup
local XFlowTreeActionPartnerOneKeyStarFeed = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyStarFeed")

---@param mo XPartnerOneKeyCultureBaseCostItemMO
---@param isTailFeed boolean?
function XFlowTreeActionPartnerOneKeyStarFeed:Ctor(mo, isTailFeed)
    self._NeedList = {}
    for _, item in ipairs(mo:GetNeedList()) do
        table.insert(self._NeedList, { Id = item.Id, Count = item.Count })
    end
    self._IsTailFeed = isTailFeed or false
end

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyStarFeed:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._OneKeyCultureMainControl = mainControl
    self._ProgressPopup = context

    self:_SetEvent(true)

    local partner = mainControl:GetCurPartnerEntity()
    if not partner then
        XLog.Error("[StarFeed] 失败! 当前辅助机实体为空")
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end

    -- 星级进度已满，跳过喂养
    if partner:GetCanUpQuality() then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    local partnerId = mainControl:GetCurPartnerId()
    local XPartnerEnum = XMVCA.XPartner.Enum

    -- 从 NeedList 取狗粮数
    local needPartnerCount = 0
    for _, item in ipairs(self._NeedList) do
        if item.Id == XPartnerEnum.XPartnerQualityClip then
            if self._IsTailFeed then
                item.Count = mainControl:GetCommitControl():GetSelectFoodCount()
            end
            needPartnerCount = item.Count
            break
        end
    end

    if needPartnerCount <= 0 then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    -- 从池中收集狗粮
    local selectFoodDic = mainControl:GetCommitControl():GetSelectFoodDic()
    local foodList = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(partnerId)

    local costPartnerIds = {}
    local collected = 0
    for _, entity in ipairs(foodList) do
        if collected >= needPartnerCount then break end
        if selectFoodDic[entity:GetId()] then
            table.insert(costPartnerIds, entity:GetId())
            collected = collected + 1
        end
    end

    if #costPartnerIds == 0 then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    self._CostPartnerIds = costPartnerIds
    self._NetControl:SendStarActivateRequest(partnerId, costPartnerIds)
end

function XFlowTreeActionPartnerOneKeyStarFeed:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeyStarFeed:OnDestroy()
    self.Super.OnDestroy(self)
    self._NeedList = nil
    self._IsTailFeed = nil
    self._CostPartnerIds = nil
    self._NetControl = nil
    self._OneKeyCultureMainControl = nil
    self._Control = nil
    self._ProgressPopup = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeyStarFeed:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_STAR_ACTIVATE, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_STAR_ACTIVATE, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeyStarFeed:_OnReply(isSuccess)
    if not isSuccess then
        self:_OnFailLog()
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    -- 清理已消耗的狗粮
    if self._CostPartnerIds then
        self._OneKeyCultureMainControl:GetCommitControl():RemoveSelectFood(self._CostPartnerIds)
        self._CostPartnerIds = nil
    end
    self._ProgressPopup:SetHasCultureSuccess(true)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyStarFeed:_OnFailLog()
    local sb = {}
    table.insert(sb, "[StarFeed] 失败!")
    table.insert(sb, "所需材料:")
    for _, item in ipairs(self._NeedList) do
        if item.Id == XMVCA.XPartner.Enum.XPartnerQualityClip then
            local have = self._OneKeyCultureMainControl:GetCommitControl():GetSelectFoodCount()
            table.insert(sb, string.format("  Id=%d(狗粮) need=%d have=%d", item.Id, item.Count, have))
        else
            local have = XDataCenter.ItemManager.GetCount(item.Id)
            table.insert(sb, string.format("  Id=%d need=%d have=%d", item.Id, item.Count, have))
        end
    end
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeyStarFeed
