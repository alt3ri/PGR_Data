local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025814 : XTheatre6BuffBase
local XBuffScript1025814 = XDlcScriptManager.RegBuffScript(1025814, "XBuffScript1025814", XTheatre6BuffBase)

--效果说明：战斗超30秒后，我方角色造成伤害提升15%，伤害减免提升15% 

function XBuffScript1025814:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._time = 30              --所需时间

    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 2             --使用的等级
    
    self._mineId = 2             --配置表的ID
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025814:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
end

--关卡时间判断
function XBuffScript1025814:Update(dt)
    if self._canUse == 0 then return end
    local _nowTime = self._proxy:GetFightTime()
    if _nowTime < self._time then return end
    self._canUse = 0
    XLog.Warning("本buff的等级："..self._buffLevel)
    self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
    self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
    self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
end

return XBuffScript1025814