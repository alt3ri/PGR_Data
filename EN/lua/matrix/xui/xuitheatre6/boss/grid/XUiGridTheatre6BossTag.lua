---@class XUiGridTheatre6BossTag : XUiNode Boss标签Grid
---@field _Control XTheatre6Control
local XUiGridTheatre6BossTag = XClass(XUiNode, "XUiGridTheatre6BossTag")

function XUiGridTheatre6BossTag:OnStart()

end

---XTool.UpdateDynamicItem调用
---@param tagId number 标签Id
---@param index number 索引
function XUiGridTheatre6BossTag:Update(tagId, index)
    self._TagId = tagId
    local tagConfig = self._Control:GetBuildTagConfig(tagId)

    if tagConfig == nil then
        self._Control:ShowTip("bossTag配置为空")
        return
    end
    
    self.TxtTitle.text = tagConfig.Name
    self.UiRImgIconBg:SetRawImage(tagConfig.Icon)
end

return XUiGridTheatre6BossTag
