local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025607 : XTheatre6BuffBase
local XBuffScript1025607 = XDlcScriptManager.RegBuffScript(1025607, "XBuffScript1025607", XTheatre6BuffBase)

--效果说明：每造成4次【剧毒】伤害，造成1层【剧毒】。

function XBuffScript1025607:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.Count = 0
    self.CountTarget = 4
    --self:LogError("......初始化")
    ------------执行------------
end

function XBuffScript1025607:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end

function XBuffScript1025607:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript1025607:AfterDamageCalc(eventArgs)
    if eventArgs.Target == self._npcUUID then return end
    if eventArgs.Id ~= 10281001 then return end
    self.Count = self.Count + 1 --计算暴击次数
    if self.Count >= self.CountTarget then
        self._poisonedController:CastStackBuff(1, self._enemyUUID)
        self.Count = 0
    end
end


return XBuffScript1025607
