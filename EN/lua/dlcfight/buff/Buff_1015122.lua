local Base = require("Common/XFightBase")

---@class XBuffScript1015122 : XFightBase
local XBuffScript1015122 = XDlcScriptManager.RegBuffScript(1015122, "XBuffScript1015122", Base)

--效果说明：进入疲劳阶段时，获得3次技能增伤80
function XBuffScript1015122:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015123          --疲劳增伤buff
    self.magicLevel = 1             --buff等级
    self.skillCount = 0             --技能计数
    self.skillTargetCount = 3       --3次技能增伤
    self.tiredBuffId = 1010029      --疲劳buff id
    self.startSkillType = 2         --技能起手类型
    self.normalAtkType = 1          --普攻类型
    self.triggerFinish = false      --判断是否已经完成全部增伤逻辑（增伤3次，并且已清除最后一次增伤）
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015122:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1015122:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
end

function XBuffScript1015122:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --进入疲劳后，如果自己释放技能时获得增伤，如果是普攻则删除增伤
    --判断是否已经完成全部增伤逻辑（增伤3次，并且已清除最后一次增伤）
    if self.triggerFinish then
        return
    end
    --判断是否进入疲劳
    if not self._proxy:CheckBuffByKind(self._uuid, self.tiredBuffId) then
        return
    end
    --不是自己释放的，返回
    if launcherId ~= self._uuid then
        return
    end
    --获取当前技能类型、释放次数、是否为最后一次、是否有增伤Buff
    local skillType = self._proxy:GetActionType(skillId)
    local isSkillCountOk = self.skillCount < self.skillTargetCount
    local isLastRemove = self.skillCount == self.skillTargetCount
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid,self.magicId)
    if skillType == self.startSkillType and isSkillCountOk then
        --如果是技能，当次数小于目标次数时，添加Buff
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.skillCount = self.skillCount + 1
        XLog.Warning("1015122：增伤生效，生效次数为" .. self.skillCount)
    elseif skillType == self.normalAtkType and isBuffActive then
        --如果是普攻，且身上有Buff，则删除Buff，如果次数已经达到目标次数了，则标记为逻辑全部完成
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        XLog.Warning("1015122：增伤移除")
        if isLastRemove then
           self.triggerFinish = true
           XLog.Warning("1015122：最后一次增伤移除")
        end
    end

end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015122:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015122:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015122
