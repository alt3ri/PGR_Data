--- 副卡详情内容子面板（普通 XUiNode，由 TipsRoot 气泡壳加载并定位；不继承 bubble、不带 BtnClose）。
--- 镜像 XUiPunishaarMainCardTips 模式，但伤害/CD 在顶层（TxtDamage/TxtCD），内容子面板只显 Icon/星级/名称；
--- 副卡有 6 种操作模式（Buy/Discard/BuyReplace/BuyPlace/Place/KeepPlace），语义/上游协议多处 TODO。
local XUiPanelPunishaarSubCard = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarSubCardTips/XUiPanelPunishaarSubCard")
local XUiPanelPunishaarSubCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarSubCardTips/XUiPanelPunishaarSubCardTag")

---@class XUiPunishaarSubCardTips: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelTop @副卡内容根节点（承载 XUiPanelPunishaarSubCard：ImgHead/GroupStar/TxtCardName 等）
---@field TxtDamage UnityEngine.UI.Text 伤害/攻击力数值（对应 PunishaarCardLevel.ATK）
---@field TxtCD UnityEngine.UI.Text CD 数值（对应 PunishaarCardLevel.CD）
---@field TxtCardSkillInfo UnityEngine.UI.Text 副卡描述文本（对应 PunishaarCard.Desc，对齐主卡 TxtDesc）
---@field PanelBuy @购买操作区根节点（内含 BtnBuy）
---@field PanelDiscard @丢弃操作区根节点（内含 BtnDiscard）
---@field PanelBuyReplace @购买替换操作区根节点（内含 BtnBuyReplace）
---@field PanelBuyPlace @购买放置操作区根节点（内含 BtnBuyPlace）
---@field PanelPlace @放置操作区根节点（内含 BtnPlace）
---@field PanelKeepPlace @保留位置操作区根节点（内含 BtnKeepPlace）
---@field PanelCardTag @卡牌类型/尺寸标签根节点（容器，直接挂 XUiPanelPunishaarSubCardTag；IconTag/TxtType/TxtSlotSize 为其子节点）
---@field CardTag @兼容保留（旧字段，不再用于创建 CardTagPanel #44）
---@field BtnLock XUiComponent.XUiButton 冻结/解冻按钮（商品冻结态切换；装备态无 frozen 不显示）
---@field BtnBuy XUiComponent.XUiButton 购买按钮
---@field BtnDiscard XUiComponent.XUiButton 丢弃按钮
---@field BtnBuyReplace XUiComponent.XUiButton 购买替换按钮
---@field BtnBuyPlace XUiComponent.XUiButton 购买放置按钮
---@field BtnPlace XUiComponent.XUiButton 放置按钮
---@field BtnKeepPlace XUiComponent.XUiButton 保留位置按钮
local XUiPunishaarSubCardTips = XClass(XUiNode, "XUiPunishaarSubCardTips")

--- 详情数据来源（detail.source）
local TipsSource = {
    Goods = 1, -- 商店待售副卡商品
    Equipped = 2, -- 已装备副卡（经主卡副卡槽点击进入）
}

--- 互斥操作按钮组模式（6 种副卡操作 + None）
local OperationMode = {
    None = 0,
    Buy = 1,
    Discard = 2,
    BuyReplace = 3,
    BuyPlace = 4,
    Place = 5,
    KeepPlace = 6,
}

function XUiPunishaarSubCardTips:OnStart()
    if self.PanelTop then
        self.SubCardPanel = XUiPanelPunishaarSubCard.New(self.PanelTop, self)
        self.SubCardPanel:Open()
    else
        XLog.Warning("[Punishaar] XUiPunishaarSubCardTips: PanelTop 节点缺失，副卡内容无法显示")
    end

    if self.PanelCardTag then
        self.CardTagPanel = XUiPanelPunishaarSubCardTag.New(self.PanelCardTag, self)
        self.CardTagPanel:Open()
    end

    if self.BtnLock then
        self.BtnLock:AddEventListener(handler(self, self._OnBtnLock))
    end
    if self.BtnBuy then
        self.BtnBuy:AddEventListener(handler(self, self._OnBtnBuy))
    end
    if self.BtnDiscard then
        self.BtnDiscard:AddEventListener(handler(self, self._OnBtnDiscard))
    end
    if self.BtnBuyReplace then
        self.BtnBuyReplace:AddEventListener(handler(self, self._OnBtnBuyReplace))
    end
    if self.BtnBuyPlace then
        self.BtnBuyPlace:AddEventListener(handler(self, self._OnBtnBuyPlace))
    end
    if self.BtnPlace then
        self.BtnPlace:AddEventListener(handler(self, self._OnBtnPlace))
    end
    if self.BtnKeepPlace then
        self.BtnKeepPlace:AddEventListener(handler(self, self._OnBtnKeepPlace))
    end

    self._IsLocked = false
    self._IsOperating = false
    self:SetOperationMode(OperationMode.None)
