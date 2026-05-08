local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025403 : XBuffBase
local XBuffScript1025403 = XDlcScriptManager.RegBuffScript(1025403, "XBuffScript1025403", Base)


--效果说明：每造成过1次【击倒】，敌人被【击倒】时，扣除其1点【体力值】与【超算值】。

function XBuffScript1025403:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025109
    --公用的击倒id
    self.originAttrib1 = 0
    ------------执行------------
end

function XBuffScript1025403:Update(dt)
    --每帧执行
end

function XBuffScript1025403:OnLuaAffixHitFly(eventArgs)
    --self:LogError("SkillEnd")
    if eventArgs._launcherUUID == self._npcUUID then return end
    self.originAttrib1 = self.originAttrib1 + 1
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025910,1,0, self.originAttrib1)
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025912,1,0, self.originAttrib1)
    --触发击飞时，计数器+1
    --return self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025403

--signalId 是冗余的
--击倒应该用HitDown事件, 这里用的是HitFly事件
--Update是冗余的
--OnLuaAffixHitFly和_npcUUID都来自于肉鸽六的buff基类, 需要继承肉鸽6的buff基类脚本
--扣除体力值和扣除超算值都有lua接口, 没必要用magic