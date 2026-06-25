local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025515 : XTheatre6BuffBase
local XBuffScript1025515 = XDlcScriptManager.RegBuffScript(1025515, "XBuffScript1025515", XTheatre6BuffBase)

--效果说明：使用【常规/插入式/核心技能】，将分别积累20/40/60点【耀斑值】。【耀斑值】上限为360点。
--每次【耀斑值】满时，耗尽【耀斑值】，释放【耀斑爆发】：无视原有的技能条件与体力消耗，强制释放一号位的【插入式技能】

function XBuffScript1025515:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025107
    --公用的怒火id
    self.originAttrib1 = 0
    ------------执行------------
end


function XBuffScript1025515:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then return end
    if eventArgs._skillType == ETheatre6SkillType.Main then
        self:GetNpc():GetSunController():CastStackBuff(20, self._npcUUID)
    end
    if eventArgs._skillType == ETheatre6SkillType.Insert then
        self:GetNpc():GetSunController():CastStackBuff(40, self._npcUUID)
    end
    if eventArgs._skillType == ETheatre6SkillType.Dodge then
        self:GetNpc():GetSunController():CastStackBuff(60, self._npcUUID)
    end
    if eventArgs._skillType == ETheatre6SkillType.Wrestle then
        self:GetNpc():GetSunController():CastStackBuff(60, self._npcUUID)
    end
end

return XBuffScript1025515
