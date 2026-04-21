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
    
    self:RefreshStateShow()
end

--- 刷新，只刷新状态，不更换关联节点
function XUiPBRGeniusGridBase:RefreshStateShow()
    if self._Control.GeniusControl:GetIsNodeUnlock(self.Cfg.NodeId) then
        self.GridStateCtrl:ChangeState('Unlock')
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.GridStateCtrl:ChangeState('Lock')
        self.PanelLock.gameObject:SetActiveEx(true)
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