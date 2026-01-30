local XUiFunctionShowNode = require('XUi/XUiCommon/XUiFunctionShow/XUiFunctionShowNode')

--- UI节点显隐控制、锁定控制、红点控制通用组件，使用通用配置表
---@class XUiFunctionShowControl: XUiNode
local XUiFunctionShowControl = XClass(XUiFunctionShowNode, 'XUiFunctionShowControl')

function XUiFunctionShowControl:OnStart()
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
    
    ---@type XUiComponent.XUiButton
    self._Button = self.Transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
    
    -- 如果控制的是XUiButton组件，则注册点击事件、红点事件
    if self._Button then
        self._Button:AddEventListener(handler(self, self._OnButtonClickEvent))
    end
    
    -- 红点事件相关
    self._CommonReddotEventId = nil     -- 通用模块的红点事件Id
    self._AdditionReddotEventIds = nil  -- 额外注册的红点事件Id
    self._ReddotEventId2ShowStateMap = { }  -- 红点事件Id-红点显示映射
    self._ReddotIndex2EventId = { } -- 红点事件注册顺序索引-红点事件Id映射
    
    self._ReddotIndexPool = 1

    self:_AddFunctionShowReddotEvent()
    
    self:CheckIsCanShow()
    self._StartRun = true
    
    -- 额外的解锁控制，默认解锁
    self._ExUnlockCommand = true
end

function XUiFunctionShowControl:OnEnable()
    if self._StartRun then
        self._StartRun = false

        if not self:CheckIsShowValid() then
            return
        end
    else
        if not self:CheckIsShowValid() then
            return
        end
        
        self:_RefreshReddotShow()
    end    
    
    self:RefreshUnlockState()
end

function XUiFunctionShowControl:OnDestroy()
    self:ReleaseShowStateEvent()
    self:_EndDelayCloseTimer()
end

function XUiFunctionShowControl:SetId(id, force)
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

--- 注册系统自己的点击回调，该回调在通用解锁判定通过后调用
function XUiFunctionShowControl:AddButtonClickEvent(clickEvent)
    self._ClickEvent = clickEvent
end

--region 红点相关

