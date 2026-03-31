local ActionStatus = {
    UNINITIALIZED = "UNINITIALIZED",
    ENTER = "ENTER",
    RUNNING = "RUNNING",
    BLOCK = "BLOCK",
    EXIT = "EXIT",
    TERMINATED = "TERMINATED"
}

---@class XMovieActionBase
---@field UiRoot XUiMovie
XMovieActionBase = XClass(nil, "XMovieActionBase")

function XMovieActionBase:Ctor(actionData)
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Params = actionData.Params
    self.Status = ActionStatus.UNINITIALIZED
    self.ActionId = actionData.ActionId
    self.IsActionBlock = paramToNumber(actionData.IsBlock) ~= 0
    self.IsEnd = actionData.IsEnd ~= 0
    self.NextActionId = actionData.NextActionId
    self.BeginAnim = actionData.BeginAnim
    self.EndAnim = actionData.EndAnim
    self.BeginDelay = actionData.BeginDelay
    self.EndDelay = actionData.EndDelay
    self.Type = actionData.Type

    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_OPEN, self.InitUiRoot, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_DESTROY, self.ClearUiRoot, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_AUTO_PLAY, self.OnSwitchAutoPlay, self)
    
    self:OnInit(actionData)
end

function XMovieActionBase:Release()
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_UI_OPEN, self.InitUiRoot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_UI_DESTROY, self.ClearUiRoot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_AUTO_PLAY, self.OnSwitchAutoPlay, self)
    self:OnRelease()
end

function XMovieActionBase:GetActionId()
    return self.ActionId
end

function XMovieActionBase:GetParams()
    return self.Params
end

function XMovieActionBase:GetNextActionId()
    return self.NextActionId
end

function XMovieActionBase:GetSelectedActionId()
    return 0
end

function XMovieActionBase:GetDelaySelectActionId()
    return 0
end

function XMovieActionBase:GetResumeActionId()
    return 0
end

function XMovieActionBase:GetBeginAnim()
    return self.BeginAnim
end

function XMovieActionBase:GetEndAnim()
    return self.EndAnim
end

function XMovieActionBase:GetBeginDelay()
    return self.BeginDelay
end

function XMovieActionBase:GetEndDelay()
    return self.EndDelay
end

function XMovieActionBase:GetType()
    return self.Type
end

function XMovieActionBase:IsBlock()
    return self.IsActionBlock
end

function XMovieActionBase:IsEnding()
    return self.IsEnd
end

function XMovieActionBase:IsWaiting()
    return self.Lock
end

function XMovieActionBase:InitUiRoot(uiRoot)
    self.UiRoot = uiRoot
    self:OnUiRootInit(uiRoot)
end

function XMovieActionBase:ClearUiRoot()
    self.UiRoot = {}
    self:ClearDelayId()
    self.Status = ActionStatus.UNINITIALIZED
    self:OnUiRootDestroy()
end

function XMovieActionBase:Enter()
    if self.Status ~= ActionStatus.ENTER then
        return
    end
    self:OnEnter()
    self:ChangeStatus(self:GetBeginDelay(), self:GetBeginAnim())
end

function XMovieActionBase:BlockSelf()
    if self.Status ~= ActionStatus.BLOCK then
        return
    end
end

function XMovieActionBase:Run()
    if self.Status ~= ActionStatus.RUNNING then
        return
    end
    self:OnRunning()
    self:ChangeStatus()
    -- 调试模式发送
    if CS.XApplication.Debug then
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_NEXT, self)
    end
end

function XMovieActionBase:Exit()
    if self.Status ~= ActionStatus.EXIT then
        return
    end
    self:ChangeStatus(self:GetEndDelay(), self:GetEndAnim())
end

function XMovieActionBase:Destroy()
    if self.Status ~= ActionStatus.TERMINATED then
        return
    end

    --self.Status = ActionStatus.UNINIIALIZED
    self:OnDestroy()
    return true
end

