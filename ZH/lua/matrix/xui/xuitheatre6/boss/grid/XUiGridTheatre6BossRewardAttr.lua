---@class XUiGridTheatre6BossRewardAttr : XUiNode Boss奖励Grid - 属性(预留)
---@field _Control XTheatre6Control
local XUiGridTheatre6BossRewardAttr = XClass(XUiNode, "XUiGridTheatre6BossRewardAttr")

function XUiGridTheatre6BossRewardAttr:OnStart()

end

---@param attrPackId number 属性包Id (Theatre6AttrPack表)
function XUiGridTheatre6BossRewardAttr:Refresh(attrPackId)
    self._AttrPackId = attrPackId
    local attrPackConfig = self._Control:GetAttrPackCfgById(attrPackId)

    -- TODO: 美术资源完成后实现
    -- 设置属性图标
    -- if self.RImgIcon and attrPackConfig.Icon then
    --     self.RImgIcon:SetRawImage(attrPackConfig.Icon)
    -- end
end

return XUiGridTheatre6BossRewardAttr
