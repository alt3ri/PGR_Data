local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")
---@class XBWSkipNews : XBWSkipBase
local XBWSkipNews = XClass(XBWSkipBase, "XBWSkipNews")

function XBWSkipNews:Skip()
    local params = self:GetParams()
    if not self:_CheckParamsValid() then
        return false
    end
    XMVCA.XBigWorldNews:OpenNewsUi(params[1])
    return true
end

function XBWSkipNews:_CheckParamsValid()
    local params = self:GetParams()
    if not XTool.IsTableEmpty(params) then
        if not params[1] then
            XLog.Error("XBWSkipNews:Skip 新闻ID不能为空")
            return false
        end
    end
    return true
end

return XBWSkipNews
