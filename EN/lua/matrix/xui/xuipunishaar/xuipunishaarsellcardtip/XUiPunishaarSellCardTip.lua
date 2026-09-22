local XUiGridShopSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopSubCard")
local XUiPunishaarSellCardTipCardTipsPanelRoot = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipCardTipsPanelRoot")
local XUiPunishaarSellCardTipGridCard = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipGridCard")
local XUiPunishaarSellCardTipComBottomBag = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipComBottomBag")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarSellCardTip : XLuaUi
---@field CardTipsPanelRoot UnityEngine.RectTransform
---@field BtnSkipReward XUiComponent.XUiButton
---@field BtnCacel XUiComponent.XUiButton 取消选择按钮（购买副卡模式显，退出 PickingHost+关弹窗）#69
---@field TxtTips UnityEngine.UI.Text
---@field UiPunishaarSubCard UnityEngine.RectTransform
---@field UiPunishaarGridCard UnityEngine.RectTransform
---@field ComBottomBag UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
local XUiPunishaarSellCardTip = XLuaUiManager.Register(XLuaUi, "UiPunishaarSellCardTip")

function XUiPunishaarSellCardTip:OnAwake()
    self:InitChildUis()
end

function XUiPunishaarSellCardTip:InitChildUis()
    ---@type XUiPunishaarSellCardTipCardTipsPanelRoot
    self._CardTipsPanelRoot = XUiPunishaarSellCardTipCardTipsPanelRoot.New(self.CardTipsPanelRoot, self)
    self._CardTipsPanelRoot:Open()
    -- BtnClose 叠加 Hide 同关 main+sub（父类 _OnBtnClose 两段式先关 sub，本监听补 Hide 同关）#69
    if self._CardTipsPanelRoot.BtnClose then
        self._CardTipsPanelRoot.BtnClose:AddEventListener(handler(self._CardTipsPanelRoot, self._CardTipsPanelRoot.Hide))
    end
    ---@type XUiPunishaarSellCardTipGridCard
    self._UiPunishaarGridCard = XUiPunishaarSellCardTipGridCard.New(self.UiPunishaarGridCard, self)
    ---@type XUiPunishaarSellCardTipComBottomBag
    self._ComBottomBag = XUiPunishaarSellCardTipComBottomBag.New(self.ComBottomBag, self)
    self._ComBottomBag:Open()
    ---@type XUiGridShopSubCard
    self._UiPunishaarSubCard = XUiGridShopSubCard.New(self.UiPunishaarSubCard, self)
    if self.BtnSkipReward then
        self.BtnSkipReward:AddEventListener(handler(self, self.OnBtnSkipRewardClick))
    end
    -- BtnCacel：取消选择，退出 PickingHost + 关弹窗（ExitPickHost 内已 Close 弹窗）#69
    if self.BtnCacel then
        self.BtnCacel:AddEventListener(handler(self, self.OnBtnCancelClick))
    end
    -- B1：点待购入副卡图标→sub 展开（mode=None 纯查看）#69
    if self._UiPunishaarSubCard and self._UiPunishaarSubCard.BtnClick then
        self._UiPunishaarSubCard.BtnClick:AddEventListener(handler(self, self._OnSubCardClick))
    end
end

function XUiPunishaarSellCardTip:OnBtnSkipRewardClick()
    -- 放弃暂存卡：gc 走 HandlePendingReward(false)→_FinishRewardPlacement（关本弹窗+ExitNode）
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:AbandonPendingReward()
    end
end

--- MasterCardChange 回调（RewardFull 模式）：卖/弃后 UpdateMasterCardByNotify 已更新 Model。
--- 刷背包视图（显腾位后状态）+ 触发 gc:TryAutoPlacePendingReward 自动找位放置（空槽充足即入背包）。
function XUiPunishaarSellCardTip:_OnMasterCardChange()
    if self._ComBottomBag then
        self._ComBottomBag:Refresh()
    end
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:TryAutoPlacePendingReward()
    end
end

--- 取消选择：退出 PickingHost（清 ctx + PickHostChange(false) + Close 弹窗 + FightMain 还原）#69
function XUiPunishaarSellCardTip:OnBtnCancelClick()
    local gc = self._Control and self._Control.GameControl
    if gc and gc:IsPickingHost() then
        gc:ExitPickHost()  -- 内部 XLuaUiManager.Close("UiPunishaarSellCardTip") 关弹窗
    end
end

