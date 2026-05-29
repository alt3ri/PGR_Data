local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1026007 : XTheatre6BuffBase
local XBuffScript1026007 = XDlcScriptManager.RegBuffScript(1026007, "XBuffScript1026007", XTheatre6BuffBase)


--效果说明：隐藏打刀、大太刀，短暂开启大大大大大太刀

function XBuffScript1026007:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self._hidedadao = 1026004
    self._hidedachi = 1026005
    self._hideNodachi = 1026006
    self._hidedadao2 = 1026012
    self._hidedachi2 = 1026013
    self._hideNodachi2 = 1026014
    self._effectbuff01 = 1026008
    self._effectbuff02 = 1026011
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hidedadao) --隐藏打刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hidedachi) --隐藏大太刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hidedadao2) --隐藏打刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hidedachi2) --隐藏大太刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._effectbuff01) --隐藏打刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._effectbuff02) --隐藏大太刀buff
    self._proxy:RemoveBuff(self._uuid, self._hideNodachi) --开启大大大大太刀
    self._proxy:RemoveBuff(self._uuid, self._hideNodachi2) --开启大大大大太刀
end

function XBuffScript1026007:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1026007:Terminate()
    self._proxy:RemoveBuff(self._uuid, self._hidedachi) --开启大太刀
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideNodachi) --隐藏大大大大太刀
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideNodachi2)
end

return XBuffScript1026007
