
---@class XBigWorldCharacter
local XBigWorldCharacter = XClass(nil, "XBigWorldCharacter")

function XBigWorldCharacter:Ctor(id)
    self._CharId = id
    self._HeadInfo = false
    self._FashionId = false
    self._FashionColorId = false
end

function XBigWorldCharacter:SetFashionId(id)
    self._FashionId = id
end

function XBigWorldCharacter:GetFashionId()
    return self._FashionId
end

function XBigWorldCharacter:SetFashionColorId(id)
    self._FashionColorId = id or 0
end

function XBigWorldCharacter:GetFashionColorId()
    return self._FashionColorId
end

function XBigWorldCharacter:SetHeadInfo(id, type)
    if not self._HeadInfo then
        self._HeadInfo = {
            HeadFashionId = 0,
            HeadFashionType = 0,
        }
    end
    self._HeadInfo.HeadFashionId = id
    self._HeadInfo.HeadFashionType = type
end

function XBigWorldCharacter:GetHeadInfo()
    return self._HeadInfo
end

return XBigWorldCharacter