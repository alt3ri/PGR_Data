local Base = require("Common/XFightBase")
---@class XBuffScript1010578 : XFightBase
local XBuffScript1010578 = XDlcScriptManager.RegBuffScript(1010578, "XBuffScript1010578", Base)

function XBuffScript1010578:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
end

---@param dt number @ delta time 
function XBuffScript1010578:Update(dt)
    Base.Update(self, dt)
    local Target = self._proxy:GetFightTargetId(self._uuid) -- 获取战斗目标
    if not self._proxy:CheckNpc(Target) or not self._proxy:CheckNpc(self._uuid) then --目标或自己死了后续就不执行
        return
    end
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local TargetHp = self._proxy:GetNpcAttribValue(Target,0) -- 检测当前敌方血量
    local TargetHpMax = self._proxy:GetNpcAttribMaxValue(Target,0) --检测当前敌方最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    local TargetHpPercent = TargetHp / TargetHpMax -- 获取敌方血量百分比
    if SelfHpPercent > TargetHpPercent  then
        if self._proxy:CheckBuffByKind(self._uuid, 1016390) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010580, 1) --强化回血1级
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016391) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010667, 1) --强化回血2级
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016392) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010668, 1) --强化回血3级
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016393) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010669, 1) --强化回血4级
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016394) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010670, 1) --强化回血5级
        end
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1010581, 1) --删除强化回血
    end
end

return XBuffScript1010578
