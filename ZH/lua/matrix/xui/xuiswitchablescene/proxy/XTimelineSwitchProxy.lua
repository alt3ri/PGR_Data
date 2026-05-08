---@class XTimelineSwitchProxy Timeline切换代理（控制状态切换动画）
---@field private _GyroController XGyroController 陀螺仪控制器
---@field private _CurTime number 当前时间
---@field private _IsPlaying boolean 是否正在播放
---@field private _ForceDisableGyro boolean 强制禁用陀螺仪
---@field private _AltActive boolean Alt键是否激活
---@field private _StartMouseX number 鼠标起始X坐标
---@field private _SceneIsSpring boolean 当前场景状态（true=春/Full，false=冬/Charge）
---@field private _SwitchDirection number 切换方向（正向/逆向）
---@field private _AutoSwitchInterval number 自动切换间隔（秒）
---@field private _AnimEnableGyroCW UnityEngine.Playables.PlayableDirector 顺时针陀螺仪动画
---@field private _AnimEnableGyroCCW UnityEngine.Playables.PlayableDirector 逆时针陀螺仪动画
---@field private _ToFullTimeline UnityEngine.Transform 春转冬动画
---@field private _ToChargeTimeline UnityEngine.Transform 冬转春动画
---@field private _FullTimeline UnityEngine.Transform 春状态停留动画
---@field private _ChargeTimeline UnityEngine.Transform 冬状态停留动画
---@field private _AnimEnableLong UnityEngine.Playables.PlayableDirector 长按动画
---@field private _GyroAnimProgress number 陀螺仪动画当前进度（0=春，0.5=冬，进度1与0状态相同，到达后重置为0）
---@field private _GyroAnimTargetProgress number 陀螺仪动画目标进度
---@field private _CurrentGyroAnim UnityEngine.Playables.PlayableDirector 当前激活的陀螺仪动画（CW或CCW，同一时间只激活一个）
---@field private _IsTransitionPlaying boolean 是否正在播放过渡动画（防止重复触发）
local XTimelineSwitchProxy = XClass(require("XUi/XUiSwitchableScene/Base/XSceneAnimProxyBase"), "XTimelineSwitchProxy")

local XGyroController = require("XUi/XUiSwitchableScene/Base/XGyroController")
local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode

function XTimelineSwitchProxy:Ctor(proxyType)
    self._ProxyType = proxyType
    self._CurTime = 0
    self._IsPlaying = false
    self._ForceDisableGyro = false
    self._AltActive = false
    self._StartMouseX = 0
    self._GyroController = nil
    self._IsTransitionPlaying = false -- 过渡动画播放锁

    -- 状态相关
    self._SceneIsSpring = true -- 默认春状态
    self._SwitchDirection = XGyroController.Direction.Sequential -- 切换方向
    self._AutoSwitchInterval = 60 -- 自动切换间隔（秒），默认60秒

    -- 陀螺仪动画进度（0=春，0.5=冬，1=春）
    self._GyroAnimProgress = 0 -- 默认春状态，进度为0
    self._GyroAnimTargetProgress = 0
    self._CurrentGyroAnim = nil -- 当前激活的陀螺仪动画

    -- Timeline动画引用
    self._AnimEnableGyroCW = nil
    self._AnimEnableGyroCCW = nil
    self._ToFullTimeline = nil
    self._ToChargeTimeline = nil
    self._FullTimeline = nil
    self._ChargeTimeline = nil
    self._AnimEnableLong = nil

    -- 加载配置
    self:_LoadConfig()
end

---加载配置
function XTimelineSwitchProxy:_LoadConfig()
    -- 读取自动切换间隔配置（秒），默认60秒
    self._AutoSwitchInterval = XMVCA.XSwitchableScene:GetIntClientConfigById("AutoSwitchInterval") or 60
end

--region 生命周期

function XTimelineSwitchProxy:OnActivate(sceneTran)
    self.Super.OnActivate(self, sceneTran)
    self:_InitTimeline(sceneTran)
    self:_CreateGyroController()
end

function XTimelineSwitchProxy:OnDeactivate()
    self:_StopInternal()
    self.Super.OnDeactivate(self)
