---@class XGoldenMinerComponentShipShell:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityShip
local XGoldenMinerComponentShipShell = XClass(XEntity, "XGoldenMinerComponentShipShell")

--region Override
function XGoldenMinerComponentShipShell:OnInit()
    ---@type UnityEngine.UI.RawImage
    self._ShipShell = nil
end

function XGoldenMinerComponentShipShell:OnRelease()
    self._ShipShell = nil
    self.GameObject = nil
end
--endregion

--region Setter
function XGoldenMinerComponentShipShell:SetShipShell(shellRawImage)
    self._ShipShell = shellRawImage
end

function XGoldenMinerComponentShipShell:Init(go)
    self.GameObject = go
    
    self.PanelCopy = XUiHelper.TryGetComponent(self.GameObject.transform, "PanelCopy")

    if self.PanelCopy then
        local isExsistValidCopyBuff = self._OwnControl.SystemBuff:CheckBuffValidByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_DRAG_EX_STONE_COPY)

        self.PanelCopy.gameObject:SetActiveEx(isExsistValidCopyBuff)
    end
end
--endregion

--region Getter

function XGoldenMinerComponentShipShell:GetShipShell()
    return self._ShipShell
end

--endregion

return XGoldenMinerComponentShipShell