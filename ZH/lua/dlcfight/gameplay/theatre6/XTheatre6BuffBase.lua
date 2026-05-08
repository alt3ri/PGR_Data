local XTheatre6FightBase = require("Gameplay/Theatre6/XTheatre6FightBase")

---@class XTheatre6BuffBase:XTheatre6FightBase
local XTheatre6BuffBase = XClass(XTheatre6FightBase, "XTheatre6BuffBase")

function XTheatre6BuffBase:_BaseInit()
    self._npcUUID = self._proxy:GetSelfBuffNpcUUID()
    self._npcId = self._proxy:GetNpcTemplate(self._npcUUID).Id
    self._uuid = self._npcUUID
    
    self._buffId = self._proxy:GetSelfBuffId()
    self._buffUUID = self._proxy:GetSelfBuffUUID()
    self._name = self._npcId .. "." .. self._npcUUID .. "." .. self.__cname .. "." .. self._buffId .. "." .. self._buffUUID

    self:InitLuaEvent()
    self:InitEventCallBackRegister()
    self:InitDefaultEventCallBackRegister()
end

---@return XTheatre6CharBase
function XTheatre6BuffBase:GetNpc()
    if not self._npc then
        self._npc = self._proxy:GetActorScriptObject(EScriptType.Npc, self._npcUUID, self._npcId) --[[@as XTheatre6CharBase]]
    end
    return self._npc
end

return XTheatre6BuffBase