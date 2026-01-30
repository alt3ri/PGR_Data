local Base = require("Common/XFightBase")

---@class XBuffScript1015414 : XFightBase
local XBuffScript1015414 = XDlcScriptManager.RegBuffScript(1015414, "XBuffScript1015414", Base)

--效果说明：每局的前5次技能，冰伤分别提升10/20/30/40/50
function XBuffScript1015414:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015415 --魔法id
    self.magicLevel = 1 --初始魔法等级
    self.skillCount = 0 --技能释放起始计数
    self.targetCount = 5 --目标技能释放次数（如果要增加，效果表里也要增加Buff的等级）
    self.skillType = 2    --跟战斗约定的起手技能类型，待定
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --添加初始效果
end

---@param dt number @ delta time 
function XBuffScript1015414:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015414:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)        -- OnNpcCastSkillEvent
end

function XBuffScript1015414:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --不是自己释放的就返回
    if not launcherId ~= self._uuid then
        return
    end

    --如果不是技能起手就返回
    local skillTypeTemp = self._proxy:GetActionType(skillId)
    if skillTypeTemp ~= self.skillType then
        return
    end

    --管理Buff释放&计数器，如果已经大于目标次数了，直接返回
    if self.skillCount > self.targetCount then
        return
    end

    self._proxy:RemoveBuff(self._uuid, self.magicId)    --先删除原有Buff
    self.skillCount = self.skillCount + 1       --释放次数+1

    --当前已释放次数<目标次数时，根据等级添加Buff；当前已释放次数=目标次数时，删除后无需再添加Buff
    if self.skillCount < self.targetCount then
        self.magicLevel = self.skillCount           --Magic等级=释放次数
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015414:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015414:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015414
