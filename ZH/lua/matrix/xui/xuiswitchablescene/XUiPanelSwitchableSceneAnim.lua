---@class XUiPanelSwitchableSceneAnim 可切换的场景动画（使用播放器+代理架构）
local XUiPanelSwitchableSceneAnim = XClass(nil, "XUiPanelSwitchableSceneAnim")

local XSceneAnimPlayer = require("XUi/XUiSwitchableScene/XSceneAnimPlayer")

function XUiPanelSwitchableSceneAnim:Ctor()
    -- 创建播放器
    ---@type XSceneAnimPlayer
    self._Player = XSceneAnimPlayer.New()
    self._IsContinuePlay = true
    self:AddEventListener()
end

function XUiPanelSwitchableSceneAnim:OnDestory()
    self._Player:OnDestroy()
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
    -- 传递给代理
    local proxy = self._Player:GetProxy()
    if proxy and proxy.SetContinuePlay then
        proxy:SetContinuePlay(bo)
    end
end

---强制关闭陀螺仪交互模式
function XUiPanelSwitchableSceneAnim:SetDisableGyro(bo)
    local proxy = self._Player:GetProxy()
    if proxy and proxy.SetForceDisableGyro then
        proxy:SetForceDisableGyro(bo)
    end
end

---视频播放期间挂起场景交互
function XUiPanelSwitchableSceneAnim:OnVideoStart()
    local proxy = self._Player:GetProxy()
    if proxy then
        proxy:SuspendForVideo()
    end
end

---播放场景动画
---@param sceneId number 场景ID
---@param sceneTran UnityEngine.Transform 场景Transform
function XUiPanelSwitchableSceneAnim:Play(sceneId, sceneTran)
    if not XTool.IsNumberValid(sceneId) then
        XLog.Error("播放场景动画失败，SceneId为空.")
        return
    end

    -- 初始化播放器
    self._Player:Init(sceneTran)

    -- 设置场景
    local proxyType = XMVCA.XSwitchableScene:GetSwitchableSceneProxyTypeById(sceneId, true)

    if proxyType then
        self._Player:SetScene(sceneId, sceneTran, proxyType)

        -- 传递继续播放设置
        local proxy = self._Player:GetProxy()
        if proxy and proxy.SetContinuePlay then
            proxy:SetContinuePlay(self._IsContinuePlay)
        end

        -- 开始播放
        self._Player:Play()
    else
        self._Player:ResetScene()
    end
end

---仅播放 无交互
---@param sceneTran UnityEngine.Transform
function XUiPanelSwitchableSceneAnim:AutoPlay(sceneId, sceneTran)
    if not XTool.IsNumberValid(sceneId) then
        XLog.Error("播放场景动画失败，SceneId为空.")
        return
    end
    
    -- 初始化播放器
    self._Player:Init(sceneTran)
    
    -- 设置场景
    local proxyType = XMVCA.XSwitchableScene:GetSwitchableSceneProxyTypeById(sceneId, true)

    if proxyType then
        self._Player:SetScene(sceneId, sceneTran, proxyType)

        -- 强制禁用陀螺仪
        self:SetDisableGyro(true)

        -- 开始播放
        self._Player:Play()
    else
        self:SetDisableGyro(false)
        
        self._Player:ResetScene()
    end
end

---恢复播放
function XUiPanelSwitchableSceneAnim:Resume()
    self._Player:Resume()
end

---暂停播放
function XUiPanelSwitchableSceneAnim:Pause()
    self._Player:Pause()
end

---停止播放
function XUiPanelSwitchableSceneAnim:Stop()
    self._Player:Stop()
end

function XUiPanelSwitchableSceneAnim:GetCurPlayTime()
    local proxy = self._Player:GetProxy()
    if proxy and proxy.GetCurPlayTime then
        return proxy:GetCurPlayTime()
    end
    return 0
end

function XUiPanelSwitchableSceneAnim:IsPlaying()
    return self._Player:IsPlaying()
end

---是否开启交互模式
function XUiPanelSwitchableSceneAnim:IsEnterGyroMode()
    local proxy = self._Player:GetProxy()
    if proxy and proxy._IsGyroEnabled then
        return proxy:_IsGyroEnabled()
    end
    return false
end

function XUiPanelSwitchableSceneAnim:OnCamAnimStatusChange(status, isUseNewCamAnim)
    if not isUseNewCamAnim then
        return
    end
    if status == XEnumConst.Favorability.CameraAnimStatus.Play then
        self:Pause()
    elseif status == XEnumConst.Favorability.CameraAnimStatus.Close then
        self:Resume()
    end
end

return XUiPanelSwitchableSceneAnim