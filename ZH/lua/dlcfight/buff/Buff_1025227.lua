local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025227 : XTheatre6BuffBase
local XBuffScript1025227 = XDlcScriptManager.RegBuffScript(1025227, "XBuffScript1025227", XTheatre6BuffBase)


--效果说明：进入战斗时，自身每有1点【体力】属性，自身【生命值上限】在本场战斗中提升4点，并恢复等量【生命值】。

function XBuffScript1025227:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.BuffId = 1025905     --生命buffid
    self.healBuffId = 1025915 --治疗BuffId
    self.ratio = 4            --倍率
    ------------执行------------
    self.curStamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    self.stacks = self.curStamina * self.ratio
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1, 0, self.stacks)
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.healBuffId, 1, 0, 1)
end

function XBuffScript1025227:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
end

function XBuffScript1025227:AfterCureCalc(eventArgs)
    if eventArgs.Target ~= self._uuid then return end
    if eventArgs.Id ~= self.healBuffId then return end
    local healCal = self.stacks
    self._proxy:SetAfterCureMagicContext(eventArgs.ContextId, healCal)
end

return XBuffScript1025227
