local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261090 : XTheatre6SkillBase
local XBuffScript10261090 = XDlcScriptManager.RegBuffScript(10261090, "XBuffScript10261090", XTheatre6SkillBase)

--效果说明：
-- · 扣除双方10点【体力值】。
-- · 获得1层<心眼>。

function XBuffScript10261090:ScriptInit(isGainControl) --初始化
    self.staminaChange = -10                           --体力扣除量
    self.stackCount = 1                                --心眼层数
    --注册暴击控制器
    self._critController = self:GetNpc():GetCritController()
end

function XBuffScript10261090:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --扣除双方体力值
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, self.staminaChange, 0)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.staminaChange, 0)
    --添加心眼层数
    self._critController:AddSkillCount(self.stackCount)
end

return XBuffScript10261090