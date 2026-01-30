local Base = require("Character/Char_8052")

---Relink黑辉辉难度4
---@class XChar8064 : XChar8052
local XChar8064 = XDlcScriptManager.RegCharScript(8064, "XChar8064", Base)

--软狂暴配置
function XChar8064:SoftFuryConfig()
    Base.SoftFuryConfig(self)
    self.isHaveSoftFury = true --开启软狂暴
    self.enterSoftFuryFightTime = 400 --战斗开始后5秒进入软狂暴
end

return XChar8064