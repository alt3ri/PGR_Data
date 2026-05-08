local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10253020 : XTheatre6SkillBase
local XBuffScript10253020 = XDlcScriptManager.RegBuffScript(10253020, "XBuffScript10253020", XTheatre6SkillBase)

--效果说明：
--· 必定【暴击】；
--· 每场战斗首次使用此技能时，额外获得5层<心眼>；
--· 造成5秒【晕眩】。

function XBuffScript10253020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._stackCountNormal = 1
    self._stackCountFirst = 5
    self.ChanceCheck = 0
    self._critController = self:GetNpc():GetCritController()
    --self:LogError(".....初始化完成")
end

function XBuffScript10253020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --self:LogError(".....抓到技能id999:"..eventArgs._skillId)
    --self:LogError(".....抓到技能id1:"..self._skillId)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self:LogError(".....抓到此技能的使用1")
    self._critController:AddSkillCount(self._stackCountNormal)
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
    --self:LogError(".....抓到此技能的使用2")
    if self.ChanceCheck == 0 then
        self._critController:AddSkillCount(self._stackCountFirst)
        --self:LogError(".....抓到此技能的初次使用")
        self.ChanceCheck = 1
    end
end

return XBuffScript10253020


--_critController没有初始化    ：已加
--25行的XDlcCSharpFuncs是冗余的    ：妈的昏厥了