local XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff =
    XClass(XUiNode, "XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff")

function XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff:SetData(
    buffName, icon, desc, triangleBg)
    self.TxtName.text = buffName
    self.RImgIcon:SetRawImage(icon)
    self.TxtDesc.text = desc

    if triangleBg and self.ImgfTriangleBg then
        self.ImgfTriangleBg:SetImage(triangleBg)
    end
end

return XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff
