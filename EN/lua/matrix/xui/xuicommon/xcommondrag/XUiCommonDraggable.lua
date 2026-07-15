-- 可拖拽源（挂在每个可拖格子上）：内部持有手势并自动驱动 XUiCommonDragContext，
-- 调用方只需声明配置，无需手动连接手势事件、会话开关与进度条。
--
-- 用法：
--   XUiCommonDraggable.New(transform, {
--       Context = ctx,                                                         -- 必填 XUiCommonDragContext
--       Mode = XEnumConst.CommonDrag.TriggerMode.Press,                        -- 默认 Press
--       CanDrag = function() return ... end,                                   -- 本次能否拖
--       GetPayload = function() return data end,                               -- 必填 业务数据
--       CloneFactory = function(payload) return cloneTransform, cloneObj end,  -- 必填 返回(cloneTransform, cloneObj)
--       CloneRecycle = function(cloneObj) cloneObj:Close() end,                -- 必填 抬手回收
--       OnClick = function() ... end,                                          -- 短按
--       ProgressTarget = transform,                                            -- 设了则进度阶段显示进度条
--       ProgressAnchor = XEnumConst.CommonDrag.AnchorType.TopRight,            -- 进度条锚点
--   })
---@class XUiCommonDraggable
local XUiCommonDraggable = XClass(nil, "XUiCommonDraggable")

local XUiCommonDragGesture = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragGesture")

---@class XUiCommonDraggableConfig
---@field Context XUiCommonDragContext 必填，共享的拖拽上下文
---@field Mode number 默认 Press
---@field MoveTolerance number 进度阶段移动容差（像素），可空（默认 20）
---@field SlideThreshold number 滑动/起拖位移阈值（像素），可空（默认 15）
---@field DisableMultiTouch boolean 是否禁止多指，默认 true
---@field CanDrag fun():boolean 本次能否拖，可空
---@field GetPayload fun():any 必填，返回拖拽业务数据
---@field CloneFactory fun(payload:any):UnityEngine.RectTransform, any 必填，返回(克隆 transform, 克隆对象)
---@field CloneRecycle fun(cloneObj:any) 必填，抬手回收克隆
---@field OnClick fun() 短按点击，可空
---@field ProgressTarget UnityEngine.RectTransform 进度条定位目标；设了则显示进度条，可空
---@field ProgressAnchor number 进度条锚点，可空

---@param transform UnityEngine.Transform 挂在可拖拽源上的 transform
---@param config XUiCommonDraggableConfig 配置项
function XUiCommonDraggable:Ctor(transform, config)
    self._Transform = transform
    self._Context = config.Context
    self._GetPayload = config.GetPayload
    self._CloneFactory = config.CloneFactory
    self._CloneRecycle = config.CloneRecycle
    self._OnClick = config.OnClick
    self._ProgressTarget = config.ProgressTarget
    self._ProgressAnchor = config.ProgressAnchor

    if not self._Context then
        XLog.Error("XUiCommonDraggable:Ctor error: config.Context is required")
    end

    local mode = config.Mode or XEnumConst.CommonDrag.TriggerMode.Press
    -- 进度阶段时长对齐进度条时长
    local progressDuration = self._Context and self._Context:GetProgressShowTime()

    ---@type XUiCommonDragGesture
    self._Gesture = XUiCommonDragGesture.New(transform,
        {
            TriggerMode = mode,
            ProgressDuration = progressDuration,
            MoveTolerance = config.MoveTolerance,
            SlideThreshold = config.SlideThreshold,
            DisableMultiTouch = config.DisableMultiTouch,
        })
    if config.CanDrag then
        self._Gesture:SetCanTrigger(config.CanDrag)
    end
    if self._OnClick then
        self._Gesture:SetOnClick(function() self._OnClick() end)
    end
    self._Gesture:SetOnPressProgress(function() self:_OnPressProgress() end)
    self._Gesture:SetOnPressTick(function(progress) self:_OnPressTick(progress) end)
    self._Gesture:SetOnPressCancel(function() self:_OnPressCancel() end)
    self._Gesture:SetOnDragBegin(function() self:_OnDragBegin() end)
    self._Gesture:SetOnPointerUp(function() self:_OnPointerUp() end)

    -- 复位手势 + 派发结束回调。
    self._AfterEndCb = function()
        if self._Gesture then
            self._Gesture:Reset()
        end
        if self._OnDragEndExtra then
            self._OnDragEndExtra()
        end
    end
