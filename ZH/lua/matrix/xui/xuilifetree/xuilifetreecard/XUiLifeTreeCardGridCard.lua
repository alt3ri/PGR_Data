
---@class XUiLifeTreeCardGridCard : XUiNode
---@field _Control XLifeTreeControl
---@field IsAnimPlaying boolean
local XUiLifeTreeCardGridCard = XClass(XUiNode, "XUiLifeTreeCardGridCard")

function XUiLifeTreeCardGridCard:InitLine()
    local line = self.Transform.parent:Find("Line")
    if line then
        local catalogConfig = self._Control:GetLifeTreeCharacterCatalogConfigById(self.CatalogId)
        line.gameObject:SetActiveEx(catalogConfig.LinkIsShowLine)
    end
end

function XUiLifeTreeCardGridCard:PlayEnableAnim()
    self:PlayAnimation("Enable", function()
        self.IsAnimPlaying = false
    end, function()
        self.IsAnimPlaying = true
    end)
end

function XUiLifeTreeCardGridCard:GetIsAnimPlaying()
    return self.IsAnimPlaying == true
end

return XUiLifeTreeCardGridCard
