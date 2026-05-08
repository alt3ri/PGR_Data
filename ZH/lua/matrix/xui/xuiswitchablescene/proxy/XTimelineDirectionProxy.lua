---@class XTimelineDirectionProxy Timeline方向控制代理（控制Timeline播放方向）
---@field private _GyroController XGyroController 陀螺仪控制器
---@field private _Playable UnityEngine.Playables.PlayableDirector Timeline播放器
---@field private _CurTime number 当前时间
---@field private _Duration number 总时长
---@field private _PlayOrder number 播放方向
---@field private _Speed number 当前速度
---@field private _TargetSpeed number 目标速度
---@field private _Acceleration number 加速度
---@field private _IsPlaying boolean 是否正在播放
---@field private _ForceDisableGyro boolean 强制禁用陀螺仪
---@field private _IsContinuePlay boolean 是否继续播放
---@field private _AltActive boolean Alt键是否激活
---@field private _StartMouseX number 鼠标起始X坐标
local XTimelineDirectionProxy = XClass(require("XUi/XUiSwitchableScene/Base/XSceneAnimProxyBase"), "XTimelineDirectionProxy")

local XGyroController = require("XUi/XUiSwitchableScene/Base/XGyroController")
local Mathf = CS.UnityEngine.Mathf
local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode

function XTimelineDirectionProxy:Ctor(proxyType)
    self._ProxyType = proxyType
    self._CurTime = 0
    self._Duration = 0
    self._PlayOrder = XGyroController.Direction.Sequential
    self._Speed = 1
    self._TargetSpeed = 1
    self._IsPlaying = false
    self._ForceDisableGyro = false
    self._IsContinuePlay = true
    self._AltActive = false
    self._StartMouseX = 0
    self._Playable = nil
    self._GyroController = nil

    -- 加载配置
    self:_LoadConfig()
end

---加载配置
function XTimelineDirectionProxy:_LoadConfig()
    self._Acceleration = XMVCA.XSwitchableScene:GetIntClientConfigById("Acceleration")
end

--region 生命周期

function XTimelineDirectionProxy:OnActivate(sceneTran)
    self.Super.OnActivate(self, sceneTran)
    self:_InitTimeline(sceneTran)
    self:_CreateGyroController()
end

function XTimelineDirectionProxy:OnDeactivate()
    self:_StopInternal()
    self.Super.OnDeactivate(self)
end

function XTimelineDirectionProxy:OnDestroy()
    if self._GyroController then
        self._GyroController:OnDestroy()
        self._GyroController = nil
    end
    self._Playable = nil
end

--endregion

--region 初始化

---初始化Timeline
---@param sceneTran UnityEngine.Transform
function XTimelineDirectionProxy:_InitTimeline(sceneTran)
    if XTool.UObjIsNil(sceneTran) then
        return
    end

    local animName = XMVCA.XSwitchableScene:GetClientConfigById("AnimName")
    local animGo = sceneTran:FindTransform(animName)
    if XTool.UObjIsNil(animGo) then
        return
    end

    self._Playable = animGo:GetComponent("PlayableDirector")
end

---创建陀螺仪控制器
function XTimelineDirectionProxy:_CreateGyroController()
    local gyroFrequency = XMVCA.XSwitchableScene:GetIntClientConfigById("GyroFrequency")
    local eulerXLimit = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerXLimit")
    local eulerZKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerZKeep")
    local moveXKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("MoveXKeep")

    self._GyroController = XGyroController.New(gyroFrequency, eulerXLimit, eulerZKeep, moveXKeep)

    -- 设置速度计算器
    self._GyroController:SetSpeedCalculatorByAngle(function(angle)
        return XMVCA.XSwitchableScene:GetSpeedByAngle(self._SceneId, angle)
    end)

    self._GyroController:SetSpeedCalculatorByDistance(function(distance)
        return XMVCA.XSwitchableScene:GetSpeedByDistance(self._SceneId, distance)
    end)

    -- 设置回调
    self._GyroController:SetOnDirectionChanged(function(direction)
        self._PlayOrder = direction
    end)

    self._GyroController:SetOnSpeedChanged(function(speedValue)
        self._TargetSpeed = self._PlayOrder == XGyroController.Direction.Sequential and speedValue or -speedValue
    end)

    self._GyroController:SetOnInputEnd(function()
        self._TargetSpeed = self._TargetSpeed >= 0 and 1 or -1
    end)

    -- 设置输入检测器
    self._GyroController:SetInputChecker(function()
        local altHold = Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt)
        if altHold then
            if not self._AltActive then
                self._AltActive = true
                self._StartMouseX = Input.mousePosition.x
            end
            return true, Input.mousePosition.x - self._StartMouseX
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

