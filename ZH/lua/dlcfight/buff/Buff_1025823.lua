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
    self._WToNBuff = 1025803    --对涅缇娅
    self._WSelfBuff = 1025825    --给龙骑自己
    
    --阿尔法相关
    self._AEFId = 1026
    self._AToWBuff = 1025804    --对龙骑
    self._AToSBuff = 1025805    --对神威
    self._AToNBuff = 1025806    --对涅缇娅
    self._AToABuff = 1025826    --对白毛，给对面也挂增伤15%
    self._ASelfBuff = 1025826    --给白毛自己增伤15%
    
    --神威相关
    self._SWId = 1027
    self._SToWBuff = 1025807    --对龙骑
    self._SToABuff = 1025808    --对白毛
    self._SToNBuff = 1025809    --对涅缇娅
    self._SSelfBuff = 1025827    --给神威自己

    --涅缇娅相关
    self._NTYId = 1028
    self._NToWBuff = 1025810    --对龙骑
    self._NToABuff = 1025811    --对白毛
    self._NToSBuff = 1025812    --对神威
    self._NSelfBuff = 1025828    --给涅缇娅自己
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025823:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    self._proxy:AddBuff(self._npcUUID,self._commonBuff)
    
    local _enemyId = self._proxy:GetNpcTemplate(self._enemyUUID).Id
    
    --神秘判断
    if self._npcId == self._WLNKId then         --维罗妮卡判断
        self._proxy:AddBuff(self._npcUUID,self._WSelfBuff)
        if _enemyId == self._AEFId then
            self._proxy:AddBuff(self._npcUUID,self._WToABuff)
            self._proxy:AddBuff(self._enemyUUID,self._ASelfBuff) -- 对面是白毛时，给对面挂增伤
        elseif _enemyId == self._SWId then
            self._proxy:AddBuff(self._npcUUID,self._WToSBuff)
        elseif _enemyId == self._NTYId then
            self._proxy:AddBuff(self._npcUUID,self._WToNBuff)
        end
    elseif self._npcId == self._AEFId then     --白毛判断
        self._proxy:AddBuff(self._npcUUID,self._ASelfBuff)
        if _enemyId == self._WLNKId then
            self._proxy:AddBuff(self._npcUUID,self._AToWBuff)
        elseif _enemyId == self._SWId then
            self._proxy:AddBuff(self._npcUUID,self._AToSBuff)
        elseif _enemyId == self._AEFId then
            self._proxy:AddBuff(self._enemyUUID,self._AToABuff) -- 对面是白毛时，给对面也挂增伤
        elseif _enemyId == self._NTYId then
            self._proxy:AddBuff(self._npcUUID,self._AToNBuff)
        end
    elseif self._npcId == self._SWId then     --神威判断
            self._proxy:AddBuff(self._npcUUID,self._SSelfBuff)
        if _enemyId == self._WLNKId then
            self._proxy:AddBuff(self._npcUUID,self._SToWBuff)
        elseif _enemyId == self._AEFId then
            self._proxy:AddBuff(self._npcUUID,self._SToABuff)
            self._proxy:AddBuff(self._enemyUUID,self._ASelfBuff) -- 对面是白毛时，给对面挂增伤
        elseif _enemyId == self._NTYId then
            self._proxy:AddBuff(self._npcUUID,self._SToNBuff)
        end
    elseif self._npcId == self._NTYId then     --涅缇娅判断
        self._proxy:AddBuff(self._npcUUID,self._NSelfBuff)
        if _enemyId == self._WLNKId then
            self._proxy:AddBuff(self._npcUUID,self._NToWBuff)
        elseif _enemyId == self._AEFId then
            self._proxy:AddBuff(self._npcUUID,self._NToABuff)
            self._proxy:AddBuff(self._enemyUUID,self._ASelfBuff) -- 对面是白毛时，给对面挂增伤
        elseif _enemyId == self._SWId then
            self._proxy:AddBuff(self._npcUUID,self._NToSBuff)
        end
    end
end

return XBuffScript1025823