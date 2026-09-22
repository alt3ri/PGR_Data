local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025601 : XTheatre6BuffBase
local XBuffScript1025601 = XDlcScriptManager.RegBuffScript(1025601, "XBuffScript1025601", XTheatre6BuffBase)

--效果说明：触发【暴击】时，自身超算属性提升10点。

function XBuffScript1025601:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.ChanceCheck = 0
    self._StackBuff = 6
    ------------执行------------
end

function XBuffScript1025601:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.ChanceCheck = 0
end

function XBuffScript1025601:OnLuaAffixCritDamage(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025902,1,0, self._StackBuff)
        self.ChanceCheck = 1       --一个技能仅生效一次
    end
end

return XBuffScript1025601
