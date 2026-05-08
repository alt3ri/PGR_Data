local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1025312 : XBuffBase
local XBuffScript1025312 = XDlcScriptManager.RegBuffScript(1025312, "XBuffScript1025312", Base)


--效果说明：处于【点燃】状态的对手，每有1层【点燃】则造成的伤害降低2%。
--自身每有1层点燃造成伤害降低2%的效果

function XBuffScript1025312:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self.signalId = 1025101
    --检测到战斗开始
    ------------执行------------
    self.originAttrib1 = 0
end

function XBuffScript1025312:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end


function XBuffScript1025312:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._uuid == npcUUID and self.signalId == buffId then
        self.originAttrib2 = self._proxy:GetBuffStacks( self._uuid,1025101)
        self.originAttrib3 = self.originAttrib2 - self.originAttrib1
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025907,1,0,self.originAttrib3)
        --检测到点燃时刷新一次层数，计算和上次触发时的点燃层数差值，附加减伤
        self.originAttrib1 = self.originAttrib2
        --刷新层数计数
    end

end



return XBuffScript1025312

--这个没看懂