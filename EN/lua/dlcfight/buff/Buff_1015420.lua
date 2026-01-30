local Base = require("Common/XFightBase")

---@class XBuffScript1015420 : XFightBase
local XBuffScript1015420 = XDlcScriptManager.RegBuffScript(1015420, "XBuffScript1015420", Base)

--效果说明：釋放技能时，基于位移距离，获得10~100冰伤提升，最大值将在累计位移25m时生效
function XBuffScript1015420:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015421
    self.magicLevelTable = { 1, 2, 3, 4, 5, 6 }
    self.distanceGroup = { 0, 5, 10, 15, 20, 25, 99 }
    self.isAdd = { false, false, false, false, false, false }
    self.magicLevel = 0
    self.hisDistance = 0
    ------------执行------------
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboEnd)
end

---@param dt number @ delta time 
function XBuffScript1015420:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015420:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)


    -- 技能combo开始时，拿NPC的位置
    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then
        -- 满级了就不走了
        if self.magicLevel == 6 then
            return
        end
        -- 记录是哪一个combo开始
        self.skillId = eventArgs.ItemSkillId
        -- 记录开始时位置
        self.skillBeforePos = self._proxy:GetNpcPosition(self._uuid)
    end
    -- 技能combo结束时，计算位移距离
    if eventType == EFightLuaEvent.AutoChessItemSkillComboEnd then
        -- 满级了就不走了
        if self.magicLevel == 6 then
            return
        end
        -- 判断是相同的combo结束

        if eventArgs.ItemSkillId == self.skillId then
            -- 计算累计combo位移距离
            self.distance = self._proxy:GetNpcToPositionDistance(self._uuid, self.skillBeforePos, true) + self.hisDistance
            self.hisDistance = self.distance
            -- 遍历位移区间
            for i = 6, 1, -1 do
                -- 有高级的buff就不走了
                if self.isAdd[i] then
                    break
                end
                -- 判断累计位移在哪个区间
                if self.distance >= self.distanceGroup[i] and self.distance < self.distanceGroup[i + 1] then
                    -- 如果是更高的区间就加buff，否则不加
                    if self.magicLevelTable[i] > self.magicLevel then
                        self.magicLevel = self.magicLevelTable[i]
                        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                        self.isAdd[i] = true
                        break
                    end
                end
            end
            -- 重置id
            self.skillId = 0
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015420:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015420:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015420
