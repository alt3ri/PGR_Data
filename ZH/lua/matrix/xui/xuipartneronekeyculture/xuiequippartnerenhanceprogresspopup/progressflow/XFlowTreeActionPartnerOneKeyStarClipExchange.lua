---@class XFlowTreeActionPartnerOneKeyStarClipExchange : XFlowTreeAction 碎片兑换节点：逐个合成选中碎片后标记新辅助机 Id 到 commit 模型
---@field private _Control XPartnerControl
---@field private _NetControl XPartnerNetWorkControl
---@field private _OneKeyCultureMainControl XPartnerOneKeyCultureControl
---@field private _ClipCount number 选中的碎片数量
---@field private _ComposedCount number 已合成数量
---@field private _TemplateId number 辅助机模板Id
---@field private _OldIdSet table<number, boolean> 兑换前快照
local XFlowTreeActionPartnerOneKeyStarClipExchange = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyStarClipExchange")

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyStarClipExchange:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._NetControl = control:GetNetWorkControl()
    self._OneKeyCultureMainControl = mainControl

    self:_SetEvent(true)

    local commitControl = mainControl:GetCommitControl()
    self._ClipCount = commitControl:GetSelectClipCount() + commitControl:GetSelectOreExchangeClipCount()

    -- 无选中碎片，直接完成
    if self._ClipCount <= 0 then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    local partner = mainControl:GetCurPartnerEntity()
    if not partner then
        XLog.Error("[StarClipExchange] 失败! 当前辅助机实体为空")
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end
    self._TemplateId = partner:GetTemplateId()

    -- 快照当前所有辅助机 Id
    self._OldIdSet = {}
    local allIds = XDataCenter.PartnerManager.GetAllPartnerIds()
    for _, id in ipairs(allIds) do
        self._OldIdSet[id] = true
    end

    self._ComposedCount = 0
    -- 逐个合成（服务器不支持重复 templateId 批量请求）
    self:SendNextCompose()
end

function XFlowTreeActionPartnerOneKeyStarClipExchange:SendNextCompose()
    self._NetControl:SendChipExchangeRequest({ self._TemplateId })
end

function XFlowTreeActionPartnerOneKeyStarClipExchange:OnExit(isInterrupt)
    self:_SetEvent(false)
end

function XFlowTreeActionPartnerOneKeyStarClipExchange:OnDestroy()
    self.Super.OnDestroy(self)
    self._OldIdSet = nil
    self._NetControl = nil
    self._OneKeyCultureMainControl = nil
    self._Control = nil
end

--region 事件

function XFlowTreeActionPartnerOneKeyStarClipExchange:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_CHIP_EXCHANGE, self._OnReply, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_REPLY_PARTNER_CHIP_EXCHANGE, self._OnReply, self)
    end
end

function XFlowTreeActionPartnerOneKeyStarClipExchange:_OnReply(isSuccess)
    if not isSuccess then
        self:_OnFailLog()
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end

    self._ComposedCount = self._ComposedCount + 1
    if self._ComposedCount < self._ClipCount then
        -- 继续合成下一个
        self:SendNextCompose()
        return
    end

    -- 全部合成完成，清理碎片选中索引
    self._OneKeyCultureMainControl:GetCommitControl():ClearSelectClip()

    -- diff 出新辅助机 Id
    local newIds = {}
    local allIds = XDataCenter.PartnerManager.GetAllPartnerIds()
    for _, id in ipairs(allIds) do
        if not self._OldIdSet[id] then
            table.insert(newIds, id)
        end
    end

    -- 标记到 commit 控制器，后续喂养节点会从 selectFoodDic 中取到
    if #newIds > 0 then
        self._OneKeyCultureMainControl:GetCommitControl():AddExchangedFoodIds(newIds)
    end

    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyStarClipExchange:_OnFailLog()
    local sb = {}
    table.insert(sb, string.format("[StarClipExchange] 失败! clipCount=%d composedCount=%d", self._ClipCount or 0, self._ComposedCount or 0))
    XLog.Error(table.concat(sb, "\n"))
end

--endregion

return XFlowTreeActionPartnerOneKeyStarClipExchange