--- 转发 _CardTipsPanelRoot:ShowMainCard（供弹窗内 grid _OnCardClick _GetTipsHost 找到弹窗作 host）#69
--- PickingHost 期间 B2：main+sub 同时展开，sub=待购入副卡 + BuyPlace/BuyReplace mode
function XUiPunishaarSellCardTip:ShowMainCardTips(data, posUi)
    if not self._CardTipsPanelRoot then
        return
    end
    local gc = self._Control and self._Control.GameControl
    local isPickingHost = gc and gc:IsPickingHost()
    -- PickingHost 期间置灰主卡（不能装配）不展开 B2（禁止点击响应）#69
    if isPickingHost and data and data.TemplateId ~= nil then
        if not gc:CanMountSubCardOnMaster(gc:GetPickingSubCardId(), data) then
            return
        end
    end
    -- PickingHost 期间主卡只读：不显出售/丢弃按钮（装配场景非卖卡）#bug3
    self._CardTipsPanelRoot:ShowMainCard(data, posUi, isPickingHost)
    if isPickingHost and data and data.TemplateId ~= nil then
        local hasSub = data.SubCardId and data.SubCardId ~= 0
        local mode = hasSub and 3 or 4  -- BuyReplace=3 / BuyPlace=4，对应 XUiPunishaarSubCardTips.OperationMode
        self._CardTipsPanelRoot:ShowSubCardNested({
            CardId = gc:GetPickingSubCardId(),
            GoodsIndex = gc:GetPickingGoodsIndex(),
            operationMode = mode,
            masterCard = data,
        }, posUi)
    end
end

--- 转发 _CardTipsPanelRoot:ShowSubCard（商品态副卡入口，供 grid _OnCardClick :219 调）#69
function XUiPunishaarSellCardTip:ShowSubCardTips(data, posUi)
    if self._CardTipsPanelRoot then
        self._CardTipsPanelRoot:ShowSubCard(data, posUi)
    end
end

--- B1：点 UiPunishaarSubCard（待购入副卡图标）→ sub 展开 mode=None（纯查看，无购买按钮）#69
function XUiPunishaarSellCardTip:_OnSubCardClick()
    if not self._CardTipsPanelRoot then
        return
    end
    local gc = self._Control and self._Control.GameControl
    if not gc or not gc:IsPickingHost() then
        return
    end
    self._CardTipsPanelRoot:ShowSubCardNested({
        CardId = gc:GetPickingSubCardId(),
        GoodsIndex = gc:GetPickingGoodsIndex(),
        operationMode = 0, -- OperationMode.None
    })
    -- B1 单独 sub（无 main）：ShowSubCardNested 不显 BtnClose（设计是 main 内 sub），需手动显供关闭
    if self._CardTipsPanelRoot.BtnClose then
        self._CardTipsPanelRoot.BtnClose.gameObject:SetActiveEx(true)
    end
end

--- @param data table { mode="PickHost"|"RewardFull", subCardId?(PickHost), cardId?(RewardFull) }

function XUiPunishaarSellCardTip:OnStart(data)
    self:Refresh(data)
    -- RewardFull：订阅 MasterCardChange，卖/弃腾位后刷背包 + 触发 gc 自动找位放置
    if data and data.mode == "RewardFull" then
        XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnMasterCardChange, self)
        -- 开启即重检一次：重连/重进场景下背包可能本就有空位（非双区满），直接自动放入（空槽充足自动入背包），
        -- 避免玩家卡在无放置动作的界面。双区满则 _FindPlacementForDirectBuy 返 nil 不动作，留玩家卖/弃腾位。
        -- _EnterManualPlacement 已先置 gc 流程态；HandlePendingReward 异步，Close 在响应 cb（非 mid-OnStart）。
        local gc = self._Control and self._Control.GameControl
        if gc then
            gc:TryAutoPlacePendingReward()
        end
    end
end