end

function XTimelineSwitchProxy:OnDestroy()
    if self._GyroController then
        self._GyroController:OnDestroy()
        self._GyroController = nil
    end

    -- 清理动画引用
    self._AnimEnableGyroCW = nil
    self._AnimEnableGyroCCW = nil
    self._ToFullTimeline = nil
    self._ToChargeTimeline = nil
    self._FullTimeline = nil
    self._ChargeTimeline = nil
    self._AnimEnableLong = nil
    self._CurrentGyroAnim = nil
end

--endregion

--region 初始化

---初始化Timeline
---@param sceneTran UnityEngine.Transform
function XTimelineSwitchProxy:_InitTimeline(sceneTran)
    if XTool.UObjIsNil(sceneTran) then
        return
    end

    -- 获取Animations节点
    local animRoot = sceneTran:Find("Animations")
    if XTool.UObjIsNil(animRoot) then
        return
    end

    -- 初始化陀螺仪动画
    local cwGo = animRoot:Find("AnimEnableGyro_CW")
    if not XTool.UObjIsNil(cwGo) then
        self._AnimEnableGyroCW = cwGo:GetComponent("PlayableDirector")
    end

    local ccwGo = animRoot:Find("AnimEnableGyro_CCW")
    if not XTool.UObjIsNil(ccwGo) then
        self._AnimEnableGyroCCW = ccwGo:GetComponent("PlayableDirector")
    end

    -- 初始化切换动画
    self._ToFullTimeline = animRoot:Find("ToFullTimeLine")     -- 春转冬
    self._ToChargeTimeline = animRoot:Find("ToChargeTimeLine") -- 冬转春

    -- 初始化状态停留动画
    self._FullTimeline = animRoot:Find("FullTimeLine")     -- 春状态停留
    self._ChargeTimeline = animRoot:Find("ChargeTimeLine") -- 冬状态停留

    -- 初始化长按动画
    local longGo = animRoot:Find("AnimEnableLong")
    if not XTool.UObjIsNil(longGo) then
        self._AnimEnableLong = longGo:GetComponent("PlayableDirector")
    end
end

---创建陀螺仪控制器
function XTimelineSwitchProxy:_CreateGyroController()
    local gyroFrequency = XMVCA.XSwitchableScene:GetIntClientConfigById("GyroFrequency")
    local eulerXLimit = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerXLimit")
    local eulerZKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerZKeep")
    local moveXKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("MoveXKeep")

    self._GyroController = XGyroController.New(gyroFrequency, eulerXLimit, eulerZKeep, moveXKeep)

    -- 设置速度计算器
    self._GyroController:SetSpeedCalculatorByAngle(function(angle)
        --todo: 后续看需求是否是固定速度
        return 100
    end)

    self._GyroController:SetSpeedCalculatorByDistance(function(distance)
        --todo 后续看需求是否是固定速度
        return 100
    end)

    -- 设置方向变化回调
    self._GyroController:SetOnDirectionChanged(function(direction)
        self._SwitchDirection = direction

        -- 执行手动切换
        self:_OnManualSwitch(direction)
    end)

    -- 设置输入结束回调（玩家停止操作陀螺仪）
    self._GyroController:SetOnInputEnd(function()
        -- 动画播放期间陀螺仪已被禁用，定时器在_OnManualSwitch中统一控制
    end)

    -- 设置输入检测器
    self._GyroController:SetInputChecker(function()
        local altHold = Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt)
        if altHold then
            if not self._AltActive then
                self._AltActive = true
                self._StartMouseX = Input.mousePosition.x
            end
            -- 丽芙这个场景需要调整反向
            return true, self._StartMouseX - Input.mousePosition.x
        else
            if self._AltActive then
                self._AltActive = false
                return false, nil
            end
            return nil, nil
        end
    end)
end

--endregion

--region 播放控制

