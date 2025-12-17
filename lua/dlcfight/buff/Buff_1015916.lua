local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015916 : XBuffBase
local XBuffScript1015916 = XDlcScriptManager.RegBuffScript(1015916, "XBuffScript1015916", Base)

--效果说明：敌人生命值低于20%，且自身生命值低于80%时，每次使用技能，可以将10%的生命最大值转换为10%的护盾值

function XBuffScript1015916:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicIds = {
        1015975, --护盾(要先执行护盾，否则会亏）
        1015917, --生命最大值减少
    }
    self.runeId = 20916           --符纹ID赋值
    self.magicLevel = 1
    self.signal1Id = 1015901         --【浑身】状态标记，标记管理脚本见1015900
    self.signal1CtrlId = 1015900     --【浑身】状态管理Buff
    self.signal2Id = 1015905        --【斩杀】状态标记，标记管理脚本见1015904
    self.signal2CtrlId = 1015904    --【斩杀】状态管理Buff

    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signal1CtrlId, 1)   --为自己添加【浑身】管理Buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signal2CtrlId, 1)   --为自己添加【斩杀】管理Buff
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)              --注册技能释放事件

end

---@param dt number @ delta time 
function XBuffScript1015916:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015916:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)
    --技能combo开始时，判断是否处于浑身和斩杀状态
    local issignal1IdActive = self._proxy:CheckBuffByKind(self._uuid,self.signal1Id)
    local issignal2IdActive = self._proxy:CheckBuffByKind(self._uuid,self.signal2Id)
    if issignal1IdActive and issignal2IdActive then
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, self.magicLevel)
        end
    end

end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015916:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015916:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015916

    