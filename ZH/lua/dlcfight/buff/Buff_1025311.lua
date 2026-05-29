local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025311 : XTheatre6BuffBase
local XBuffScript1025311 = XDlcScriptManager.RegBuffScript(1025311, "XBuffScript1025311", XTheatre6BuffBase)

--效果说明：处于【点燃】状态的对手，每有1层【点燃】则造成的伤害降低1%。

function XBuffScript1025311:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.UseNum = 0
    --self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, 1025312,1,0, 1) --给对面发个1025312，战斗开始的时候因为玩家初始化比对面早，所以玩家抓不到敌人的id。改成在用完第一次技能的时候给对面挂1025312
end

function XBuffScript1025311:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.UseNum = self.UseNum + 1 --计算使用技能次数
    if self.UseNum <= 1 then
        self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, 1025312,1,0, 1) --给对面发个1025312
    end
end

return XBuffScript1025311

    