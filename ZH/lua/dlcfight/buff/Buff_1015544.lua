local Base = require("Common/XFightBase")

---@class XBuffScript1015544 : XFightBase
local XBuffScript1015544 = XDlcScriptManager.RegBuffScript(1015544, "XBuffScript1015544", Base)

--效果说明：开局时，扣除自身40%HP，转化为等值护盾（与开局效果翻倍配合才能开局背水）彩蛋：如果再拿了开局buff触发两次，就似了

function XBuffScript1015544:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = 1015545
    self.magicId2 = 1015546
    self.magicLevel = 1
    self.percent = 0.4
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.isSelfHurt = false
    self.activeTime = 0.1   --确保能吃到开局效果的加成，延迟0.1秒释放
    self.enhBuff1Id = 1015790 --狂飙开幕类型符纹效果翻倍
    self.enhBuff1Percent = 0.8
    self.enhBuff1MagicLevel = 2
    self.signalCtrlId = 1015906     --【开局】状态管理Buff
    ------------执行------------
    self.runeId = self.magicId1 - 1015000 + 20000 - 1
    self.activeTimer = 0  --确保能吃到开局效果的加成，延迟0.1秒释放
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【开局】管理Buff

end

---@param dt number @ delta time
function XBuffScript1015544:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    --有强化Buff1时，比例和效果等级调整
    if self._proxy:CheckBuffByKind(self._uuid, self.enhBuff1Id) then
        self.percent = self.enhBuff1Percent
        self.magicLevel = self.enhBuff1MagicLevel
    end

    if self.activeTimer == 0 then
        self.activeTimer = self.activeTime + self._proxy:GetNpcTime(self._uuid)
    end

    if (not self.isSelfHurt) and self._proxy:GetNpcTime(self._uuid) >= self.activeTimer then
        -- 战斗开始时扣血1
        self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
        self.attHp = math.floor(self.maxHp * self.percent)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.isSelfHurt = true
    end
end

--region EventCallBack
function XBuffScript1015544:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) -- OnNpcDamageEvent
end

function XBuffScript1015544:AfterDamageCalc(eventArgs)
    if eventArgs.Id == self.magicId1 then
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.attHp, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    end
end

function XBuffScript1015544:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if magicId == self.magicId1 then
        -- 添加护盾
        self._proxy:ApplyMagic(self._uuid, targetId, self.magicId2, self.magicLevel)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015544:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015544:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015544

    