--- 主界面场景镜头动画控制
--- 挂载节点即场景镜头节点自身，动画组件位于本节点的 Animation/ 子物体下
---@class XUiPBRMainSceneAnim: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRMainSceneAnim = XClass(XUiNode, "XUiPBRMainSceneAnim")

function XUiPBRMainSceneAnim:OnStart()
    -- 首次进入播放开场动画，后续重新激活的动画交给 OnEnable 的 AnimEnable
    self:PlayAnimation("AnimStart")
    
    self._StartRun = true
end

function XUiPBRMainSceneAnim:OnEnable()
    if self._StartRun then
        self._StartRun = nil
    else
        self:PlayAnimation("AnimEnable")
    end
end

return XUiPBRMainSceneAnim