function XTimelineSwitchProxy:OnPlay()
    self._IsPlaying = true

    -- 启用陀螺仪
    if not self._ForceDisableGyro and self:_IsGyroEnabled() then
        self._GyroController:Enable()
    end

    -- 初始化状态（默认春状态）
    self._SceneIsSpring = true
    self._GyroAnimProgress = 0

    -- 初始化陀螺仪动画
    self:_InitGyroAnimation()

    -- 播放初始状态停留动画
    self:_PlayIdleAnimation()

    -- 开启定时器
    self:StartSwitchTimer()
end

function XTimelineSwitchProxy:OnPause()
    self._IsPlaying = false
end

function XTimelineSwitchProxy:OnResume()
    self._IsPlaying = true
end

function XTimelineSwitchProxy:OnStop()
    self:_StopInternal()
end

---内部停止
function XTimelineSwitchProxy:_StopInternal()
    self._IsPlaying = false
    XMVCA.XSwitchableScene:SetPlayProgress(self._CurTime)
    if self._GyroController then
        self._GyroController:Disable()
    end

    -- 停止所有动画
    self:_StopAllAnimations()

    -- 停止定时器
    self:StopSwitchTimer()
end

--endregion

--region 更新

function XTimelineSwitchProxy:OnUpdate(deltaTime)
    if not self._IsPlaying then
        return
    end

    -- 更新陀螺仪输入
    if self._GyroController and not self._ForceDisableGyro and self:_IsGyroEnabled() then
        self._GyroController:Update()
    end

    -- 更新陀螺仪动画进度
    self:_UpdateGyroAnimation(deltaTime)
end

--endregion

--region 场景切换

function XTimelineSwitchProxy:SwitchScene(sceneId)
    self.Super.SwitchScene(self, sceneId)
    -- 切换场景时重置时间
    self._CurTime = 0
end

--endregion

--region 公共方法

---设置强制禁用陀螺仪
---@param disable boolean
function XTimelineSwitchProxy:SetForceDisableGyro(disable)
    self._ForceDisableGyro = disable
    if self._GyroController then
        self._GyroController:SetForceDisable(disable)
    end
end

---获取当前播放时间
---@return number
function XTimelineSwitchProxy:GetCurPlayTime()
    return self._CurTime or 0
end

---是否正在播放
---@return boolean
function XTimelineSwitchProxy:IsPlaying()
    return self._IsPlaying
end

--endregion

--region 私有方法

---是否开启陀螺仪交互
---@return boolean
function XTimelineSwitchProxy:_IsGyroEnabled()
    return XMVCA.XSwitchableScene:GetGyroSetting(self._SceneId) == XEnumConst.SwitchableScene.Setting.Open
end

---获取动画节点名称
---@param anim UnityEngine.Object 动画对象（Transform或PlayableDirector）
---@return string
function XTimelineSwitchProxy:_GetAnimName(anim)
    if XTool.UObjIsNil(anim) then
        return "nil"
    end
    -- PlayableDirector需要获取gameObject
    if anim.gameObject then
        return anim.gameObject.name
    end
    -- Transform直接获取name
    return anim.name or "unknown"
end

--endregion

--region 定时器

---停止定时器
function XTimelineSwitchProxy:StopSwitchTimer()
    if self._SwitchTimerId then
        XScheduleManager.UnSchedule(self._SwitchTimerId)
        self._SwitchTimerId = nil
        XLog.Debug('[丽芙场景]定时器已停止')
    end
end

---开启定时器
function XTimelineSwitchProxy:StartSwitchTimer()
    self:StopSwitchTimer()
    self:ResetSwitchTick()

    self._SwitchTimerId = XScheduleManager.ScheduleForever(function()
        self._SwitchTick = self._SwitchTick + 1

        if self._SwitchTick % 10 == 0 then
            XLog.Debug('[丽芙场景]定时器计时：' .. tostring(self._SwitchTick) .. '/' .. tostring(self._AutoSwitchInterval))
        end

        if self._SwitchTick >= self._AutoSwitchInterval then
            -- 重置时间
            self:ResetSwitchTick()

            -- 执行自动切换
            self:_OnAutoSwitch()
        end
    end, XScheduleManager.SECOND)

    XLog.Debug('[丽芙场景]定时器已开启，间隔：' .. tostring(self._AutoSwitchInterval) .. '秒')
