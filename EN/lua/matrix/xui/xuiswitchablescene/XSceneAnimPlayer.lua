---@class XSceneAnimPlayer 场景动画播放器（代理容器，不包含业务逻辑）
---@field private _Proxy XSceneAnimProxyBase 当前代理
---@field private _SceneTran UnityEngine.Transform 场景Transform
---@field private _LuaBehaviour XLuaBehaviour LuaBehaviour组件
---@field private _IsPlaying boolean 是否正在播放
local XSceneAnimPlayer = XClass(nil, "XSceneAnimPlayer")

local Time = CS.UnityEngine.Time

---代理类型枚举
XSceneAnimPlayer.ProxyType = {
    Base = 0,
    TimelineDirection = 1,
    TimelineSwitch = 2,
    SceneState = 3,
}

--- 代理类枚举定义（预测每个场景都有完全独立的设计，后续代理命名可跟随版本或场景名）
XSceneAnimPlayer.ProxyType2ClassPath = {
    [XSceneAnimPlayer.ProxyType.TimelineDirection] = "XUi/XUiSwitchableScene/Proxy/XTimelineDirectionProxy",
    [XSceneAnimPlayer.ProxyType.TimelineSwitch] = "XUi/XUiSwitchableScene/Proxy/XTimelineSwitchProxy",
}

---代理类型映射表（静态，子类可扩展）
XSceneAnimPlayer._ProxyClassMap = {}

---注册代理类型
---@param proxyType string 代理类型
---@param proxyClass table 代理类
function XSceneAnimPlayer.RegisterProxyClass(proxyType, proxyClass)
    XSceneAnimPlayer._ProxyClassMap[proxyType] = proxyClass
end

function XSceneAnimPlayer:Ctor()
    self._Proxy = nil
    self._SceneTran = nil
    self._LuaBehaviour = nil
    self._IsPlaying = false
end

--region 生命周期

---初始化（绑定LuaBehaviour）
---@param sceneTran UnityEngine.Transform
function XSceneAnimPlayer:Init(sceneTran)
    if XTool.UObjIsNil(sceneTran) then
        return
    end

    self._SceneTran = sceneTran
    self._LuaBehaviour = sceneTran.gameObject:GetOrAddComponent(typeof(CS.XLuaBehaviour))
    if not XTool.UObjIsNil(self._LuaBehaviour) then
        self._LuaBehaviour.LuaLateUpdate = handler(self, self._OnLateUpdate)
    end
end

---销毁
function XSceneAnimPlayer:OnDestroy()
    if not XTool.UObjIsNil(self._LuaBehaviour) then
        self._LuaBehaviour.LuaLateUpdate = nil
    end

    if self._Proxy then
        self._Proxy:OnDeactivate()
        self._Proxy:OnDestroy()
        self._Proxy = nil
    end

    self._SceneTran = nil
    self._IsPlaying = false
end

---LateUpdate回调
function XSceneAnimPlayer:_OnLateUpdate()
    if not self._IsPlaying then
        return
    end

    if self._Proxy then
        self._Proxy:OnUpdate(Time.deltaTime)
    end
end

--endregion

--region 场景切换（核心：代理复用策略）

---设置场景
---@param sceneId number 场景ID
---@param sceneTran UnityEngine.Transform
---@param proxyType string|nil 代理类型（可选，不传则使用默认逻辑）
function XSceneAnimPlayer:SetScene(sceneId, sceneTran, proxyType)
    -- 获取代理类型
    proxyType = proxyType or self:_GetProxyType(sceneId)

    -- 当前代理类型
    local currentType = self._Proxy and self._Proxy:GetProxyType()

    if proxyType ~= currentType then
        -- 场景类型变化，切换代理
        if self._Proxy then
            self._Proxy:OnDeactivate()
            self._Proxy:OnDestroy()
        end
        self._Proxy = self:_CreateProxyByType(proxyType, sceneId)
    else
        -- 同类型场景，复用代理
        if self._Proxy then
            self._Proxy:SwitchScene(sceneId)
        end
    end

    -- 激活代理
    if self._Proxy then
        self._Proxy:OnActivate(sceneTran)
    end

    self._SceneTran = sceneTran
end

--- 清空场景设置（当场景没有相关功能时）
function XSceneAnimPlayer:ResetScene()
    if self._Proxy then
        self._Proxy:OnDeactivate()
        self._Proxy:OnDestroy()

        self._Proxy = nil
    end

    self._SceneTran = nil
end

---根据场景ID获取代理类型（子类可覆盖）
---@param sceneId number
---@return string
function XSceneAnimPlayer:_GetProxyType(sceneId)
    -- 默认返回TimelineDirection类型
    -- 子类可覆盖此方法，根据sceneId返回不同的代理类型
    -- 未来可从配置读取：return XMVCA.XSwitchableScene:GetProxyType(sceneId)
    return XSceneAnimPlayer.ProxyType.TimelineDirection
end

---根据类型创建代理
---@param proxyType string
---@param sceneId number
---@return XSceneAnimProxyBase
function XSceneAnimPlayer:_CreateProxyByType(proxyType, sceneId)
    local proxyClass = self:_GetProxyClassByType(proxyType)
    if proxyClass then
        return proxyClass.New(proxyType, sceneId)
    end
end

function XSceneAnimPlayer:_GetProxyClassByType(proxyType)
    -- 先看是否已经注册了
    local proxyClass = XSceneAnimPlayer._ProxyClassMap[proxyType]
    
    if proxyClass then
        return proxyClass
    end
    
    -- 再看是否是预定义的代理，是则注册
    if XSceneAnimPlayer.ProxyType2ClassPath[proxyType] then
        proxyClass = require(XSceneAnimPlayer.ProxyType2ClassPath[proxyType])

        if proxyClass then
            XSceneAnimPlayer._ProxyClassMap[proxyType] = proxyClass
            
            return proxyClass
        end
    end
    
    -- 否则返回默认代理
    return require("XUi/XUiSwitchableScene/Base/XSceneAnimProxyBase")
end

--endregion

--region 播放控制

---播放
function XSceneAnimPlayer:Play()
    self._IsPlaying = true
    if self._Proxy then
        self._Proxy:OnPlay()
    end
end

---暂停
function XSceneAnimPlayer:Pause()
    self._IsPlaying = false
    if self._Proxy then
        self._Proxy:OnPause()
    end
end

---恢复
function XSceneAnimPlayer:Resume()
    self._IsPlaying = true
    if self._Proxy then
        self._Proxy:OnResume()
    end
end

---停止
function XSceneAnimPlayer:Stop()
    self._IsPlaying = false
    if self._Proxy then
        self._Proxy:OnStop()
    end
end

--endregion

--region 公共方法

---是否正在播放
---@return boolean
function XSceneAnimPlayer:IsPlaying()
    return self._IsPlaying
end

---获取当前代理
---@return XSceneAnimProxyBase
function XSceneAnimPlayer:GetProxy()
    return self._Proxy
end

---获取当前场景Transform
---@return UnityEngine.Transform
function XSceneAnimPlayer:GetSceneTran()
    return self._SceneTran
end

--endregion

return XSceneAnimPlayer