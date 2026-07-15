local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025823 : XTheatre6BuffBase
local XBuffScript1025823 = XDlcScriptManager.RegBuffScript(1025823, "XBuffScript1025823", XTheatre6BuffBase)

--效果说明：PVP角色判断脚本

function XBuffScript1025823:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    --通用减伤脚本
    self._commonBuff = 1025800
    
    --维罗妮卡相关
    self._WLNKId = 1025
    self._WToABuff = 1025801    --对白毛
    self._WToSBuff = 1025802    --对神威
    
    --阿尔法相关
    self._AEFId = 1026
    self._AToWBuff = 1025804    --对龙骑
    self._AToSBuff = 1025805    --对神威
    
    --神威相关
    self._SWId = 1027
    self._SToWBuff = 1025807    --对龙骑
    self._SToABuff = 1025808    --对白毛
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025823:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    self._proxy:AddBuff(self._npcUUID,self._commonBuff)
    
    local _enemyId = self._proxy:GetNpcTemplate(self._enemyUUID).Id
    
    --神秘判断
    if self._npcId == self._WLNKId then         --维罗妮卡判断
        if _enemyId == self._AEFId then
            self._proxy:AddBuff(self._npcUUID,self._WToABuff)
        elseif _enemyId == self._SWId then
            self._proxy:AddBuff(self._npcUUID,self._WToSBuff)
        end
    elseif self._npcId == self._AEFId then     --白毛判断
        if _enemyId == self._WLNKId then
            self._proxy:AddBuff(self._npcUUID,self._AToWBuff)
        elseif _enemyId == self._SWId then
            self._proxy:AddBuff(self._npcUUID,self._AToSBuff)
        end
    elseif self._npcId == self._SWId then     --神威判断
        if _enemyId == self._WLNKId then
            self._proxy:AddBuff(self._npcUUID,self._SToWBuff)
        elseif _enemyId == self._AEFIdId then
            self._proxy:AddBuff(self._npcUUID,self._SToABuff)
        end
    end
end

return XBuffScript1025823