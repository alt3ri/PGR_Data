local Base = require("Common/XFightBase")

---@class XBuffScript1015036 : XBuffBase
local XBuffScript1015036 = XDlcScriptManager.RegBuffScript(1015036, "XBuffScript1015036", Base)

--效果说明：每释放2次技能，将使自己下一次技能的【火属性伤害提升】80点
function XBuffScript1015036:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel = 1  -- 初始buff等级
    self.magicId = 1015037     -- 火伤BUFF
    self.count = 0         -- buff叠加计数器
    self.maxCount = 2  --目标次数
    self.skillStartType = 2    --起手技能的标记
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015036:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015036:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastSkillEvent
end

function XBuffScript1015036:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --判断一下是不是自己释放的
    if launcherId ~= self._uuid then
        return
    end
    --判断一下是不是技能起手
    local skillType = self._proxy:GetActionType(skillId)
    if skillType ~= self.skillStartType then
        return
    end
    --判断下身上有没有Buff，有的话删除
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
    --如果已经到了最大次数，则施加buff，没到次数则计数+1
    if self.count >= self.maxCount then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.count = 0
    else
        self.count = self.count + 1
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015036:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015036:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015036
