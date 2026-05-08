local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025411 : XBuffBase
local XBuffScript1025411 = XDlcScriptManager.RegBuffScript(1025411, "XBuffScript1025411", Base)


--效果说明：【狂暴】状态下使用主动技能时，额外获得3点【体力值】。

function XBuffScript1025411:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025108
    --XLog.Error(".....初始化")
    --公用的狂暴id
    self.originAttrib1 = 0
    ------------执行------------
end

function XBuffScript1025411:Update(dt)
    --每帧执行
end

function XBuffScript1025411:OnLuaSkillEnd(eventArgs)
    --XLog.Error(".....技能结束")
    --self:LogError("SkillEnd")
    self.originAttrib1 = self._proxy:GetBuffStacks( self._uuid,1025108)
    if self.originAttrib1 ~= 1 then return end
    if eventArgs._launcherUUID == self._npcUUID then return end
    --XLog.Error(".....抓到了玩家在狂暴状态下执行行为")
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1025910,1,0,3)
    --return self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025411

--调试用的打印别提交到线上
--OnLuaSkillEnd和_npcUUID都来自于肉鸽六的buff基类, 需要继承肉鸽6的buff基类脚本
--主动技能/插入技能/超算成功技能/拼刀成功技能都会触发技能结束和技能启动的通知, 这里需要检查是否是主动技能
--29和30行应该可以直接调用self._proxy:CheckBuffByKind()