end

--- 刷新副卡详情。
---@param detail table|nil 详情契约：{ source=TipsSource, cardId, goodsIndex?(source=1), isBought?(source=1), frozen?(source=1), masterCard?(宿主主卡), operationMode?(覆盖) }
function XUiPunishaarSubCardTips:Refresh(detail)
    self._Detail = detail
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end

    local cardCfg = self._Control:GetTablePunishaarCard(detail.cardId)

    if self.SubCardPanel then
        self.SubCardPanel:Refresh(detail.cardId)
    end
    if self.CardTagPanel then
        self.CardTagPanel:Refresh(cardCfg)
    end

    -- 副卡不显示 ATK/CD（已约定不再读取 level 表 #43）
    -- 描述文本走 PunishaarCard.Desc（对齐主卡 TxtDesc），DescParams 占位符替换经 GetCardDesc 统一处理
    if self.TxtCardSkillInfo then
        self.TxtCardSkillInfo.text = self._Control:GetCardDesc(detail.cardId)
    end

    --[[
    原冻结状态读取（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    -- BtnLock 状态读服务端 frozen（商品冻结态；装备态无 frozen → 未冻结，不显按钮）
    self._IsLocked = detail.frozen == true
    --]]
    self:_RefreshLockBtn()  -- 冻结功能屏蔽：恒隐 BtnLock（#CEFreeze）
    self:SetOperationMode(self:_ResolveOperationMode(detail))

    -- 购买价显示走 SetNameByGroup(1, ...)（约定 group 1 = 价格文本）#69
    -- 副卡无 level（#44），CardSale key 中 Level 默认 1
    if detail.source == TipsSource.Goods and cardCfg then
        local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + 1
        local saleCfg = self._Control.GameControl:GetTablePunishaarCardSale(saleKey, true)
        local buyPrice = saleCfg and saleCfg.Buy or 0
        local gold = self._Control:GetCurrentGold() or 0
        local canAfford = gold >= buyPrice
        -- 各购买按钮（Buy/BuyReplace/BuyPlace）统一价格 + 金币先验 SetDisable（误购唯一防线 Q2）
        if self.BtnBuy then
            self.BtnBuy:SetNameByGroup(1, tostring(buyPrice))
            self.BtnBuy:SetDisable(not canAfford)
        end
        if self.BtnBuyReplace then
            self.BtnBuyReplace:SetNameByGroup(1, tostring(buyPrice))
            self.BtnBuyReplace:SetDisable(not canAfford)
        end
        if self.BtnBuyPlace then
            self.BtnBuyPlace:SetNameByGroup(1, tostring(buyPrice))
            self.BtnBuyPlace:SetDisable(not canAfford)
        end
    end
end

--- 由 detail 解析应显示的操作模式：detail.operationMode 优先；否则按 source 默认。
--- 兜底仅 Goods→Buy、Equipped→Discard；BuyReplace/BuyPlace 等靠 detail.operationMode 显式传入触发
---   （按钮+事件已接 _OnBtnBuyReplace/_OnBtnBuyPlace，本兜底不覆盖其余模式，由上游 operationMode 决定）。
---@param detail table
---@return number
function XUiPunishaarSubCardTips:_ResolveOperationMode(detail)
    if not detail then
        return OperationMode.None
    end
    -- 战前准备阶段不允许丢弃（PreFight 无商品，Buy 不会显；仅压 Discard）
    local fightState = self._Control.GameControl
            and self._Control.GameControl.RunControl
            and self._Control.GameControl.RunControl:GetCurrentFightState()
    if fightState == XMVCA.XPunishaar.EnumConst.FightState.PreFight then
        return OperationMode.None
    end
    if detail.operationMode then
        return detail.operationMode
    end
    if detail.source == TipsSource.Goods then
        return detail.isBought and OperationMode.None or OperationMode.Buy
    elseif detail.source == TipsSource.Equipped then
        -- 装备态副卡：显示 Discard 按钮（丢弃副卡，IsMasterCard=false #45）
        return OperationMode.Discard
    end
    return OperationMode.None
