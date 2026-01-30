local XBigWorldSkipFunctionConfigModel = require("XModule/XBigWorldSkipFunction/XBigWorldSkipFunctionConfigModel")
local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBigWorldSkipFunctionModel : XBigWorldSkipFunctionConfigModel
local XBigWorldSkipFunctionModel = XClass(XBigWorldSkipFunctionConfigModel, "XBigWorldSkipFunctionModel")

function XBigWorldSkipFunctionModel:OnInit()
    ---@type table<string, XBWSkipBase>
    self._SkipMap = {}

    self:_InitTableKey()
end

function XBigWorldSkipFunctionModel:ClearPrivate()
end

function XBigWorldSkipFunctionModel:ResetAll()
end

function XBigWorldSkipFunctionModel:GetSkipBySkipId(skipId)
    local skipName = self:GetBigWorldSkipFunctionSkipNameById(skipId)
    local skip = self._SkipMap[skipName]

    if not skip then
        local skipClass = require("XModule/XBigWorldSkipFunction/XSkip/XBWSkip" .. skipName)
        skip = skipClass.New(skipId)
        self._SkipMap[skipName] = skip
    end

    skip:SetId(skipId)

    return skip
end

return XBigWorldSkipFunctionModel