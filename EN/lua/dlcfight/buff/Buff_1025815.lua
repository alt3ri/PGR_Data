local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025815 : XTheatre6BuffBase
local XBuffScript1025815 = XDlcScriptManager.RegBuffScript(1025815, "XBuffScript1025815", XTheatre6BuffBase)

--效果说明：全局生效1次，当对方环境效果触发时，我方获得对方150%的效果

function XBuffScript1025815:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._attkBuff = 1025918
    self._defBuff = 1025919

    self._enemyAttkBuff = 1025916
    self._enemyDefBuff = 1025917
    
    self._key = 815
    self._canUse = 1
    self.hasLevel = false
    self.level = 0
    
    self._mineId = 3             --配置表的ID
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025815:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
end

---初始化事件回调注册
function XBuffScript1025815:InitEventCallBackRegister()
    self._canUse = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._key)
    if self._canUse == 2 then return end
    self._proxy:RegisterEvent(EWorldEvent.Theatre6Environment)
end

function XBuffScript1025815:HandleEvent(eventType, eventArgs)
    XTheatre6BuffBase.HandleEvent(self, eventType, eventArgs)
    --保底处理
    if eventType ~= EWorldEvent.Theatre6Environment then return end
    if eventArgs.UUID == self._uuid then return end
    if self._canUse == 2 then return end
    
    XLog.Warning("敌方npc3："..self._enemyUUID)
    
    --获取下对方身上buff的等级，自身添加同等级的1.5倍效果buff
    if self._proxy:CheckBuffByKind(self._enemyUUID, self._enemyAttkBuff) then
        if self._canUse == 2 then return end
        if self.hasLevel == false then
            self.hasLevel,self.level = self._proxy:TryQueryBuffLevel(self._enemyUUID, self._enemyAttkBuff)
        end
        self._canUse = 2
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self.level)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self.level)
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)

        --防止后续继续触发
        self._proxy:SetTheatre6BuffActionValue(self._uuid,self._key,2)
        self._canUse = 2
    end
end

return XBuffScript1025815