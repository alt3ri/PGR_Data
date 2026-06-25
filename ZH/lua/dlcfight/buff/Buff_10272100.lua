local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272100 : XTheatre6SkillBase
local XBuffScript10272100 = XDlcScriptManager.RegBuffScript(10272100, "XBuffScript10272100", XTheatre6SkillBase)

-- 效果说明：累计触发6/5/4次【插入式技能】时触发：
--· 造成100%攻击伤害；
--· 自身每有1点【攻击】属性，获得1点【护盾】；
--· 造成【击飞】

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272100:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)
    self._TargetCount = {
        [1] = 6,
        [2] = 5,
        [3] = 4                         -- 技能释放次数需求
    }
    self.SkillCount = 0                 -- 使用技能次数计数器
    self.dmgTrigger = true
    self._protectorMagicId = 1027210    -- 护盾BuffId
    --self._AddATK = 10                 -- 攻击提升
    self._stackCount = 1                -- 击飞次数
    self.Protector = self:GetNpc():GetProtectorController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10272100:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType ~= ETheatre6SkillType.Insert then return end
    self.SkillCount = self.SkillCount + 1
    if self.SkillCount == self._TargetCount[self._lv] then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self.SkillCount = 0
    end
    if eventArgs._skillId == self._skillId then
        local attack = self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.Attack)
        local Energy1 = self._proxy:GetNpcAttribMaxValue(self._npcUUID,ENpcAttrib.CustomEnergyGroup1) --刷新一下缓存
        self._proxy:AddNpcAttribAdditive(self._npcUUID, ENpcAttrib.CustomEnergyGroup1, -Energy1, 0) -- 把之前的缓存清空
        self._proxy:AddNpcAttribAdditive(self._npcUUID, ENpcAttrib.CustomEnergyGroup1, attack, 0) -- 令自定义能量1的上限等值于玩家攻击
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self._protectorMagicId)
        --self:AddAttrib(ENpcAttrib.Attack, self._AddATK, self._npcUUID, self._npcUUID)
        self._HitFlyController:AddSkillCount(self._stackCount)
    end
end


return XBuffScript10272100
