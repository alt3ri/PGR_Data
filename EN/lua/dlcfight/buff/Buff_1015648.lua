local Base = require("Common/XFightBase")

---@class XBuffScript1015648 : XFightBase
local XBuffScript1015648 = XDlcScriptManager.RegBuffScript(1015648, "XBuffScript1015648", Base)


--效果说明：触发效果的血量要求降低10%

function XBuffScript1015648:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015649
    self.magicKind = 1015649
    self.magicLevel = 1
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
end

return XBuffScript1015648

    