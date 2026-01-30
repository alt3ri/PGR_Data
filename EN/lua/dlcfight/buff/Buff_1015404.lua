local Base = require("Common/XFightBase")

---@class XBuffScript1015404 : XFightBase
local XBuffScript1015404 = XDlcScriptManager.RegBuffScript(1015404, "XBuffScript1015404", Base)

--效果说明：每3次释放技能，将使自己获得3s的冰伤提升50
function XBuffScript1015404:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015405 --魔法id
    self.magicLevel = 1 --初始魔法等级
    self.skillCount = 0 --技能释放起始计数
    self.targetCount = 3 --目标技能释放次数
    self.skillStartType = 2    --起手技能的标记
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015404:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015404:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastSkillEvent
end

function XBuffScript1015404:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    XLog.Warning("开始释放技能")

    --不是自己释放的就返回
    if launcherId ~= self._uuid then
        return
    end

    --如果不是技能起手就返回
    local skillType = self._proxy:GetActionType(skillId)
    --判断一下是不是技能起手
    if skillType ~= self.skillStartType then
        XLog.Warning("不是起手技能")
        return
    end

    --管理Buff释放&计数器，如果计数满3次，施加增益Buff并重置计数器
    if self.skillCount == self.targetCount then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.skillCount = 1
    elseif self.skillCount < self.targetCount then
        self.skillCount = self.skillCount + 1
    end
    XLog.Warning(self.skillCount)
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015404:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015404:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015404
