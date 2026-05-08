---@class XSceneAnimProxyBase 场景动画代理基类（纯抽象接口，不假设任何实现方式）
---@field protected _SceneId number 场景ID
---@field protected _SceneTran UnityEngine.Transform 场景Transform
---@field protected _ProxyType string 代理类型标识
local XSceneAnimProxyBase = XClass(nil, "XSceneAnimProxyBase")

---创建代理
---@param sceneId number 场景ID
function XSceneAnimProxyBase:Ctor(proxyType, sceneId)
    self._SceneId = sceneId
    self._SceneTran = nil
    self._ProxyType = proxyType
end

--region 生命周期（子类实现）

---激活场景
---@param sceneTran UnityEngine.Transform
function XSceneAnimProxyBase:OnActivate(sceneTran)
    self._SceneTran = sceneTran
end

---离开场景
function XSceneAnimProxyBase:OnDeactivate()
    self._SceneTran = nil
end

---销毁
function XSceneAnimProxyBase:OnDestroy()
end

--endregion

--region 播放控制（子类实现）

---播放
function XSceneAnimProxyBase:OnPlay()
end

---暂停
function XSceneAnimProxyBase:OnPause()
end

---恢复
function XSceneAnimProxyBase:OnResume()
end

---停止
function XSceneAnimProxyBase:OnStop()

end

---视频播放期间挂起场景交互（子类按需覆写）
function XSceneAnimProxyBase:SuspendForVideo()
end

--endregion

--region 更新（子类实现）

---每帧更新
---@param deltaTime number
function XSceneAnimProxyBase:OnUpdate(deltaTime)
end

--endregion

--region 代理类型

---获取代理类型
---@return string
function XSceneAnimProxyBase:GetProxyType()
    return self._ProxyType
end

--endregion

--region 公共方法

---切换场景
---@param sceneId number
function XSceneAnimProxyBase:SwitchScene(sceneId)
    self._SceneId = sceneId
end

---获取当前场景ID
---@return number
function XSceneAnimProxyBase:GetSceneId()
    return self._SceneId
end

---获取场景Transform
---@return UnityEngine.Transform
function XSceneAnimProxyBase:GetSceneTran()
    return self._SceneTran
end

--endregion

return XSceneAnimProxyBase