end

--- 切换互斥操作按钮组：仅匹配 mode 的那个 Panel 显示。
---@param mode number
function XUiPunishaarSubCardTips:SetOperationMode(mode)
    self._OperationMode = mode
    if self.PanelBuy then
        self.PanelBuy.gameObject:SetActiveEx(mode == OperationMode.Buy)
    end
    if self.PanelDiscard then
        self.PanelDiscard.gameObject:SetActiveEx(mode == OperationMode.Discard)
    end
    if self.PanelBuyReplace then
        self.PanelBuyReplace.gameObject:SetActiveEx(mode == OperationMode.BuyReplace)
    end
    if self.PanelBuyPlace then
        self.PanelBuyPlace.gameObject:SetActiveEx(mode == OperationMode.BuyPlace)
    end
    if self.PanelPlace then
        self.PanelPlace.gameObject:SetActiveEx(mode == OperationMode.Place)
    end
    if self.PanelKeepPlace then
        self.PanelKeepPlace.gameObject:SetActiveEx(mode == OperationMode.KeepPlace)
    end
end

function XUiPunishaarSubCardTips:_OnBtnBuy()
    if self._IsOperating then
        return
    end
    local detail = self._Detail
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end
    -- 金币先验：不足弹 tips 不进入 PickingHost #46（副卡 Level 默认 1）
    local cardCfg = self._Control:GetTablePunishaarCard(detail.cardId)
    if cardCfg then
        local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + 1
        local saleCfg = self._Control.GameControl:GetTablePunishaarCardSale(saleKey, true)
        local price = saleCfg and saleCfg.Buy or 0
        local gold = self._Control:GetCurrentGold() or 0
        if gold < price then
            XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("PunishaarShopBuyGoldNotEnough"))
            return
        end
    end
    -- 进入副卡选宿主子流程（PickingHost）：收商店栏+锁背包+主卡 Disable+开承载弹窗(预留) #69
    -- 选宿主后由 BuyPlace/BuyReplace 走 BuyGoods(含宿主 MasterCardId)
    self._Control.GameControl:EnterPickHost(detail.goodsIndex, detail.cardId)
    if self.Parent then
        self.Parent:Hide()
    end  -- 关副卡详情气泡（PickingHost 期间经主卡详情重新展开 B2）
end

function XUiPunishaarSubCardTips:_OnBtnDiscard()
    if self._IsOperating then
        return
    end
    local detail = self._Detail
    local masterCard = detail and detail.masterCard
    if not masterCard then
        return
    end
    self._IsOperating = true
    -- 丢弃副卡：IsMasterCard=false，用宿主主卡 Id 定位其副卡（协议 XPunishaarDiscardCardRequest #45）
    self._Control.GameControl:DiscardCard(masterCard.Id, false, function(success)
        self._IsOperating = false
        if success then
            XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("DiscardSubCardSuccess"))
            if self.Parent then
                self.Parent:Hide()
            end
        end
    end)
end

function XUiPunishaarSubCardTips:_OnBtnBuyReplace()
    -- Q2 定案：覆盖不二次确认，直接购买（旧副卡按既有规则丢弃不返金币，与拖拽路径有意不同）
    if self._IsOperating then
        return
    end
    local masterCard = self._Detail and self._Detail.masterCard
    if not masterCard then
        return
    end
    self:_DoBuyGoodsWithHost(masterCard.Id)
end

function XUiPunishaarSubCardTips:_OnBtnBuyPlace()
    if self._IsOperating then
        return
    end
    local masterCard = self._Detail and self._Detail.masterCard
    if not masterCard then
        return
    end
    self:_DoBuyGoodsWithHost(masterCard.Id)
end

