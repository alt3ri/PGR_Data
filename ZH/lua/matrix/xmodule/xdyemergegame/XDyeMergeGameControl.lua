---@class XDyeMergeGameControl : XControl
---@field private _Model XDyeMergeGameModel
local XDyeMergeGameControl = XClass(XControl, "XDyeMergeGameControl", true)
--部分类require
XClassPartialRequire("XModule/XDyeMergeGame/XDyeMergeGameConfigControl", "XDyeMergeGameControl")

function XDyeMergeGameControl:OnInit()
    --初始化内部变量
    self:InitConfig()
    
    self.EnumConst = {
        UIInputTypes = {
            SelectStage = 1,
            ClickHelp = 2, -- 点击图文
            ClickBack = 3, -- 点击返回
            GamingClickReset = 4, -- 点击重置关卡
            GamingClickTips = 5, -- 点击关卡提示
            GamingClickGrid = 6, -- 点击格子上的方块
            GamingClickFloor = 7, -- 点击地板格
        },
    }
    
    self:StartActivityTimer()
end

function XDyeMergeGameControl:AddAgencyEvent()

end

function XDyeMergeGameControl:RemoveAgencyEvent()

end

function XDyeMergeGameControl:OnRelease()
    self:StopActivityTimer()
end

function XDyeMergeGameControl:EnterGame(stageId)
    self:_InitGamingControl() 
    self.GamingControl:InitGame(stageId)
    self._Model:CacheCurGamingStageId(stageId)
end

--- 切换关卡：已在游戏中时复用 GamingControl，否则走完整初始化
function XDyeMergeGameControl:EnterStage(stageId)
    if self.GamingControl then
        self.GamingControl:ResetGame(stageId)
        self._Model:CacheCurGamingStageId(stageId)
    else
        self:EnterGame(stageId)
    end
end

function XDyeMergeGameControl:ExitGame()
    if self.GamingControl then
        self.GamingControl:RecordExitResult()
    end
    self:_ReleaseGamingControl()
    self._Model:CacheCurGamingStageId(nil)
end

function XDyeMergeGameControl:_InitGamingControl()
    self:_ReleaseGamingControl()
    
    ---@type XDyeMergeGamingControl
    self.GamingControl = self:AddSubControl(require("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeGamingControl"))
end

function XDyeMergeGameControl:_ReleaseGamingControl()
    if self.GamingControl then
        self:RemoveSubControl(self.GamingControl)
        self.GamingControl = nil
    end
end

--region 蓝点

function XDyeMergeGameControl:MarkNewChapter(chapterId)
    self._Model:MarkNewChapter(chapterId)
end

--endregion

--region 活动时间定时器

function XDyeMergeGameControl:StopActivityTimer()
    if self._ActivityTimerId then
        XScheduleManager.UnSchedule(self._ActivityTimerId)
        self._ActivityTimerId = nil
    end
    self._TimeTickOutCallBack = nil
end

function XDyeMergeGameControl:StartActivityTimer()
    self:StopActivityTimer()

    self:UpdateActivityTimer()

    self._ActivityTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityTimer), XScheduleManager.SECOND)
end

function XDyeMergeGameControl:GetIsActivityTimerStart()
    return XTool.IsNumberValidEx(self._ActivityTimerId)
end

function XDyeMergeGameControl:UpdateActivityTimer()
    local activityCfg = XMVCA.XDyeMergeGame:GetCurActivityCfg(true)
    
    if not activityCfg then
        goto TICK_OUT
    end

    if XTool.IsNumberValidEx(activityCfg.TimeId) then
        self:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ACTIVITY_TIMER_UPDATE, activityCfg.TimeId)
    end

    if not XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
        goto TICK_OUT
    else
        return
    end

    :: TICK_OUT::

    if self:TryDoTimeTickOut() then
        self:StopActivityTimer()
    end
end

function XDyeMergeGameControl:TryDoTimeTickOut()
    if self._IsLockTimeTickOut then
        return false
    end

    if self._TimeTickOutCallBack then
        self._TimeTickOutCallBack()
    else
        -- 检查有没有引导
        if XDataCenter.GuideManager.CheckIsInGuide() then
            -- 结束引导
            XDataCenter.GuideManager.ResetGuide()
        end
        XLuaUiManager.RunMain()

        XUiManager.TipText('ActivityMainLineEnd')
    end

    return true
end

function XDyeMergeGameControl:LockActivityTimerTickOut()
    self._IsLockTimeTickOut = true
end

function XDyeMergeGameControl:UnLockActivityTimerTickOut()
    self._IsLockTimeTickOut = false
end

function XDyeMergeGameControl:SetTimeTickOutCallBack(cb)
    self._TimeTickOutCallBack = cb
end

function XDyeMergeGameControl:AddTimeEventListener(func, obj)
    self:AddEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE, func, obj)

    -- 注册监听后立刻刷新一次
    if self:GetIsActivityTimerStart() then
        self:UpdateActivityTimer()
    end
end

function XDyeMergeGameControl:RemoveTimeEventListener(func, obj)
    self:RemoveEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_ACTIVITY_TIMER_UPDATE, func, obj)
end
--endregion

return XDyeMergeGameControl