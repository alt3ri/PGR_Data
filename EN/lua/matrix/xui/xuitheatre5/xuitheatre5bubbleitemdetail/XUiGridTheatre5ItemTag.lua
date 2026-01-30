---@class XUiGridTheatre5ItemTag: XUiNode
---@field private _Control XTheatre5Control
---@field ImgBg UnityEngine.UI.Image
---@field RImgIcon UnityEngine.UI.RawImage
local XUiGridTheatre5ItemTag = XClass(XUiNode, 'XUiGridTheatre5ItemTag')

---@param tagCfg XTableTheatre5ItemTag
function XUiGridTheatre5ItemTag:Refresh(tagCfg)
    if not tagCfg then
        return
    end
    
    if self.ImgBg and not string.IsNilOrEmpty(tagCfg.BgRes) then
        self.ImgBg:SetImage(tagCfg.BgRes)
    end

    if self.RImgIcon and not string.IsNilOrEmpty(tagCfg.IconRes) then
        self.RImgIcon:SetRawImage(tagCfg.IconRes)
    end

    if self.TxtTag then
        self.TxtTag.text = tagCfg.Name
    end
end

return XUiGridTheatre5ItemTag