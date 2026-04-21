local MathFloor = math.floor
local mathSin = math.sin
local pi = math.pi
local CSTime = CS.UnityEngine.Time

---@class XMovieActionBgShake
---@field UiRoot XUiMovie
local XMovieActionBgShake = XClass(XMovieActionBase, "XMovieActionBgShake")

---@param actionData XTableMovieNew
function XMovieActionBgShake:OnInit(actionData)
    local params = actionData.Params
    local offsetParam = XMVCA.XMovie:SplitParam(params[1], "|", true) -- X、Y、Z三个方向的振动幅度
    self.OffsetX = offsetParam[1]
    self.OffsetY = offsetParam[2]
    self.OffsetZ = offsetParam[3]
    self.IsTwoSide = params[2] == "1" -- 是否是双向运动
    self.Time = XMVCA.XMovie:ParamToNumber(params[3]) -- 一个周期振动的时间
    self.LoopCount = XMVCA.XMovie:ParamToNumber(params[4]) -- 0为一直循环
    self.OffsetReduce = XMVCA.XMovie:SplitParam(params[5], "|", true) -- 一个周期后减少幅度
    self.IsClose = params[6] == "1"
    self.BgIds = XMVCA.XMovie:SplitParam(params[7], "|", true)
    self.ActorIds = XMVCA.XMovie:SplitParam(params[8], "|", true)
    self.TextIds = XMVCA.XMovie:SplitParam(params[9], "|")
end

function XMovieActionBgShake:OnRunning()
    if self.IsClose then
        self.UiRoot:RemoveShakeTimer()
    else
        self.UiRoot:SetShakeAction(self)
        self.StartTime = CSTime.realtimeSinceStartup
        self:RemoveShakeTimer()
        self.ShakeTimer = XScheduleManager.ScheduleForever(function()
            self:OnShakeUpdate()
        end, 0)
    end
end

function XMovieActionBgShake:OnShakeUpdate()
    local passSecond = CSTime.realtimeSinceStartup - self.StartTime
    local v =  passSecond / self.Time
    local loopCount = MathFloor(v)
    local progress = v - loopCount
    
    -- 配置指定循环次数，并且达到循环次数，结束振动
    if self.LoopCount ~= 0 and loopCount >= self.LoopCount then
        self:OnShakeEnd()
        return
    end

    -- 更新目标位置
    local targetPosX, targetPosY, targetPosZ = self.OffsetX, self.OffsetY, self.OffsetZ
    if #self.OffsetReduce > 0 then
        targetPosX = self:ReduceOffset(targetPosX, self.OffsetReduce[1] * loopCount)
        targetPosY = self:ReduceOffset(targetPosY, self.OffsetReduce[2] * loopCount)
        targetPosZ = self:ReduceOffset(targetPosZ, self.OffsetReduce[3] * loopCount)
        
        -- 目标位置递减都变成0，结束振动
        if targetPosX == 0 and targetPosY == 0 and targetPosZ == 0 then
            self:OnShakeEnd()
            return
        end
    end
    
    local sinValue = self.IsTwoSide and mathSin(2 * pi * progress) or mathSin(pi * progress)
    self:SetPosition(targetPosX * sinValue, targetPosY * sinValue, targetPosZ * sinValue)
end

---@return number 减掉衰减后的值
function XMovieActionBgShake:ReduceOffset(value, reduce)
    if value > 0 and value - reduce > 0 then
        return value - reduce
    elseif value < 0 and value + reduce < 0 then
        return value + reduce
    end
    return 0
end

-- 设置位置
function XMovieActionBgShake:SetPosition(x, y, z)
    self.TempPos = self.TempPos or XLuaVector3.New(0, 0, 0)
    self.TempPos.x = x
    self.TempPos.y = y
    self.TempPos.z = z

    -- 背景
    if #self.BgIds > 0 then
        for _, bgId in pairs(self.BgIds) do
            local gridBg = self.UiRoot.UiMovieBg:GetBg(bgId)
            gridBg:SetBgRootLocalPosition(self.TempPos)
        end
    end
    -- 角色
    if #self.ActorIds > 0 then
        for _, actorId in pairs(self.ActorIds) do
            local gridActor = self.UiRoot:GetActor(actorId)
            gridActor:SetActorRootLocalPosition(self.TempPos)
        end
    end

    -- 文本移动
    if #self.TextIds > 0 then
        local uiPanelText = self.UiRoot:GetUiPanelText()
        for _, textId in pairs(self.TextIds) do
            uiPanelText:SetTextRootLocalPosition(textId, self.TempPos)
        end
    end
end

function XMovieActionBgShake:OnShakeEnd()
    self:SetPosition(0, 0, 0)
    self:RemoveShakeTimer()
end

function XMovieActionBgShake:RemoveShakeTimer()
    if self.ShakeTimer then
        XScheduleManager.UnSchedule(self.ShakeTimer)
        self.ShakeTimer = nil
    end
end

function XMovieActionBgShake:IsPassedActionRun(index)
    -- 关闭背景组/非循环的背景组，跳过都不执行
    if self.IsClose or self.LoopCount ~= 0 then return false end

    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBgShake:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return action.IsClose
    end
    return false
end

function XMovieActionBgShake:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionBgShake