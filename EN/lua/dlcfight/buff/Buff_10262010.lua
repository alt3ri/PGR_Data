local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262010 : XTheatre6SkillBase
local XBuffScript10262010 = XDlcScriptManager.RegBuffScript(10262010, "XBuffScript10262010", XTheatre6SkillBase)

--效果说明：每累计造成3次【击倒】后触发：
--· 造成50%攻击伤害；
--· 若对手在本场战斗中没有出手过，造成【击倒】；
--· 自身每有x点【拼刀】属性，降低对手1点【超算值】。

function XBuffScript10262010:ScriptInit(isGainControl) --初始化
    self._Count = 0                                    --击倒累计计数
    self.ChanceCheck = 0                               --对手是否出手过标记（0=未出手，1=已出手）
    self._stackCountHitDown = 1                        --击倒层数
    self.TargetHitDown = 3                             --触发技能所需击倒次数
    self.dictCSCostRate = {                            --降低对手超算值所需拼刀点数
        [1] = 16,
        [2] = 14,
        [3] = 12
    }
end

function XBuffScript10262010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetNpc():GetHitDownController()
end

function XBuffScript10262010:OnLuaAffixHitDown(eventArgs)
    ------------击倒事件：累计击倒次数，达到目标后插入技能------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._Count = self._Count + 1
    if self._Count == self.TargetHitDown then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self._Count = 0
        --self:LogError("目标插入式技能1注册完成")
    end
end

function XBuffScript10262010:OnLuaAttackerChange(eventArgs)
    ------------出手权交换：标记对手是否已出手过------------
    if eventArgs._newAttackerUUID == self._enemyUUID then
        self.ChanceCheck = 1
    end
end

function XBuffScript10262010:OnLuaSkillStart(eventArgs)
    ------------技能启动：根据对手是否出手过执行不同效果------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    if self.ChanceCheck == 0 then --对手未出手过：仅造成击倒
        self._HitDownController:AddSkillCount(self._stackCountHitDown)
    end

    ------------对手已出手过：根据拼刀属性扣除对手超算值------------
    self.CSCost = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.WrestlePoint) //
        self.dictCSCostRate[self._lv]
    local targetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    if targetCS <= self.CSCost then
        self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID, targetCS)
    else
        self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID, self.CSCost)
    end
end

return XBuffScript10262010

--无法获取到击飞事件
