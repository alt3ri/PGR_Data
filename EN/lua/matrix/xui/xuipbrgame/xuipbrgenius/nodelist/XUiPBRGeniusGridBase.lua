---@class XUiPBRGeniusGridBase: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field PanelLock UnityEngine.RectTransform
---@field BtnGenuis XUiComponent.XUiButton
---@field GridStateCtrl XUiComponent.XUiStateControl
local XUiPBRGeniusGridBase = XClass(XUiNode, "XUiPBRGeniusGridBase")

function XUiPBRGeniusGridBase:OnStart(index)
    self.Index = index
end

---@param cfg XTablePBRMetaProgression
function XUiPBRGeniusGridBase:RefreshShow(cfg)
    self.BtnGenuis:SetRawImage(cfg.NodeIcon)

    self.Cfg = cfg

    local GeniusNodeType = XMVCA.XPBRGame.EnumConst.GeniusNodeType
    if cfg.NodeType == GeniusNodeType.Normal or cfg.NodeType == GeniusNodeType.Important then
        local animTrans = self.Transform.parent:Find("Animation")
        self._AnimSibling = animTrans and animTrans.gameObject or nil
    end

    self:RefreshStateShow()
end

--- 刷新，只刷新状态，不更换关联节点
function XUiPBRGeniusGridBase:RefreshStateShow()
    local isUnlock = self._Control.GeniusControl:GetIsNodeUnlock(self.Cfg.NodeId)

    if isUnlock then
        self.GridStateCtrl:ChangeState('Unlock')
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.GridStateCtrl:ChangeState('Lock')
        self.PanelLock.gameObject:SetActiveEx(true)
    end

    if self._AnimSibling then
        self._AnimSibling:SetActiveEx(isUnlock)
    end

    self.BtnGenuis:ShowReddot(XMVCA.XPBRGame:GetIsNodeCanUnlock(self.Cfg.NodeId))
end

function XUiPBRGeniusGridBase:GetNodeId()
    return self.Cfg and self.Cfg.NodeId or 0
end

function XUiPBRGeniusGridBase:GetIndex()
    return self.Index
end

return XUiPBRGeniusGridBase