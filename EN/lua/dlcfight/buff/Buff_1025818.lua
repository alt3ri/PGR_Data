local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025818 : XTheatre6BuffBase
local XBuffScript1025818 = XDlcScriptManager.RegBuffScript(1025818, "XBuffScript1025818", XTheatre6BuffBase)

--效果说明：本场双方累计造成12次点燃后触发，我方角色造成伤害提升15%，伤害减免提升15%    

function XBuffScript1025818:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._fireBuffId = 1025101  --点燃Buff
    self._time = 12               --所需次数
    self._fireKey = 1            --点燃key

    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 6             --使用的等级
    
    self._nowTime = 0            --当前次数
    self._canUse = 1             --是否可用
    self._trigger = false        --重复触发开关，每个技能仅能触发1次
    
    self._mineId = 6             --配置表的ID
end

function XBuffScript1025818:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --防重复检测
    self.trigger = false
end

--回调方法注册
function XBuffScript1025818:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025818:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
    --取历史的次数
    local _history = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._fireKey)
    if _history >= self._time then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._canUse = 0
    end
end

--添加buff时判断
function XBuffScript1025818:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --点燃时触发技能
    if buffId ~= self._fireBuffId then return end
    if self._canUse == 0 then return end
    if self.trigger then return end
    self.trigger = true
    
    --取历史的次数
    local _history = self._proxy:GetTheatre6BuffActionValue(self._uuid,self._fireKey)
    
    --本局次数+1
    self._nowTime = self._nowTime + 1
    --把总次数上传一下
    local _times = self._nowTime + _history
    self._proxy:SetTheatre6BuffActionValue(self._uuid,self._fireKey,_times)
    
    if _times >= self._time then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
        self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
        self._canUse = 0
    end
    
end

return XBuffScript1025818