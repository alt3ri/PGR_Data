---@class XUiGridLuosaitaBlock : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
local XUiGridLuosaitaBlock = XClass(XUiNode, "XUiGridLuosaitaBlock")

function XUiGridLuosaitaBlock:OnStart()
    self.RImgRed = self.Transform:FindTransform("a")
    self.RImgBlue = self.Transform:FindTransform("b")
end

function XUiGridLuosaitaBlock:Refresh(blockData)
    if not blockData then
        self:Close()
        return
    end

    local isOccupied = blockData:IsOccupied()
    if self.IsOccupied == isOccupied then return end

    self.RImgRed.gameObject:SetActiveEx(not isOccupied)
    self.RImgBlue.gameObject:SetActiveEx(isOccupied)
    
    -- 只有从未占领切换到占领的时候才播切换特效，其他时候播常驻特效
    if self.IsOccupied == false and isOccupied then
        self.AnimEnableBlue = self.AnimEnableBlue or self.Transform:FindTransform("AnimEnableBlue")
        self.AnimEnableBlue.gameObject:SetActiveEx(true)
        self.AnimEnableBlue:PlayTimelineAnimation()
    end
    self.IsOccupied = isOccupied
end

return XUiGridLuosaitaBlock
