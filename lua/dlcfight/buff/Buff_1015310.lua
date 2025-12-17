local Base = require("Common/XFightBase")

---@class XBuffScript1015310 : XFightBase
local XBuffScript1015310 = XDlcScriptManager.RegBuffScript(1015310, "XBuffScript1015310", Base)


--效果说明：生命首次低于30%时，【回复效率】+100点，每秒减少10点

function XBuffScript1015310:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015311
    self.magicLevel = 1
    self.isAdd = false
    self.timeDis = 1
    self.buffKind = 1015311
    self.addTime = 0
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015310:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 获取我方的当前属性
    if not self.isAdd then
        self.percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
        -- 加buff
        if self.percentHp < 0.3 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.addTime = self._proxy:GetNpcTime(self._uuid)
            self.isAdd = true
        end
    end
    -- 如果添加了buff，开始减
    if self.isAdd and self.timeDis <= 10 then
        if self._proxy:GetNpcTime(self._uuid) - self.addTime >= self.timeDis then
            self.magicLevel = self.timeDis + 1
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.timeDis = self.timeDis + 1
            -- 移除buff
            if self.timeDis > 10 then
                self._proxy:RemoveBuff(self._uuid, self.buffKind)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015310:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015310:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015310

    