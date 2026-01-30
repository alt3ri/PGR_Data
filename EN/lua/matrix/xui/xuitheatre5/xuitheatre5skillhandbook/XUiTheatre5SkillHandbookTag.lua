---@class XUiTheatre5SkillHandbookTag : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbookTag = XClass(XUiNode, "XUiTheatre5SkillHandbookTag")

function XUiTheatre5SkillHandbookTag:OnStart()
end

---@param tagId number
function XUiTheatre5SkillHandbookTag:Update(tagId)
    ---@type XTableTheatre5ItemTag
    local tagConfig = self._Control:GetTheatre5ItemTagCfgById(tagId)
    if tagConfig then
        self.TxtTag.text = tagConfig.Name
        self.RImgIcon:SetRawImage(tagConfig.IconRes)
    end
end

return XUiTheatre5SkillHandbookTag