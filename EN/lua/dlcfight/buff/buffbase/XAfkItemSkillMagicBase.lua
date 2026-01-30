local Base = require("Buff/BuffBase/XBuffBase")
---自走棋ItemSkillMagic基础脚本
---@class XAfkItemSkillMagicBase : XBuffBase
local XAfkItemSkillMagicBase = XClass(Base,"XAfkItemSkillMagicBase")

--region 脚本生命周期
function XAfkItemSkillMagicBase:Init() --初始化
    Base.Init(self)
    -------------------------------读表------------------------
    self.config = self._proxy:GetAutoChessSkillConfigByMagicId(self._buffId) --通过MagicId获得配置
    -------------------------------配置------------------------
    self.itemSkillId = self.config.Id
    self.cd =self.config.CoolDownSec
    -----------------------------逻辑------------------------
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)  --初始Timer
    self:ItemSkillMagicStop() --默认不可以触发，等关卡发消息触发。
end

---@param dt number @ delta time 
function XAfkItemSkillMagicBase:Update(dt)
    Base.Update(self, dt)

    if not self.isCanTrigger then --不能触发的时候
        return
    end
    if not self:ItemSkillMagicCondition() then
        return
    end
    
    self:ItemSkillMagicTrigger()  --触发时要执行的内容
end

function XAfkItemSkillMagicBase:Terminate()
    Base.Terminate(self)
end
--endregion

--region 事件系统
function XAfkItemSkillMagicBase:InitEventCallBackRegister() --注册ItemSkillMagic要用的事件
    -----------Lua事件监听-------------------------------------
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessSetAIEnable)       --注册AI设置事件
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)       -- 注册触发ComboStart事件
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboEnd)       --注册Combo结束事件
    -----------Lua事件监听-------------------------------------
end

---@param eventType number
---@param eventArgs userdata
function XAfkItemSkillMagicBase:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

end

function XAfkItemSkillMagicBase:HandleLuaEvent(eventType, eventArgs)
    Base.HandleLuaEvent(self, eventType, eventArgs)

    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then --Combo开始
        self:OnLuaComboStartEvent(eventArgs.NpcUUid,eventArgs.ItemSkillId)
    end

    if eventType == EFightLuaEvent.AutoChessItemSkillComboEnd then --Combo结束
        self:OnLuaComboEndEvent(eventArgs.NpcUUid,eventArgs.ItemSkillId)
    end

    if eventType == EFightLuaEvent.AutoChessSetAIEnable then --设置AI
        self:OnLuaSetAiEnableEvent(eventArgs.Enable)
    end
end

function XAfkItemSkillMagicBase:OnLuaComboStartEvent(npcUUID, itemSkillId)
    if npcUUID ~= self._uuid then
        return
    end
    if itemSkillId ~= self.itemSkillId then
        return
    end

    self._proxy:SetAutoChessSkillActiveState(self._uuid,self.itemSkillId)--当前技能正在释放
end

function XAfkItemSkillMagicBase:OnLuaComboEndEvent(npcUUID, itemSkillId) --Combo结束
    --XLog.Warning("itemID:"..itemSkillId.."npcID:"..npcUUID.."Combo结束")
    if (npcUUID ~= self._uuid) or (itemSkillId~=self.itemSkillId) then
        return
    end
    self:ItemSkillMagicGoOn()
end

function XAfkItemSkillMagicBase:OnLuaSetAiEnableEvent(isAiOpen) -- 设置AI开关
    if not isAiOpen then  --是在开启AI的时候生效
        return
    end
    self:ItemSkillMagicBegin()
end
--endregion

--region ItemSkill核心功能

function XAfkItemSkillMagicBase:ItemSkillMagicCondition() --条件，返回True表示成功，返回False表示失败
    return self:CheckCd()
end

function XAfkItemSkillMagicBase:ItemSkillMagicTrigger() --触发时要执行的内容
    --发送事件
    ---@type XLuaEventArgsAutoChessTriggerItemSkill
    local eventArg = {
        NpcUUid = self._uuid,
        ItemSkillId = self.itemSkillId
    }
    self:DispatchLuaEvent(ELuaEventTarget.Npc, EFightLuaEvent.AutoChessTriggerItemSkill, eventArg)--发送触发进入队列事件
    self._proxy:SetAutoChessSkillTriggerState(self._uuid,self.itemSkillId)--设置技能ui状态
    --暂停Magic
    self:ItemSkillMagicStop()
end

function XAfkItemSkillMagicBase:ItemSkillMagicBegin()
    --AI开启时开启记时
    XLog.Warning(self.itemSkillId.."开始")
    self.isCanTrigger = true
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)  --重新算CD
    self._proxy:SetAutoChessSkillData(self._uuid,self.itemSkillId,self.cd,self.cd) --重新开始计算CD
end

function XAfkItemSkillMagicBase:ItemSkillMagicStop()
    --Magic暂时停止
    self.isCanTrigger = false
end

function XAfkItemSkillMagicBase:ItemSkillMagicGoOn()
    --Combo结束Magic继续运行
    XLog.Warning(self.itemSkillId.."继续")
    self.isCanTrigger = true
    self.timer = self.cd + self._proxy:GetFightTime(self._uuid)  --重新算CD
    self._proxy:SetAutoChessSkillData(self._uuid,self.itemSkillId,self.cd,self.cd) --重新开始计算CD
end

function XAfkItemSkillMagicBase:CheckCd()
    if self.isCanTrigger == false then  --不可以触发的时候永远到不了Cd结束。
        return false
    end
    return self._proxy:GetFightTime(self._uuid) >= self.timer  --返回CD是否到了
end

--endregion

return XAfkItemSkillMagicBase
