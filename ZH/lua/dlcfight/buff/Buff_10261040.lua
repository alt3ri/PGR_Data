local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261040 : XTheatre6SkillBase
local XBuffScript10261040 = XDlcScriptManager.RegBuffScript(10261040, "XBuffScript10261040", XTheatre6SkillBase)

--效果说明：
--·自身处于【狂暴】状态下时，额外获得1层<坚毅>。

function XBuffScript10261040:ScriptInit(isGainControl) --初始化
    self._stackCount = 1                               --坚毅层数
    self.StackBuffBurst = 1025108                      --狂暴buffId
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuffScript10261040:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10261040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --判断是否处于狂暴状态
    local isBurst = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffBurst) >= 1
    if not isBurst then return end
    --处于狂暴状态，获得坚毅
    self._blockController:AddSkillCount(self._stackCount)
end

return XBuffScript10261040