--- 添加系统额外的红点监听
function XUiFunctionShowControl:AddAdditionRedPointEvent(conditionGroup, args, isCheck)
    if self._Button then
        local index = self:_GetReddotIndex()

        local reddotEventId = self:AddRedPointEvent(self._Button, function(count)
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
        
        return reddotEventId
    end
end

--- 外部手动移除红点
function XUiFunctionShowControl:RemoveAdditionRedPointEvent(redEventId)
    if XTool.IsTableEmpty(self._AdditionReddotEventIds) then
        return
    end
    
    local isIn, index = table.contains(self._AdditionReddotEventIds, redEventId)

    if isIn then
        self:RemoveRedPointEvent(redEventId)
        table.remove(self._AdditionReddotEventIds, index)
        
        -- 移除对应的结果
        self._ReddotEventId2ShowStateMap[redEventId] = nil
        
        -- 从索引表中移除
        local isInIndex, indexInIndex = table.contains(self._ReddotIndex2EventId, redEventId)

        if isInIndex then
            self._ReddotIndex2EventId[indexInIndex] = nil
        end
    end
end

--- 外部手动设置红点显示，而不是通过红点事件
function XUiFunctionShowControl:SetReddotShow(isShow)
    self:_OnReddotEvent(isShow)
end

--- 外部手动刷新红点显示
function XUiFunctionShowControl:RefreshReddot()
    self:_RefreshReddotShow()
end

function XUiFunctionShowControl:_AddFunctionShowReddotEvent()
    if XTool.IsNumberValidEx(self.Id) then
        local cfg = XFunctionConfig.GetFunctionalShowCfg(self.Id)

        if cfg then
            if self._Button and not XTool.IsTableEmpty(cfg.RedPointConditions) then
                self._CommonReddotEventId = self:AddRedPointEvent(self._Button, self._OnCommonReddotEvent, self, cfg.RedPointConditions, cfg.RedPointArgs)
            end
        end
    end
end

function XUiFunctionShowControl:_RefreshReddotShow()
    if XTool.IsNumberValid(self._CommonReddotEventId) then
        XRedPointManager.Check(self._CommonReddotEventId)
    end

    if not XTool.IsTableEmpty(self._AdditionReddotEventIds) then
        for i, reddotEventId in pairs(self._AdditionReddotEventIds) do
            XRedPointManager.Check(reddotEventId)
        end
    end
end

function XUiFunctionShowControl:_GetReddotIndex()
    local index = self._ReddotIndexPool

    self._ReddotIndexPool = self._ReddotIndexPool + 1

    return index
end

function XUiFunctionShowControl:_OnCommonReddotEvent(count)
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

function XUiFunctionShowControl:_OnReddotEvent(isShow)
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

function XUiFunctionShowControl:_OnButtonClickEvent()
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

function XUiFunctionShowControl:_AfterClickSuccess()
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
function XUiFunctionShowControl:SetActiveByHand(isShow)
    if self.ComFunctionShowControl then
        self.ComFunctionShowControl:SetActiveEx(isShow)
    else
        self._ShowCommand = isShow
    end

    if isShow and self:GetIsCanShow() then
        self:Open()
    else
        self:Close()
    end
end

function XUiFunctionShowControl:SetUnlockByHand(isUnlock)
    self._ExUnlockCommand = isUnlock

    self:RefreshUnlockState()
end

function XUiFunctionShowControl:InitShowStateEvent()
    if XTool.IsNumberValid(self.Id) then
        local cfg = XFunctionConfig.GetFunctionalShowCfg(self.Id)

        if cfg and not XTool.IsTableEmpty(cfg.EventIds) then
            for i, eventId in pairs(cfg.EventIds) do
                XEventManager.AddEventListener(eventId, self.RefreshStateOnEvent, self)
            end
        end
    end
end

function XUiFunctionShowControl:ReleaseShowStateEvent(id)
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

function XUiFunctionShowControl:GetIsCanShow()
    return self._IsShow
end

function XUiFunctionShowControl:CheckIsCanShow()
    if XTool.IsNumberValid(self.Id) then
        self._IsShow = XFunctionManager.CheckUiNodeIsShowByFunctionShowId(self.Id)
        self:_SetImpIsShow()
        return self._IsShow
    end
    
    self._IsShow = true
    self:_SetImpIsShow()
    
    return true
end

function XUiFunctionShowControl:_SetImpIsShow()
    if self.ComFunctionShowControl then
        self.ComFunctionShowControl:SetFunctionOpenStateByProxy(self._IsShow)
    end
end

function XUiFunctionShowControl:CheckIsUnlock()
    if XTool.IsNumberValidEx(self.Id) then
        return XFunctionManager.CheckUiNodeIsUnlockByFunctionShowId(self.Id)
    end
    
    return true
end

function XUiFunctionShowControl:CheckIsShowValid()
    if not self:GetIsCanShow() then
        self:_EndDelayCloseTimer()
        self._DelayCloseTimerId = XScheduleManager.ScheduleOnce(handler(self, self._DelayClose))
        return false
    end
    
    return true
end

function XUiFunctionShowControl:RefreshStateOnEvent()
    self:RefreshShowState()
    self:RefreshUnlockState()
end

function XUiFunctionShowControl:RefreshShowState()
    if self:CheckIsCanShow() then
        self:Open()
    else
        self:Close()
    end
end

function XUiFunctionShowControl:RefreshUnlockState()
    if not self:GetIsCanShow() then
        return
    end
    
    if self._Button then
        local isUnlock = self:CheckIsUnlock() and self._ExUnlockCommand
        self._Button:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

function XUiFunctionShowControl:_EndDelayCloseTimer()
    if self._DelayCloseTimerId then
        XScheduleManager.UnSchedule(self._DelayCloseTimerId)
        self._DelayCloseTimerId = nil
    end
end

function XUiFunctionShowControl:_DelayClose()
    self:Close()
    
    -- Close执行依赖XUiNode状态字段
    -- 因为UI节点的显示可能是外部其他系统控制的，不一定能真的隐藏，所以需要手动隐藏GameObject
    self.GameObject:SetActiveEx(false)
end
--endregion


return XUiFunctionShowControl