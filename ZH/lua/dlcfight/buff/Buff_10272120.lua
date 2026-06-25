local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272120 : XTheatre6SkillBase
local XBuffScript10272120 = XDlcScriptManager.RegBuffScript(10272120, "XBuffScript10272120", XTheatre6SkillBase)

-- 效果说明：使用【拼刀成功技能】后触发：
--· 造成120%攻击的伤害；
--· 获得40点【耀斑值】，每次使用时【耀斑值】恢复量降低10点。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272120:ScriptInit(isGainControl)
    --XTheatre6SkillBase.ScriptInit(self, isGainControl)

    --self.TLCost = 10                  -- 体力消耗量
    self._SunRecover = 40               -- 初始耀斑恢复量
    self._SunDecrease = 10              -- 每次使用后耀斑值恢复量降低
    self._sunController = self:GetNpc():GetSunController()
end

function XBuffScript10272120:OnLuaSkillStart(eventArgs)
    local ChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Wrestle then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
    if eventArgs._skillId ~= self._skillId then return end
    if ChanceCheck == 0 then
        --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.TLCost, 0)
        self._sunController:CastStackBuff(self._SunRecover, self._npcUUID)
        --self:LogError(".....耀斑获取通知1027，"..self._SunRecover) -- 不知道为什么使用一次技能会执行两次这段代码，加个判断
        self._SunRecover = self._SunRecover - self._SunDecrease
        if self._SunRecover <= 0 then
            self._SunRecover = 0 -- 虽然CastStackBuff不会因为输入负数而报错但还是处理一下
        end
        ChanceCheck = 1
    end
end


return XBuffScript10272120
