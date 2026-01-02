local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015690 : XBuffBase
local XBuffScript1015690 = XDlcScriptManager.RegBuffScript(1015690, "XBuffScript1015690", Base)

--效果说明：未进入疲劳阶段时，受到伤害降低20%
function XBuffScript1015690:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015692
    self.magicKind = 1015692
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.enhBuffId = 1015960    --带有【未进入疲劳阶段时】条件的所有触发效果翻倍
    self.enhMagicLevel = 1      --存在增强Buff时，等级+1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0   --目标ID
    ------------执行------------
    self.runeId = 20690

end

---@param dt number @ delta time
function XBuffScript1015690:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end
--region EventCallBack
function XBuffScript1015690:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015690:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    local calMagicLevel = self.magicLevel
    --开局时，添加Buff
    if self._uuid == npcUUID and self.battleStartBuffId == buffId then
        self.targetId = self._proxy:GetNpcFocusTarget(self._uuid)
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffId) then
            calMagicLevel = calMagicLevel + self.enhMagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        if self.targetId ~= 0 then
            self._proxy:ApplyMagic(self._uuid, self.targetId, self.magicId, calMagicLevel)
        end
    end
    --获得疲劳标记时删除
    if self._uuid == npcUUID and self.tiredBuff == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        if self.targetId ~= 0 then
            self._proxy:RemoveBuff(self.targetId, self.magicKind)
        end
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

function XBuffScript1015690:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    local calMagicLevel = self.magicLevel
    --疲劳标记被移除时，重新获得Buff
    if self._uuid == npcUUID and self.tiredBuff == buffId then
        self.targetId = self._proxy:GetNpcFocusTarget(self._uuid)
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffId) then
            calMagicLevel = calMagicLevel + self.enhMagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        if self.targetId ~= 0 then
            self._proxy:ApplyMagic(self._uuid, self.targetId, self.magicId, calMagicLevel)
        end
    end
end
---endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015690:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015690:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015690