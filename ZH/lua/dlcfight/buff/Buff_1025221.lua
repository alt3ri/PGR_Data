local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025221 : XTheatre6BuffBase
local XBuffScript1025221 = XDlcScriptManager.RegBuffScript(1025221, "XBuffScript1025221", XTheatre6BuffBase)


--效果说明：双方每次造成【格挡】【暴击】时，自身【生命】属性提升100点，并恢复等量【生命值】。--我草，格挡通知呢。哦找到了。

function XBuffScript1025221:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.critTrigger = 0           --暴击触发
    self.blockTrigger = 0          --格挡触发
    self.buffStacks = 100          --生命提升点数
    self.addHealthBuffId = 1025905 --生命提升BuffId
    self.healBuffId = 1025914      --治疗BuffId
    ------------执行------------
    --self.originAttrib4 = 0
end

function XBuffScript1025221:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if self.critTrigger == 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.addHealthBuffId, 1, 0, self.buffStacks)
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.healBuffId, 1, 0, 1)
        self.critTrigger = 1
    end
end

function XBuffScript1025221:OnLuaAffixBlock(eventArgs)
    --self:LogError(".....抓到暴击")
    if self.blockTrigger == 0 then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.addHealthBuffId, 1, 1, self.buffStacks)
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.healBuffId, 1, 0, 1)
        self.blockTrigger = 1
    end
end

function XBuffScript1025221:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.critTrigger = 0           --暴击触发重置
    self.blockTrigger = 0          --格挡触发重置
end

return XBuffScript1025221
