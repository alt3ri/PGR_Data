
---@class XUiGridFubenBossSingleDetailBuffOrSkill : XUiNode

local XUiGridFubenBossSingleDetailBuffOrSkillV4P5 =
    XClass(XUiNode, "XUiGridFubenBossSingleDetailBuffOrSkillV4P5")

function XUiGridFubenBossSingleDetailBuffOrSkillV4P5:OnStart(
    name, icon, triangleBg)

    self.TxtName.text = name

    if icon then
        self.RImgIcom:SetRawImage(icon)
    end

    if triangleBg then
        self.ImgfTriangleBg:SetImage(triangleBg)
    end
end

return XUiGridFubenBossSingleDetailBuffOrSkillV4P5
