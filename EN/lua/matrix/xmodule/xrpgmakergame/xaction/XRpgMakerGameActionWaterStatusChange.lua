local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionWaterStatusChange:XRpgMakerGameActionBase
local XRpgMakerGameActionWaterStatusChange = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionWaterStatusChange")

-- 继承类初始化
function XRpgMakerGameActionWaterStatusChange:OnInit()
    
end

-- 执行
function XRpgMakerGameActionWaterStatusChange:Execute()
    for _, water in pairs(self.ActionData.WaterList) do
        local posX = water.PositionX
        local posY = water.PositionY
        local status = water.WaterStatus
        ---@type XRpgMakerGameWaterData
        local waterObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(posX, posY, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water)
        if waterObj then
            waterObj:SetStatus(status)
            waterObj:CheckPlayFlat()
        end

        ---@type XRpgMakerGameWaterData
        local iceObj = XDataCenter.RpgMakerGameManager.GetEntityObjByPosition(posX, posY, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice)
        if iceObj then
            iceObj:SetStatus(status)
            iceObj:CheckPlayFlat()
        end
    end
    self:Complete()
end

return XRpgMakerGameActionWaterStatusChange