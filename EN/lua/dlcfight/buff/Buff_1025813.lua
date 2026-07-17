local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025813 : XTheatre6BuffBase
local XBuffScript1025813 = XDlcScriptManager.RegBuffScript(1025813, "XBuffScript1025813", XTheatre6BuffBase)

--效果说明：战斗失败后，后续角色造成伤害提升15%，伤害减免提升15% 

function XBuffScript1025813:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 1             --使用的等级
    self._mineId = 1            --配置表的ID
    
    self._timer = 1             --延迟播放UI时间
    self._isShow = false            --是否要播UI
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025813:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    local _nowRound = self._proxy:Theatre6GetRound()
    
    --检测条件
    for checkRound = _nowRound - 1, 1, -1 do
        if checkRound == 0 then return end
        XLog.Warning(self._proxy:GetTheatre6WinResult(self._uuid, checkRound))
        if not self._proxy:GetTheatre6WinResult(self._uuid, checkRound) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
            
            self._isShow = true
            return
        end
    end
end

--环境效果触发显示
function XBuffScript1025813:Update(dt)
    ------------执行------------
    if not self._isShow then return end
    local _nowTime = self._proxy:GetFightTime()
    if _nowTime >= self._timer then
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._isShow = false
    end
end

return XBuffScript1025813