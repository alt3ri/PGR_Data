local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---效果-获得10点【超算值】,【攻击】属性在本场战斗中提升2点。
---@class XBuffScript.10251600 : XTheatre6SkillBase
local XBuff10251600 = XDlcScriptManager.RegBuffScript(10251600, "XBuffScript10251600", XTheatre6SkillBase)

function XBuff10251600:ScriptInit(isGainControl) --初始化
    ---初始配置
    self.getValue = 10
    self.atkBuffStacks = 2
    ---初始化时，获得10点超算值
    self._proxy:Theatre6AddNpcRuntimeOverClock(self._npcUUID, self.getValue)
    ---获得攻击属性提升的buff
    self:AddAttrib(ENpcAttrib.Attack, self.atkBuffStacks, self._npcUUID, self._npcUUID)
end

return XBuff10251600
