local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1026015 : XTheatre6BuffBase
local XBuffScript1026015 = XDlcScriptManager.RegBuffScript(1026015, "XBuffScript1026015", XTheatre6BuffBase)


--效果说明：隐藏大太刀开启小太刀

function XBuffScript1026015:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self._hideKodachi = 1026004
    self._hideDachi = 1026005
    self._hideNodachi = 1026006
    self._hideKodachiskin = 1026012
    self._hideDachiskin = 1026013
    self._hideNodachiskin = 1026014
    self._effectbuff01 = 1026008
    self._effectbuff02 = 1026009

    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideDachi) --隐藏打刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideNodachi) --隐藏野太刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideDachiskin) --隐藏打刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._hideNodachiskin) --隐藏野太刀buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._effectbuff01) --特效
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._effectbuff02) --特效
    self._proxy:RemoveBuff(self._uuid, self._hideKodachi) --开启大大大大太刀
    self._proxy:RemoveBuff(self._uuid, self._hideKodachiskin) --开启大大大大太刀
end

function XBuffScript1026015:Terminate()

end

return XBuffScript1026015
