local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldPhotographPopupAlbumGridPhoto : XUiNode
local XUiBigWorldPhotographPopupAlbumGridPhoto = XClass(XUiNode, "XUiBigWorldPhotographPopupAlbumGridPhoto")

function XUiBigWorldPhotographPopupAlbumGridPhoto:Ctor()
    self.GridPhoto:AddEventListener(handler(self, self.OnGridPhotoClick))
    self._defaultSize = self.ImgPhoto.transform.sizeDelta
    self._sizeAspectRatio = self._defaultSize.x / self._defaultSize.y
end

function XUiBigWorldPhotographPopupAlbumGridPhoto:OnDestroy()
    self:_DestroyTexCache()
end

function XUiBigWorldPhotographPopupAlbumGridPhoto:_DestroyTexCache()
    if self._photoTexCache then
        CS.UnityEngine.Object.DestroyImmediate(self._photoTexCache)
        self._photoTexCache = false
    end
end

function XUiBigWorldPhotographPopupAlbumGridPhoto:OnGridPhotoClick()
    if self.Parent.OnPhotoClick then self.Parent:OnPhotoClick(self._photoIndex) end
end

function XUiBigWorldPhotographPopupAlbumGridPhoto:SetSelected(isSelected)
    self.Select.gameObject:SetActive(isSelected)
end

function XUiBigWorldPhotographPopupAlbumGridPhoto:ResetData(data, i)
    self._photoIndex = i
    self:_DestroyTexCache()
    self._photoTexCache = self._Control:GetPhotoTexture(data, true)
    if self._photoTexCache then
        self.ImgPhoto.texture = self._photoTexCache
        self.ImgPhoto.gameObject:SetActive(true)

        local textureAspectRatio = self._photoTexCache.width / self._photoTexCache.height
        if textureAspectRatio > self._sizeAspectRatio then
            self.ImgPhoto.transform.sizeDelta = CS.UnityEngine.Vector2(self._photoTexCache.width, self._photoTexCache.height) * (self._defaultSize.y / self._photoTexCache.height)
        else
            self.ImgPhoto.transform.sizeDelta = CS.UnityEngine.Vector2(self._photoTexCache.width, self._photoTexCache.height) * (self._defaultSize.x / self._photoTexCache.width)
        end
    else
        self.ImgPhoto.gameObject:SetActive(false)
    end
    self:SetSelected(self.Parent:IsSelectedByPhotoIndex(i))
end

return XUiBigWorldPhotographPopupAlbumGridPhoto
