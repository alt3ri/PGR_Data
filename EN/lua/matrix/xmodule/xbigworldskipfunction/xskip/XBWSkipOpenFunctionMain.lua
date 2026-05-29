local XBWSkipBase = require("XModule/XBigWorldSkipFunction/XSkip/XBase/XBWSkipBase")

---@class XBWSkipOpenFunctionMain : XBWSkipBase
local XBWSkipOpenFunctionMain = XClass(XBWSkipBase, "XBWSkipOpenFunctionMain")

function XBWSkipOpenFunctionMain:Skip()
    local params = self:GetParams()
    if not self:_CheckParamsValid() then
        return false
    end
    
    local functionKey = params[1]
    
    local functionConfig = self:_GetFunctionConfig(functionKey)
    if not functionConfig then
        XLog.Error("XBWSkipOpenFunctionMain:Skip 未找到功能配置, key:", functionKey)
        return false
    end
    
    if not self:_CheckFunctionOpen(functionConfig) then
        local tips = XMVCA.XBigWorldService:GetText("FunctionNotOpen")
        XMVCA.XBigWorldUI:TipMsg(tips)
        return false
    end
    
    if not functionConfig.UiName or functionConfig.UiName == "" then
        XLog.Error("XBWSkipOpenFunctionMain:Skip 未配置UI名称, key:", functionKey)
        return false
    end
    
    self:_OpenTargetUI(functionConfig)
    return true
end

function XBWSkipOpenFunctionMain:_GetFunctionConfig(functionKey)
    return XMVCA.XCommanderCollege:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
end

function XBWSkipOpenFunctionMain:_GetConfigModel()
    if XMVCA.XBigWorldFunction and XMVCA.XBigWorldFunction.GetBigWorldFunctionMainConfigModel then
        return XMVCA.XBigWorldFunction:GetBigWorldFunctionMainConfigModel()
    end
    return nil
end

function XBWSkipOpenFunctionMain:_CheckFunctionOpen(functionConfig)
    if functionConfig.FunctionId and functionConfig.FunctionId > 0 then
        if not XMVCA.XBigWorldFunction:CheckFunctionOpen(functionConfig.FunctionId) then
            return false
        end
    end
    
    return true
end

function XBWSkipOpenFunctionMain:_OpenTargetUI(functionConfig)
    --functionConfig.Args 是一个预判需求，目前没有这个字段
    if functionConfig.Args and #functionConfig.Args > 0 then
        XMVCA.XBigWorldUI:Open(functionConfig.UiName, table.unpack(functionConfig.Args))
    else
        XMVCA.XBigWorldUI:Open(functionConfig.UiName)
    end
end

function XBWSkipOpenFunctionMain:_CheckParamsValid()
    local params = self:GetParams()
    if XTool.IsTableEmpty(params) then
        XLog.Error("XBWSkipOpenFunctionMain:Skip 参数不能为空")
        return false
    end
    
    if not params[1] then
        XLog.Error("XBWSkipOpenFunctionMain:Skip 功能Key不能为空")
        return false
    end
    
    return true
end

return XBWSkipOpenFunctionMain
