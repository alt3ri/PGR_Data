local XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff =
    XClass(XUiNode, "XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff")

function XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff:SetData(args)
    self.TxtName.text = args.BuffName
    self.RImgIcon:SetRawImage(args.Icon)
    self.TxtDesc.text = args.Desc

    if args.TriangleBg and self.ImgfTriangleBg then
        self.ImgfTriangleBg:SetImage(args.TriangleBg)
    end
end

return XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff
