local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1000494 : XFightBase
local XBuffScript1000494 = XDlcScriptManager.RegBuffScript(1000494, "XBuffScript1000494", Base)

function XBuffScript1000494:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    --- 破韧可QTE范围(30米)
    self._breakValidRadius = 30
    --- 破韧QTE范围检测频率
    self._breakRangeCheckInterval = 0.2
    --- 破韧QTE范围检测计时器
    self._breakRangeCheckTimer = 0.2
    --- 玩家可破韧QTE效果
    self._breakPlayerQTEMagicId = 1000492
    --- 移除玩家可破韧QTE效果
    self._removeBreakPlayerQTEMagicId = 1000493
end

function XBuffScript1000494:Update(dt)
    Base.Update(self, dt)

    -- 范围内玩家施加QTE效果逻辑，计时器控制频率
    if self._breakRangeCheckTimer >= self._breakRangeCheckInterval then
        local players = self._proxy:GetPlayerNpcList()
        for k, player in ipairs(players) do
            local isPlayerInRange = self._proxy:CheckNpcDistance(self._uuid, player, self._breakValidRadius)
            local canPlayerQte = self._proxy:CheckBuffByKind(player, self._breakPlayerQTEMagicId)
            if isPlayerInRange and not canPlayerQte then
                self._proxy:ApplyMagic(self._uuid, player, self._breakPlayerQTEMagicId, 1)
            end
            if not isPlayerInRange and canPlayerQte then
                self._proxy:ApplyMagic(self._uuid, player, self._removeBreakPlayerQTEMagicId, 1)
            end
        end
        self._breakRangeCheckTimer = 0
    end
    self._breakRangeCheckTimer = self._breakRangeCheckTimer + dt
end

function XBuffScript1000494:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1000494:Terminate()
    -- 移除所有玩家的可QTE效果
    for k, player in ipairs(self._proxy:GetPlayerNpcList()) do
        self._proxy:ApplyMagic(self._uuid, player, self._removeBreakPlayerQTEMagicId, 1)
    end

    Base.Terminate(self)
end

return XBuffScript1000494