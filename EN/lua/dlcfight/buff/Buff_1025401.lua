local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025401 : XTheatre6BuffBase
local XBuffScript1025401 = XDlcScriptManager.RegBuffScript(1025401, "XBuffScript1025401", XTheatre6BuffBase)


--效果说明：每次造成【击倒】时，本场战斗中自身【先机】属性提升1点。

function XBuffScript1025401:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025109
    --公用的击倒id
    self.originAttrib1 = 0
    self._HitDownController = self:GetNpc():GetHitDownController()
    ------------执行------------
end

--function XBuffScript1025401:Update(dt)
--每帧执行
--end

function XBuffScript1025401:OnLuaAffixHitDown(eventArgs)
    -- self:LogError("SkillEnd")
    if eventArgs._launcherUUID == self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025901,1,0,1)
    --触发击飞时，计数器+1
    --return self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025401


--signalId 是冗余的
--击倒应该用HitDown事件, 这里用的是HitFly事件
--Update是冗余的
--OnLuaAffixHitFly和_npcUUID都来自于肉鸽六的buff基类, 需要继承肉鸽6的buff基类脚本