local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025511 : XTheatre6BuffBase
local XBuffScript1025511 = XDlcScriptManager.RegBuffScript(1025511, "XBuffScript1025511", XTheatre6BuffBase)

--效果说明：首次使用【插入式技能】时，额外获得20点【耀斑值】。

function XBuffScript1025511:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.chanceCheck = 0
    self.sunRecover = 20
    self._sunController = self:GetNpc():GetSunController()
    ------------执行------------
end

function XBuffScript1025511:OnLuaSkillEnd(eventArgs)
    if eventArgs._skillType ~= ETheatre6SkillType.Insert then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.chanceCheck == 0 then
        self._sunController:CastStackBuff(self.sunRecover, self._npcUUID)
        self.chanceCheck = 1
    end
end

return XBuffScript1025511

--调试用的打印别提交到线上
--OnLuaSkillEnd和_npcUUID都来自于肉鸽六的buff基类, 需要继承肉鸽6的buff基类脚本
--主动技能/插入技能/超算成功技能/拼刀成功技能都会触发技能结束和技能启动的通知, 这里需要检查是否是主动技能
--29和30行应该可以直接调用self._proxy:CheckBuffByKind()
