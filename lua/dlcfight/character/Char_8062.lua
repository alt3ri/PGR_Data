local Base = require("Character/Char_8052")

---Relink黑辉辉难度3
---@class XChar8062 : XChar8052
local XChar8062 = XDlcScriptManager.RegCharScript(8062, "XChar8062", Base)

--软狂暴配置
function XChar8062:SoftFuryConfig()
    Base.SoftFuryConfig(self)
    self.isHaveSoftFury = true --开启软狂暴
    self.enterSoftFuryFightTime = 320 --战斗多久后会进入软狂暴
end

return XChar8062