end

---重置计时
function XTimelineSwitchProxy:ResetSwitchTick()
    self._SwitchTick = 0
end

---重置场景状态
function XTimelineSwitchProxy:ResetSceneState()
    self._SceneIsSpring = true
end

--endregion

--region 动画播放

---停止Timeline动画节点（内部辅助方法）
---@param timeline UnityEngine.Transform
---@param hide boolean 是否隐藏节点
function XTimelineSwitchProxy:_StopTimelineNode(timeline, hide)
    if not XTool.UObjIsNil(timeline) then
        timeline.gameObject:StopTimelineAnimation()
        if hide then
            timeline.gameObject:SetActiveEx(false)
        end
    end
end

---停止所有动画（完全停止，退出时调用）
function XTimelineSwitchProxy:_StopAllAnimations()
    -- 停止状态停留动画
    self:_StopTimelineNode(self._FullTimeline, true)
    self:_StopTimelineNode(self._ChargeTimeline, true)

    -- 停止切换动画
    self:_StopTimelineNode(self._ToFullTimeline, true)
    self:_StopTimelineNode(self._ToChargeTimeline, true)

    -- 完全停止陀螺仪动画
    self:_StopGyroAnimation()
end

---停止切换相关动画（切换前调用，保留陀螺仪动画状态）
function XTimelineSwitchProxy:_StopTransitionAnimations()
    -- 停止状态停留动画
    self:_StopTimelineNode(self._FullTimeline, true)
    self:_StopTimelineNode(self._ChargeTimeline, true)

    -- 停止切换动画
    self:_StopTimelineNode(self._ToFullTimeline, true)
    self:_StopTimelineNode(self._ToChargeTimeline, true)

    -- 停止陀螺仪动画进度更新，但保持当前状态显示
    self:_StopGyroAnimProgress()
end

---初始化陀螺仪动画（设置为手动控制模式，默认只激活CW动画）
function XTimelineSwitchProxy:_InitGyroAnimation()
    -- 默认使用顺时针动画
    self._CurrentGyroAnim = self._AnimEnableGyroCW

    -- 初始化顺时针动画（激活）
    if not XTool.UObjIsNil(self._AnimEnableGyroCW) then
        self._AnimEnableGyroCW.gameObject:SetActiveEx(true)
        self._AnimEnableGyroCW.playOnAwake = false
        self._AnimEnableGyroCW.timeUpdateMode = CS.UnityEngine.Playables.DirectorUpdateMode.Manual
        -- 防止 duration 为 0
        local duration = self._AnimEnableGyroCW.duration
        if duration and duration > 0 then
            self._AnimEnableGyroCW.time = self._GyroAnimProgress * duration
        else
            self._AnimEnableGyroCW.time = 0
        end
        self._AnimEnableGyroCW:Evaluate()
    end

    -- 确保逆时针动画停用
    if not XTool.UObjIsNil(self._AnimEnableGyroCCW) then
        self._AnimEnableGyroCCW.gameObject:SetActiveEx(false)
    end
end

---停止陀螺仪动画进度更新（保持当前状态显示）
function XTimelineSwitchProxy:_StopGyroAnimProgress()
    self._IsGyroAnimPlaying = false
    -- 不停用gameObject，保持最终状态显示
end

---完全停止陀螺仪动画（退出时调用）
function XTimelineSwitchProxy:_StopGyroAnimation()
    self._IsGyroAnimPlaying = false
    if not XTool.UObjIsNil(self._AnimEnableGyroCW) then
        self._AnimEnableGyroCW:Stop()
        self._AnimEnableGyroCW.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self._AnimEnableGyroCCW) then
        self._AnimEnableGyroCCW:Stop()
        self._AnimEnableGyroCCW.gameObject:SetActiveEx(false)
    end
    self._CurrentGyroAnim = nil
end

