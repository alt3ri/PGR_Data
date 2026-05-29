local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025309 : XTheatre6BuffBase
local XBuffScript1025309 = XDlcScriptManager.RegBuffScript(1025309, "XBuffScript1025309", XTheatre6BuffBase)

--效果说明：每释放2次【常规技能】，造成1层【点燃】。

function XBuffScript1025309:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    self.UseNum = 0
    self._stackCount = 1
    self._stackCountBurn = 1
end

function XBuffScript1025309:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Main then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.UseNum = self.UseNum + 1 --计算使用技能次数
    if self.UseNum >= 2 then
        self:GetEnemyNpc():GetBurnController():CastStackBuff(self._stackCountBurn, self._enemyUUID)
        self.UseNum = 0
    end
end

return XBuffScript1025309