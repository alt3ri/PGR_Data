local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025402 : XBuffBase
local XBuffScript1025402 = XDlcScriptManager.RegBuffScript(1025402, "XBuffScript1025402", Base)


--效果说明：每次造成【击飞】时，本场战斗中自身【拼刀】属性提升1点。

function XBuffScript1025402:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025109
    --公用的击倒id
    self.originAttrib1 = 0
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    ------------执行------------
end

--function XBuffScript1025402:Update(dt)
    --每帧执行
--end

function XBuffScript1025402:OnLuaAffixHitFly(eventArgs)
    -- self:LogError("SkillEnd")
    if eventArgs._launcherUUID == self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025901,1,0,1)
    --触发击飞时，计数器+1
    --return self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025402


--signalId 是冗余的
--击倒应该用HitDown事件, 这里用的是HitFly事件
--Update是冗余的
--OnLuaAffixHitFly和_npcUUID都来自于肉鸽六的buff基类, 需要继承肉鸽6的buff基类脚本