---@class XFlowTreeActionSetCellStatus : XFlowTreeAction 设置进度 Cell 状态（同步，立即完成）
---@field private _Cell XUiEquipPartnerEnhanceProgressCell
---@field private _ProgressStatus number EnhanceProgressType
local XFlowTreeActionSetCellStatus = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionSetCellStatus")

---@param cell XUiEquipPartnerEnhanceProgressCell
---@param status number XUiEquipPartnerEnhanceProgressCell.EnhanceProgressType
function XFlowTreeActionSetCellStatus:Ctor(cell, status)
    self._Cell = cell
    self._ProgressStatus = status
end

function XFlowTreeActionSetCellStatus:OnEnter(context)
    self._Cell:RefreshByProgressStatus(self._ProgressStatus)
    self:OnDone(self.XFlowTreeEnum.Result.Succeed)
end

function XFlowTreeActionSetCellStatus:OnExit(isInterrupt)
end

function XFlowTreeActionSetCellStatus:OnDestroy()
    self.Super.OnDestroy(self)
    self._Cell = nil
end

return XFlowTreeActionSetCellStatus
