local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2AnimationGridEnable = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGridEnable")
local XLineArithmetic2AnimationGroup = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationGroup")
local XLineArithmetic2AnimationWait = require("XModule/XLineArithmetic2/Game/Animation/XLineArithmetic2AnimationWait")
local XLineArithmetic2Util = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Util")

---@class XLineArithmetic2Control : XControl
---@field private _Model XLineArithmetic2Model
local XLineArithmetic2Control = XClass(XControl, "XLineArithmetic2Control")
function XLineArithmetic2Control:OnInit()
    ---@type XLineArithmetic2Game
    self._Game = nil

    -- 预览功能
    ---@type XLineArithmetic2Game
    self._GamePreview = nil

    self._UiData = {
        MapEmptyData = {},

        ---@type XLineArithmetic2ControlMapData[]
        MapData = false,

        ---@type XLineArithmetic2ControlLineData[]
        LineData = false,

        ---@type XLineArithmetic2ControlDataEventDesc[]
        GridDescData = false,

        ---@type XLineArithmetic2ControlDataStarDesc[]
        StarDescData = false,

        StarAmount = 0,

        Settle = {
            Tip = false,
            RoleIcon = false,
        },

        Time = "",

        ---@type XLineArithmetic2ControlChapterData[]
        Chapter = false,
        UnlockChapters = { 1 },

        ---@type XLineArithmetic2ControlStageData[]
        Stage = false,

        ChapterTitleImg = false,
        ChapterTitle = false,
        ChapterBg = false,

        RewardOnMainUi = false,

        --CurrentChapterName = "",
        CurrentChapterStar = "",

        IsCanManualSettle = false,

        IsDefaultSelectDirty = false,
        DefaultSelectStageIndex = false,

        ---@type XLineArithmetic2ControlMapData[]
        HelpMapData = false,

        ---@type XLineArithmetic2ControlLineData[]
        HelpLineData = false,
    }
    self._StageId = 0

    -- 动态从ui读取
    self._GridSize = XLuaVector2.New(0, 0)
    self._GridBgSize = XLuaVector2.New(0, 0)

    self._TouchMovePos = XLuaVector2.New(0, 0)
    self._TouchTime = 0

    if XMain.IsEditorDebug and rawget(_G, "TestFile") then
        self._StageId = 1001
    end

    self._CurrentChapterId = false

    self._IsShowHelpBtn = false

    ---@type XLineArithmetic2HelpGame
    self._HelpGame = nil
    self._HelpActionDuration = 0.4
    self._HelpActionTime = 0
    self._HelpActionIndex = 1

    self._Timer = false

    self._HelpRecord = {}
end

function XLineArithmetic2Control:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_CLICK_GRID, self.OnClickPos, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_CONFIRM, self.ConfirmTouch, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_LAUNCH1, self.Launch1, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_LAUNCH2, self.Launch2, self)

    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            if not self._Model:CheckInTime() then
                XUiManager.TipText("FubenRepeatNotInActivityTime")
                self:CloseThisModule()
            end
        end, 0)
    end
end

function XLineArithmetic2Control:RemoveAgencyEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_CLICK_GRID, self.OnClickPos, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_CONFIRM, self.ConfirmTouch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_LAUNCH1, self.Launch1, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_LAUNCH2, self.Launch2, self)

    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XLineArithmetic2Control:OnRelease()
    self:ClearGame()
end

function XLineArithmetic2Control:GetGame()
    if not self._Game then
        self._Game = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Game").New()
    end
    return self._Game
end

function XLineArithmetic2Control:ClearGame()
    self._Game = nil
    self._GamePreview = nil
end

function XLineArithmetic2Control:SetGridSize(width, height)
    self._GridSize.x = width
    self._GridSize.y = height
end

