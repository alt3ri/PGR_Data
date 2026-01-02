---@class XUiPanelSwitchableSceneAnim 可切换的场景动画
local XUiPanelSwitchableSceneAnim = XClass(nil, "XUiPanelSwitchableSceneAnim")

local Sequential = 1 --正序播放
local Reverse = 2 --倒序播放
local Reference = CS.UnityEngine.Quaternion.Euler(90, 0, 0)
local Time = CS.UnityEngine.Time
local Input = CS.UnityEngine.Input
local Mathf = CS.UnityEngine.Mathf
local KeyCode = CS.UnityEngine.KeyCode
local XUiPcMode = XDataCenter.UiPcManager.XUiPcMode
local XDebugManager = CS.XDebugManager

function XUiPanelSwitchableSceneAnim:Ctor()
    self._CurTime = 0
    self._IsContinuePlay = true
    self._IsDebug = CS.XApplication.Debug
    self._AnimName = XMVCA.XSwitchableScene:GetClientConfigById("AnimName")
    self._GyroFrequency = XMVCA.XSwitchableScene:GetIntClientConfigById("GyroFrequency")
    self._EulerXLimit = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerXLimit")
    self._EulerZKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerZKeep")
    self._Acceleration = XMVCA.XSwitchableScene:GetIntClientConfigById("Acceleration")
    self._MoveXKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("MoveXKeep")
end

function XUiPanelSwitchableSceneAnim:InitScene(sceneId, sceneTran)
    if XTool.UObjIsNil(sceneTran) then
        return
    end
    local animGo = sceneTran:FindTransform(self._AnimName)
    if XTool.UObjIsNil(animGo) then
        return
    end
    ---@type UnityEngine.Playables.PlayableDirector
    self._Playable = animGo:GetComponent("PlayableDirector")
end

---是否接着上个界面的播放进度继续播放
function XUiPanelSwitchableSceneAnim:IsContinuePlay(bo)
    self._IsContinuePlay = bo
end

---播放场景动画
function XUiPanelSwitchableSceneAnim:Play(sceneId, sceneTran)
    local isSwitchScene = self._SceneId and sceneId ~= self._SceneId
    self._SceneId = sceneId
    self:StopTimer()
    if not XTool.IsNumberValid(sceneId) then
        XLog.Error("播放场景动画失败，SceneId为空.")
        return
    end

    self:InitScene(sceneId, sceneTran)
    if XTool.UObjIsNil(self._Playable) then
        return
    end
    
    --开启陀螺仪
    if XDataCenter.UiPcManager.GetUiPcMode() == XUiPcMode.CloudGame then
        XDataCenter.CloudGameManager.SeteMotionListeningAction(handler(self, self.ChangeSceneByCloud))
        XDataCenter.CloudGameManager.EnableMotionListening(true)
    else
        CS.UnityEngine.Input.gyro.enabled = true
    end
    --关闭自动播放控制
    self._Playable.playOnAwake = false
    self._Playable.timeUpdateMode = CS.UnityEngine.Playables.DirectorUpdateMode.Manual
    self._Playable:Play()
    --开始手动播放
    self:InitPlayData()
    if isSwitchScene then
        --切换场景时从头开始播
        self._CurTime = 0
    else
        --打开界面时从上次记录的地方开始播
        local offsetTime = self._IsContinuePlay and XMVCA.XSwitchableScene:GetPlayProgress() or 0
        self._CurTime = XMath.Clamp(offsetTime, 0, self._Duration)
    end
    self._TimerId = XScheduleManager.ScheduleForever(handler(self, self.Update), 0)
    self._IsPlaying = true
end

---恢复播放
function XUiPanelSwitchableSceneAnim:Resume()
    if self._IsPlaying then
        return
    end
    self._TimerId = XScheduleManager.ScheduleForever(handler(self, self.Update), 0)
end

---停止播放
function XUiPanelSwitchableSceneAnim:Stop()
    --场景动画是手动控制的 时间没更新 动画就不会继续播
    self:StopTimer()
    XMVCA.XSwitchableScene:SetPlayProgress(self._CurTime)
    --关闭云游戏的陀螺仪监听
    if XDataCenter.UiPcManager.GetUiPcMode() == XUiPcMode.CloudGame then
        XDataCenter.CloudGameManager.SeteMotionListeningAction(nil)
        XDataCenter.CloudGameManager.EnableMotionListening(false)
    end
end

function XUiPanelSwitchableSceneAnim:InitPlayData()
    self._Speed = 1
    self._TargetSpeed = 1
    self._CheckGyroTime = 0
    self._PlayOrder = Sequential
    self._Duration = self._Playable.duration
    self._AltActive = false
end

function XUiPanelSwitchableSceneAnim:Update()
    if XTool.UObjIsNil(self._Playable) then
        self:StopTimer()
        return
    end

    if self:IsEnterGyroMode() then
        local mode = XDataCenter.UiPcManager.GetUiPcMode()
        if mode == XUiPcMode.Pc then
            self:ChangeSceneByMouse()
        elseif mode == XUiPcMode.Default then
            local nowTime = Time.time
            if nowTime - self._CheckGyroTime >= self._GyroFrequency then
                self._CheckGyroTime = nowTime
                self:ChangeSceneByGyro()
            end
        end
    else
        self:ChangeToDefault()
    end

    self._Playable.time = self._CurTime
    self._Playable:Evaluate()
    
    self._Speed = Mathf.MoveTowards(self._Speed, self._TargetSpeed, Time.deltaTime * self._Acceleration)
    local dt = self._Speed * Time.deltaTime
    
    if self._PlayOrder == Sequential then
        if self._CurTime < self._Duration then
            self._CurTime = math.min(self._CurTime + dt, self._Duration)
        else
            self._CurTime = 0 --避免美术在动画头尾添加帧事件时没调到的情况
        end
    else
        if self._CurTime > 0 then
            self._CurTime = math.max(self._CurTime + dt, 0)
        else
            self._CurTime = self._Duration
        end
    end