---切换陀螺仪动画到目标方向（同步进度防止抖动）
---@param targetDirection number 目标方向
---@return UnityEngine.Playables.PlayableDirector 目标动画
function XTimelineSwitchProxy:_SwitchGyroAnimToDirection(targetDirection)
    -- 确定目标动画
    local targetAnim = targetDirection == XGyroController.Direction.Sequential
        and self._AnimEnableGyroCW or self._AnimEnableGyroCCW

    -- 如果已经是目标动画，直接返回
    if self._CurrentGyroAnim == targetAnim then
        return targetAnim
    end

    -- 1. 先记录当前动画的进度
    local currentProgress = self._GyroAnimProgress
    if not XTool.UObjIsNil(self._CurrentGyroAnim) then
        local duration = self._CurrentGyroAnim.duration
        if duration > 0 then
            currentProgress = self._CurrentGyroAnim.time / duration
        end
    end

    -- 2. 停用当前动画
    if not XTool.UObjIsNil(self._CurrentGyroAnim) then
        self._CurrentGyroAnim:Stop()
        self._CurrentGyroAnim.gameObject:SetActiveEx(false)
    end

    -- 3. 激活目标动画，并同步进度（防止抖动）
    if not XTool.UObjIsNil(targetAnim) then
        targetAnim.gameObject:SetActiveEx(true)
        targetAnim.playOnAwake = false
        targetAnim.timeUpdateMode = CS.UnityEngine.Playables.DirectorUpdateMode.Manual
        -- 防止 duration 为 0
        local targetDuration = targetAnim.duration
        if targetDuration and targetDuration > 0 then
            targetAnim.time = currentProgress * targetDuration
        else
            targetAnim.time = 0
        end
        targetAnim:Evaluate()
    end

    -- 4. 更新当前动画引用
    self._CurrentGyroAnim = targetAnim

    return targetAnim
end

---播放陀螺仪动画（手动控制进度，总是正向播放）
---@param direction number 切换方向
---@param callback function 切换完成回调
function XTimelineSwitchProxy:_PlayGyroAnimation(direction, callback)
    -- 切换到目标方向的陀螺仪动画（同步进度防止抖动）
    local gyroAnim = self:_SwitchGyroAnimToDirection(direction)

    if XTool.UObjIsNil(gyroAnim) then
        if callback then
            callback()
        end
        return
    end

    -- 确定目标进度
    -- 进度0和1都是春状态，0.5是冬状态
    -- 动画总是正向播放：0→0.5→1→0→...
    if self._SceneIsSpring then
        -- 当前是春（进度0），目标切换到冬（进度0.5）
        self._GyroAnimTargetProgress = 0.5
    else
        -- 当前是冬（进度0.5），目标切换到春（进度1，到达后重置为0）
        self._GyroAnimTargetProgress = 1
    end

    -- 激活并播放陀螺仪动画
    gyroAnim.gameObject:SetActiveEx(true)
    gyroAnim:Play()

    local animName = self:_GetAnimName(gyroAnim)
    XLog.Debug('[丽芙场景]开始播放陀螺仪动画，节点：' .. animName .. '，当前状态：' .. (self._SceneIsSpring and "春" or "冬") .. '，目标进度：' .. tostring(self._GyroAnimTargetProgress))

    -- 开始更新进度
    self:_StartGyroAnimProgressUpdate(gyroAnim, callback)
end

---开始更新陀螺仪动画进度
---@param gyroAnim UnityEngine.Playables.PlayableDirector
---@param callback function
function XTimelineSwitchProxy:_StartGyroAnimProgressUpdate(gyroAnim, callback)
    if XTool.UObjIsNil(gyroAnim) then
        if callback then
            callback()
        end
        return
    end

    local duration = gyroAnim.duration
    -- 防止 duration 为 0 或无效
    if not duration or duration <= 0 then
        XLog.Warning('[丽芙场景]陀螺仪动画时长为0，直接完成')
        if callback then
            callback()
        end
        return
    end

    -- 目标时间 = 目标进度 * 总时长
    local targetTime = self._GyroAnimTargetProgress * duration

    -- 设置目标时间和回调
    self._GyroAnimTargetTime = targetTime
    self._GyroAnimCallback = callback
    self._IsGyroAnimPlaying = true
end

