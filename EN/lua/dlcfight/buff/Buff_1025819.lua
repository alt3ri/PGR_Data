local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025819 : XTheatre6BuffBase
local XBuffScript1025819 = XDlcScriptManager.RegBuffScript(1025819, "XBuffScript1025819", XTheatre6BuffBase)

--效果说明：本场双方累计进入3次狂暴后触发，我方角色造成伤害提升15%，伤害减免提升15%

function XBuffScript1025819:Init()
    --初始化
    XTheatre6BuffBase.Init(self)

    self._angryBuffId = 1025108  --狂暴Buff
    self._time = 3               --所需次数
    self._angerKey = 2           --狂暴key

    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 7             --使用的等级
    
    self._nowTime = 0            --当前次数
    self._canUse = 1             --是否可用
    
    self._mineId = 7             --配置表的ID
end

--回调方法注册
function XBuffScript1025819:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025819:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    --取历史的次数
    local _history = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._angerKey)
    if _history >= self._time then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._canUse = 0
    end
end

--添加buff时判断
function XBuffScript1025819:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --狂暴时触发技能
    if buffId ~= self.angryBuffId then return end
    if self._canUse == 0 then return end

    --取历史的次数
    local _history = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._angerKey)

    --本局次数+1
    self._nowTime = self._nowTime + 1
    --把总次数上传一下
    local _times = self._nowTime + _history
    self._proxy:SetTheatre6BuffActionValue(self._uuid,self._angerKey,_times)
    
    if _times >= self._time then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._canUse = 0
    end
    
end

return XBuffScript1025819