--- 按 mode 切场景显隐 + TxtTips 走 ClientConfig（key 待填值，未填 IsNilOrEmpty 兜底空串）#69
--- ComBottomBag/CardTipsPanelRoot 常驻（InitChildUis Open），Refresh 只切 UiPunishaarSubCard/UiPunishaarGridCard/BtnSkipReward
function XUiPunishaarSellCardTip:Refresh(data)
    self._Mode = data and data.mode
    if self._Mode == "PickHost" then
        -- 选宿主：显待购入副卡 + TxtTips；隐奖励主卡 grid/BtnSkipReward
        if self._UiPunishaarSubCard then
            self._UiPunishaarSubCard:Open()
            self._UiPunishaarSubCard:Refresh(data.subCardId)
        end
        if self._UiPunishaarGridCard then
            self._UiPunishaarGridCard:Close()
        end
        if self.BtnSkipReward then
            self.BtnSkipReward.gameObject:SetActiveEx(false)
        end
        if self.BtnCacel then
            self.BtnCacel.gameObject:SetActiveEx(true)
        end
        if self.TxtTips then
            self.TxtTips.text = XMVCA.XPunishaar:GetClientStringByKey("SellCardTipPickHostTips") or ""
        end
    elseif self._Mode == "RewardFull" then
        -- 奖励位置不足：显奖励主卡 grid（UiPunishaarGridCard，替代旧 CardHead）+ TxtTips+BtnSkipReward；隐副卡
        if self._UiPunishaarSubCard then
            self._UiPunishaarSubCard:Close()
        end
        if self._UiPunishaarGridCard then
            self._UiPunishaarGridCard:Open()
            local cardId = data.cardId
            local cardCfg = self._Control:GetTablePunishaarCard(cardId, true)
            local size = cardCfg and cardCfg.Size or 1
            self._UiPunishaarGridCard:RefreshAsEquipped({ TemplateId = cardId, Level = data.level or 1 }, size)
        end
        if self.BtnSkipReward then
            self.BtnSkipReward.gameObject:SetActiveEx(true)
        end
        if self.BtnCacel then
            self.BtnCacel.gameObject:SetActiveEx(false)
        end
        if self.TxtTips then
            self.TxtTips.text = XMVCA.XPunishaar:GetClientStringByKey("SellCardTipRewardFullTips") or ""
        end
    end
    -- 两场景都需 ComBottomBag 显两区卡牌（选宿主选主卡 / 奖励整理背包）+ 锁收起防误关 #69
    if self._ComBottomBag then
        self._ComBottomBag:Refresh()
        self._ComBottomBag:OpenBagWithLock()
        -- PickingHost 期间弹窗内主卡置灰（不能装配副卡的 Disable 遮罩）#69
        local gc = self._Control and self._Control.GameControl
        if gc and gc:IsPickingHost() then
            self._ComBottomBag:RefreshHostHintDisable(gc:GetPickingSubCardId())
        end
    end
end

function XUiPunishaarSellCardTip:OnEnable()
end

function XUiPunishaarSellCardTip:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnMasterCardChange, self)
    -- 不在异常关闭（断网重连/闪退/Esc）时默认放弃：玩家未主动点 BtnSkipReward 前，暂存卡应保留，
    -- 由重连路径（AutoPassthroughEvent RewardReplace→_EnterManualPlacement）重开 SellCardTip 让玩家决断。
    -- 仅 BtnSkipReward（放弃）/自动放置走 HandlePendingReward(false/true)→_FinishRewardPlacement 显式收尾。
end

function XUiPunishaarSellCardTip:OnDestroy()
end

return XUiPunishaarSellCardTip

