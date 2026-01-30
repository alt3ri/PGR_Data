local XUiBaseComponent = require('XUi/XUiCommon/XUiBaseComponent')

--- 单纯对XUiButton的封装，以支持FunctionalShow相关控制，因此不继承XUiNode
---@class XUiFunctionShowBtn: XUiBaseComponent
local XUiFunctionShowBtn = XClass(XUiBaseComponent, 'XUiFunctionShowBtn')

function XUiFunctionShowBtn:Ctor(rootUi, uiButton)
    ---@type XUiComponent.XUiButton
    self._Button = uiButton
    self._Button:AddEventListener(handler(self, self._OnButtonClickEvent))
    
    -- 检查UI是否挂载了该组件，如果有，那么配置Id以组件上的配置为主
    ---@type XUiComponent.XFunctionShowControl
    self.ComFunctionShowControl = self.Transform:GetComponent(typeof(CS.XUiComponent.XFunctionShowControl))

    if self.ComFunctionShowControl then
        self.Id = self.ComFunctionShowControl.Id

        -- 如果该组件启用了lua代理，则需要注册刷新方法
        if self.ComFunctionShowControl.IsEnableLuaProxy then
            self.ComFunctionShowControl.AOPLuaOnRefreshSelf = handler(self, self.RefreshShowState)
            self.ComFunctionShowControl.LuaOnCheckShowValid = handler(self, self.CheckIsShowValid)
        end

        -- 初始化事件监听
        self:InitShowStateEvent()
    end

    self:CheckIsCanShow()

    -- 红点事件相关
    self._CommonReddotEventId = nil     -- 通用模块的红点事件Id
    self._AdditionReddotEventIds = nil  -- 额外注册的红点事件Id
    self._ReddotEventId2ShowStateMap = { }  -- 红点事件Id-红点显示映射
    self._ReddotIndex2EventId = { } -- 红点事件注册顺序索引-红点事件Id映射

    self._ReddotIndexPool = 1

    self:_AddFunctionShowReddotEvent()

    self._StartRun = true

    -- 额外的解锁控制，默认解锁
    self._ExUnlockCommand = true
end

function XUiFunctionShowBtn:SetId(id, force)
    local isSetSuccess = false

    local oldId = self.Id

    if force then
        self.Id = id
        isSetSuccess = true
    elseif not XTool.IsNumberValidEx(self.Id) then
        self.Id = id
        isSetSuccess = true
    end

    if isSetSuccess then
        -- 需要更换红点事件
        if XTool.IsNumberValidEx(self._CommonReddotEventId) then
            self:RemoveRedPointEvent(self._CommonReddotEventId)
            self._CommonReddotEventId = nil
        end
        self:_AddFunctionShowReddotEvent()

        -- 刷新事件监听
        self:ReleaseShowStateEvent(oldId)
        self:InitShowStateEvent()
    end
end

function XUiFunctionShowBtn:RefreshAll()
    self:CheckIsCanShow()
    self:RefreshShowState()
    self:RefreshUnlockState()
    self:RefreshReddot()
end

--region 红点相关

function XUiFunctionShowBtn:ReleaseReddotEvents()
    if XTool.IsNumberValidEx(self._CommonReddotEventId) then
        XRedPointManager.RemoveRedPointEvent(self._CommonReddotEventId)
        self._CommonReddotEventId = nil
    end

    if not XTool.IsTableEmpty(self._AdditionReddotEventIds) then
        for i, v in pairs(self._AdditionReddotEventIds) do
            if XTool.IsNumberValidEx(v) then
                XRedPointManager.RemoveRedPointEvent(v)
            end
        end

        self._AdditionReddotEventIds = nil
        self._ReddotEventId2ShowStateMap = { }
        self._ReddotIndex2EventId = { }
    end
end

--- 添加系统额外的红点监听
function XUiFunctionShowBtn:AddAdditionRedPointEvent(conditionGroup, args, isCheck)
    if self._Button then
        local index = self:_GetReddotIndex()

        local reddotEventId = XRedPointManager.AddRedPointEvent(self._Button, function(count)
            local eventId = self._ReddotIndex2EventId[index]
            local isShow = count >= 0

            if XTool.IsNumberValid(eventId) then
                self._ReddotEventId2ShowStateMap[eventId] = isShow

                self:_OnReddotEvent()
            else
                -- 其他原因没有找到，或处于初始化阶段还没注册，则直传显隐状态
                self:_OnReddotEvent(isShow)
            end
        end, nil, conditionGroup, args, isCheck)

        if self._AdditionReddotEventIds == nil then
            self._AdditionReddotEventIds = {}
        end

        table.insert(self._AdditionReddotEventIds, reddotEventId)

        self._ReddotIndex2EventId[index] = reddotEventId
    end
