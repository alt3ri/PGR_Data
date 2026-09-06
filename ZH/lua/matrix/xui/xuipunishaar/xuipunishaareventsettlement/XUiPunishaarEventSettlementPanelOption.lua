-- ======== AUTO FIELDS BEGIN ========
---@class XUiPunishaarEventSettlementPanelOption : XUiNode
---@field ListOption UnityEngine.RectTransform
-- ======== AUTO FIELDS END ========
--- v2 返工：原多选项（BtnOptionGroup/BtnOption + RefreshBtnOptionGroup）已删除。
--- 内容阶段只有一个 ConfirmContent 按钮（BtnComfirm），prefab 未挂 UiObject 故经 TryGetComponent 获取。
--- 事件描述文本（TxtDesc）不在本节点子树（挂在 PanelEventDec/TxtList 下），由主面板直接刷新。
local XUiPunishaarEventSettlementPanelOption = XClass(XUiNode, "XUiPunishaarEventSettlementPanelOption")

function XUiPunishaarEventSettlementPanelOption:OnStart()
    -- 旧多选项容器不再使用，整组隐藏
    if self.ListOption then
        self.ListOption.gameObject:SetActiveEx(false)
    end
    -- BtnComfirm 未在 @field 暴露（prefab 无对应 UiObject），按名取 XUiButton
    self._BtnComfirm = XUiHelper.TryGetComponent(self.Transform, "BtnComfirm", "XUiButton")
    if self._BtnComfirm then
        self._BtnComfirm:AddEventListener(Handler(self, self.OnBtnComfirmClick))
    else
        XLog.Error("[PunishaarEventSettlement] PanelOption:OnStart 未找到 BtnComfirm，请检查预制体")
    end
end

function XUiPunishaarEventSettlementPanelOption:OnEnable()
end

function XUiPunishaarEventSettlementPanelOption:OnDisable()
end

function XUiPunishaarEventSettlementPanelOption:OnDestroy()
    self._AdvanceHandler = nil
end

--- 设置"推进链"回调（由主面板 AdvanceChain 注入）。点 BtnComfirm 即推进：
--- NextEvent 非空→主面板刷下一 Content；空→主面板 FinishEvent 切奖励阶段。
---@param handler function()
function XUiPunishaarEventSettlementPanelOption:SetAdvanceHandler(handler)
    self._AdvanceHandler = handler
end

--- 刷新 ConfirmContent 按钮文案（事件描述文本由主面板刷新，本面板只管按钮）。
---@param confirmContent string Content.ConfirmContent
function XUiPunishaarEventSettlementPanelOption:Refresh(confirmContent)
    if not self._BtnComfirm then return end
    self._BtnComfirm:SetName(confirmContent or "")
end

function XUiPunishaarEventSettlementPanelOption:OnBtnComfirmClick()
    if self._AdvanceHandler then
        self._AdvanceHandler()
    end
end

return XUiPunishaarEventSettlementPanelOption

-- ======== UI INFO BEGIN ========
--[[
# PanelOption UI 信息
- GameObject: `PanelOption`
- Hierarchy 路径: `SafeAreaContentPane/PanelEventDec/PanelOption`
- 基类: XUiNode

## 节点树（被 UiObject 引用的物体会标注变量名）
```
PanelOption
└─ ListOption (被UiObject引用: ListOption、BtnOptionGroup)
  └─ BtnOption
    └─ ...
└─ BtnComfirm
  └─ Normal
    └─ ImgNormal
    └─ Txt
  └─ ...
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `ListOption` | RectTransform | `ListOption` |

注意：BtnComfirm 在预制体中未挂 UiObject，运行时经 XUiHelper.TryGetComponent 按 "BtnComfirm" 取 XUiButton。
TxtDesc（事件描述）挂在 PanelEventDec/TxtList/.../TxtDesc 下，不在本节点子树，由主面板刷新。
]]
-- ======== UI INFO END ========
