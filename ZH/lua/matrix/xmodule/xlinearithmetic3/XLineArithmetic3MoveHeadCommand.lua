--- 移动车头命令
local XLineArithmetic3Command = require("XModule/XLineArithmetic3/XLineArithmetic3Command")
local XLineArithmetic3Enum = require("XModule/XLineArithmetic3/XLineArithmetic3Enum")
local XLineArithmetic3MoveHeadCommand = XClass(XLineArithmetic3Command, "XLineArithmetic3MoveHeadCommand")

--- 构造函数
---@param uiGame XUiLineArithmetic3Game UI游戏对象
---@param targetX number 目标X坐标
---@param targetY number 目标Y坐标
---@param headPosBefore table 移动前的车头位置
---@param carriagePositionsBefore table 移动前的车厢位置列表
function XLineArithmetic3MoveHeadCommand:Ctor(uiGame, targetX, targetY, headPosBefore, carriagePositionsBefore)
    self._TargetX = targetX
    self._TargetY = targetY
    -- Game 层状态（从指令获取）
    self._GameHeadPosBefore = headPosBefore
    self._GameCarriagePositionsBefore = carriagePositionsBefore or {}
    -- 是否真的添加了 TraveledPath
    self._DidAddTraveledPath = false
    -- UI 层状态（在 Execute 时填充）
    self._StartHeadPos = nil
    self._StartCarriagePositions = {}
    self._TargetPos = nil
    -- 起点格子相关
    self._WasAtStart = false  -- 移动前是否在起点
end

--- 执行命令（正向动画）
function XLineArithmetic3MoveHeadCommand:Execute(game, onComplete)
    local uiGame = self._UiGame

    -- 使用移动前的位置判断是否在起点（不能实时查询Game层，因为位置可能已更新）
    self._WasAtStart = uiGame:IsPosAtStart(self._GameHeadPosBefore)

    -- 保存 UI 层状态
    local headGo = uiGame:GetHeadGo()
    if not headGo then
        if onComplete then onComplete() end
        return
    end
    self._StartHeadPos = headGo.transform.position
    self._TargetPos = uiGame:GetGridWorldPosition(self._TargetX, self._TargetY)

    for i = 1, uiGame:GetCarriageCount() do
        local carriageGo = uiGame:GetCarriageGo(i)
        if carriageGo then
            self._StartCarriagePositions[i] = carriageGo.transform.position
        end
    end

    -- 如果从起点离开，更新起点格子显示（显示车头）
    if self._WasAtStart then
        uiGame:UpdateStartGridDisplay(false)
    end

    -- 检查目标格子是否为终点（用于播放音效）
    local targetGrid = game:GetGrid({ x = self._TargetX, y = self._TargetY })
    self._IsTargetEnd = targetGrid and targetGrid.Type == XLineArithmetic3Enum.GridType.End

    -- 执行正向动画
    self:_PlayTween(self._StartHeadPos, self._TargetPos, self._StartCarriagePositions, self._StartHeadPos, function()
        -- 动画完成后，更新 Game 层状态，记录是否真的添加了
        self._DidAddTraveledPath = game:AddTraveledPath({ x = self._TargetX, y = self._TargetY })
        -- 如果车头进入终点，播放音效
        if self._IsTargetEnd then
            self:_PlayEnterEndSound()
        end
        if onComplete then onComplete() end
    end)
end

--- 播放车头进入终点音效
function XLineArithmetic3MoveHeadCommand:_PlayEnterEndSound()
    local cueId = XMVCA.XLineArithmetic3:GetClientConfigNumberByKey("ToFinalEndCueId") or 0
    XLog.Debug("[MoveHeadCommand] _PlayEnterEndSound called, cueId=" .. tostring(cueId))
    if cueId > 0 then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    end
end

--- 撤销命令（反向动画）
function XLineArithmetic3MoveHeadCommand:Undo(game, onComplete)
    local uiGame = self._UiGame
    local headGo = uiGame:GetHeadGo()
    if not headGo or not self._StartHeadPos then
        if onComplete then onComplete() end
        return
    end

    -- 恢复 Game 层状态
    if self._GameHeadPosBefore then
        game:SetHeadPos(self._GameHeadPosBefore)
    end
    -- 只有 Execute 时真的添加了，才移除
    if self._DidAddTraveledPath then
        game:RemoveLastTraveledPath()
    end
    -- 恢复车厢的 Game 层位置
    for i, pos in ipairs(self._GameCarriagePositionsBefore) do
        game:SetCarriagePos(i, pos)
    end

    -- Game 层状态恢复后，立即刷新路径显示（在动画开始前隐藏即将离开的格子）
    uiGame:RefreshTraveledPathDisplay()

    -- 当前 UI 位置作为起点，回到之前的位置
    local currentHeadPos = headGo.transform.position
    local currentCarriagePositions = {}
    for i = 1, uiGame:GetCarriageCount() do
        local carriageGo = uiGame:GetCarriageGo(i)
        if carriageGo then
            currentCarriagePositions[i] = carriageGo.transform.position
        end
    end

    -- 执行反向动画（使用全局 undo 时长）
    self:_PlayTween(currentHeadPos, self._StartHeadPos, currentCarriagePositions, self._StartCarriagePositions, function()
        -- 动画完成后，如果原本在起点（撤销后回到起点），更新起点格子显示
        if self._WasAtStart then
            uiGame:UpdateStartGridDisplay(true)
        end
        if onComplete then onComplete() end
    end, XLineArithmetic3Enum.UndoDuration)
end

--- 播放移动动画
---@param durationOverride number|nil 可选的时长覆盖（用于 undo 加速）
function XLineArithmetic3MoveHeadCommand:_PlayTween(headFrom, headTo, carriagesFrom, carriagesTo, onComplete, durationOverride)
    local uiGame = self._UiGame
    local duration = durationOverride or 0.3

    uiGame:CreateTween(duration, function(progress)
        -- 车头移动
        local headGo = uiGame:GetHeadGo()
        if not XTool.UObjIsNil(headGo) then
            local headPos = CS.UnityEngine.Vector3.Lerp(headFrom, headTo, progress)
            headGo.transform.position = headPos
        end

        -- 车厢移动
        for i = 1, uiGame:GetCarriageCount() do
            local carriageGo = uiGame:GetCarriageGo(i)
            if not XTool.UObjIsNil(carriageGo) and carriagesFrom[i] then
                local targetPos = type(carriagesTo) == "table" and carriagesTo[i] or carriagesTo
                if targetPos then
                    local carriagePos = CS.UnityEngine.Vector3.Lerp(carriagesFrom[i], targetPos, progress)
                    carriageGo.transform.position = carriagePos
                end
            end
        end
    end, onComplete)
end

return XLineArithmetic3MoveHeadCommand
