---@class XUiModelDisplayCacheInfo
local XUiModelDisplayCacheInfo = XClass(nil, "XUiModelDisplayCacheInfo")

function XUiModelDisplayCacheInfo:Ctor(key, cacheTime)
    self.Key = key
    self.CacheTime = cacheTime or 5
    self.IsActive = true
    self.Timestamp = XTime.GetServerNowTimestamp()
end

function XUiModelDisplayCacheInfo:IsEmpty()
    return string.IsNilOrEmpty(self.Key)
end

function XUiModelDisplayCacheInfo:CouldClear()
    if self:IsEmpty() or self.IsActive then
        return false
    end

    local time = XTime.GetServerNowTimestamp()

    return time - self.Timestamp > self.CacheTime
end

function XUiModelDisplayCacheInfo:Clear()
    self.Key = nil
    self.IsActive = false
    self.Timestamp = 0
end

function XUiModelDisplayCacheInfo:SetActive(isActive)
    self.IsActive = isActive
    
    if not isActive then
        self.Timestamp = XTime.GetServerNowTimestamp()
    end
end

return XUiModelDisplayCacheInfo