end

---根据陀螺仪倾斜角度切换场景动画
function XUiPanelSwitchableSceneAnim:ChangeSceneByGyro()
    --当动画倒序播放时，时间依旧继续增加，然后慢慢停止，最后开始减少。所以，当目标速度<0时，动画可能还在正序播放
    local q = Input.gyro.attitude
    local deviceRotation = CS.UnityEngine.Quaternion(q.x, q.y, -q.z, -q.w) --将旋转从右手坐标系转换到左手坐标系
    local adjusted = Reference * deviceRotation
    local euler = adjusted.eulerAngles

    self:ShowDebugInfo(string.format("X:%0.2f,Y:%0.2f,Z:%0.2f", euler.x, euler.y, euler.z))

    --在某个角度内时才进行陀螺仪判断
    -- euler.x：上下倾斜 -90°~90° 手机垂直桌面时为0
    -- euler.z：左右倾斜 -180°~180° 左正右负
    if euler.x <= self._EulerXLimit or euler.x >= (360 - self._EulerXLimit) then
        local pitch = euler.z > 180 and euler.z - 360 or euler.z
        local speedValue = XMVCA.XSwitchableScene:GetSpeedByAngle(self._SceneId, math.abs(pitch))
        --在某个角度内时不改变旋转方向
        if math.abs(pitch) > self._EulerZKeep then
            self._PlayOrder = pitch >= 0 and Reverse or Sequential
            self:SetTargetSpeedWithDir(speedValue)
        else
            self:SetTargetSpeedWithoutDir(speedValue)
        end
    else
        --保持原有方向不变 速度恢复正常
        self:SetTargetSpeedWithoutDir(1)
    end
end

---按住Alt键并移动鼠标
function XUiPanelSwitchableSceneAnim:ChangeSceneByMouse()
    local altHold = Input.GetKey(KeyCode.LeftAlt) or Input.GetKey(KeyCode.RightAlt)
    if altHold then
        if not self._AltActive then
            self._AltActive = true
            self._StartMouseX = Input.mousePosition.x
        end
        
        local delta = Input.mousePosition.x - self._StartMouseX --离起点的距离（像素）
        local speedValue = XMVCA.XSwitchableScene:GetSpeedByDistance(self._SceneId, math.abs(delta))

        self:ShowDebugInfo(string.format("delta:%0.2f,speed:%0.2f", delta, speedValue))

        if math.abs(delta) > self._MoveXKeep then
            self._PlayOrder = delta >= 0 and Sequential or Reverse
        end
        self:SetTargetSpeedWithDir(speedValue)
    else
        if self._AltActive then
            self:SetTargetSpeedWithoutDir(1)
        end
        self._AltActive = false
    end
end

function XUiPanelSwitchableSceneAnim:ChangeSceneByCloud(attitude)
    if not attitude or not self:IsEnterGyroMode() then
        self:ChangeToDefault()
        return
    end

    local pitch = attitude.pitch / 100 --左右倾斜 -90°~90° 左正右负
    local roll = attitude.roll / 100 --上下倾斜 -180°~180° 水平时为0
    
    if math.abs(roll) >= 90 - self._EulerXLimit then
        local speedValue = XMVCA.XSwitchableScene:GetSpeedByAngle(self._SceneId, math.abs(pitch))
        --在某个角度内时不改变旋转方向
        if math.abs(pitch) > self._EulerZKeep then
            self._PlayOrder = pitch >= 0 and Reverse or Sequential
            self:SetTargetSpeedWithDir(speedValue)
        else
            self:SetTargetSpeedWithoutDir(speedValue)
        end
    else
        --保持原有方向不变 速度恢复正常
        self:SetTargetSpeedWithoutDir(1)
    end
end

function XUiPanelSwitchableSceneAnim:ChangeToDefault()
    self._PlayOrder = Sequential
    self:SetTargetSpeedWithDir(1)
end

function XUiPanelSwitchableSceneAnim:SetTargetSpeedWithDir(value)
    self._TargetSpeed = self._PlayOrder == Sequential and value or -value
end

--目标速度不会出现为0的情况（当前速度则会）
function XUiPanelSwitchableSceneAnim:SetTargetSpeedWithoutDir(value)
    self._TargetSpeed = self._TargetSpeed >= 0 and value or -value
end

function XUiPanelSwitchableSceneAnim:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
    self._IsPlaying = false
end

function XUiPanelSwitchableSceneAnim:GetCurPlayTime()
    return self._CurTime or 0
end

function XUiPanelSwitchableSceneAnim:IsPlaying()
    return self._IsPlaying
end

---是否开启交互模式
function XUiPanelSwitchableSceneAnim:IsEnterGyroMode()
    return XMVCA.XSwitchableScene:GetGyroSetting(self._SceneId) == XEnumConst.SwitchableScene.Setting.Open
end

function XUiPanelSwitchableSceneAnim:ShowDebugInfo(value)
    if self._IsDebug then
        local debuggerGyroInfo = XDebugManager.DebuggerGyroInfo
        if debuggerGyroInfo then
            debuggerGyroInfo:SetEulerCustom(value)
        end
    end
end

return XUiPanelSwitchableSceneAnim