function XMovieActionBase:ChangeStatus(delay, animName)
    self.Lock = true

    local changeFunc = function()
        self.Lock = nil
        if XTool.UObjIsNil(self.UiRoot.GameObject) then
            return
        end

        if self.Status == ActionStatus.UNINITIALIZED then
            self.Status = ActionStatus.ENTER
            self:Enter()
        elseif self.Status == ActionStatus.ENTER then
            self.Status = ActionStatus.RUNNING
            self:Run()
        elseif self.Status == ActionStatus.RUNNING then
            if self:IsBlock() then
                self.Status = ActionStatus.BLOCK
                self:BlockSelf()
            else
                self.Status = ActionStatus.EXIT
                self:Exit()
            end
        elseif self.Status == ActionStatus.BLOCK then
            self.Status = ActionStatus.EXIT
            self:Exit()
        elseif self.Status == ActionStatus.EXIT then
            self.Status = ActionStatus.TERMINATED
            self:OnExit()
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
        end
    end

    local animCb = function()
        if delay and delay ~= 0 then
            self.DelayId = self.DelayId or XScheduleManager.ScheduleOnce(function()
                self.DelayId = nil
                changeFunc()
            end, delay)
        else
            changeFunc()
        end
    end

    if animName and animName ~= "NoAnim" then
        if XTool.UObjIsNil(self.UiRoot.GameObject) then
            return
        end

        local anim = self.UiRoot:GetUiAnimation(animName)
        if not anim then
            XLog.Error("animName配置错误，找不到" .. animName .. "对应的动画，请检查节点: " .. self.ActionId)
            animCb()
            return
        end

        self:StopAnimtion(anim)
        anim.gameObject:SetActiveEx(true)
        if not anim.gameObject.activeInHierarchy then
            XLog.Warning(string.format("动画%s当前activeInHierarchy为false，直接跳过播放动画执行回调！", animName))
            animCb()
            return
        end
        anim:PlayTimelineAnimation(
                function()
                    XLuaUiManager.SetMask(false)
                    anim.gameObject:SetActiveEx(false)
                    animCb()
                end,
                function()
                    XLuaUiManager.SetMask(true)
                end
        )
    else
        animCb()
    end
end

function XMovieActionBase:ClearDelayId()
    if self.DelayId then
        XScheduleManager.UnSchedule(self.DelayId)
        self.DelayId = nil
    end
    self.Lock = false
end

--region 继承类重写函数
function XMovieActionBase:OnUiRootInit()
    
end

function XMovieActionBase:OnUiRootDestroy()
    
end

function XMovieActionBase:OnInit(actionData)

end

function XMovieActionBase:OnEnter()
    
end

function XMovieActionBase:OnRunning()
    
end

function XMovieActionBase:OnExit()
    -- 请求记录当前ActionId已读
    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    XMVCA.XMovie:RequestRecordOption(movieId, self.ActionId)
end

-- 节点切换ActionStatus.TERMINATED 状态时调用
function XMovieActionBase:OnDestroy()
    
end

-- 剧情播放结束时调用
function XMovieActionBase:OnRelease()

end

function XMovieActionBase:OnSwitchAutoPlay()
    
end

function XMovieActionBase:OnUndo()

end

function XMovieActionBase:OnReset()
    self.Status = ActionStatus.UNINITIALIZED
end
--endregion

function XMovieActionBase:CanContinue()
    return true
end

-- 停止动画，触发结束回调
function XMovieActionBase:StopAnimtion(anim)
    local timelineAnimation = anim.transform:GetComponent(typeof(CS.XUiPlayTimelineAnimation))
    if timelineAnimation then
        timelineAnimation:Stop(false)
    end
end

--region PassAction 跳到某个节点开始播放，前面Action需要执行的函数

-- 是走Run还是Skip函数
-- 跳过：后续Action覆盖/后续Action关闭显示，不需要刷新UI，只做数据记录
function XMovieActionBase:IsPassedActionRun(index)
    return false
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBase:IsPassedActionCovered(action)
    XLog.Error(string.format("Action Type %s 未实现IsPassedActionCovered函数!", self.Type))
    return false
end

-- 是否导致开始播的Action提前
function XMovieActionBase:IsAdvanceStartAction()
    return false
end

-- 作为跳过Action执行
function XMovieActionBase:OnPassedActionExecute(index)
    if self:IsPassedActionRun(index) then
        self:OnPassedActionRun()
    else
        self:OnPassedActionSkip()
    end
end

-- 执行Action的UI刷新
function XMovieActionBase:OnPassedActionRun()

end

-- 跳过Action的UI刷新
function XMovieActionBase:OnPassedActionSkip()

end

-- 当此Action为跳过Actions之后的第一个时，需要判断这个Action是否在PanelLoading之后执行
function XMovieActionBase:IsStartAfterLoading()
    return false
end

--endregion

return XMovieActionBase