---更新陀螺仪动画（每帧调用，总是正向播放）
---@param deltaTime number
function XTimelineSwitchProxy:_UpdateGyroAnimation(deltaTime)
    if not self._IsGyroAnimPlaying then
        return
    end

    -- 使用当前激活的陀螺仪动画
    local gyroAnim = self._CurrentGyroAnim

    if XTool.UObjIsNil(gyroAnim) then
        self._IsGyroAnimPlaying = false
        if self._GyroAnimCallback then
            self._GyroAnimCallback()
            self._GyroAnimCallback = nil
        end
        return
    end

    local duration = gyroAnim.duration
    -- 防止 duration 为 0 导致除零错误
    if not duration or duration <= 0 then
        XLog.Warning('[丽芙场景]陀螺仪动画时长为0，跳过更新')
        self._IsGyroAnimPlaying = false
        self._GyroAnimProgress = 0 -- 默认春状态
        if self._GyroAnimCallback then
            self._GyroAnimCallback()
            self._GyroAnimCallback = nil
        end
        return
    end

    local currentTime = gyroAnim.time
    local targetTime = self._GyroAnimTargetTime or 0

    -- 正向播放：总是从当前时间向目标时间移动
    local speed = 2.0 -- 过渡速度
    local newTime = CS.UnityEngine.Mathf.MoveTowards(currentTime, targetTime, speed * deltaTime)

    gyroAnim.time = newTime
    gyroAnim:Evaluate()

    -- 检查是否到达目标
    if math.abs(newTime - targetTime) < 0.01 then
        self._IsGyroAnimPlaying = false

        -- 到达目标进度后的处理
        if self._GyroAnimTargetProgress >= 1 then
            -- 到达进度1（春状态），立刻重置为0（进度0和1状态相同）
            gyroAnim.time = 0
            gyroAnim:Evaluate()
            self._GyroAnimProgress = 0
            XLog.Debug('[丽芙场景]陀螺仪动画到达进度1，重置为0')
        else
            -- 到达进度0.5（冬状态）
            self._GyroAnimProgress = newTime / duration
        end

        local animName = self:_GetAnimName(gyroAnim)
        XLog.Debug('[丽芙场景]陀螺仪动画播放完成，节点：' .. animName .. '，最终进度：' .. string.format("%.2f", self._GyroAnimProgress))

        if self._GyroAnimCallback then
            self._GyroAnimCallback()
            self._GyroAnimCallback = nil
        end
    end
end

---播放状态停留动画（待机动画）
function XTimelineSwitchProxy:_PlayIdleAnimation()
    if self._SceneIsSpring then
        -- 春状态，播放FullTimeline
        if not XTool.UObjIsNil(self._FullTimeline) then
            local animName = self:_GetAnimName(self._FullTimeline)
            XLog.Debug('[丽芙场景]开始播放状态停留动画，节点：' .. animName .. '，状态：春')
            self._FullTimeline.gameObject:SetActiveEx(true)
            self._FullTimeline.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        end
        -- 隐藏冬状态动画
        if not XTool.UObjIsNil(self._ChargeTimeline) then
            self._ChargeTimeline.gameObject:SetActiveEx(false)
        end
    else
        -- 冬状态，播放ChargeTimeline
        if not XTool.UObjIsNil(self._ChargeTimeline) then
            local animName = self:_GetAnimName(self._ChargeTimeline)
            XLog.Debug('[丽芙场景]开始播放状态停留动画，节点：' .. animName .. '，状态：冬')
            self._ChargeTimeline.gameObject:SetActiveEx(true)
            self._ChargeTimeline.gameObject:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        end
        -- 隐藏春状态动画
        if not XTool.UObjIsNil(self._FullTimeline) then
            self._FullTimeline.gameObject:SetActiveEx(false)
        end
    end
end

