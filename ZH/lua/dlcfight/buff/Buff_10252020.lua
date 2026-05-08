local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252020 : XTheatre6SkillBase
local XBuffScript10252020 = XDlcScriptManager.RegBuffScript(10252020, "XBuffScript10252020", XTheatre6SkillBase)

--效果说明：对手身上的【点燃】达到15层时触发：
--· 【攻击】属性提升20点；
--· 本次战斗内使用任意技能均将【暴击】。

function XBuffScript10252020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self.TargetCount = 15
    self._stackCountAtk = 20
    self._stackCountCrit = 99
    self._critController = self:GetNpc():GetCritController()
    --self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, 1025105,1,0, 3)
end

function XBuffScript10252020:OnLuaSkillEnd(eventArgs)
    self.originAttrib1 = self._proxy:GetBuffStacks( self._enemyUUID,1025101)
    --self:LogError(".....播报下对方点燃层数"..self.originAttrib1)
    if self.originAttrib1 >= self.TargetCount then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
            self.ChanceCheck = 1
        end
    end
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._critController:AddSkillCount(self._stackCountCrit)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025904,1,0,self._stackCountAtk)
end

return XBuffScript10252020


--99不一定够大
--可能会影响affix状态图标的层数    ：管他呢就这么整，不然没啥别的好办法
--申请插入式技能的逻辑可以单独拆到OnNpcAddBuff通知里面, 不过这个不改也行