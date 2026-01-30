local XBigWorldViewData = require("XUi/XUiBigWorld/XHud/ViewData/XBigWorldViewData")

---@class XBigWorldObjectiveData : XBigWorldViewData
local XBigWorldObjectiveData = XClass(XBigWorldViewData, "XBigWorldObjectiveData")

function XBigWorldObjectiveData:OnReset()
    self.Id = 0
    self.Description = nil
    self.IsCompleted = false
end

function XBigWorldObjectiveData:SetParams(id, description, isCompleted)
    self.Id = id or 0
    self.Description = description or ""
    self.IsCompleted = isCompleted or false
end

function XBigWorldObjectiveData:GetId()
    return self.Id
end

function XBigWorldObjectiveData:GetHashCode()
    return self.Id
end

return XBigWorldObjectiveData