--- 购买副卡并装配到指定宿主主卡（BuyPlace/BuyReplace 共用入口）。#69
--- 走 BuyGoods(goodsIndex, cb, {MasterCardId})——副卡挂宿主模式（AreaType/StartPos 不传，服务端按 MasterCardId 装配）。
--- 金币先验由 BuyGoods 内统一处理（不足 cb(false)+TipMsg，误购唯一防线 Q2）；成功→ExitPickHost 收尾+关气泡，失败留 PickingHost。
---@param masterCardId number 宿主主卡唯一 Id
function XUiPunishaarSubCardTips:_DoBuyGoodsWithHost(masterCardId)
    local detail = self._Detail
    if not detail or not detail.goodsIndex then
        return
    end
    self._IsOperating = true
    self._Control.GameControl:BuyGoods(detail.goodsIndex, function(success)
        self._IsOperating = false
        if success then
            self._Control.GameControl:ExitPickHost()
            if self.Parent then
                self.Parent:Hide()
            end
        end
    end, { StartPos = 0, SubCardId = 0, MasterCardId = masterCardId })  -- 对齐拖拽副卡传参（副卡挂宿主模式）#69
end

function XUiPunishaarSubCardTips:_OnBtnPlace()
    -- TODO: 放置（不购买）到宿主——上游协议未支持
    if self._IsOperating then
        return
    end
end

--- 设置"保留并放入"确认回调（自上而下注入，由使用 KeepPlace 模式的父面板提供，如副卡保留 UI）。
--- 未注入时 _OnBtnKeepPlace 为 no-op（上游协议未支持，待策划定）。
---@param cb function(cardId:number) 确认保留当前展示副卡的回调
function XUiPunishaarSubCardTips:SetKeepPlaceConfirm(cb)
    self._KeepPlaceCb = cb
end

function XUiPunishaarSubCardTips:_OnBtnKeepPlace()
    -- 保留并放入：KeepPlace 模式下调用注入的确认回调（cardId=当前展示副卡）。
    -- 无注入回调时 no-op（上游协议未支持，待策划定）。
    if self._IsOperating then
        return
    end
    if self._KeepPlaceCb then
        local cardId = self._Detail and self._Detail.cardId
        if cardId and cardId ~= 0 then
            self._KeepPlaceCb(cardId)
        end
    end
end

function XUiPunishaarSubCardTips:_OnBtnLock()
    -- 冻结功能屏蔽：入口 guard，不响应点击（即使 BtnLock 误显）#CEFreeze
    --[[
    原冻结切换逻辑（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    if self._IsOperating then return end
    local detail = self._Detail
    -- 仅商品态（source=Goods）支持冻结；装备态无 frozen/goodsIndex 不支持
    if not detail or detail.goodsIndex == nil or detail.source ~= TipsSource.Goods then
        return
    end
    self._IsOperating = true
    -- 切换冻结态：当前冻结→解冻，未冻结→冻结；成功后 Hide（商品列表经 BuySuccess 已刷新）
    self._Control.GameControl:FreezeGoods(detail.goodsIndex, not detail.frozen, function(success)
        self._IsOperating = false
        if success and self.Parent then self.Parent:Hide() end
    end)
    --]]
end

function XUiPunishaarSubCardTips:_RefreshLockBtn()
    if not self.BtnLock then
        return
    end
    -- 冻结功能屏蔽：BtnLock 恒隐（入口屏蔽），冻结态遮罩(PnlFrozen)保留 #CEFreeze
    self.BtnLock.gameObject:SetActiveEx(false)
    --[[
    原冻结按钮文本逻辑（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    -- 文本按冻结态切换：已冻结→"解冻"，未冻结→"冻结"
    local desc = XMVCA.XPunishaar:GetClientStringByKey("BtnFreezeNames", self._IsLocked and 2 or 1)
    self.BtnLock:SetNameByGroup(0, desc)
    --]]
end

function XUiPunishaarSubCardTips:OnDisable()
    -- 防操作锁残留：界面被覆盖中断期间网络回调未返回，复位操作锁
    self._IsOperating = false
end

function XUiPunishaarSubCardTips:OnDestroy()
    self._Detail = nil
    self._KeepPlaceCb = nil
end

-- 暴露枚举供外部复用本面板时指定模式/来源（如 UiPunishaarMainCardLevelupTip 副卡保留 UI 用 KeepPlace 模式）
XUiPunishaarSubCardTips.OperationMode = OperationMode
XUiPunishaarSubCardTips.TipsSource = TipsSource

return XUiPunishaarSubCardTips
