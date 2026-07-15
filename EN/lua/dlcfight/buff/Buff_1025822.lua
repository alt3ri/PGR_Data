local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025822 : XTheatre6BuffBase
local XBuffScript1025822 = XDlcScriptManager.RegBuffScript(1025822, "XBuffScript1025822", XTheatre6BuffBase)

--效果说明：本局超序反击环节累计失败2次后，我方角色造成伤害提升15%，伤害减免提升15%

function XBuffScript1025822:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    
    self._failTime = 2      --失败的次数

    self._nowFailTime = 0   --当前失败次数
    self._canUse = 1        --是否可用

    self._attkBuff = 1025916
    self._defBuff = 1025917
    self._buffLevel = 10             --使用的等级
    
    self._mineId = 10       --配置表的ID
    
end

---初始化事件回调注册
function XBuffScript1025822:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.Theatre6DodgeRollDiceEnd)
end

---进入关卡时初始化控制器
---@param levelId number 关卡ID
function XBuffScript1025822:OnEnterLevel(levelId)
    XTheatre6BuffBase.OnEnterLevel(self, levelId)
end

---处理超算事件
function XBuffScript1025822:HandleEvent(eventType, eventArgs)
    XTheatre6BuffBase.HandleEvent(self, eventType, eventArgs)

    --保底处理
    if eventType ~= EWorldEvent.Theatre6DodgeRollDiceEnd then return end
    if not self._buffLevel then return end
    if self._canUse == 0 then return end
    
    --逻辑判断
    if eventArgs.WinnerUUID ~= self._npcUUID then
        self._nowFailTime = self._nowFailTime + 1
        if self._nowFailTime >= self._failTime then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._attkBuff,self._buffLevel)
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._defBuff,self._buffLevel)
            self._proxy:Theatre6EnvironmentShow(self._uuid, self._mineId)
            self._canUse = 0
        end
    end
    
end

return XBuffScript1025822