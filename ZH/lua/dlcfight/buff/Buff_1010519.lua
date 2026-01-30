local Base = require("Common/XFightBase")
---@class XBuffScript1010519 : XFightBase
local XBuffScript1010519 = XDlcScriptManager.RegBuffScript(1010519, "XBuffScript1010519", Base)

function XBuffScript1010519:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
end

---@param dt number @ delta time 
function XBuffScript1010519:Update(dt)
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
    if SelfHpPercent < 0.3 or TargetHpPercent < 0.3 then
        if self._proxy:CheckBuffByKind(self._uuid, 1016380) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010521, 1) --额外护盾1
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016381) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010524, 1) --额外护盾2
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016382) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010525, 1) --额外护盾3
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016383) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010526, 1) --额外护盾4
        elseif self._proxy:CheckBuffByKind(self._uuid, 1016384) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1010527, 1) --额外护盾5
        end
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1010522, 1) --删除额外护盾
    end
    
end

return XBuffScript1010519
