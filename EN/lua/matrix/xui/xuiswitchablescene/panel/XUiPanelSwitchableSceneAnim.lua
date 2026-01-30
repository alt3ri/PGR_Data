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
    self._IsPlaying = false
    self._IsContinuePlay = true
    self._ForceDisableGyro = false
    self._IsDebug = CS.XApplication.Debug
    self._AnimName = XMVCA.XSwitchableScene:GetClientConfigById("AnimName")
    self._GyroFrequency = XMVCA.XSwitchableScene:GetIntClientConfigById("GyroFrequency")
    self._EulerXLimit = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerXLimit")
    self._EulerZKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("EulerZKeep")
    self._Acceleration = XMVCA.XSwitchableScene:GetIntClientConfigById("Acceleration")
    self._MoveXKeep = XMVCA.XSwitchableScene:GetIntClientConfigById("MoveXKeep")
    self:AddEventListener()
end

function XUiPanelSwitchableSceneAnim:InitScene(sceneTran)
    ---@type UnityEngine.Playables.PlayableDirector
    self._Playable = nil
    if XTool.UObjIsNil(sceneTran) then
        return
    end
    local animGo = sceneTran:FindTransform(self._AnimName)
    if XTool.UObjIsNil(animGo) then
        return
    end
    self._Playable = animGo:GetComponent("PlayableDirector")

    ---@type XLuaBehaviour
    self._LuaBehaviour = sceneTran.gameObject:GetOrAddComponent(typeof(CS.XLuaBehaviour))
    if not XTool.UObjIsNil(self._LuaBehaviour) then
        self._LuaBehaviour.LuaLateUpdate = handler(self, self.OnLateUpdate)
    end
end

function XUiPanelSwitchableSceneAnim:OnLateUpdate()
    if not self._IsPlaying then
        return
    end
    self:LateUpdate()
end

function XUiPanelSwitchableSceneAnim:OnDestory()
    if not XTool.UObjIsNil(self._LuaBehaviour) then
        self._LuaBehaviour.LuaLateUpdate = nil
    end
    self:RemoveEventListener()
end

function XUiPanelSwitchableSceneAnim:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SIGNBOARD_CAMERA_ANIM_STATUS_CHANGE, self.OnCamAnimStatusChange, self)
end

function XUiPanelSwitchableSceneAnim:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SIGNBOARD_CAMERA_ANIM_STATUS_CHANGE, self.OnCamAnimStatusChange, self)
end

---是否接着上个界面的播放进度继续播放
function XUiPanelSwitchableSceneAnim:IsContinuePlay(bo)
    self._IsContinuePlay = bo
end

---强制关闭陀螺仪交互模式
function XUiPanelSwitchableSceneAnim:SetDisableGyro(bo)
    self._ForceDisableGyro = bo
end

---播放场景动画
function XUiPanelSwitchableSceneAnim:Play(sceneId, sceneTran)
    local isSwitchScene = self._SceneId and sceneId ~= self._SceneId
    self._SceneId = sceneId
    self:Pause()
    if not XTool.IsNumberValid(sceneId) then
        XLog.Error("播放场景动画失败，SceneId为空.")
        return
    end

    self:InitScene(sceneTran)
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
    self._Playable.gameObject:SetActiveEx(true)
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
    self._IsPlaying = true
end

---仅播放 无交互
function XUiPanelSwitchableSceneAnim:AutoPlay(sceneTran)
    self:Pause()

    self:InitScene(sceneTran)
    if XTool.UObjIsNil(self._Playable) then
        return
    end

    self._Playable.gameObject:SetActiveEx(true)
    self._Playable.playOnAwake = false
    self._Playable.timeUpdateMode = CS.UnityEngine.Playables.DirectorUpdateMode.Manual
    self._Playable:Play()

    self:InitPlayData()
    self:SetDisableGyro(true)

    local offsetTime = self._IsContinuePlay and XMVCA.XSwitchableScene:GetPlayProgress() or 0
    self._CurTime = XMath.Clamp(offsetTime, 0, self._Duration)
    self._IsPlaying = true
end

---恢复播放
function XUiPanelSwitchableSceneAnim:Resume()
    self._IsPlaying = true
end

---暂停播放
function XUiPanelSwitchableSceneAnim:Pause()
    self._IsPlaying = false
end

---停止播放
function XUiPanelSwitchableSceneAnim:Stop()
    --场景动画是手动控制的 时间没更新 动画就不会继续播
    self:Pause()
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

---更新timeline的时机不能比渲染时机早（Update）
function XUiPanelSwitchableSceneAnim:LateUpdate()
    if XTool.UObjIsNil(self._Playable) then
        self:Pause()
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

    if self._IsDebug then
        self:ShowDebugInfo(string.format("X:%0.2f,Y:%0.2f,Z:%0.2f", euler.x, euler.y, euler.z))
    end

    --在某个角度内时才进行陀螺仪判断
    -- euler.x：上下倾斜 -90°~90° 手机垂直桌面时为0
    -- euler.z：左右倾斜 -180°~180° 左正右负
    if euler.x <= self._EulerXLimit or euler.x >= (360 - self._EulerXLimit) then
        local pitch = euler.z > 180 and euler.z - 360 or euler.z
        local speedValue = XMVCA.XSwitchableScene:GetSpeedByAngle(self._SceneId, math.abs(pitch))
        --在某个角度内时不改变旋转方向
        if math.abs(pitch) > self._EulerZKeep then
            self._PlayOrder = pitch >= 0 and Sequential or Reverse
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

        if self._IsDebug then
            self:ShowDebugInfo(string.format("delta:%0.2f,speed:%0.2f", delta, speedValue))
        end

        if math.abs(delta) > self._MoveXKeep then
            self._PlayOrder = delta >= 0 and Reverse or Sequential
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
            self._PlayOrder = pitch >= 0 and Sequential or Reverse
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

function XUiPanelSwitchableSceneAnim:GetCurPlayTime()
    return self._CurTime or 0
end

function XUiPanelSwitchableSceneAnim:IsPlaying()
    return self._IsPlaying
end

---是否开启交互模式
function XUiPanelSwitchableSceneAnim:IsEnterGyroMode()
    if self._ForceDisableGyro then
        return false
    end
    return XMVCA.XSwitchableScene:GetGyroSetting(self._SceneId) == XEnumConst.SwitchableScene.Setting.Open
end

function XUiPanelSwitchableSceneAnim:ShowDebugInfo(value)
    local debuggerGyroInfo = XDebugManager.DebuggerGyroInfo
    if debuggerGyroInfo then
        debuggerGyroInfo:SetEulerCustom(value)
    end
end

function XUiPanelSwitchableSceneAnim:OnCamAnimStatusChange(status, isUseNewCamAnim)
    if not isUseNewCamAnim then
        return
    end
    if XTool.UObjIsNil(self._Playable) or not XTool.IsNumberValid(self._SceneId) then
        return
    end
    if status == XEnumConst.Favorability.CameraAnimStatus.Play then
        self:Pause()
    elseif status == XEnumConst.Favorability.CameraAnimStatus.Close then
        self:Resume()
    end
end

return XUiPanelSwitchableSceneAnim