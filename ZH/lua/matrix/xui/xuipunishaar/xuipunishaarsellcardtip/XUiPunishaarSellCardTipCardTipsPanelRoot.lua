local XUiPanelPunishaarTipsRoot = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/XUiPanelPunishaarTipsRoot")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarSellCardTipCardTipsPanelRoot : XUiPanelPunishaarTipsRoot
---@field BtnClose XUiComponent.XUiButton
-- ======== AUTO FIELDS END ========
--- 弹窗内独立 TipsRoot：main+sub 总是同时展开/同时关闭（不分两段式 toggle）#69
--- - BtnClose 直接 Hide（main+sub 同关，不像 FightMain 先关 sub 再关 main）
--- - ShowSubCardNested 不 toggle（同 data Refresh 不关 sub；不同 data 调 super 展开）
local XUiPunishaarSellCardTipCardTipsPanelRoot = XClass(XUiPanelPunishaarTipsRoot, "XUiPunishaarSellCardTipCardTipsPanelRoot")

--- 覆写：BtnClose 同时关 main+sub（不分两段式）
function XUiPunishaarSellCardTipCardTipsPanelRoot:_OnBtnClose()
    self:Hide()
end

--- 覆写：ShowSubCardNested——同 data（已显当前副卡）时：PickingHost 期间恢复待购入副卡（B2），否则 Refresh 保留
function XUiPunishaarSellCardTipCardTipsPanelRoot:ShowSubCardNested(data, posUi)
    local detail = self:_NormalizeSubCardData(data)
    if not detail then return end
    if self._SubInst and self:_IsDetailEqual(self._SubData, detail) then
        -- PickingHost 期间 toggle 关已装备副卡 → 恢复待购入副卡（B2 态），不空关 #bug1
        local gc = self._Control and self._Control.GameControl
        if gc and gc:IsPickingHost() then
            self:_RestorePickingSub()
            return
        end
        if self._SubInst.Refresh then self._SubInst:Refresh(detail) end
        return
    end
    XUiPanelPunishaarTipsRoot.ShowSubCardNested(self, data, posUi)
end

--- PickingHost 期间 toggle 关已装备副卡后，恢复显示待购入副卡（B2 态）。#bug1
--- 构造待购入 subData（GetPickingSubCardId/GoodsIndex + BuyReplace/BuyPlace mode）调基类 ShowSubCardNested 切换。
function XUiPunishaarSellCardTipCardTipsPanelRoot:_RestorePickingSub()
    local gc = self._Control and self._Control.GameControl
    if not gc or not gc:IsPickingHost() then return end
    local mainDetail = self._CurData
    local masterCard = mainDetail and mainDetail.masterCard
    local hasSub = masterCard and masterCard.SubCardId and masterCard.SubCardId ~= 0
    local mode = hasSub and 3 or 4  -- BuyReplace=3 / BuyPlace=4，对齐 ShowMainCardTips B2 逻辑
    local pickingSubData = {
        CardId = gc:GetPickingSubCardId(),
        GoodsIndex = gc:GetPickingGoodsIndex(),
        operationMode = mode,
        masterCard = masterCard,
    }
    -- 调基类 ShowSubCardNested：pickingSubData vs 当前已装备 detail 不等（source/cardId 不同）→ 关旧+开新（待购入）
    XUiPanelPunishaarTipsRoot.ShowSubCardNested(self, pickingSubData, nil)
end

--- 覆写：不自动展开副卡（#69 PickingHost 有自己的 B1→B2 渐进流程，
--- 副卡=待购入 picking sub 而非主卡已装备 sub，由 ShowMainCardTips 内显式 ShowSubCardNested 展开，
--- base 自动展开会展开错误副卡+错误 mode，故禁用 4.8 自动展开）。
function XUiPunishaarSellCardTipCardTipsPanelRoot:_AutoExpandSub()
end

return XUiPunishaarSellCardTipCardTipsPanelRoot

-- ======== UI INFO BEGIN ========
--[[
# CardTipsPanelRoot UI 信息
- GameObject: `CardTipsPanelRoot`
- Hierarchy 路径: `SafeAreaContentPane/CardTipsPanelRoot`
- 基类: XUiNode

## 节点树（被 UiObject 引用的物体会标注变量名）
```
CardTipsPanelRoot
└─ BtnClose (被UiObject引用: BtnClose)
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `BtnClose` | XUiButton | `BtnClose` |
]]
-- ======== UI INFO END ========