function XLineArithmetic2Control:StartGame(restart, gridSize)
    if not restart then
        if not self._Model:IsPlaying() then
            XMVCA.XLineArithmetic2:RequestStart(self._StageId)
        end
    end

    self:ClearGame()
    ---@type XLineArithmetic2Game
    local game = self:GetGame()
    local configs = self._Model:GetMapByStageId(self._StageId)
    game:ImportConfig(self._Model, configs, self._StageId)
    if gridSize then
        self:SetGridSize(gridSize.x, gridSize.y)
    end
    self._GridBgSize.x = game:GetMapSize().x * self._GridSize.x
    self._GridBgSize.y = game:GetMapSize().y * self._GridSize.y
    game:SetGridAndBgSize(self._GridSize, self._GridBgSize)

    -- condition
    local stageId = self._StageId
    local starCondition = self._Model:GetStageStarCondition(stageId)
    local conditions = {}
    for i = 1, #starCondition do
        local conditionId = starCondition[i]
        local condition = XConditionManager.GetConditionTemplate(conditionId)
        conditions[#conditions + 1] = condition
    end
    game:SetCondition(conditions)

    local isStagePassed = self._Model:IsStagePassed(stageId)
    self:SetShowHelpBtn(isStagePassed)
    self:SetCurrentGameStageId()

    -- init preview game
    self._GamePreview = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Game").New()
end

function XLineArithmetic2Control:GetUiData()
    return self._UiData
end

function XLineArithmetic2Control:GetGridUiPos(x, y)
    return self._GridSize.x * (x - 0.5) - self._GridBgSize.x / 2, self._GridSize.y * (y - 0.5) - self._GridBgSize.y / 2
end

function XLineArithmetic2Control:UpdateEmptyData()
    local mapSize = self._Game:GetMapSize()
    local emptyData = {}
    self._UiData.MapEmptyData = emptyData
    for x = 1, mapSize.x do
        for y = 1, mapSize.y do
            local uiX, uiY = self:GetGridUiPos(x, y)
            local data = {
                X = uiX,
                Y = uiY
            }
            table.insert(emptyData, data)
        end
    end
end

function XLineArithmetic2Control:UpdateMap()
    local mapData = {}
    self._UiData.MapData = mapData

    local game = self:GetGame()
    game:GetGameMapData(mapData)
    --self:PrintMap("普通game:", game)

    -- 预览发射后的game
    if game:IsReadyShot() then
        local shotGrid = game:GetGrid(game:GetReadyShotPos())
        if shotGrid then
            local direction = shotGrid:GetShotDirection()
            if direction.x ~= 0 or direction.y ~= 0 then
                --显示预览后的game
                self._GamePreview:Copy(game)
                self._GamePreview:SetOffline()
                self._GamePreview:DisableAnimation()
                self._GamePreview:ConfirmAction()
                for i = 1, 99 do
                    if not self._GamePreview:Update(self._Model) then
                        break
                    end
                end
                ---@type XLineArithmetic2ControlMapData[]
                local mapDataPreview = {}
                self._GamePreview:GetGameMapData(mapDataPreview)
                --self:PrintMap("预览game:", game)
                for i = 1, #mapData do
                    ---@type XLineArithmetic2ControlMapData
                    local gridData = mapData[i]
                    -- 除了发射格, 其他格子, 使用发射后的数据代替
                    if (not gridData) or (not gridData.ShotDirection) then
                        local gridPreview = mapDataPreview[i]
                        mapData[i] = gridPreview
                    end
                end
            end
        end
    end

    --if XMain.IsEditorDebug then
    --    local str = ""
    --    for i = 1, #lineCurrent do
    --        local grid = lineCurrent[i]
    --        local pos = grid:GetPos()
    --        local strPos = string.format("(%d,%d)", pos.x, pos.y)
    --        str = str .. "," .. strPos
    --    end
    --    XLog.Debug(str)
    --end

    -- 第二期改为: 达成一星之后可以手动结算
    --if game:IsFinishSomeFinalGrids() then
    --    self._UiData.IsCanManualSettle = true
    --else
    --    self._UiData.IsCanManualSettle = false
    --end

    -- 预览即将被射中的格子
    local map = game:GetMap()
    local mapSize = game:GetMapSize()
    ---@type XLineArithmetic2Grid
    local endGridShot = nil
    for y = 1, mapSize.y do
        for x = 1, mapSize.x do
            local grid = map[y][x]
            if grid then
                if grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                        or grid:GetType() == XLineArithmetic2Enum.GRID.END_FILL
                        or grid:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
                then
                    endGridShot = grid
                    break
                end
            end
        end
        if endGridShot then
            break
        end
    end
    if endGridShot then
        if endGridShot:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_ONE then
            local grid = XLineArithmetic2Util.FindGrid2Shot(game, endGridShot, endGridShot:GetShotDirection())
            if grid then
                for i = 1, #mapData do
                    local gridData = mapData[i]
                    if gridData then
                        if gridData.Uid == grid:GetUid() then
                            gridData.IsToShot = true
                        end
                    end
                end
            end
        elseif endGridShot:GetType() == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH then
            local grids = XLineArithmetic2Util.FindGrid2Shot(game, endGridShot, endGridShot:GetShotDirection())
            for i = 1, #mapData do
                local gridData = mapData[i]
                if gridData then
                    for j = 1, #grids do
                        local grid = grids[j]
                        if gridData.Uid == grid:GetUid() then
                            gridData.IsToShot = true
                        end
                    end
                end
            end
        end
    end
end

function XLineArithmetic2Control:GetUiLineData(lineCurrent)
    local lineData = {}
    for i = 1, #lineCurrent do
        local grid1 = lineCurrent[i]
        local grid2 = lineCurrent[i + 1]
        if grid2 then
            local pos1
            local pos2
            if grid1.IsPosData then
                pos1 = grid1
            else
                pos1 = grid1:GetPos()
            end
            if grid2.IsPosData then
                pos2 = grid2
            else
                pos2 = grid2:GetPos()
            end

            local rotation = false
            if pos2.y > pos1.y and pos1.x == pos2.x then
                rotation = 90
            elseif pos2.y < pos1.y and pos1.x == pos2.x then
                rotation = -90
            elseif pos2.y == pos1.y and pos1.x > pos2.x then
                rotation = 180
            elseif pos2.y == pos1.y and pos1.x < pos2.x then
                rotation = 0
            else
                XLog.Error("[XLineArithmetic2Control] 连线存在未定义的情况")
            end
            if rotation then
                local x = (pos1.x + pos2.x - 1) / 2 * self._GridSize.x
                local y = (pos1.y + pos2.y - 1) / 2 * self._GridSize.y

                x = x - self._GridBgSize.x / 2
                y = y - self._GridBgSize.y / 2

                ---@class XLineArithmetic2ControlLineData
                local line = {
                    X = x,
                    Y = y,
                    Rotation = rotation,
                    -- 逆序, 方便动画使用
                    Index = #lineCurrent - i + 1,
                }
                lineData[#lineData + 1] = line
            end
        end
    end
    return lineData
end

function XLineArithmetic2Control:UpdateLine(line)
    local game = self:GetGame()
    line = line or game:GetLineGridList()
    local lineData = self:GetUiLineData(line)
    self._UiData.LineData = lineData
end

function XLineArithmetic2Control:GetGridXY(x, y)
    -- 改成相当左下角
    x = x + self._GridBgSize.x / 2
    y = y + self._GridBgSize.y / 2

    local gridX = math.floor(x / self._GridSize.x) + 1
    local gridY = math.floor(y / self._GridSize.y) + 1
    return gridX, gridY
end

function XLineArithmetic2Control:SetTouchPosOnDrag(x, y)
    local gridX, gridY = self:GetGridXY(x, y)

    -- 处于发射状态, 根据角度选择方向
    local line = self._Game:GetLineGridList()
    local lastGrid = line[#line]
    if lastGrid then
        local lastGridPos = lastGrid:GetPos()
        if lastGridPos.x ~= gridX or lastGridPos.y ~= gridY then
            local gridType = lastGrid:GetType()
            if gridType == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                    or gridType == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
                    or gridType == XLineArithmetic2Enum.GRID.END_FILL then
                local uiPosX, uiPosY = self._Game:GetGridUiPos(lastGridPos.x, lastGridPos.y)
                -- 计算角度
                local angle = math.atan(y - uiPosY, x - uiPosX) * 180 / math.pi
                if angle < 0 then
                    angle = angle + 360
                end
                if angle < 45 or angle > 315 then
                    gridX = lastGridPos.x + 1
                    gridY = lastGridPos.y
                elseif angle < 135 then
                    gridX = lastGridPos.x
                    gridY = lastGridPos.y + 1
                elseif angle < 225 then
                    gridX = lastGridPos.x - 1
                    gridY = lastGridPos.y
                else
                    gridX = lastGridPos.x
                    gridY = lastGridPos.y - 1
                end
            end
        end
    end

    -- 如果从其他位置拖回起点, 有效, 取消选中起点
    if self._TouchMovePos.x == gridX and self._TouchMovePos.y == gridY then
        -- 如果从起点再次拖动, 未选中起点, 有效, 选中起点
        if #line > 0 then
            return
        else
            -- 拖动到起点后, cd一段时间, 不然会反复选中取消
            if CS.UnityEngine.Time.time - self._TouchTime < 0.3 then
                return
            end
        end
    end
    self._TouchTime = CS.UnityEngine.Time.time
    self._TouchMovePos.x = gridX
    self._TouchMovePos.y = gridY
    self._Game:OnClickDrag(XLuaVector2.New(gridX, gridY))
end

function XLineArithmetic2Control:SetTouchPosOnBegin(x, y)
    local gridX, gridY = self:GetGridXY(x, y)

    -- 如果处于选中状态, 支持拖动时, 恢复选中
    local pos = XLuaVector2.New(gridX, gridY)
    local game = self:GetGame()
    local grid = game:GetGrid(pos)
    if not game:IsOnLineGridList(grid) then
        self._TouchMovePos.x = gridX
        self._TouchMovePos.y = gridY
    end
    self._Game:OnClickPos(pos)
end

function XLineArithmetic2Control:ConfirmTouch()
    self._Game:ConfirmAction()
end

function XLineArithmetic2Control:ClearTouchPos()
    self._TouchMovePos.x = 0
    self._TouchMovePos.y = 0
end

function XLineArithmetic2Control:UpdateGame(ui)
    self._Game:Update(self._Model, ui)
end

function XLineArithmetic2Control:IsUpdateGame()
    return self._Game:IsDirty()
end

function XLineArithmetic2Control:IsPlayingAnimation()
    return self._Game:IsPlayingAnimation()
end

function XLineArithmetic2Control:ClearGameDirty()
    self._Game:ClearDirty()
end

function XLineArithmetic2Control:OnClickReset()
    XMVCA.XLineArithmetic2:RequestRestart(self._StageId)
    self._Model:SetEditorGameData(false)
    self:ClearGame()
    self:StartGame(true)
    self:SetShowHelpBtn(true)
end

function XLineArithmetic2Control:GetAnimation()
    return self._Game:GetAnimation()
end

function XLineArithmetic2Control:UpdateGridDesc()
    local gridDescData = {}
    self._UiData.GridDescData = gridDescData

    local stageId = self._StageId
    local stageConfig = self._Model:GetStage(stageId)
    for i = 1, #stageConfig.MeshIcon do
        local icon = stageConfig.MeshIcon[i]
        local desc = stageConfig.MeshDesc[i]
        ---@class XLineArithmetic2ControlDataGridDesc
        local dataGrid = {
            Icon = icon,
            Desc = desc,
        }
        gridDescData[#gridDescData + 1] = dataGrid
    end
end

function XLineArithmetic2Control:UpdateStarTarget()
    local starDescData = {}
    self._UiData.StarDescData = starDescData
    local game = self:GetGame()

    local stageId = self._StageId
    local starCondition = self._Model:GetStageStarCondition(stageId)
    local starDesc = self._Model:GetStageStarConditionDesc(stageId)

    local starAmount = 0
    for i = 1, #starCondition do
        local conditionId = starCondition[i]
        local condition = XConditionManager.GetConditionTemplate(conditionId)
        local isFinish, strProgress = game:IsMatchCondition(condition, true)

        local isValid = true

        -- 隐藏星
        if condition.Type == XLineArithmetic2Enum.CONDITION.ALL_NUMBER_GRID then
            if not isFinish then
                isValid = false
            end
        end

        if isValid then
            -- 关卡进行中时不显示完成状态
            if condition.Type == XLineArithmetic2Enum.CONDITION.OPERATION_AMOUNT
                    and not game:IsFinish()
                    and not game:IsRequestSettle()
            then
                isFinish = false
            end

            if isFinish then
                starAmount = starAmount + 1
            end

            local desc = starDesc[i]
            if strProgress then
                desc = desc .. strProgress
            end
            ---@class XLineArithmetic2ControlDataStarDesc
            local data = {
                IsFinish = isFinish,
                Desc = desc,
                Index = i,
            }
            starDescData[#starDescData + 1] = data
        end
    end

    if starAmount > 0 then
        self._UiData.IsCanManualSettle = true
    else
        self._UiData.IsCanManualSettle = false
    end
    self._UiData.StarAmount = starAmount
end

function XLineArithmetic2Control:CheckFinish()
    -- 发送请求中
    if self._Model:IsRequesting() then
        return
    end
    local game = self:GetGame()
    if game:IsRequestSettle() then
        return
    end
    if not game:IsOnline() then
        return
    end
    if game:IsFinish() then
        self:SetShowHelpBtn(true)
        XMVCA.XLineArithmetic2:RequestSettle(game)
    end
end

function XLineArithmetic2Control:UpdateTime()
    local remainTime = self._Model:GetActivityRemainTime()
    if remainTime < 0 then
        remainTime = 0
    end
    if remainTime == 0 then
        self:CloseThisModule()
        return false
    end
    local text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    self._UiData.Time = text
    return true
end

function XLineArithmetic2Control:CloseThisModule()
    XLuaUiManager.SafeClose("UiLineArithmetic2Main")
    XLuaUiManager.SafeClose("UiLineArithmetic2Chapter")
    XLuaUiManager.SafeClose("UiLineArithmetic2Task")
    XLuaUiManager.SafeClose("UiLineArithmetic2Game")
    XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
    XLuaUiManager.SafeClose("UiLineArithmetic2Tips")
    XLuaUiManager.SafeClose("UiLineArithmetic2PopupTips")
    XLuaUiManager.SafeClose("UiHelp")
    XLuaUiManager.SafeClose("UiLineArithmetic2PopupCommon")
    XLuaUiManager.SafeClose("UiPopupTeach")
end

function XLineArithmetic2Control:UpdateChapter()
    local chapterData = {}
    self._UiData.Chapter = chapterData

    local chapters = self._Model:GetAllChaptersCurrentActivity()
    for i, chapterConfig in pairs(chapters) do
        --local name = chapterConfig.Name
        local chapterId = chapterConfig.Id
        local isOpen = self._Model:IsChapterOpen(chapterId)
        --local isRunning = currentGameChapterId == chapterId
        local isNewChapter
        if isOpen then
            isNewChapter = self._Model:IsNewChapter(chapterId)
        end
        local starAmount = self._Model:GetStarAmount(chapterId)
        local maxStarAmount = self._Model:GetMaxStarAmount(chapterId)
        local txtLock
        if not isOpen then
            txtLock = self:GetChapterLockTips(chapterId)
        end
        ---@class XLineArithmetic2ControlChapterData
        local chapter = {
            TxtStar = starAmount .. "/" .. maxStarAmount,
            Name = chapterConfig.Name,
            IsOpen = isOpen,
            --isRunning = isRunning,
            IsNew = isNewChapter,
            ChapterId = chapterId,
            TxtLock = txtLock,
        }
        chapterData[#chapterData + 1] = chapter
    end
    table.sort(chapterData, function(a, b)
        return a.ChapterId < b.ChapterId
    end)

    self._UiData.UnlockChapters = { 1 }
    for i, chapterConfig in pairs(chapters) do
        -- 默认解锁1
        if i ~= 1 then
            local chapterId = chapterConfig.Id
            local starAmount = self._Model:GetStarAmount(chapterId)
            local maxStarAmount = self._Model:GetMaxStarAmount(chapterId)
            if starAmount == maxStarAmount then
                table.insert(self._UiData.UnlockChapters, i)
            end
        end
    end
end

function XLineArithmetic2Control:SetChapterId(chapterId)
    self:SetDefaultSelectDirty(true)
    self._UiData.DefaultSelectStageIndex = false
    self._CurrentChapterId = chapterId
    self._Model:SetNotNewChapter(chapterId)
end

function XLineArithmetic2Control:SetDefaultSelectDirty(isDirty)
    self._UiData.IsDefaultSelectDirty = isDirty
end

function XLineArithmetic2Control:OpenChapterUi(chapterId)
    --local currentGameData = self._Model:GetCurrentGameData()
    --if currentGameData then
    --    local currentStageId = currentGameData.StageId
    --    local currentChapterId = self._Model:GetChapterIdByStageId(currentStageId)
    --    if currentChapterId ~= chapterId then
    --        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("LineArithmeticGoOnStage"), nil, nil, function()
    --            --self._StageId = currentStageId
    --            --XLuaUiManager.Open("UiLineArithmeticGame")
    --            self:SetChapterId(currentChapterId)
    --            XLuaUiManager.Open("UiLineArithmeticChapter", chapterId)
    --        end)
    --        return
    --    end
    --end
    self:SetChapterId(chapterId)
    XLuaUiManager.Open("UiLineArithmetic2Chapter", chapterId)
end

function XLineArithmetic2Control:OpenStageUi(stageId)
    if XLuaUiManager.IsStackUiOpen("UiLineArithmetic2Game") then
        return
    end
    self._StageId = stageId
    XLuaUiManager.Open("UiLineArithmetic2Game")
end

function XLineArithmetic2Control:ChallengeNextStage()
    local currentStageId = self._StageId
    if not currentStageId then
        XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
        XLuaUiManager.SafeClose("UiLineArithmetic2Game")
        XLog.Error("[XLineArithmetic2Control] 当前关卡有问题:", currentStageId)
        return
    end
    local stages = self._Model:GetAllStage()
    local isFind = false
    for i, config in pairs(stages) do
        if config.PreStageId == currentStageId then
            isFind = true
            -- 可能跨章节
            if self._Model:IsChapterOpen(config.ChapterId) then
                self._StageId = config.Id
                self:SetChapterId(config.ChapterId, false)
                break
            else
                -- 未开放
                XUiManager.TipText("LineArithmeticChapterLock")
                XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
                XLuaUiManager.SafeClose("UiLineArithmetic2Chapter")
                XLuaUiManager.SafeClose("UiLineArithmetic2Game")
                return
            end
        end
    end
    if not isFind then
        local chapterId = self._Model:GetNextChapterId(self._CurrentChapterId)
        if chapterId then
            -- 可能跨章节
            if self._Model:IsChapterOpen(chapterId) then
                isFind = self:SetFirstStageByChapterId(chapterId)
            else
                -- 未开放
                XUiManager.TipText("LineArithmeticChapterLock")
                XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
                XLuaUiManager.SafeClose("UiLineArithmetic2Chapter")
                XLuaUiManager.SafeClose("UiLineArithmetic2Game")
                return
            end
        end
    end
    if not isFind then
        XUiManager.TipText("LineArithmeticPassAll")
        XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
        XLuaUiManager.SafeClose("UiLineArithmetic2Chapter")
        XLuaUiManager.SafeClose("UiLineArithmetic2Game")
        return
    end
    self:StartGame()
    XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME)
    XLuaUiManager.SafeClose("UiLineArithmetic2PopupSettlement")
end

function XLineArithmetic2Control:SetFirstStageByChapterId(chapterId)
    local nextChapterStages = self._Model:GetStageByChapter(chapterId)
    local firstStage = nextChapterStages[1]
    if firstStage then
        self._StageId = firstStage.Id
        self:SetChapterId(chapterId, false)
        self._UiData.DefaultSelectStageIndex = 1
        return true
    end
    return false
end

function XLineArithmetic2Control:UpdateReward()
    local rewards = self._Model:GetRewardOnMainUi()
    self._UiData.RewardOnMainUi = rewards
end

function XLineArithmetic2Control:UpdateStage()
    ---@type XLineArithmetic2ControlStageData[]
    local stageData = {}
    self._UiData.Stage = stageData
    self._UiData.ChapterBg = self._Model:GetChapterConfig(self._CurrentChapterId).BgChapter
    ---@type XTableLineArithmeticStage[]
    local stages = self._Model:GetStageByChapter(self._CurrentChapterId)
    local chapterStarAmount = 0
    local maxChapterStarAmount = 0
    for i, stageConfig in pairs(stages) do
        local stageId = stageConfig.Id
        local starAmount = self._Model:GetStarAmountByStageId(stageId)
        local maxStarAmount = self._Model:GetMaxStarAmountByStageId(stageId)
        --local isRunning = currentStageId == stageId
        local preStageId = stageConfig.PreStageId
        local isLock
        if preStageId and preStageId ~= 0 then
            local isPassed = self._Model:IsStagePassed(preStageId)
            if not isPassed then
                isLock = true
            end
        end
        chapterStarAmount = chapterStarAmount + starAmount
        maxChapterStarAmount = maxChapterStarAmount + maxStarAmount

        ---@class XLineArithmetic2ControlStageData
        local stage = {
            StarAmount = starAmount,
            MaxStarAmount = maxStarAmount,
            Name = stageConfig.Name,
            --IsRunning = isRunning,
            StageId = stageId,
            IsLock = isLock,
            Icon = stageConfig.ChapterRoleIcon,
        }
        stageData[#stageData + 1] = stage
    end
    table.sort(stageData, function(a, b)
        return a.StageId < b.StageId
    end)

    local currentChapterId = self._CurrentChapterId
    local chapterConfig = self._Model:GetChapterConfig(currentChapterId)
    local chapterName = chapterConfig.Name
    self._UiData.CurrentChapterName = chapterName
    self._UiData.CurrentChapterStar = chapterStarAmount .. "/" .. maxChapterStarAmount

    -- 默认选中的关卡
    if not self._UiData.DefaultSelectStageIndex then
        local index
        --for i = 1, #stageData do
        --    local stage = stageData[i]
        --    if stage.IsRunning then
        --        index = i
        --        break
        --    end
        --end
        if not index then
            for i = #stageData, 1, -1 do
                local stage = stageData[i]
                if not stage.IsLock then
                    index = i
                    break
                end
            end
        end
        if not index then
            index = 1
        end
        self._UiData.DefaultSelectStageIndex = index
    end
end

function XLineArithmetic2Control:RequestManualSettle()
    local game = self._Game
    if game:IsRequestSettle() then
        return
    end
    if not game:IsOnline() then
        return
    end
    XMVCA.XLineArithmetic2:RequestSettle(self._Game)
end

function XLineArithmetic2Control:ClearHelpGame()
    self._HelpGame = nil
    self._HelpActionTime = 0
    self._HelpActionIndex = 1
end

function XLineArithmetic2Control:GetHelpGame()
    if not self._HelpGame then
        self._HelpGame = require("XModule/XLineArithmetic2/Game/XLineArithmetic2HelpGame").New()
    end
    return self._HelpGame
end

function XLineArithmetic2Control:StartHelpGame()
    self:ClearHelpGame()
    local game = self:GetHelpGame()
    local configs = self._Model:GetMapByStageId(self._StageId)
    game:ImportConfig(self._Model, configs, self._StageId)
    self._GridBgSize.x = game:GetMapSize().x * self._GridSize.x
    self._GridBgSize.y = game:GetMapSize().y * self._GridSize.y
    self._HelpGame:SetGridAndBgSize(self._GridSize, self._GridBgSize)
end

function XLineArithmetic2Control:GetHelpGameActionRecord()
    if self._HelpRecord[self._StageId] then
        return self._HelpRecord[self._StageId]
    end

    local configs = self._Model:GetStageHelpConfig(self._StageId)
    local record = {}
    local action
    for i = 1, #configs do
        local config = configs[i]
        if action then
            if action.Round ~= config.Round then
                action = nil
            end
        end
        if not action then
            action = {
                Round = config.Round,
                Points = {}
            }
            record[#record + 1] = action
        end
        action.Points[#action.Points + 1] = { X = config.X, Y = config.Y }
    end
    self._HelpRecord[self._StageId] = record
    return record
end

function XLineArithmetic2Control:UpdateHelpGame(deltaTime)
    deltaTime = deltaTime or CS.UnityEngine.Time.deltaTime
    self._HelpActionTime = self._HelpActionTime + deltaTime
    if self._HelpActionTime > self._HelpActionDuration then
        self._HelpActionTime = 0

        local game = self:GetHelpGame()
        local record = self:GetHelpGameActionRecord()
        local operatorRecords = record
        local index = 0
        local isValid = false
        for i = 1, #operatorRecords do
            local operation = operatorRecords[i]
            local points = operation.Points
            for j = 1, #points do
                index = index + 1
                if index == self._HelpActionIndex then
                    local point = points[j]
                    local pos = XLuaVector2.New(point.X, point.Y)
                    if j == 1 then
                        game:OnClickPos(pos)
                    else
                        game:OnClickDrag(pos)
                    end
                    self:SyncOperation(game)
                    isValid = true
                    break
                end
                if j == #points then
                    index = index + 1
                    if index == self._HelpActionIndex then
                        isValid = true
                        game:ConfirmAction(self._Model)
                        self:SyncOperation(game)
                    end
                    break
                end
            end
            if isValid then
                break
            end
        end

        if isValid then
            self._HelpActionIndex = self._HelpActionIndex + 1
            return true
        else
            --if XMain.IsEditorDebug then
            --    XLog.Error("[XLineArithmetic2Control] 连线图文已结束:", self._HelpActionIndex)
            --end
            self:StartHelpGame()
            return false
        end
        return true
    end
    return false
end

function XLineArithmetic2Control:UpdateHelpMap()
    ---@type XLineArithmetic2ControlMapData[]
    local mapData = {}
    self._UiData.HelpMapData = mapData

    local game = self:GetHelpGame()
    game:GetGameMapData(mapData)

    -- 移除特效表情之类的
    --for i = 1, #mapData do
    --    local gridData = mapData[i]
    --    gridData.EmoIcon = false
    --    gridData.NumberOnPreview = 0
    --    gridData.IsNormal = true
    --end
end

function XLineArithmetic2Control:UpdateHelpLine()
    local game = self:GetHelpGame()
    local lineCurrent = game:GetLineGridList()
    local lineData = self:GetUiLineData(lineCurrent)
    self._UiData.HelpLineData = lineData
end

function XLineArithmetic2Control:IsShowHelpBtn()
    return self._IsShowHelpBtn and self._Model:IsUnlockHelpBtn()
end

function XLineArithmetic2Control:MarkOpenUiHelp()
    local game = self:GetGame()
    game:MarkUseHelp()
end

function XLineArithmetic2Control:IsGamePlayed()
    local game = self:GetGame()
    return game:IsHasRecord() or #game:GetLineGridList() > 0
end

function XLineArithmetic2Control:IsGameSettle()
    return self:GetGame():IsRequestSettle()
end

function XLineArithmetic2Control:SetShowHelpBtn(value)
    -- 有缓存取缓存
    local valueCache = XSaveTool.GetData("LineArithmeticShowHelp" .. XPlayer.Id .. self._StageId, value)
    if valueCache ~= nil then
        value = valueCache
    end
    if self._IsShowHelpBtn ~= value then
        self._IsShowHelpBtn = value
        if value then
            XSaveTool.SaveData("LineArithmeticShowHelp" .. XPlayer.Id .. self._StageId, true)
        end
    end
end

function XLineArithmetic2Control:GetCurrentStageName()
    local stageId = self._StageId
    return self._Model:GetStageName(stageId)
end

function XLineArithmetic2Control:UpdateChapterTitle()
    local chapterId = self._CurrentChapterId
    --local titleImg = self._Model:GetChapterTitleImg(chapterId)
    --self._UiData.ChapterTitleImg = titleImg
    local title = self._Model:GetChapterTitle(chapterId)
    self._UiData.ChapterTitle = title
end

function XLineArithmetic2Control:GetChapterLockTips(chapterId)
    local timeId = self._Model:GetChapterTimeId(chapterId)
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if timeId ~= 0 and startTime == 0 and endTime == 0 then
        XLog.Error("[XLineArithmetic2Control] 未获取到服务端的时间数据 timeId:" .. tostring(timeId))
        return XUiHelper.GetText("LineArithmeticChapterLock")
    end

    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = startTime - currentTime
    if remainTime >= 0 then
        local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR_2)
        return XUiHelper.GetText("LineArithmeticUnlockChapter", timeStr)
    end
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return XUiHelper.GetText("LineArithmeticChapterLock")
    end
    XLog.Error("[XLineArithmetic2Control] 不明情况导致上锁")
    return XUiHelper.GetText("LineArithmeticChapterLock")
end

---@param data XLineArithmetic2ControlChapterData
function XLineArithmetic2Control:OnClickChapter(data)
    local chapterId = data.ChapterId
    if not data.IsOpen then
        XUiManager.TipMsg(self:GetChapterLockTips(chapterId))
        return
    end
    self:OpenChapterUi(chapterId)
end

function XLineArithmetic2Control:SetCurrentGameStageId()
    self._Model:SetCurrentGameStageId(self._StageId)
end

function XLineArithmetic2Control:ClearCurrentGameStageId()
    self._Model:SetCurrentGameStageId(false)
end

function XLineArithmetic2Control:OnClickPos(gridX, gridY)
    local pos = XLuaVector2.New(tonumber(gridX), tonumber(gridY))
    self._Game:OnClickPos(pos)
end

function XLineArithmetic2Control:IsRequesting()
    return self._Model:IsRequesting()
end

function XLineArithmetic2Control:GetScore()
    return self._Game:GetScore()
end

function XLineArithmetic2Control:SyncOperation(game)
    for k = 1, 99 do
        if not game:Update(self._Model) then
            break
        end
    end
end

---@param game XLineArithmetic2Game
function XLineArithmetic2Control:PrintMap(prefix, game)
    local map = game:GetMap()
    local mapSize = game:GetMapSize()
    local log = {}
    for i = 1, mapSize.y do
        local line = ""
        for j = 1, mapSize.x do
            local grid = map[i] and map[i][j]
            if grid then
                line = line .. "\t" .. grid:GetCellName()
            else
                line = line .. "\t0"
            end
        end
        log[i] = line
    end
    local logStr = prefix .. "打印map:\n"
    for i = #log, 1, -1 do
        logStr = logStr .. log[i] .. "\n"
    end
    XLog.Debug(logStr)
end

function XLineArithmetic2Control:UpdateSettleDesc()
    local data = self._UiData.Settle
    local stageId = self._StageId
    local stageConfig = self._Model:GetStage(stageId)
    data.RoleIcon = stageConfig.SettleRoleIcon
    local star = self._UiData.StarAmount
    -- 应策划要求, 三星使用描述2, 其他使用描述1, 作为提示文本
    if star >= 3 then
        data.Tip = stageConfig.SettleDesc[2]
    else
        data.Tip = stageConfig.SettleDesc[1]
    end
end

function XLineArithmetic2Control:IsCanManualSettle()
    local game = self:GetGame()
    if game:IsCanOperate() then
        return true
    end
    return false
end

function XLineArithmetic2Control:PlayAnimationGridEnable()
    local game = self:GetGame()
    -----@type XLineArithmetic2AnimationWait
    --local animationWait = XLineArithmetic2AnimationWait.New()
    --animationWait:SetData(0.5)
    --game:AddAnimation(animationWait)

    ---@type XLineArithmetic2AnimationGroup
    local animationGroup = XLineArithmetic2AnimationGroup.New()
    local mapSize = game:GetMapSize()
    for x = 1, mapSize.x do
        for y = 1, mapSize.y do
            local grid = game:GetGrid(XLuaVector2.New(x, y))
            if grid then
                if not grid:IsEmpty() then
                    ---@type XLineArithmetic2AnimationGridEnable
                    local animationEnable = XLineArithmetic2AnimationGridEnable.New()
                    animationEnable:SetData(grid:GetUid())
                    animationGroup:Add(animationEnable)
                end
            end
        end
    end
    game:AddAnimation(animationGroup)
end

function XLineArithmetic2Control:GetTaskList()
    return XMVCA.XLineArithmetic2:GetTaskList()
end

function XLineArithmetic2Control:Launch1(x, y, direction)
    x = tonumber(x)
    y = tonumber(y)
    direction = tonumber(direction)
    self._Game:OnClickDrag(XLuaVector2.New(x, y))
    -- 发射方向 1234分别对应上下左右
    local offset
    if direction == 1 then
        offset = XLuaVector2.New(0, 1)
    elseif direction == 2 then
        offset = XLuaVector2.New(0, -1)
    elseif direction == 3 then
        offset = XLuaVector2.New(-1, 0)
    elseif direction == 4 then
        offset = XLuaVector2.New(1, 0)
    end
    if offset then
        --XScheduleManager.ScheduleNextFrame(function()
        --end)
        self._Game:OnClickDrag(XLuaVector2.New(x + offset.x, y + offset.y), true)
    else
        XLog.Error("[XLineArithmetic2Control] 发射方向参数有问题:" .. tostring(direction))
    end
end

function XLineArithmetic2Control:Launch2()
    self._Game:ConfirmAction()
end

function XLineArithmetic2Control:TestAllStageByConfig()
    local stageConfigs = self._Model:GetAllStage()
    for k, v in pairs(stageConfigs) do
        self._StageId = v.Id
        self:StartHelpGame()
        for i = 1, 999 do
            self:UpdateHelpGame(999)
            if self._HelpGame:IsFinish() then
                print("完成测试:" .. v.Id)
                break
            end
            if i == 999 then
                print("测试失败:" .. v.Id)
            end
        end
    end
end

return XLineArithmetic2Control