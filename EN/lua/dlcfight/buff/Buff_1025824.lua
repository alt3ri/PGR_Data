local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025824 : XTheatre6BuffBase
local XBuffScript1025824 = XDlcScriptManager.RegBuffScript(1025824, "XBuffScript1025824", XTheatre6BuffBase)

--效果说明：PVE模式中，我方角色拼点失败后，下次拼点上下限提升30

function XBuffScript1025824:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._upDice = 30               --每次失败后，增长的幅度

end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025824:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    --如果不是玩家，跳过
    if not self._proxy:IsPlayerNpc(self._npcUUID) then return end

    --开启补偿
    self._proxy:SetTheatre6DiceDelta(ETheatre6DiceType.All,self._upDice)
    self._proxy:Theatre6OpenDice(ETheatre6DiceType.All,true,false)
end

return XBuffScript1025824