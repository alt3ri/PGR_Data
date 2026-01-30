---@class XBigWorldUiData
local XBigWorldUiData = XClass(nil, "XBigWorldUiData")

function XBigWorldUiData:Ctor(uiName, ...)
    self:SetUiName(uiName)
    self:SetArgs(...)
end

function XBigWorldUiData:SetUiName(uiName)
    self._UiName = uiName
end

function XBigWorldUiData:GetUiName()
    return self._UiName
end

function XBigWorldUiData:SetArgs(...)
    self._Args = self:_GetArgsFromParams(...)
end

function XBigWorldUiData:GetArgs(isUnpack)
    if isUnpack then
        if self._Args then
            return table.unpack(self._Args, 1, self._Args.n)
        end
    end

    return self._Args or nil
end

function XBigWorldUiData:SetArgByIndex(index, value)
    if not self._Args then
        self._Args = {}
    end

    self._Args[index] = value
end

function XBigWorldUiData:GetArgByIndex(index, defaultValue)
    local args = self:GetArgs()

    return args and args[index] or defaultValue
end

function XBigWorldUiData:GetPriority()
    if self:IsEmpty() then
        return 0
    end
    
    return XMVCA.XBigWorldUI:GetPopupPriority(self:GetUiName())
end

function XBigWorldUiData:IsModality()
    if self:IsEmpty() then
        return false
    end

    if XMVCA.XBigWorldUI:IsPopupModality(self:GetUiName()) then
        return true
    end

    local customParams = XMVCA.XBigWorldUI:GetPopupCustomModalityParams(self:GetUiName())

    if not XTool.IsTableEmpty(customParams) then
        for index, param in pairs(customParams) do
            local arg = self:GetArgByIndex(index)

            if arg and tostring(arg) == param then
                return true
            end
        end
    end

    return false
end

function XBigWorldUiData:IsSpecificModality(targetUiName)
    if self:IsEmpty() then
        return false
    end

    local specificUiNames = XMVCA.XBigWorldUI:GetPopupSpecificModalityUi(self:GetUiName())

    if not XTool.IsTableEmpty(specificUiNames) then
        for _, uiName in pairs(specificUiNames) do
            if uiName == targetUiName then
                return true
            end
        end
    end

    return false
end

function XBigWorldUiData:IsEmpty()
    return string.IsNilOrEmpty(self._UiName)
end

function XBigWorldUiData:Clear()
    self._UiName = ""
    self._Args = nil
end

function XBigWorldUiData:_GetArgsFromParams(...)
    local count = select("#", ...)

    if count > 0 then
        return table.pack(...)
    end

    return nil
end

return XBigWorldUiData
