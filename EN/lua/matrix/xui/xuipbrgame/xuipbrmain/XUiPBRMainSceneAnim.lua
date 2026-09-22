--- 主界面场景镜头动画控制
--- 挂载节点即场景镜头节点自身，动画组件位于本节点的 Animation/ 子物体下
--- AnimStart/AnimEnable 均设 playOnAwake，初始化时隐藏，由父界面 OnEnable 驱动播放
---@class XUiPBRMainSceneAnim: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRMainSceneAnim = XClass(XUiNode, "XUiPBRMainSceneAnim")

function XUiPBRMainSceneAnim:OnStart()
    local animRoot = self.Transform:Find("Animation")
    if animRoot then
        local animStart = animRoot:Find("AnimStart")
        local animEnable = animRoot:Find("AnimEnable")
        if animStart then
            self._AnimStart = animStart.gameObject
            self._AnimStart:SetActive(false)
        end
        if animEnable then
            self._AnimEnable = animEnable.gameObject
            self._AnimEnable:SetActive(false)
        end
    end
end

function XUiPBRMainSceneAnim:PlayAnimStart()
    self:_ActivateAnim(self._AnimStart, self._AnimEnable)
end

function XUiPBRMainSceneAnim:PlayAnimEnable()
    self:_ActivateAnim(self._AnimEnable, self._AnimStart)
end

-- playOnAwake 节点需先关再开才能重播，同时隐藏对称节点
function XUiPBRMainSceneAnim:_ActivateAnim(animGo, hideGo)
    if hideGo then
        hideGo:SetActive(false)
    end
    if not animGo then
        return
    end
    animGo:SetActive(false)
    animGo:SetActive(true)
end

return XUiPBRMainSceneAnim
