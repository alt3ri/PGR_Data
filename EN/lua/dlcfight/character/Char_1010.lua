---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋万事脚本
---@class XCharTes1010 : XAFKCharBase
local XCharTes1010 = XDlcScriptManager.RegCharScript(1010, "XCharTes1010", Base)

function XCharTes1010:Init() --初始化
    Base.Init(self)
    self.Jishu = 0
end

---@param dt number @ delta time 
function XCharTes1010:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharTes1010:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

end

--region EventCallBack
function XCharTes1010:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastSkillEvent
end

function XCharTes1010:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)
    
    if launcherId ~= self._uuid then
        return
    end

    if targetId == 0 then --效果都需要有目标才生效
        return
    end

    if skillId == 101006 then --火焰无人机
        --Dot伤害
        self._proxy:ApplyMagic(self._uuid, targetId, 1010013, 1) --Dot伤害
    end

    if skillId == 101009 then --自爆无人机
        --自爆无人机，延迟伤害
        self._proxy:ApplyMagic(self._uuid, targetId, 1010015, 1) --延迟爆炸
    end

    if skillId == 101020 then --灼烧无人机
        self._proxy:ApplyMagic(self._uuid, targetId, 1010017, 1) --dot伤害
    end

    if skillId == 101013 then --寂灭灵灰强化效果
        if self._proxy:CheckBuffByKind(self._uuid, 1010518) and self.Jishu < 4 then
            self.Jishu = self.Jishu + 1
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010520, 1) --删除强化效果
        end
    end
end

function XCharTes1010:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionBeforeEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    if skillId == 101029 then --闪避技能
        self:FaceTargetSide()
    end

end

function XCharTes1010:FaceTargetSide()--看向侧面
    local own = self._uuid
    local targetPosition = self._proxy:GetNpcPosition(self._proxy:GetFightTargetId(own))  --获取自己战斗目标的位置
    local distance = 3
    local euler = {x=0,y=45,z=0} --概率左右，增加变化

    if self:GetRandomSuccess(50) then
        euler = {x=0,y=-45,z=0}
    end

    local pos = self._proxy:GetNpcOffsetPosition(self._uuid,targetPosition,euler,distance) --获取和目标一个偏移的位置，用来看向这个位置

    self._proxy:SetNpcFaceToPosition(self._uuid,pos) --看向侧面
end--向侧面望去

function XCharTes1010:GetRandomSuccess(maybe)--概率成功
    local isSuccess = false

    if self._proxy:Random(0,100) < maybe then
        isSuccess = true
    end

    return isSuccess
end


function XCharTes1010:Terminate()
    Base.Terminate(self)
end

return XCharTes1010
