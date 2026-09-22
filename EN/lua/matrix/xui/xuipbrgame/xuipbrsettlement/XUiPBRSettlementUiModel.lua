---@class XUiPBRSettlementUiModel: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field GameObject @对应的镜头节点UiModelGo
local XUiPBRSettlementUiModel = XClass(XUiNode, "XUiPBRSettlementUiModel")

local IpadResolution = 1.4 -- 4:3 默认配置

function XUiPBRSettlementUiModel:OnStart()
    self:InitCameraShow()
end

function XUiPBRSettlementUiModel:InitCameraShow()
    local ipadResolution = self._Control:GetClientPBRNumber('IpadResolutionLimit')
    if XTool.IsNumberValidEx(ipadResolution) then
        IpadResolution = ipadResolution
    end
    
    local ipadNearCam = self.Transform:FindTransformWithSplit("UiNearRoot/CamNearMain1")

    local radio = self.Parent.Transform.rect.width / self.Parent.Transform.rect.height
    
    if radio < IpadResolution then
        ipadNearCam.gameObject:SetActiveEx(true)
    else
        ipadNearCam.gameObject:SetActiveEx(false)
    end
end

function XUiPBRSettlementUiModel:RefreshShowBySettle(isWin)
    -- do nothing
end

return XUiPBRSettlementUiModel