local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipFashionPreview : XBWSkipBase
local XBWSkipFashionPreview = XClass(XBWSkipBase, "XBWSkipFashionPreview")

function XBWSkipFashionPreview:Skip()
    local params = self:GetParams()

    if params == nil then
        XLog.Error("XBWSkipFashionPreview:Skip 预览配置无效")
        return false
    end
    local previewId = params[1]

    if previewId == nil then
        XLog.Error("XBWSkipFashionPreview:Skip 预览ID无效")
        return false
    end

    local previewConfigs = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPreviewConfigs(previewId)
    if not previewConfigs or XTool.IsTableEmpty(previewConfigs) then
        XLog.Error("XBWSkipFashionPreview:Skip 未找到预览配置, previewId:", previewId)
        return false
    end
    XLuaUiManager.Open("UiBigWorldFashionPreview", previewId)
    return true
end


return XBWSkipFashionPreview
