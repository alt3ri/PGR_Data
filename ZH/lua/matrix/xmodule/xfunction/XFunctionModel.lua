---@class XFunctionModel : XModel
---@field CurrentFunction XFunctionData
local XFunctionModel = XClass(XModel, "XFunctionModel")

local TableKey = {
    FunctionalEntranceConfig = {
        Identifier = "FunctionId",
        CacheType = XConfigUtil.CacheType.Normal
    }
}

function XFunctionModel:OnInit()
    self._EntryRedPoint = false
    
    self._ConfigUtil:InitConfigByTableKey("Functional", TableKey)
end

function XFunctionModel:ClearPrivate()
  
end

function XFunctionModel:ResetAll()
    self:RemoveUploadDelayTimer()
end

--region 上报玩法停留时间
-- 进入玩法
---@param functionId number 玩法Id(XFunctionManager.FunctionName)
function XFunctionModel:EnterFunction(functionId)
    if not self.CurrentFunction then
        self.CurrentFunction = require("XModule/XFunction/XEntity/XFunctionData").New()
    end
    
    self:RemoveUploadDelayTimer()
    local oldFunctionId = self.CurrentFunction:GetFunctionId()
    if oldFunctionId ~= functionId then
        -- 同一时间只有一个玩法记录时间，跳转其他玩法时，自动结束上一个玩法的时间记录
        if XTool.IsNumberValidEx(oldFunctionId) then
            self:ExitFunction(oldFunctionId, true)
        end
        self.CurrentFunction:SetFunctionId(functionId)
    end
    self.CurrentFunction:Enter()
end

-- 退出玩法
---@param functionId number 玩法Id(XFunctionManager.FunctionName)
---@param isImmediate boolean 是否立刻结束，默认会有1S的CD，重进玩法可叠加玩法的游戏时间
function XFunctionModel:ExitFunction(functionId, isImmediate)
    if not self.CurrentFunction or self.CurrentFunction:GetFunctionId() ~= functionId then
        return
    end

    -- 停留时间小于上报的最小时间，不上报
    local dwellTime = self.CurrentFunction:Exit() -- 玩法的停留时间
    if dwellTime <= XMVCA.XFunction.EnumConst.UPLOAD_MIN_TIME then
        return
    end

    if isImmediate then
        self.CurrentFunction:Reset()
        XMVCA.XFunction:RequestPlayerCostTimeUpload(functionId, dwellTime)
    else
        local delayTime = XMVCA.XFunction.EnumConst.UPLOAD_DELAY_TIME
        self.UploadDelayTimer = XScheduleManager.ScheduleOnce(function()
            self.UploadDelayTimer = nil
            self.CurrentFunction:Reset()
            XMVCA.XFunction:RequestPlayerCostTimeUpload(functionId, dwellTime)
        end, delayTime)
    end
end

-- 退出当前玩法
function XFunctionModel:ExitCurrentFunction()
    if not self.CurrentFunction then return end
    
    local functionId = self.CurrentFunction:GetFunctionId()
    if XTool.IsNumberValidEx(functionId) then
        self:RemoveUploadDelayTimer()
        self:ExitFunction(functionId, true)
    end
end

-- 移除上报的延迟定时器
function XFunctionModel:RemoveUploadDelayTimer()
    if self.UploadDelayTimer then
        XScheduleManager.UnSchedule(self.UploadDelayTimer)
        self.UploadDelayTimer = nil
    end
end

-- 获取当前的玩法
function XFunctionModel:GetCurrentFunction()
    return self.CurrentFunction
end
--endregion

--region 入口红点

function XFunctionModel:InitEntryRedPoint(dict)
    if not dict then
        self._EntryRedPoint = {}
    else
        self._EntryRedPoint = dict
    end
end

function XFunctionModel:MarkEntryRedPoint(functionId, num)
    if not self._EntryRedPoint then
        self._EntryRedPoint = {}
    end
    self._EntryRedPoint[functionId] = num
end

function XFunctionModel:CheckEntryRedPoint(functionId)
    if not self._EntryRedPoint then
        self._EntryRedPoint = {}
    end
    local redNum = self._EntryRedPoint[functionId]
    if not redNum or redNum <= 0 then
        redNum = 0
    end
    local configNum = self:GetEntryFunctionalRedNum(functionId)
    if not configNum or configNum <= 0 then
        return false
    end
    return redNum < configNum
end

---@return XTableFunctionalEntranceConfig
function XFunctionModel:GetEntryFunctionalTemplate(functionId)
    local template = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.FunctionalEntranceConfig, functionId, true)
    return template
end

function XFunctionModel:GetEntryFunctionalRedNum(functionId)
    local t = self:GetEntryFunctionalTemplate(functionId)
    return t and t.RedPointNum or 0
end

function XFunctionModel:GetEntryFunctionalLabel(functionId)
    local t = self:GetEntryFunctionalTemplate(functionId)
    return t and t.Label or "???"
end

function XFunctionModel:GetEntryFunctionalLabelTimeId(functionId)
    local t = self:GetEntryFunctionalTemplate(functionId)
    return t and t.LabelTimeId or 0
end

--endregion

return XFunctionModel
