local Base = require("Common/XFightBase")
---@class XBuffScript1013217 : XFightBase
local XBuffScript1013217 = XDlcScriptManager.RegBuffScript(1013217, "XBuffScript1013217", Base)

function XBuffScript1013217:Init() --初始化
    Base.Init(self)
    self.kaiguan = true
end


---@param dt number @ delta time
function XBuffScript1013217:Update(dt)
    Base.Update(self, dt)
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标

    if not self._proxy:CheckBuffByKind(self._uuid, 1010449) then
        return
    end

    if not self._proxy:CheckBuffByKind(self._uuid, 1015992)then
        return
    end

    if not self._proxy:CheckActorExist(target) then --检测目标是否存活
    return
    end

    if self.kaiguan == false then --检测目标是否存活
    return
    end

    self.kaiguan = false
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾

    self._proxy:AddTimerTask(10, function()--延迟10秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(20, function()--延迟20秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(30, function()--延迟30秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(40, function()--延迟40秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(50, function()--延迟50秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(60, function()--延迟60秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(70, function()--延迟70秒后，释放技能
    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
    local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
    if SelfHpPercent > 0.4 then
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
    else
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
    end
    end)

    self._proxy:AddTimerTask(80, function()--延迟80秒后，释放技能
        local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
        local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
        local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
        if SelfHpPercent > 0.4 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1013218, 1) --额外护盾
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1013219, 1) --强化护盾
        end
    end)

end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1013217:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1013217:Terminate()
    Base.Terminate(self)
end

return XBuffScript1013217
