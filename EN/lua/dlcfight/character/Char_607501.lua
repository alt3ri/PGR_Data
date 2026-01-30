local XCharLuciaQ4 = XDlcScriptManager.RegCharScript(607501, "XCharLuciaQ4") --Q版四阶露西亚（鸦羽
local XNpcFollowToSectorController = require("Character/Common/XNpcFollowToSectorController")

local _skillIdMap = {
    Interaction = 100219,
}

---@param proxy XDlcCSharpFuncs
function XCharLuciaQ4:Ctor(proxy)
    self._proxy = proxy
    self._localNpc = 0
end

function XCharLuciaQ4:Init()
    self._uuid = self._proxy:GetSelfNpcId()
    self._localNpc = self._proxy:GetLocalPlayerNpcId() ---@type number

    ---@type XNpcFollowToSectorController
    self._followController = XNpcFollowToSectorController.New(self._proxy, self._uuid)
    self._followController:SetFollowTargetNpc(self._localNpc, 45, 1, 1, 1, 1, 1)
end
---@param dt number @ delta time
function XCharLuciaQ4:Update(dt)
    self._followController:Update(dt)
    self._followController:SetMaxIdleRange(1)
    self._followController:SetStartFollowRange(1)
    self._followController:SetTargetParam(self._localNpc, 45, 1)
    self._followController:SetIdleLookAtTargetDelayTime(1)
end

---@param eventType number
---@param eventArgs userdata
function XCharLuciaQ4:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaQ4 Npc:%d HandleEvent eventType:%d", self._npc, eventType))
end

function XCharLuciaQ4:Terminate()
    self._proxy = nil
    self._followController.Terminate()
    self._followController = nil
end

return XCharLuciaQ4