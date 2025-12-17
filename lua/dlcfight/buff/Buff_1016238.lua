local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016238 : XBuffBase
local XBuffScript1016238 = XDlcScriptManager.RegBuffScript(1016238, "XBuffScript1016238", Base)
--效果说明：添加对应的通用强化
local ConfigMagicIdDict = {
    [1016238] = 1016021,
    [1016239] = 1016022,
    [1016240] = 1016023,
    [1016241] = 1016024,
    [1016242] = 1016025,
    [1016243] = 1016026,
    [1016244] = 1016027,
}

function XBuffScript1016238:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --对应的通用强化Buff
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    ------------执行------------

    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)

end
---@param dt number @ delta time
function XBuffScript1016238:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016238:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016238:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016238
