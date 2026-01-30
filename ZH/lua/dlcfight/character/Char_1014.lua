local XCharBiancaP3 = XDlcScriptManager.RegCharScript(1014, "XCharBiancaP3") --三阶比安卡（真理
local XAnchorVisualization = require("Level/Common/XAnchorVisualization")
local Hunt01BossFight = require("Level/Common/XLevelScriptHunt01")

local _skillIdMap = {
    Interaction = 101424,
}

---@param proxy XDlcCSharpFuncs
function XCharBiancaP3:Ctor(proxy)
    self._proxy = proxy
end

function XCharBiancaP3:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number

    self._anchorVisual = XAnchorVisualization.New(self._proxy, self._npc)
    self._bossFight = Hunt01BossFight.New(self._proxy,self._npc)
end

---@param dt number @ delta time
function XCharBiancaP3:Update(dt)
    self._anchorVisual:Update(dt)
    self._bossFight:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharBiancaP3:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaP1 Npc:%d HandleEvent etype:%d", self._npc, eventType))
    self._bossFight:HandleEvent(eventType, eventArgs)
end

function XCharBiancaP3:Terminate()

end

return XCharBiancaP3