local XRpgMakerGameActionBase = require("XModule/XRpgMakerGame/XAction/XRpgMakerGameActionBase")

---@class XRpgMakerGameActionSkillTypeChange:XRpgMakerGameActionBase
local XRpgMakerGameActionSkillTypeChange = XClass(XRpgMakerGameActionBase, "XRpgMakerGameActionSkillTypeChange")

-- 继承类初始化
function XRpgMakerGameActionSkillTypeChange:OnInit()
    
end

-- 执行
function XRpgMakerGameActionSkillTypeChange:Execute()
    local skillTypes = self.ActionData.CurSkillTypes
    if self.ActionData.RoleId ~= 0 then
        self._Scene.PlayerObj:ChangeSkillTypes(skillTypes)
    elseif self.ActionData.ShadowId ~= 0 then
        local shadowObj = XDataCenter.RpgMakerGameManager.GetShadowObj(self.ActionData.ShadowId)
        shadowObj:ChangeSkillTypes(skillTypes)
    elseif self.ActionData.MonsterId ~= 0 then
        ---@type XRpgMakerGameMonsterData
        local monsterObj = XDataCenter.RpgMakerGameManager.GetMonsterObj(self.ActionData.MonsterId)
        monsterObj:ChangeSkillTypes(skillTypes)
    else
        XLog.Error(string.format("Action %s 未处理属性变化! ActionData = ", XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameActionType.ActionSkillTypeChange, XLog.Dump(self.ActionData)))
    end
    
    self:Complete()
end

return XRpgMakerGameActionSkillTypeChange