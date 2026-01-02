---@class XPreviewData
local XPreviewData = XClass(nil, "XPreviewData")

function XPreviewData:Ctor()
    self.Type = XEnumConst.BWPreviewType.Image
    self.ImageUrl = ""
    self.Texture = nil
    self.VideoId = 0
    self.IsAutoClose = false
    self.IsFullScreen = false
end

---@return XPreviewData
function XPreviewData:SetType(type)
    self.Type = type or XEnumConst.BWPreviewType.Image

    return self
end

---@return XPreviewData
function XPreviewData:SetImageUrl(imageUrl)
    self.ImageUrl = imageUrl or ""

    return self
end

---@return XPreviewData
function XPreviewData:SetTexture(texture)
    self.Texture = texture or nil

    return self
end

---@return XPreviewData
function XPreviewData:SetVideoId(videoId)
    self.VideoId = videoId or 0

    return self
end

---@return XPreviewData
function XPreviewData:SetIsAutoClose(isAutoClose)
    self.IsAutoClose = isAutoClose or false

    return self
end

---@return XPreviewData
function XPreviewData:SetIsFullScreen(isFullScreen)
    self.IsFullScreen = isFullScreen or false

    return self
end

---@return XPreviewData
function XPreviewData:SetImageData(imageUrl)
    return self:SetType(XEnumConst.BWPreviewType.Image):SetImageUrl(imageUrl)
end

---@return XPreviewData
function XPreviewData:SetTextureData(texture, defaultImageUrl)
    return self:SetType(XEnumConst.BWPreviewType.Image):SetTexture(texture):SetImageUrl(defaultImageUrl)
end

---@return XPreviewData
function XPreviewData:SetVideoData(videoId, imageUrl)
    return self:SetType(XEnumConst.BWPreviewType.Video):SetVideoId(videoId):SetImageUrl(imageUrl)
end

---@return XPreviewData
function XPreviewData:SetImageToVideoData(imageUrl, videoId)
    return self:SetType(XEnumConst.BWPreviewType.ImageToVideo):SetVideoId(videoId):SetImageUrl(imageUrl):SetIsFullScreen(true)
end

function XPreviewData:IsVideoValid()
    return XTool.IsNumberValid(self.VideoId)
end

function XPreviewData:IsImageValid()
    return not string.IsNilOrEmpty(self.ImageUrl) or self.Texture
end

function XPreviewData:Clear()
    self.Type = XEnumConst.BWPreviewType.Image
    self.ImageUrl = ""
    self.Texture = nil
    self.VideoId = 0
    self.IsAutoClose = false
    self.IsFullScreen = false
end

function XPreviewData:Dispose()
    XMVCA.XBigWorldCommon:RepaidPreviewData(self)
end

function XPreviewData:RefreshRawImage(rawImage)
    if self.Texture then
        rawImage.texture = self.Texture
        rawImage:SetNativeSize()
    elseif not string.IsNilOrEmpty(self.ImageUrl) then
        rawImage:SetRawImage(self.ImageUrl, function()
            rawImage:SetNativeSize()
        end)
    end
end

return XPreviewData