---播放切换动画（ToxxxTimeline）
---@param toSpring boolean 是否切换到春状态
---@param callback function 切换完成回调
function XTimelineSwitchProxy:_PlaySwitchAnimation(toSpring, callback)
    local animTrans = toSpring and self._ToChargeTimeline or self._ToFullTimeline

    if XTool.UObjIsNil(animTrans) then
        if callback then
            callback()
        end
        return
    end

    local animName = self:_GetAnimName(animTrans)
    XLog.Debug('[丽芙场景]开始播放切换动画，节点：' .. animName .. '，目标状态：' .. (toSpring and "春" or "冬"))
    animTrans.gameObject:SetActiveEx(true)
    animTrans.gameObject:PlayTimelineAnimation(function()
        animTrans.gameObject:SetActiveEx(false)
        XLog.Debug('[丽芙场景]切换动画播放完成，节点：' .. animName)
        if callback then
            callback()
        end
    end)
end

---播放过渡动画（同时播放AnimEnableGyro和ToxxxTimeline）
---@param direction number 切换方向
---@param callback function 完成回调
function XTimelineSwitchProxy:_PlayTransitionAnimation(direction, callback)
    XLog.Debug('[丽芙场景]开始播放过渡动画，方向：' .. (direction == XGyroController.Direction.Sequential and "顺时针" or "逆时针"))

    -- 停止切换相关动画（保留陀螺仪动画状态）
    self:_StopTransitionAnimations()

    -- 防止抖动：先切换陀螺仪动画（同步进度）
    local gyroAnim = self:_SwitchGyroAnimToDirection(direction)

    -- 使用布尔值追踪动画完成状态，方便定位问题
    local gyroAnimCompleted = false
    local switchAnimCompleted = false

    -- 记录动画名称用于日志
    local gyroAnimName = self:_GetAnimName(gyroAnim)

    local function checkAllCompleted()
        if gyroAnimCompleted and switchAnimCompleted then
            XLog.Debug('[丽芙场景]所有过渡动画播放完成')
            if callback then
                callback()
            end
        end
    end

    -- 1. 播放AnimEnableGyro动画（手动控制进度）
    if not XTool.UObjIsNil(gyroAnim) then
        self:_PlayGyroAnimation(direction, function()
            gyroAnimCompleted = true
            XLog.Debug('[丽芙场景]陀螺仪过渡动画完成，节点：' .. gyroAnimName)
            checkAllCompleted()
        end)
    else
        XLog.Debug('[丽芙场景]陀螺仪动画节点不存在，跳过')
        gyroAnimCompleted = true
        checkAllCompleted()
    end

    -- 2. 播放ToxxxTimeline动画（正常播放）
    local toSpring = not self._SceneIsSpring
    local switchAnim = toSpring and self._ToChargeTimeline or self._ToFullTimeline
    local switchAnimName = self:_GetAnimName(switchAnim)

    if not XTool.UObjIsNil(switchAnim) then
        XLog.Debug('[丽芙场景]开始播放切换动画，节点：' .. switchAnimName .. '，目标状态：' .. (toSpring and "春" or "冬"))
        switchAnim.gameObject:SetActiveEx(true)
        switchAnim.gameObject:PlayTimelineAnimation(function()
            switchAnim.gameObject:SetActiveEx(false)
            switchAnimCompleted = true
            XLog.Debug('[丽芙场景]切换动画完成，节点：' .. switchAnimName)
            checkAllCompleted()
        end)
    else
        XLog.Debug('[丽芙场景]切换动画节点不存在，跳过')
        switchAnimCompleted = true
        checkAllCompleted()
    end
end

--endregion

--region 状态切换

