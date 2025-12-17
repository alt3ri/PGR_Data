local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionTorchStatusChange:XRpgMakerGameActionBase
local XRpgMakerGameActionTorchStatusChange = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionTorchStatusChange")

-- 继承类初始化
function XRpgMakerGameActionTorchStatusChange:OnInit(actionData)
    
end

-- 执行
function XRpgMakerGameActionTorchStatusChange:Execute()
    for _, torchData in pairs(self.ActionData.TorchList) do
        ---@type XRpgMakerGameTorch
        local torch = self._Scene:GetTorchObj(torchData.PositionX, torchData.PositionY)
        torch:SetState(torchData.TorchStatus)
    end
    self:Complete()
end

return XRpgMakerGameActionTorchStatusChange