end

function XUiCommonDraggable:_OnPressProgress()
    if self._ProgressTarget and self._Context then
        self._Context:ShowPressProgress(self._ProgressTarget, self._ProgressAnchor)
    end
end

function XUiCommonDraggable:_OnPressTick(progress)
    if self._ProgressTarget and self._Context then
        self._Context:UpdatePressProgress(progress)
    end
end

function XUiCommonDraggable:_OnPressCancel()
    if self._Context then
        self._Context:HidePressProgress()
    end
end

function XUiCommonDraggable:_OnDragBegin()
    if not self._Context or self._Context:IsDragging() then
        return
    end
    local payload = self._GetPayload and self._GetPayload() or nil
    local cloneTransform, cloneObj = self._CloneFactory(payload)
    if XTool.UObjIsNil(cloneTransform) then
        XLog.Error("XUiCommonDraggable:_OnDragBegin error: CloneFactory returned nil transform")
        return
    end
    self._Context:Begin(payload, cloneTransform, cloneObj, self._CloneRecycle, self._Gesture:GetPointerId())
    -- 拖拽结束（含异常抬手由 Context 轮询兜底 End）后复位本手势，AfterEnd 总指向“当前正在拖”的手势。
    self._Context:SetAfterEnd(self._AfterEndCb)
    if self._OnDragBeginExtra then
        self._OnDragBeginExtra(payload)
    end
end

function XUiCommonDraggable:_OnPointerUp()
    if self._Context and self._Context:IsDragging() then
        self._Context:End()
    end
end

-- 额外的拖拽开始回调（如隐藏源格子），参数 payload
function XUiCommonDraggable:SetOnDragBegin(cb)
    self._OnDragBeginExtra = cb
end

-- 额外的拖拽结束回调（如显示源格子）
function XUiCommonDraggable:SetOnDragEnd(cb)
    self._OnDragEndExtra = cb
end

-- 将本拖拽源同时登记为 Enter 模式的落点（仅“源即落点”场景，如槽位互换）。
-- zoneId 为本格子自身的落点标识；指针拖到本格子上方时回灌给 Context。
-- 注：纯落点格子（不可拖）无需本方法，直接在该格子的事件里调 ctx:NotifyEnter/NotifyExit(zoneId) 即可。
function XUiCommonDraggable:SetAsDropZone(zoneId)
    if not self._Gesture then
        return
    end
    self._Gesture:SetOnPointerEnter(function()
        if self._Context and self._Context:IsDragging() then
            self._Context:NotifyEnter(zoneId)
        end
    end)
    self._Gesture:SetOnPointerExit(function()
        if self._Context and self._Context:IsDragging() then
            self._Context:NotifyExit(zoneId)
        end
    end)
end

-- 复位（grid 复用回收时调用）
function XUiCommonDraggable:Reset()
    -- 若正拖拽自己（拖拽中 grid 被复用/回收），先结束会话收尾，防克隆体残留 / 源格子隐藏
    if self._Context then
        self._Context:EndIfDraggingBy(self._AfterEndCb)
    end
    if self._Gesture then
        self._Gesture:Reset()
    end
    if self._Context then
        self._Context:ClearAfterEnd(self._AfterEndCb)
    end
end

function XUiCommonDraggable:Destroy()
    if self._Context then
        self._Context:EndIfDraggingBy(self._AfterEndCb)
        self._Context:ClearAfterEnd(self._AfterEndCb)
    end
    if self._Gesture then
        self._Gesture:Destroy()
        self._Gesture = nil
    end
    self._Transform = nil
    self._Context = nil
    self._GetPayload = nil
    self._CloneFactory = nil
    self._CloneRecycle = nil
    self._OnClick = nil
    self._ProgressTarget = nil
    self._ProgressAnchor = nil
    self._OnDragBeginExtra = nil
    self._OnDragEndExtra = nil
    self._AfterEndCb = nil
end

return XUiCommonDraggable
