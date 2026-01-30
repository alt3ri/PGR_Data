local Base = require("Character/Char_8052")

---Relink黑辉辉难度4
---@class XChar8063 : XChar8052
local XChar8063 = XDlcScriptManager.RegCharScript(8063, "XChar8063", Base)

--软狂暴配置
function XChar8063:SoftFuryConfig()
    Base.SoftFuryConfig(self)
    self.isHaveSoftFury = true --开启软狂暴
    self.enterSoftFuryFightTime = 350 --战斗开始后5秒进入软狂暴
end

return XChar8063