---手动切换（玩家操作触发）
---@param direction number 切换方向
function XTimelineSwitchProxy:_OnManualSwitch(direction)
    -- 防止重复触发
    if self._IsTransitionPlaying then
        XLog.Debug('[丽芙场景]过渡动画正在播放，忽略本次手动切换请求')
        return
    end

    -- 空指针保护
    if not self._GyroController then
        XLog.Error('[丽芙场景]陀螺仪控制器为空，无法执行手动切换')
        return
    end

    XLog.Debug('[丽芙场景]开始手动切换场景，方向：' .. (direction == XGyroController.Direction.Sequential and "顺时针" or "逆时针"))

    -- 1. 禁用陀螺仪输入
    XLog.Debug('[丽芙场景]陀螺仪输入已禁用')
    self._GyroController:SetForceDisable(true)

    -- 2. 停止并重置定时器
    self:StopSwitchTimer()
    self:ResetSwitchTick()

    -- 标记正在播放过渡动画
    self._IsTransitionPlaying = true

    -- 根据方向切换状态
    local targetIsSpring = not self._SceneIsSpring

    -- 播放过渡动画（同时播放AnimEnableGyro和ToxxxTimeline）
    self:_PlayTransitionAnimation(direction, function()
        -- 清除播放锁
        self._IsTransitionPlaying = false

        -- 更新状态
        self._SceneIsSpring = targetIsSpring

        -- 更新陀螺仪动画进度（进度1已在_UpdateGyroAnimation中重置为0）
        -- 春状态：进度0，冬状态：进度0.5
        if targetIsSpring then
            self._GyroAnimProgress = 0
        else
            self._GyroAnimProgress = 0.5
        end

        -- 播放状态停留动画
        self:_PlayIdleAnimation()

        -- 解除陀螺仪禁用
        if self._GyroController then
            XLog.Debug('[丽芙场景]陀螺仪输入已启用')
            self._GyroController:SetForceDisable(false)
        end

        -- 重新开启定时器
        self:StartSwitchTimer()
    end)
end

---自动切换（定时器触发）
function XTimelineSwitchProxy:_OnAutoSwitch()
    -- 防止重复触发
    if self._IsTransitionPlaying then
        XLog.Debug('[丽芙场景]过渡动画正在播放，忽略本次自动切换请求')
        return
    end

    -- 空指针保护
    if not self._GyroController then
        XLog.Error('[丽芙场景]陀螺仪控制器为空，无法执行自动切换')
        return
    end

    XLog.Debug('[丽芙场景]开始自动切换场景，方向：' .. (self._SwitchDirection == XGyroController.Direction.Sequential and "顺时针" or "逆时针"))

    -- 1. 禁用陀螺仪输入
    XLog.Debug('[丽芙场景]陀螺仪输入已禁用')
    self._GyroController:SetForceDisable(true)

    -- 2. 停止并重置定时器
    self:StopSwitchTimer()
    self:ResetSwitchTick()

    -- 标记正在播放过渡动画
    self._IsTransitionPlaying = true

    -- 切换到另一个状态
    local targetIsSpring = not self._SceneIsSpring

    -- 自动切换使用当前方向的陀螺仪动画
    local direction = self._SwitchDirection

    -- 播放过渡动画（同时播放AnimEnableGyro和ToxxxTimeline）
    self:_PlayTransitionAnimation(direction, function()
        -- 清除播放锁
        self._IsTransitionPlaying = false

        -- 更新状态
        self._SceneIsSpring = targetIsSpring
        XLog.Debug('[丽芙场景]场景状态已更新，IsSpring：' .. tostring(self._SceneIsSpring))

        -- 更新陀螺仪动画进度（进度1已在_UpdateGyroAnimation中重置为0）
        -- 春状态：进度0，冬状态：进度0.5
        if targetIsSpring then
            self._GyroAnimProgress = 0
        else
            self._GyroAnimProgress = 0.5
        end

        -- 播放状态停留动画
        self:_PlayIdleAnimation()

        -- 解除陀螺仪禁用
        if self._GyroController then
            XLog.Debug('[丽芙场景]陀螺仪输入已启用')
            self._GyroController:SetForceDisable(false)
        end

        -- 重新开启定时器
        self:StartSwitchTimer()
    end)
end

---视频播放期间挂起场景交互：切换到春状态、停止并重置定时器、禁用陀螺仪
function XTimelineSwitchProxy:SuspendForVideo()
    if not self._SceneIsSpring then
        self._SceneIsSpring = true
        self:_PlayIdleAnimation()
    end
    self:StopSwitchTimer()
    self:ResetSwitchTick()
    self:SetForceDisableGyro(true)
end

---获取当前状态
---@return boolean true=春状态，false=冬状态
function XTimelineSwitchProxy:IsSpringState()
    return self._SceneIsSpring
end

---获取切换方向
---@return number
function XTimelineSwitchProxy:GetSwitchDirection()
    return self._SwitchDirection
end

--endregion

return XTimelineSwitchProxy