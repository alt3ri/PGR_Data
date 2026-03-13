---@class XAprilFoolDayModel : XModel
local XAprilFoolDayModel = XClass(XModel, "XAprilFoolDayModel")

local TableNormal = {
    FoolsDayMainInterface = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    FoolsDayActivityBroadcast = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    FoolsDayClearOut = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

function XAprilFoolDayModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self.TempWholeDic = {} -- 临时存放的字典
    
    --2026愚人节服务端数据
    self._ActivityId = nil
    self._IsAtkComplete = nil

    self._ConfigUtil:InitConfigByTableKey('MiniActivity/FoolsDayClearOut', TableNormal, XConfigUtil.CacheType.Normal)
    
    self._ActivityBroadcastEnableTimeId = CS.XGame.ClientConfig:GetInt('ActivityBroadcastEnableTimeId') or 0
    self._ActivityBroadcastCheckIntervalTime = CS.XGame.ClientConfig:GetInt('ActivityBroadcastCheckIntervalTime') or 1
end

function XAprilFoolDayModel:ClearPrivate()
    
end

function XAprilFoolDayModel:ResetAll()
    self._ActivityId = nil
    self._IsAtkComplete = nil
end

function XAprilFoolDayModel:UpdateClearOutData(data)
    self._ActivityId = data.ActivityId
    self._IsAtkComplete = data.IsAtkComplete
end

function XAprilFoolDayModel:SetIsComplete(complete)
    self._IsAtkComplete = complete
end

function XAprilFoolDayModel:Check2026ActivityIsOpen()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.AprilFoolsDayClearOut, true, true) then
        return false
    end

    if XTool.IsNumberValidEx(self._ActivityId) then
        if self._IsAtkComplete then
            return false
        end

        local cfg = self:GetFoolsDayClearOutCfgById(self._ActivityId)

        if cfg then
            return XFunctionManager.CheckInTimeByTimeId(cfg.TimeId, false)
        end
    end
    
    return false
end

--- 检查踢飞次数是否达最大
function XAprilFoolDayModel:CheckClearOutIsMax()
    local curTimes = self:GetPlayerTickOutTimes()
    local targetTime = self:GetCurActivityTargetTickoutTimes()

    if XTool.IsNumberValidEx(targetTime) then
        return curTimes >= targetTime
    end
    
    return true
end

function XAprilFoolDayModel:GetCurActivityId()
    return self._ActivityId or 0
end

function XAprilFoolDayModel:GetCurActivityTargetTickoutTimes()
    if XTool.IsNumberValidEx(self._ActivityId) then
        local cfg = self:GetFoolsDayClearOutCfgById(self._ActivityId)

        if cfg then
            return cfg.NeedAtkTimes
        end
    end
end

function XAprilFoolDayModel:GetClientConfigActivityBroadcastEnableTimeId()
    return self._ActivityBroadcastEnableTimeId
end

function XAprilFoolDayModel:GetClientConfigActivityBroadcastCheckIntervalTime()
    return self._ActivityBroadcastCheckIntervalTime
end

---@return XTableFoolsDayClearOut
function XAprilFoolDayModel:GetFoolsDayClearOutCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.FoolsDayClearOut, id)
end

---@return XTableFoolsDayMainInterface
function XAprilFoolDayModel:GetFoolsDayMainInterfaceConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.FoolsDayMainInterface, id)
end

---@return XTableFoolsDayActivityBroadcast[]
function XAprilFoolDayModel:GetFoolsDayActivityBroadcastCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.FoolsDayActivityBroadcast)
end

---@return XTableFoolsDayActivityBroadcast
function XAprilFoolDayModel:GetFoolsDayActivityBroadcastCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.FoolsDayActivityBroadcast, id)
end

--- 获取本地缓存，愚人节踢飞次数
function XAprilFoolDayModel:GetPlayerTickOutTimes()
    return self._SaveUtil:GetData('TickOutTimes') or 0
end

--- 愚人节踢飞次数 + 1到本地缓存
function XAprilFoolDayModel:AddPlayerTickOutTimes()
    local lastTimes = self:GetPlayerTickOutTimes()
    local newTimes = lastTimes + 1
    
    self._SaveUtil:SaveData('TickOutTimes', newTimes)
    
    return newTimes
end

--- 愚人节飘窗刷新时间缓存
function XAprilFoolDayModel:SetBroadcastShowTime(id, time)
    self._SaveUtil:SaveData('BroadcastShowTime_' .. tostring(id), time)
end

--- 获取愚人节指定飘窗上次显示的时间
function XAprilFoolDayModel:GetBroadcastLastShowTime(id)
    return self._SaveUtil:GetData('BroadcastShowTime_' .. tostring(id)) or 0
end

return XAprilFoolDayModel