end

--- 外部手动移除红点
function XUiFunctionShowBtn:RemoveAdditionRedPointEvent(redEventId)
    if XTool.IsTableEmpty(self._AdditionReddotEventIds) then
        return
    end

    local isIn, index = table.contains(self._AdditionReddotEventIds, redEventId)

    if isIn then
        self:RemoveRedPointEvent(redEventId)
        table.remove(self._AdditionReddotEventIds, index)
    end
end

--- 外部手动设置红点显示，而不是通过红点事件
function XUiFunctionShowBtn:SetReddotShow(isShow)
    self:_OnReddotEvent(isShow)
end

--- 外部手动刷新红点显示
function XUiFunctionShowBtn:RefreshReddot()
    self:_RefreshReddotShow()
end

function XUiFunctionShowBtn:_AddFunctionShowReddotEvent()
    if XTool.IsNumberValidEx(self.Id) then
        local cfg = XFunctionConfig.GetFunctionalShowCfg(self.Id)

        if cfg then
            if self._Button and not XTool.IsTableEmpty(cfg.RedPointConditions) then
                self._CommonReddotEventId = XRedPointManager.AddRedPointEvent(self._Button, self._OnCommonReddotEvent, self, cfg.RedPointConditions, cfg.RedPointArgs)
            end
        end
    end
end

function XUiFunctionShowBtn:_RefreshReddotShow()
    if XTool.IsNumberValid(self._CommonReddotEventId) then
        XRedPointManager.Check(self._CommonReddotEventId)
    end

    if not XTool.IsTableEmpty(self._AdditionReddotEventIds) then
        for i, reddotEventId in pairs(self._AdditionReddotEventIds) do
            XRedPointManager.Check(reddotEventId)
        end
    end
end

function XUiFunctionShowBtn:_GetReddotIndex()
    local index = self._ReddotIndexPool

    self._ReddotIndexPool = self._ReddotIndexPool + 1

    return index
end

function XUiFunctionShowBtn:_OnCommonReddotEvent(count)
    if self._Button then
        local isShow = count >= 0

        if XTool.IsNumberValid(self._CommonReddotEventId) then
            self._ReddotEventId2ShowStateMap[self._CommonReddotEventId] = isShow

            self:_OnReddotEvent()
        else
            -- 其他原因没有找到，或处于初始化阶段还没注册，则直传显隐状态
            self:_OnReddotEvent(isShow)
        end
    end
end

function XUiFunctionShowBtn:_OnReddotEvent(isShow)
    if self._Button then
        -- 隐藏、锁定时不显示红点
        if not self:GetIsCanShow() or self._Button.ButtonState == CS.UiButtonState.Disable then
            self._Button:ShowReddot(false)
            return
        end

        -- 先判断缓存里是否有显示
        if not XTool.IsTableEmpty(self._ReddotEventId2ShowStateMap) then
            for i, v in pairs(self._ReddotEventId2ShowStateMap) do
                if v then
                    self._Button:ShowReddot(true)
                    return
                end
            end
        end

        -- 否则检查是否有直传的显隐状态
        if type(isShow) == 'boolean' then
            self._Button:ShowReddot(isShow)
            return
        end

        self._Button:ShowReddot(false)
    end
end

--endregion

--region 点击响应相关

--- 注册系统自己的点击回调，该回调在通用解锁判定通过后调用
function XUiFunctionShowBtn:AddButtonClickEvent(clickEvent)
    self._ClickEvent = clickEvent
end

function XUiFunctionShowBtn:_OnButtonClickEvent()
    local unlock, desc = self:CheckIsUnlock()

    if not unlock then
        XUiManager.TipMsg(desc)
        return
    end

    if self._ClickEvent then
        local success = self._ClickEvent()

        if success then
            self:_AfterClickSuccess()
        end
    end
end

