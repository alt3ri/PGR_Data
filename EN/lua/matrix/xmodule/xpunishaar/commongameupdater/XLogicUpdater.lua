--- 逻辑帧更新器
---@class XLogicUpdater
local XLogicUpdater = XClass(nil, "XLogicUpdater")

local State = {
    None = 0,
    Running = 1,
    Pause = 2,
}

-- 追帧上限 cap：卡顿恢复瞬间 delta 累积大时限速逐帧追上，勿一次性跑数百帧卡死主线程（审查条目4，截断式）
local MAX_CATCH_UP_FRAMES = 5  -- 容忍 ~0.25s（20fps），超此视为已卡顿不应再放大追帧；剩余累积留后续帧继续追

function XLogicUpdater:Ctor(logicFrame, callback)
    self._LogicFrame = logicFrame           -- 设定的帧率
    
    self._TimePerFrame = 1 / logicFrame     -- 每帧时长
    self._State = State.None

    self._CurRealTime = 0                   -- 当前经过的实际时间
    self._CurLogicFrame = 0                 -- 当前逻辑帧数
    self._PassedValidTime = 0               -- 当前经过的有效时间（实际产出了帧数）
    
    self._CallBack = callback
end

function XLogicUpdater:SetPause()
    self._State = State.Pause
end

function XLogicUpdater:SetResume()
    self._State = State.Running
end

function XLogicUpdater:SetRunning()
    self._State = State.Running
    
    self._CurRealTime = 0
    self._CurLogicFrame = 0
    self._PassedValidTime = 0
end

function XLogicUpdater:SetLogicFrame(logicFrame)
    self._LogicFrame = logicFrame

    self._TimePerFrame = 1 / logicFrame
end

function XLogicUpdater:Update(delta)
    if self._State ~= State.Running then
        return
    end
    
    self._CurRealTime = self._CurRealTime + delta
    
    local passRealTime = self._CurRealTime - self._PassedValidTime
    
    local passRealFrame = math.floor(passRealTime / self._TimePerFrame)
    
    if passRealFrame > MAX_CATCH_UP_FRAMES then
        passRealFrame = MAX_CATCH_UP_FRAMES
    end

    -- 追帧
    for i = 1, passRealFrame do
        -- 逻辑帧进1
        self._CurLogicFrame = self._CurLogicFrame + 1
        -- 积累实际消耗时间
        self._PassedValidTime = self._PassedValidTime + self._TimePerFrame

        if self._CallBack then
            self._CallBack(self._CurLogicFrame)
        end
    end
end

return XLogicUpdater

