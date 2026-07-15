local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025816 : XTheatre6BuffBase
local XBuffScript1025816 = XDlcScriptManager.RegBuffScript(1025816, "XBuffScript1025816", XTheatre6BuffBase)

--效果说明：我方角色造成伤害提升10%，伤害减免提升10% 

function XBuffScript1025816:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 4             --使用的等级
    
    self._mineId = 4             --配置表的ID
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025816:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)

    self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
    self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
    self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
end

return XBuffScript1025816