function XUiFunctionShowBtn:_AfterClickSuccess()
    -- 检查是否有新手
    local cfg = XFunctionConfig.GetFunctionalShowCfg(self.Id)

    if cfg and table.contains(cfg.RedPointConditions, 'CONDITION_COMMON_FUNCTION_SHOW') then
        -- 如果配置了新手，并且参数id与自己一致，点击后消除红点
        if cfg.RedPointArgs[1] == self.Id and cfg.RedPointArgs[2] == XFunctionConfig.RedPointType.NewbieFirstShow then
            XPlayerManager.RequestRecordPlayerPoint(self.Id, XFunctionConfig.RedPointType.NewbieFirstShow)
        end
    end
end
--endregion

--region 解锁状态显示相关

--- 其他外部逻辑无状态显隐设置
function XUiFunctionShowBtn:SetActiveByHand(isShow)
    if self.ComFunctionShowControl then
        self.ComFunctionShowControl:SetActiveEx(isShow)
    else
        self._ShowCommand = isShow
    end

    if isShow and self:GetIsCanShow() then
        self:_Open()
    else
        self:_Close()
    end
end

function XUiFunctionShowBtn:SetUnlockByHand(isUnlock)
    self._ExUnlockCommand = isUnlock

    self:RefreshUnlockState()
end

function XUiFunctionShowBtn:InitShowStateEvent()
    if XTool.IsNumberValid(self.Id) then
        local cfg = XFunctionConfig.GetFunctionalShowCfg(self.Id)

        if cfg and not XTool.IsTableEmpty(cfg.EventIds) then
            for i, eventId in pairs(cfg.EventIds) do
                XEventManager.AddEventListener(eventId, self.RefreshStateOnEvent, self)
            end
        end
    end
end

function XUiFunctionShowBtn:ReleaseShowStateEvent(id)
    id = id or self.Id

    if XTool.IsNumberValid(id) then
        local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

        if cfg and not XTool.IsTableEmpty(cfg.EventIds) then
            for i, eventId in pairs(cfg.EventIds) do
                XEventManager.RemoveEventListener(eventId, self.RefreshStateOnEvent, self)
            end
        end
    end
end

function XUiFunctionShowBtn:GetIsCanShow()
    return self._IsShow
end

function XUiFunctionShowBtn:CheckIsCanShow()
    if XTool.IsNumberValid(self.Id) then
        self._IsShow = XFunctionManager.CheckUiNodeIsShowByFunctionShowId(self.Id)
        self:_SetImpIsShow()
        return self._IsShow
    end

    self._IsShow = true
    self:_SetImpIsShow()

    return true
end

function XUiFunctionShowBtn:_SetImpIsShow()
    if self.ComFunctionShowControl then
        self.ComFunctionShowControl:SetFunctionOpenStateByProxy(self._IsShow)
    end
end

function XUiFunctionShowBtn:CheckIsUnlock()
    if XTool.IsNumberValidEx(self.Id) then
        return XFunctionManager.CheckUiNodeIsUnlockByFunctionShowId(self.Id)
    end

    return true
end

function XUiFunctionShowBtn:CheckIsShowValid()
    if not self:GetIsCanShow() then
        self:_EndDelayCloseTimer()
        self._DelayCloseTimerId = XScheduleManager.ScheduleOnce(handler(self, self._DelayClose))
        return false
    end

    return true
end

function XUiFunctionShowBtn:RefreshStateOnEvent()
    self:RefreshShowState()
    self:RefreshUnlockState()
end

function XUiFunctionShowBtn:RefreshShowState()
    if self:CheckIsCanShow() then
        self:_Open()
    else
        self:_Close()
    end
end

function XUiFunctionShowBtn:RefreshUnlockState()
    if not self:GetIsCanShow() then
        return
    end

    if self._Button then
        local isUnlock = self:CheckIsUnlock() and self._ExUnlockCommand
        self._Button:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

function XUiFunctionShowBtn:_EndDelayCloseTimer()
    if self._DelayCloseTimerId then
        XScheduleManager.UnSchedule(self._DelayCloseTimerId)
        self._DelayCloseTimerId = nil
    end
end

function XUiFunctionShowBtn:_DelayClose()
    self:_Close()
end
--endregion

function XUiFunctionShowBtn:_Close()
    self.GameObject:SetActiveEx(false)
end

function XUiFunctionShowBtn:_Open()
    self.GameObject:SetActiveEx(true)
    
    self:RefreshUnlockState()
    self:RefreshReddot()
end


return XUiFunctionShowBtn