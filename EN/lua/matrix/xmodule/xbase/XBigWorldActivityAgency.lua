---@class XBigWorldActivityAgency : XAgency 空花活动基类
---@field _Config XTableBigWorldActivity 活动配置
local XBigWorldActivityAgency = XClass(XAgency, "XBigWorldActivityAgency")

function XBigWorldActivityAgency:SetConfig(config)
    self._Config = config
end

function XBigWorldActivityAgency:GetConfig()
    return self._Config
end

--- 活动未开放提示
---@return string
--------------------------
function XBigWorldActivityAgency:GetLockedTip()
end

--- 是否在开放时间内
---@return boolean
--------------------------
function XBigWorldActivityAgency:CheckInTime()
end

--- 是否完成
---@return boolean
--------------------------
function XBigWorldActivityAgency:IsComplete()
    local progressData = self:GetProgressTipData()

    if not XTool.IsTableEmpty(progressData) then
        for _, data in pairs(progressData) do
            if not data.IsComplete then
                return false
            end
        end
    end

    return true
end

--- 活动进度提示
---@return string[]
--------------------------
function XBigWorldActivityAgency:GetProgressTips()
end

--- 活动进度提示数据
--------------------------
function XBigWorldActivityAgency:GetProgressTipData()
end

--- 活动Name
---@return string
--------------------------
function XBigWorldActivityAgency:GetName()
end

--- 活动奖励
--------------------------
function XBigWorldActivityAgency:GetRewards()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        return XMVCA.XBigWorldGamePlay:GetBigWorldActivityGoodsByActivityId(activityId)
    end

    return nil
end

--- 活动教程
--------------------------
function XBigWorldActivityAgency:GetTeachId()
end

--- 关卡Id
---@return number
function XBigWorldActivityAgency:GetLevelId()
    local config = self:GetConfig()
    return config and config.LevelId or 0
end

--- 玩法活动Id
---@return number
function XBigWorldActivityAgency:GetActivityId()
    local config = self:GetConfig()
    return config and config.Id or 0
end

--- 打开玩法主界面
---@vararg
--------------------------
function XBigWorldActivityAgency:OpenMainUi(...)
end

--- 判断玩法
---@param 
---@return 
function XBigWorldActivityAgency:CheckFunctionOpen()
    return true
end

--- 进入关卡
function XBigWorldActivityAgency:OnEnterLevel()
end

-- 加载完成后回调
function XBigWorldActivityAgency:OnLevelBeginUpdate()
end

--- 退出关卡
function XBigWorldActivityAgency:OnLeaveLevel()
end

--- 判断当前所处关卡是否处于活动关卡
---@return boolean
function XBigWorldActivityAgency:IsEnterLevel()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return false
    end
    return XMVCA.XBigWorldGamePlay:GetCurrentLevelId() == self:GetLevelId()
end

--- 注册活动
--------------------------
function XBigWorldActivityAgency:RegisterActivityAgency()
    XMVCA.XBigWorldGamePlay:RegisterActivityAgency(self)
end

return XBigWorldActivityAgency
