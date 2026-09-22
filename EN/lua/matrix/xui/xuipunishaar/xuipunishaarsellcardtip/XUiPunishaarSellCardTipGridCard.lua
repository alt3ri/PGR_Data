-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarSellCardTipGridCard : XUiGridShopCard
---@field BtnClick XUiComponent.XUiButton
---@field PanelNormal UnityEngine.RectTransform
---@field PanelLock UnityEngine.RectTransform
---@field PanelShopFreeze UnityEngine.RectTransform
---@field DetailRoot UnityEngine.RectTransform
---@field PanelShopSubCard UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
local XUiGridShopCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCard")

--- 弹窗内 ComBottomBag 主卡 grid：派生 XUiGridShopCard，复用 Refresh/RefreshAsEquipped/_OnCardClick（不重写）#69
local XUiPunishaarSellCardTipGridCard = XClass(XUiGridShopCard, "XUiPunishaarSellCardTipGridCard")

--- 覆写禁拖：PickingHost 装配界面不允许拖动主卡（仅点选宿主），不建 _DragHandler 拖拽不启用 #bug2
--- 落点 EnableAsDropZone 已由基类注释（栏级反算接管落点 #批次2；PickingHost 无拖拽源，OnEnter 不触发，无害）
function XUiPunishaarSellCardTipGridCard:EnableDrag(dragArea)
    -- no-op
end

return XUiPunishaarSellCardTipGridCard

-- ======== UI INFO BEGIN ========
--[[
# GridCard UI 信息
- GameObject: `GridCard`
- Hierarchy 路径: `SafeAreaContentPane/ComBottomBag/PanelBagList/GridCard`
- 基类: XUiNode

## 节点树（被 UiObject 引用的物体会标注变量名）
```
GridCard
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
      └─ BtnClick (被UiObject引用: BtnClick)
  └─ PnlDisable
    └─ RImgDisable
  └─ GroupBall
    └─ ImgBallInBg
    └─ ImgBallOutBg
    └─ ImgBall
  └─ GroupLevelup
    └─ TxtLevelup
└─ PanelLock (被UiObject引用: PanelLock)
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
    └─ BtnClick (被UiObject引用: BtnClick)
└─ PanelBuy
  └─ ImgBg
  └─ IconCoin
  └─ TxtPrice
└─ Effect
  └─ EffectSelect
  └─ EffectLevelup
└─ BtnClick (被UiObject引用: BtnClick)
└─ DetailRoot (被UiObject引用: DetailRoot)
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `BtnClick` | XUiButton | `BtnClick` |
| `PanelNormal` | RectTransform | `PanelNormal` |
| `PanelLock` | RectTransform | `PanelLock` |
| `PanelShopFreeze` | RectTransform | `PanelNormal/PnlCardHead/UiPunishaarCardHeadRole/ImgFrozen` |
| `DetailRoot` | RectTransform | `DetailRoot` |
| `PanelShopSubCard` | RectTransform | `PanelShopSubCard` |

## 子 UI 引用
| 变量名 | 目标 UI |
|---|---|
| `PanelNormal` | `PanelNormal` |
| `PanelShopSubCard` | `PanelShopSubCard` |
]]
-- ======== UI INFO END ========

