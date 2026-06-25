local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025820 : XTheatre6BuffBase
local XBuffScript1025820 = XDlcScriptManager.RegBuffScript(1025820, "XBuffScript1025820", XTheatre6BuffBase)

--效果说明：当我方角色与对方不同时，我方角色造成伤害提升5%，伤害减免提升5%，可叠加

function XBuffScript1025820:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    self._mineId = 8        --配置表的ID

    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 8             --使用的等级
    
    self._buffKey = 820     --跨局传值Key

    self._timer = 1             --延迟播放UI时间
    self._isShow = false            --是否要播UI
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025820:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)

    --敌我ID对比
    local _myId = self._npcId
    local _enemyId = self._proxy:GetNpcTemplate(self._enemyUUID).Id
    if not _enemyId then 
        XLog.Warning("1025820找不到敌人")
        return
    end
    
    --实际逻辑判断
    if _myId ~= _enemyId then
        --取一下历史的值
        local _count = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._buffKey)
        _count = _count + 1
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel,0,_count)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel,0,_count)
        
        self._isShow = true

        --跨局传值
        self._proxy:SetTheatre6BuffActionValue(self._uuid, self._buffKey, _count)
        end
end

--环境效果触发显示
function XBuffScript1025820:Update(dt)
    ------------执行------------
    if not self._isShow then return end
    local _nowTime = self._proxy:GetFightTime()
    if _nowTime >= self._timer then
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._isShow = false
    end
end

return XBuffScript1025820