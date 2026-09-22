---@class XFlowTreeActionPartnerOneKeyStarOreExchange : XFlowTreeAction 矿石兑换碎片节点：按选中的矿石兑换格子数，去商店用矿石购买碎片，供后续碎片合成节点使用
---@field private _Control XPartnerControl
---@field private _OneKeyCultureMainControl XPartnerOneKeyCultureControl
---@field private _OreClipCount number 选中的矿石兑换格子数（折算为狗粮只数）
---@field private _ChipItemId number 碎片道具Id
---@field private _PreChipCount number 购买前碎片持有量快照
---@field private _BuyTimes number 商店购买次数
---@field private _IsStopped boolean 节点是否已退出（BuyShop 走回调而非事件，需要标记拦截晚到回调）
local XFlowTreeActionPartnerOneKeyStarOreExchange = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyStarOreExchange")

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyStarOreExchange:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._OneKeyCultureMainControl = mainControl
    self._IsStopped = false

    local commitControl = mainControl:GetCommitControl()
    self._OreClipCount = commitControl:GetSelectOreExchangeClipCount()
    local needChipCount = commitControl:GetSelectOreExchangeChipCount()

    -- 无选中矿石兑换格子，直接完成
    if self._OreClipCount <= 0 or needChipCount <= 0 then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    local partner = mainControl:GetCurPartnerEntity()
    if not partner then
        XLog.Error("[StarOreExchange] 失败! 当前辅助机实体为空")
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end

    local chipPerPartner = partner:GetChipNeedCount()
    if not chipPerPartner or chipPerPartner <= 0 then
        XLog.Error(string.format("[StarOreExchange] 失败! chipNeedCount 非法, chipNeedCount=%s", tostring(chipPerPartner)))
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end

    self._ChipItemId = partner:GetChipItemId()
    local buyTimes, exchangeChipCount = XMVCA.XPartner.Util.GetOreExchangeChipCostByCount(self._ChipItemId,
        needChipCount)
    local shopId, goodsId = XMVCA.XPartner.Util.GetChipOreExchangeRoute(self._ChipItemId)
    if not shopId or not goodsId or exchangeChipCount < needChipCount then
        XLog.Error(string.format(
            "[StarOreExchange] 失败! 无法满足碎片兑换需求, chipItemId=%s needChipCount=%s exchangeChipCount=%s",
            tostring(self._ChipItemId), tostring(needChipCount), tostring(exchangeChipCount)))
        self:OnDone(self.XFlowTreeEnum.Result.Fail)
        return
    end

    self._BuyTimes = buyTimes

    -- 快照购买前碎片持有量，购买完成后对比校验
    self._PreChipCount = XDataCenter.ItemManager.GetCount(self._ChipItemId)

    XShopManager.BuyShop(shopId, goodsId, self._BuyTimes, function()
        self:_OnBuyFinish()
    end, function(errorCode)
        self:_OnBuyFail(errorCode)
    end)
end

function XFlowTreeActionPartnerOneKeyStarOreExchange:OnExit(isInterrupt)
    self._IsStopped = true
end

function XFlowTreeActionPartnerOneKeyStarOreExchange:OnDestroy()
    self.Super.OnDestroy(self)
    self._IsStopped = true
    self._OneKeyCultureMainControl = nil
    self._Control = nil
end

--region 购买回调

function XFlowTreeActionPartnerOneKeyStarOreExchange:_OnBuyFinish()
    if self._IsStopped then
        return
    end
    self:_OnDoneLog()
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionPartnerOneKeyStarOreExchange:_OnBuyFail(errorCode)
    if self._IsStopped then
        return
    end
    XLog.Error(string.format("[StarOreExchange] 失败! 商店购买失败, errorCode=%s buyTimes=%d oreClipCount=%d",
        tostring(errorCode), self._BuyTimes or 0, self._OreClipCount or 0))
    self:OnDone(self.XFlowTreeEnum.Result.Fail)
end

--- 购买完成后打印对比校验 log：购买前后碎片持有量变化
function XFlowTreeActionPartnerOneKeyStarOreExchange:_OnDoneLog()
    local curChipCount = XDataCenter.ItemManager.GetCount(self._ChipItemId)
    XLog.Warning(string.format("[StarOreExchange] 矿石兑换碎片完成, buyTimes=%d oreClipCount=%d 碎片(兑换前=%d 兑换后=%d 实际增加=%d)",
        self._BuyTimes or 0, self._OreClipCount or 0, self._PreChipCount or 0, curChipCount, curChipCount - (self._PreChipCount or 0)))
end

--endregion

return XFlowTreeActionPartnerOneKeyStarOreExchange
