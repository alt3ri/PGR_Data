local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252010 : XTheatre6SkillBase
local XBuffScript10252010 = XDlcScriptManager.RegBuffScript(10252010, "XBuffScript10252010", XTheatre6SkillBase)

--效果说明：触发击飞时，请求释放插入技

function XBuffScript10252010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
end

function XBuffScript10252010:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._level:RequestInsertSkill(self._uuid,self.TargetSkill)
    --self:LogError("目标插入式技能1注册完成")
end

return XBuffScript10252010

--无法获取到击飞事件