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
    
    self:AddRpc("NotifyFunctionalEntranceData", handler(self, self.NotifyFunctionalEntranceData))
end

function XFunctionAgency:InitEvent()
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

function XFunctionAgency:CheckEntryRedPoint(functionId)
    return self._Model:CheckEntryRedPoint(functionId)
end

function XFunctionAgency:GetEntryFunctionalLabelTimeId(functionId)
    return self._Model:GetEntryFunctionalLabelTimeId(functionId)
end

function XFunctionAgency:GetEntryFunctionalLabel(functionId)
    return self._Model:GetEntryFunctionalLabel(functionId)
end

function XFunctionAgency:GetEntryFunctionalIcon(functionId)
    return self._Model:GetEntryFunctionalIcon(functionId)
end

function XFunctionAgency:GetEntryFunctionalTaskId(functionId)
    return self._Model:GetEntryFunctionalTaskId(functionId)
end

function XFunctionAgency:MarkEntryRedPoint(functionId)
    --不需要Mark
    if not self._Model:CheckEntryRedPoint(functionId) then
        return false
    end
    self:RequestFunctionalEntranceRedPoint(functionId)
    return true
end

--region rpc
-- 上报玩家在某个玩法中消耗的时间
function XFunctionAgency:RequestPlayerCostTimeUpload(functionId, time)
    local req = { FunctionId = functionId, CostTime = time }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.PlayerCostTimeUploadRequest, req)
end

function XFunctionAgency:RequestFunctionalEntranceRedPoint(functionId)
    local redNum = self._Model:GetEntryFunctionalRedNum(functionId)
    if not redNum or redNum <= 0 then
        XLog.Error(string.format("功能: %s 不存在红点配置!!!", functionId))
        return
    end
    local req = { FunctionId = functionId }
    XNetwork.Call("FunctionalEntranceRedPointNumUpdateRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:MarkEntryRedPoint(functionId, redNum)
    end)
end

function XFunctionAgency:NotifyFunctionalEntranceData(data)
    if not data then
        return
    end
    self._Model:InitEntryRedPoint(data.RedPointDatas)
end

--endregion

return XFunctionAgency