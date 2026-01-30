local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPacMan2Agency : XAgency
---@field private _Model XPacMan2Model
local XPacMan2Agency = XClass(XFubenActivityAgency, "XPacMan2Agency")
function XPacMan2Agency:OnInit()
    self:RegisterActivityAgency()
end

function XPacMan2Agency:InitRpc()
    XRpc.NotifyPacMan2Activity = Handler(self, self.NotifyPacMan2Activity)
end

function XPacMan2Agency:OpenMain()
    ---@type XTablePacMan2Activity
    local activityConfig = self._Model:GetActivityConfig()
    
    -- 如果没有服务端的 activityId，从配置表获取最后一条配置来做时间判断，然后返回 false
    if not activityConfig then
        local allConfigs = self._Model:GetAllActivityConfigs()
        if allConfigs and not XTool.IsTableEmpty(allConfigs) then
            -- 找到 Id 最大的配置（最后一条）
            local lastConfig = nil
            local maxId = 0
            for _, config in pairs(allConfigs) do
                if config and config.Id and config.Id > maxId then
                    maxId = config.Id
                    lastConfig = config
                end
            end
            if lastConfig and lastConfig.TimeId then
                -- 使用配置表的配置进行时间判断
                self:_ShowTimeTip(lastConfig.TimeId)
            else
                -- 如果仍然没有配置，直接提示未开放
                XUiManager.TipText("ActivityBranchNotOpen")
            end
        else
            -- 配置表为空，直接提示未开放
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    
    local timeId = activityConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        -- 判断是活动未开始还是已结束
        self:_ShowTimeTip(timeId)
        return false
    end
    XLuaUiManager.Open("UiPacMan2Main")
    return true
end

--- 显示时间提示（活动未开始或已结束）
---@param timeId number 时间ID
function XPacMan2Agency:_ShowTimeTip(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    
    if startTime > 0 and nowTime < startTime then
        -- 活动未开始
        XUiManager.TipText("ActivityBranchNotOpen")
    elseif endTime > 0 and nowTime >= endTime then
        -- 活动已结束
        XUiManager.TipText("ActivityBranchOver")
    else
        -- 其他情况（可能时间配置有问题）
        XUiManager.TipText("ActivityBranchNotOpen")
    end
end

function XPacMan2Agency:NotifyPacMan2Activity(data)
    self._Model:SetDataFromServer(data)
end

function XPacMan2Agency:PacMan2StageStartRequest(stageId, callback)
    if self._Model.IsPlaying then
        XLog.Error("[XPacMan2Agency] playing状态出错, 很麻烦")
        callback(false)
        return
    end
    XNetwork.Call("PacMan2StageStartRequest", {
        StageId = stageId
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            callback(false)
            return
        end
        self._Model.IsPlaying = true
        callback(true)
    end)
end

function XPacMan2Agency:PacMan2SettleRequest(data)
    if not self._Model.IsPlaying then
        XLog.Warning("[XPacMan2Agency] 未开始游戏")
        return
    end
    XNetwork.Call("PacMan2SettleRequest", data, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetStageData(res.StageData)
        self._Model.IsPlaying = false
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
    end)
end

function XPacMan2Agency:ExCheckInTime()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local isInTime = XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId)
    return isInTime
end

function XPacMan2Agency:HasStageNotPassedAndCanChallenge()
    local stages = self._Model:GetStageConfigs()
    for _, stage in ipairs(stages) do
        --  判断关卡是否通过
        if not self._Model:IsStagePassed(stage.Id) then
            --  判断时间
            if XFunctionManager.CheckInTimeByTimeId(stage.TimeId) then
                -- 判断前置关卡
                local preStageId = stage.PreStageId
                if preStageId == 0 or preStageId == nil or self._Model:IsStagePassed(preStageId) then
                    return true
                end
            end
        end
    end
    return false
end

return XPacMan2Agency