local XUiPunishaarFightMainPanelStateBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarFightMainPanelStateBase")
local XUiPunishaarFightMainBaseComBottomBag = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiBase/XUiPunishaarFightMainBaseComBottomBag")

--- 基底态面板：FightMain 常驻 UI 基底的内容面板，显背包允许编排（≡ PreFight 背包能力减 BtnFight/敌人预览）。
--- 继承 PanelStateBase（DragRoot 拖拽托管 + BuySuccess 刷新订阅），组合 Base ComBottomBag。
--- 无 BtnFight（不进战斗）、无敌人预览。PanelAsset/ListStage 等顶部部件由 CommonFightMain.SetShowOnBase() 按归属显隐。#66
---@class XUiPunishaarFightMainPanelBase : XUiPunishaarFightMainPanelStateBase
---@field ComBottomBag UnityEngine.RectTransform 底部装备区挂载根节点
local XUiPunishaarFightMainPanelBase = XClass(XUiPunishaarFightMainPanelStateBase, "XUiPunishaarFightMainPanelBase")

function XUiPunishaarFightMainPanelBase:OnStart()
    if not self.ComBottomBag then
        XLog.Error("[PunishaarFightMain] PanelBase:OnStart ComBottomBag 节点缺失，请检查 FightMain prefab 是否已加 PanelBase>ComBottomBag")
        return
    end
    ---@type XUiPunishaarFightMainBaseComBottomBag
    self.BottomBag = XUiPunishaarFightMainBaseComBottomBag.New(self.ComBottomBag, self)
    self.BottomBag:Open()
end

--- BuySuccess 刷新 = Refresh（BottomBag 列表 + 暂存区若显则刷）。
function XUiPunishaarFightMainPanelBase:_OnBuySuccess()
    self:Refresh()
end

function XUiPunishaarFightMainPanelBase:Refresh()
    if self.BottomBag then
        self.BottomBag:Refresh()
        self.BottomBag:RefreshBagLayoutIfShow()
    end
end

return XUiPunishaarFightMainPanelBase
