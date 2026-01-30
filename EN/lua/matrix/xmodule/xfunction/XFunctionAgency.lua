-- 用于模块统计/收集数据
---@class XFunctionAgency : XAgency
---@field _Model XFunctionModel
local XFunctionAgency = XClass(XAgency, "XFunctionAgency")

function XFunctionAgency:OnInit()
    --初始化一些变量
    -- EnumConst
    self.EnumConst = require("XModule/XFunction/XFunctionEnumConst")
end

function XFunctionAgency:InitRpc()
    -- 注册服务器事件
    self.RequestName = {
        PlayerCostTimeUploadRequest = "PlayerCostTimeUploadRequest",                -- 上报玩家在某个玩法中停留的时间
    }
end

function XFunctionAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

-- 进入玩法
---@param functionId number 玩法Id(XFunctionManager.FunctionName)
function XFunctionAgency:EnterFunction(functionId)
    self._Model:EnterFunction(functionId)
end

-- 退出玩法
---@param functionId number 玩法Id(XFunctionManager.FunctionName)
function XFunctionAgency:ExitFunction(functionId)
    self._Model:ExitFunction(functionId)
end

-- 退出当前玩法
function XFunctionAgency:ExitCurrentFunction()
    self._Model:ExitCurrentFunction()
end

--region rpc
-- 上报玩家在某个玩法中消耗的时间
function XFunctionAgency:RequestPlayerCostTimeUpload(functionId, time)
    local req = { FunctionId = functionId, CostTime = time }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PlayerCostTimeUploadRequest, req)
end
--endregion

return XFunctionAgency