---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-加百列
---@class XCharTes8213 : XAFKCharBase
local XCharTes8213 = XDlcScriptManager.RegCharScript(8213, "XCharTes8213", Base)

function XCharTes8213:Init() --初始化
    Base.Init(self)

    self._proxy:SetNpcAnimationLayer(self._uuid, 0)

end


function XCharTes8213:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
end

function XCharTes8213:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)--动画层根据对应技能切换
    Base.OnNpcCastActionBeforeEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if (skillId == 821310) then
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
    else
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
    end

end

return XCharTes8213
