local Base = require("Common/XFightBase")

---@class XBuffScriptXBuffScript1015993 : XFightBase
local XBuffScriptXBuffScript1015993 = XDlcScriptManager.RegBuffScript(1015993, "XBuffScriptXBuffScript1015993", Base)


--效果说明：当角色属性发生变化时，添加和移除对应属性的特效

function XBuffScriptXBuffScript1015993:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.effMagicId = {
        1015994, --血属性
        1015995, --灵属性
        1015996, --圣属性
        1015997, --回复效率
        1015998  --护盾强度
    }
    self.isEffMagicActive = {
        false,
        false,
        false,
        false,
        false
    }
    self.attrId = {
        ENpcAttrib.Element1AmpP,
        ENpcAttrib.Element2AmpP,
        ENpcAttrib.Element3AmpP,
        ENpcAttrib.HealAmpP,
        ENpcAttrib.ShieldAmpP,
    }
    self.magicLevel = 1
    ------------执行------------

end

---@param dt number @ delta time 
function XBuffScriptXBuffScript1015993:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScriptXBuffScript1015993:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScriptXBuffScript1015993:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    self:EffCtrl(npcUUID)
end

function XBuffScriptXBuffScript1015993:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    self:EffCtrl(npcUUID)
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScriptXBuffScript1015993:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScriptXBuffScript1015993:Terminate()
    Base.Terminate(self)
end

function XBuffScriptXBuffScript1015993:EffCtrl(npcId)
    if npcId ~= self._uuid then
        return
    end
    for i = 1, 5 do
        local attr = self._proxy:GetNpcAttribValue(self._uuid, self.attrId[i])
        if self.isEffMagicActive[i] then
            if attr == 0 then
                self._proxy:RemoveBuff(self._uuid, self.effMagicId[i])
                self.isEffMagicActive[i] = false
            end
        else
            if attr > 0 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.effMagicId[i], self.magicLevel)
                self.isEffMagicActive[i] = true
            end
        end
    end
end

return XBuffScriptXBuffScript1015993