function XTimelineDirectionProxy:OnPlay()
    if XTool.UObjIsNil(self._Playable) then
        return
    end

    -- 配置PlayableDirector
    self._Playable.gameObject:SetActiveEx(true)
    self._Playable.playOnAwake = false
    self._Playable.timeUpdateMode = CS.UnityEngine.Playables.DirectorUpdateMode.Manual
    self._Playable:Play()

    -- 初始化播放状态
    self._Speed = 1
    self._TargetSpeed = 1
    self._PlayOrder = XGyroController.Direction.Sequential
    self._Duration = self._Playable.duration

    -- 设置初始时间
    local offsetTime = self._IsContinuePlay and XMVCA.XSwitchableScene:GetPlayProgress() or 0
    self._CurTime = XMath.Clamp(offsetTime, 0, self._Duration)

    self._IsPlaying = true

    -- 启用陀螺仪
    if not self._ForceDisableGyro and self:_IsGyroEnabled() then
        self._GyroController:Enable()
    end
end

function XTimelineDirectionProxy:OnPause()
    self._IsPlaying = false
end

function XTimelineDirectionProxy:OnResume()
    self._IsPlaying = true
end

function XTimelineDirectionProxy:OnStop()
    self:_StopInternal()
end

---内部停止
function XTimelineDirectionProxy:_StopInternal()
    self._IsPlaying = false
    XMVCA.XSwitchableScene:SetPlayProgress(self._CurTime)
    if self._GyroController then
        self._GyroController:Disable()
    end
end

--endregion

--region 更新

function XTimelineDirectionProxy:OnUpdate(deltaTime)
    if not self._IsPlaying or XTool.UObjIsNil(self._Playable) then
        return
    end

    -- 更新陀螺仪输入
    if self._GyroController and not self._ForceDisableGyro and self:_IsGyroEnabled() then
        self._GyroController:Update()
    end

    -- 应用播放状态
    self._Playable.time = self._CurTime
    self._Playable:Evaluate()

    -- 更新速度
    self._Speed = Mathf.MoveTowards(self._Speed, self._TargetSpeed, deltaTime * self._Acceleration)
    local dt = self._Speed * deltaTime

    -- 更新时间
    if self._PlayOrder == XGyroController.Direction.Sequential then
        if self._CurTime < self._Duration then
            self._CurTime = math.min(self._CurTime + dt, self._Duration)
        else
            self._CurTime = 0
        end
    else
        if self._CurTime > 0 then
            self._CurTime = math.max(self._CurTime + dt, 0)
        else
            self._CurTime = self._Duration
        end
    end
end

--endregion

--region 场景切换

function XTimelineDirectionProxy:SwitchScene(sceneId)
    self.Super.SwitchScene(self, sceneId)
    -- 切换场景时重置时间
    self._CurTime = 0
end

--endregion

--region 公共方法

---设置是否继续播放
---@param bo boolean
function XTimelineDirectionProxy:SetContinuePlay(bo)
    self._IsContinuePlay = bo
end

---设置强制禁用陀螺仪
---@param disable boolean
function XTimelineDirectionProxy:SetForceDisableGyro(disable)
    self._ForceDisableGyro = disable
    if self._GyroController then
        self._GyroController:SetForceDisable(disable)
    end
end

---获取当前播放时间
---@return number
function XTimelineDirectionProxy:GetCurPlayTime()
    return self._CurTime or 0
end

---是否正在播放
---@return boolean
function XTimelineDirectionProxy:IsPlaying()
    return self._IsPlaying
end

--endregion

--region 私有方法

---是否开启陀螺仪交互
---@return boolean
function XTimelineDirectionProxy:_IsGyroEnabled()
    return XMVCA.XSwitchableScene:GetGyroSetting(self._SceneId) == XEnumConst.SwitchableScene.Setting.Open
end

--endregion

return XTimelineDirectionProxy