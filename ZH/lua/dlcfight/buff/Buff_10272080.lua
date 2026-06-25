local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272080 : XTheatre6SkillBase
local XBuffScript10272080 = XDlcScriptManager.RegBuffScript(10272080, "XBuffScript10272080", XTheatre6SkillBase)

-- 效果说明：首次使用任意技能后触发：
--· 获得【已损生命值】20%的【护盾】；
--· 每使用过1次【插入式技能】，获得5点【耀斑值】，至多30/40/50点。
--· 造成【击飞】

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10272080:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self.maxSunRecover = {
        [1] = 30,
        [2] = 40,
        [3] = 50
    }
    self._protectorMagicId = 1027208    -- 护盾BuffId
    self._InsertSkillCount = 0          -- 初始化一个插入式技能计数器
    self._stackCount = 1                -- 击飞次数
    self._ChanceCheck = 0               -- 自己“首次使用”的触发计数
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self._sunController = self:GetNpc():GetSunController()
    self.Protector = self:GetNpc():GetProtectorController()
end

function XBuffScript10272080:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._ChanceCheck == 0 then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
        self._ChanceCheck = 1
    end
    if eventArgs._skillId == self._skillId then
        --self:LogError(".....播报下属性"..self._InsertSkillCount)
        self._HitFlyController:AddSkillCount(self._stackCount)
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self._protectorMagicId)
        local SunRecover = math.min( (self._InsertSkillCount * 5) , self.maxSunRecover[self._lv] )
        --self:LogError(".....播报下sun"..self._InsertSkillCount)
        self._sunController:CastStackBuff(SunRecover, self._npcUUID)
    end
    if eventArgs._skillType == ETheatre6SkillType.Insert then
        self._InsertSkillCount = self._InsertSkillCount + 1
    end
end

return XBuffScript10272080
