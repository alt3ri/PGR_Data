local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015694 : XBuffBase
local XBuffScript1015694 = XDlcScriptManager.RegBuffScript(1015694, "XBuffScript1015694", Base)

--效果说明：未进入疲劳阶段时，受到伤害降低20%
function XBuffScript1015694:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015695
    self.magicKind = 1015695
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.enhBuffId = 1015960    --带有【未进入疲劳阶段时】条件的所有触发效果翻倍
    self.enhMagicLevel = 1      --存在增强Buff时，等级+1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1

end

---@param dt number @ delta time
function XBuffScript1015694:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end
--region EventCallBack
function XBuffScript1015694:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015694:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    local calMagicLevel = self.magicLevel
    --开局时，添加Buff
    if self._uuid == npcUUID and self.battleStartBuffId == buffId then
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffId) then
            calMagicLevel = calMagicLevel + self.enhMagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
    --获得疲劳标记时删除
    if self._uuid == npcUUID and self.tiredBuff == buffId then
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

function XBuffScript1015694:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    local calMagicLevel = self.magicLevel
    --疲劳标记被移除时，重新获得Buff
    if self._uuid == npcUUID and self.tiredBuff == buffId then
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffId) then
            calMagicLevel = calMagicLevel + self.enhMagicLevel
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, calMagicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    end
end
---endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015694:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015694:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015694