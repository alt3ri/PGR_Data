local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025403 : XTheatre6BuffBase
local XBuffScript1025403 = XDlcScriptManager.RegBuffScript(1025403, "XBuffScript1025403", XTheatre6BuffBase)


--效果说明：每造成过1次【击倒】，敌人被【击倒】时，扣除其1点【体力值】与【超算值】。

function XBuffScript1025403:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    --公用的击倒id
    self.originAttrib1 = 0
    ------------执行------------
end


function XBuffScript1025403:OnLuaAffixHitDown(eventArgs)
    --self:LogError("SkillEnd")
    if eventArgs._launcherUUID == self._npcUUID then return end
    self.originAttrib1 = self.originAttrib1 + 1
    self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    if self.TargetCS <= self.CSCost then self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.TargetCS) --扣除对手超算值
    else self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.originAttrib1)
    end
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.originAttrib1, 0) --扣除对手体力
    --触发击飞时，计数器+1
    --return self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025403