-- ======== UI INFO BEGIN ========
--[[
# UiPunishaarSellCardTip UI 信息
- GameObject: `UiPunishaarSellCardTip`
- Hierarchy 路径: `UiPunishaarSellCardTip`
- 基类: XLuaUi

## 节点树（被 UiObject 引用的物体会标注变量名）
```
UiPunishaarSellCardTip
└─ Animation
  └─ AnimEnable
└─ FullScreenBackground
  └─ ImgBlur
    └─ Animation
      └─ Enable
└─ SafeAreaContentPane
  └─ PanelTip
    └─ ImgBg
    └─ ImgBg1
    └─ TxtTips (被UiObject引用: TxtTips)
    └─ UiPunishaarSubCard
      └─ PanelCollectionLock
        └─ ImgBg
        └─ ImgNone
      └─ PanelNone
        └─ ImgSubCardNoneBgPats
        └─ ImgSubCardNoneBgRole
      └─ PanelSubCard
        └─ GridSubCardRole
          └─ IconSubCardRole
        └─ GridSubCardPats
          └─ IconSubCardPats
      └─ PnlFrozen
        └─ ImgFrozenRole
        └─ ImgFrozenPets
      └─ SelectEffect
        └─ RImgSubCardRoleSel
        └─ RImgSubCardPatsSel
      └─ TagCheck
        └─ Bg
        └─ IconCheck
      └─ BtnClick
    └─ UiPunishaarGridCard
      └─ PanelNormal
        └─ RImgQualityBg
          └─ RImgKuang
        └─ PnlCardHead
          └─ UiPunishaarCardHeadPets
            └─ GridHeadMask
              └─ ImgHead
            └─ ImgFrozen
            └─ TagCheck
              └─ Bg
              └─ IconCheck
          └─ UiPunishaarCardHeadRole
            └─ ImgHead
            └─ ImgFrozen
            └─ TagCheck
              └─ Bg
              └─ IconCheck
        └─ PnlCard
          └─ RImgFrontBg
        └─ ImgBallLine
        └─ TagDamage
          └─ ImgBg
          └─ TxtDamage
          └─ TxtDamageUp
        └─ TagCD
          └─ ImgBg
          └─ TxtCD
          └─ TxtCDUp
        └─ TagLevelup
          └─ ImgBg
        └─ TagNew
          └─ Image
          └─ TxtNew
        └─ ImgArrow
        └─ GroupSubCardList
          └─ UiPunishaarSubCard
            └─ PanelCollectionLock
              └─ ImgBg
              └─ ImgNone
            └─ PanelNone
              └─ ImgSubCardNoneBgPats
              └─ ImgSubCardNoneBgRole
            └─ PanelSubCard
              └─ GridSubCardRole
                └─ IconSubCardRole
              └─ GridSubCardPats
                └─ IconSubCardPats
            └─ PnlFrozen
              └─ ImgFrozenRole
              └─ ImgFrozenPets
            └─ SelectEffect
              └─ RImgSubCardRoleSel
              └─ RImgSubCardPatsSel
            └─ TagCheck
              └─ Bg
              └─ IconCheck
            └─ BtnClick
        └─ PnlDisable
          └─ RImgDisable
        └─ GroupBall
          └─ ImgBallInBg
          └─ ImgBallOutBg
          └─ ImgBall
        └─ GroupLevelup
          └─ TxtLevelup
      └─ PanelLock
        └─ ImgNoneBg
        └─ ImgLock
      └─ PanelShopSubCard
        └─ ImgNoneBgPets
        └─ ImgNoneBgRole
        └─ UiPunishaarSubCard
          └─ PanelCollectionLock
            └─ ImgBg
            └─ ImgNone
          └─ PanelNone
            └─ ImgSubCardNoneBgPats
            └─ ImgSubCardNoneBgRole
          └─ PanelSubCard
            └─ GridSubCardRole
              └─ IconSubCardRole
            └─ GridSubCardPats
              └─ IconSubCardPats
          └─ PnlFrozen
            └─ ImgFrozenRole
            └─ ImgFrozenPets
          └─ SelectEffect
            └─ RImgSubCardRoleSel
            └─ RImgSubCardPatsSel
          └─ TagCheck
            └─ Bg
            └─ IconCheck
          └─ BtnClick
      └─ PanelBuy
        └─ ImgBg
        └─ IconCoin
        └─ TxtPrice
      └─ Effect
        └─ EffectSelect
        └─ EffectLevelup
      └─ BtnClick
      └─ DetailRoot
  └─ ComBottomBag
    └─ RImgBg
    └─ BtnBag
      └─ Normal 
        └─ RImgBg
        └─ TxtBag
        └─ TxtNum
        └─ TagLevelup
          └─ ImgBg
        └─ GroupLevelup
          └─ TxtLevelup
      └─ Select
        └─ RImgBg
        └─ TxtBag
        └─ TxtNum
      └─ Disable
        └─ RImgBg
        └─ TxtBag
        └─ TxtNum
      └─ Effect
        └─ EffectSelect
        └─ EffectLevelup
      └─ Red
        └─ Image2
        └─ Image1
        └─ Animation
          └─ AnimEnable
    └─ PanelBagSlotList
      └─ GridSlot
        └─ PanelNone
          └─ ImgNoneBg
        └─ PanelShopNone
          └─ ImgNoneBg
        └─ PanelLock
          └─ ImgNoneBg
          └─ ImgLock
    └─ PanelBagList
      └─ GridCard
        └─ PanelNormal
          └─ RImgQualityBg
            └─ RImgKuang
          └─ PnlCardHead
            └─ UiPunishaarCardHeadPets
              └─ GridHeadMask
                └─ ImgHead
              └─ ImgFrozen
              └─ TagCheck
                └─ Bg
                └─ IconCheck
            └─ UiPunishaarCardHeadRole
              └─ ImgHead
              └─ ImgFrozen
              └─ TagCheck
                └─ Bg
                └─ IconCheck
          └─ PnlCard
            └─ RImgFrontBg
          └─ ImgBallLine
          └─ TagDamage
            └─ ImgBg
            └─ TxtDamage
            └─ TxtDamageUp
          └─ TagCD
            └─ ImgBg
            └─ TxtCD
            └─ TxtCDUp
          └─ TagLevelup
            └─ ImgBg
          └─ TagNew
            └─ Image
            └─ TxtNew
          └─ ImgArrow
          └─ GroupSubCardList
            └─ UiPunishaarSubCard
              └─ PanelCollectionLock
                └─ ImgBg
                └─ ImgNone
              └─ PanelNone
                └─ ImgSubCardNoneBgPats
                └─ ImgSubCardNoneBgRole
              └─ PanelSubCard
                └─ GridSubCardRole
                  └─ IconSubCardRole
                └─ GridSubCardPats
                  └─ IconSubCardPats
              └─ PnlFrozen
                └─ ImgFrozenRole
                └─ ImgFrozenPets
              └─ SelectEffect
                └─ RImgSubCardRoleSel
                └─ RImgSubCardPatsSel
              └─ TagCheck
                └─ Bg
                └─ IconCheck
              └─ BtnClick
          └─ PnlDisable
            └─ RImgDisable
          └─ GroupBall
            └─ ImgBallInBg
            └─ ImgBallOutBg
            └─ ImgBall
          └─ GroupLevelup
            └─ TxtLevelup
        └─ PanelLock
          └─ ImgNoneBg
          └─ ImgLock
        └─ PanelShopSubCard
          └─ ImgNoneBgPets
          └─ ImgNoneBgRole
          └─ UiPunishaarSubCard
            └─ PanelCollectionLock
              └─ ImgBg
              └─ ImgNone
            └─ PanelNone
              └─ ImgSubCardNoneBgPats
              └─ ImgSubCardNoneBgRole
            └─ PanelSubCard
              └─ GridSubCardRole
                └─ IconSubCardRole
              └─ GridSubCardPats
                └─ IconSubCardPats
            └─ PnlFrozen
              └─ ImgFrozenRole
              └─ ImgFrozenPets
            └─ SelectEffect
              └─ RImgSubCardRoleSel
              └─ RImgSubCardPatsSel
            └─ TagCheck
              └─ Bg
              └─ IconCheck
            └─ BtnClick
        └─ PanelBuy
          └─ ImgBg
          └─ IconCoin
          └─ TxtPrice
        └─ Effect
          └─ EffectSelect
          └─ EffectLevelup
        └─ BtnClick
        └─ DetailRoot
    └─ PanelBagLayout
      └─ PanelDragBuyTips
        └─ ImgNormal
        └─ ImgDisable
        └─ TxtDragBuyTips
        └─ TxtDragBuyPriceTips
        └─ TxtDragCancelBuyTips
        └─ TxtCardNoneSlot
        └─ TxtSubCardNoneSlot
      └─ PanelExpandBag
        └─ RImgBagBg
        └─ PanelBagSlotList
          └─ GridSlot
            └─ PanelNone
              └─ ImgNoneBg
            └─ PanelShopNone
              └─ ImgNoneBg
            └─ PanelLock
              └─ ImgNoneBg
              └─ ImgLock
        └─ PanelExpandBagList
          └─ GridCard
            └─ PanelNormal
              └─ RImgQualityBg
                └─ RImgKuang
              └─ PnlCardHead
                └─ UiPunishaarCardHeadPets
                  └─ GridHeadMask
                    └─ ImgHead
                  └─ ImgFrozen
                  └─ TagCheck
                    └─ Bg
                    └─ IconCheck
                └─ UiPunishaarCardHeadRole
                  └─ ImgHead
                  └─ ImgFrozen
                  └─ TagCheck
                    └─ Bg
                    └─ IconCheck
              └─ PnlCard
                └─ RImgFrontBg
              └─ ImgBallLine
              └─ TagDamage
                └─ ImgBg
                └─ TxtDamage
                └─ TxtDamageUp
              └─ TagCD
                └─ ImgBg
                └─ TxtCD
                └─ TxtCDUp
              └─ TagLevelup
                └─ ImgBg
              └─ TagNew
                └─ Image
                └─ TxtNew
              └─ ImgArrow
              └─ GroupSubCardList
                └─ UiPunishaarSubCard
                  └─ PanelCollectionLock
                    └─ ImgBg
                    └─ ImgNone
                  └─ PanelNone
                    └─ ImgSubCardNoneBgPats
                    └─ ImgSubCardNoneBgRole
                  └─ PanelSubCard
                    └─ GridSubCardRole
                      └─ IconSubCardRole
                    └─ GridSubCardPats
                      └─ IconSubCardPats
                  └─ PnlFrozen
                    └─ ImgFrozenRole
                    └─ ImgFrozenPets
                  └─ SelectEffect
                    └─ RImgSubCardRoleSel
                    └─ RImgSubCardPatsSel
                  └─ TagCheck
                    └─ Bg
                    └─ IconCheck
                  └─ BtnClick
              └─ PnlDisable
                └─ RImgDisable
              └─ GroupBall
                └─ ImgBallInBg
                └─ ImgBallOutBg
                └─ ImgBall
              └─ GroupLevelup
                └─ TxtLevelup
            └─ PanelLock
              └─ ImgNoneBg
              └─ ImgLock
            └─ PanelShopSubCard
              └─ ImgNoneBgPets
              └─ ImgNoneBgRole
              └─ UiPunishaarSubCard
                └─ PanelCollectionLock
                  └─ ImgBg
                  └─ ImgNone
                └─ PanelNone
                  └─ ImgSubCardNoneBgPats
                  └─ ImgSubCardNoneBgRole
                └─ PanelSubCard
                  └─ GridSubCardRole
                    └─ IconSubCardRole
                  └─ GridSubCardPats
                    └─ IconSubCardPats
                └─ PnlFrozen
                  └─ ImgFrozenRole
                  └─ ImgFrozenPets
                └─ SelectEffect
                  └─ RImgSubCardRoleSel
                  └─ RImgSubCardPatsSel
                └─ TagCheck
                  └─ Bg
                  └─ IconCheck
                └─ BtnClick
            └─ PanelBuy
              └─ ImgBg
              └─ IconCoin
              └─ TxtPrice
            └─ Effect
              └─ EffectSelect
              └─ EffectLevelup
            └─ BtnClick
            └─ DetailRoot
    └─ PanelBuyEffect
      └─ ImgBg
      └─ ImgLight
    └─ BtnFight
      └─ Normal
        └─ ImgNormal02
        └─ ImgNormal03
        └─ ImgNormal04
        └─ ImgNormal01
        └─ Txt
      └─ Press
        └─ ImgNormal02
        └─ ImgNormal03
        └─ ImgNormal04
        └─ ImgNormal01
        └─ Txt
      └─ Select
      └─ Disable
        └─ ImgNormal02
        └─ ImgNormal03
        └─ ImgNormal04
        └─ ImgNormal01
        └─ Txt
      └─ Red
        └─ Red
          └─ Image2
          └─ Image1
          └─ Animation
            └─ AnimEnable
  └─ BtnSkipReward (被UiObject引用: BtnSkipReward)
    └─ Normal
      └─ ImgNormal
      └─ Txt
    └─ Press
      └─ ImgNormal
      └─ Txt
    └─ Select
    └─ Disable
    └─ Red
      └─ Red
        └─ Image2
        └─ Image1
        └─ Animation
          └─ AnimEnable
  └─ CardTipsPanelRoot
    └─ BtnClose
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `CardTipsPanelRoot` | RectTransform | `SafeAreaContentPane/CardTipsPanelRoot` |
| `BtnSkipReward` | XUiButton | `SafeAreaContentPane/BtnSkipReward` |
| `TxtTips` | Text | `SafeAreaContentPane/PanelTip/TxtTips` |
| `UiPunishaarSubCard` | RectTransform | `SafeAreaContentPane/PanelTip/UiPunishaarSubCard` |
| `UiPunishaarGridCard` | RectTransform | `SafeAreaContentPane/PanelTip/UiPunishaarGridCard` |
| `ComBottomBag` | RectTransform | `SafeAreaContentPane/ComBottomBag` |

## 子 UI 引用
| 变量名 | 目标 UI |
|---|---|
| `CardTipsPanelRoot` | `CardTipsPanelRoot` |
| `UiPunishaarSubCard` | `UiPunishaarSubCard` |
| `UiPunishaarGridCard` | `UiPunishaarGridCard` |
| `ComBottomBag` | `ComBottomBag` |
]]
-- ======== UI INFO END ========

