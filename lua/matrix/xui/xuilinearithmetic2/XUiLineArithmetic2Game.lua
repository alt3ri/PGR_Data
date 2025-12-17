local XUiLineArithmetic2GameGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2GameGrid")
local XUiLineArithmetic2GameEventGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2GameEventGrid")
local XUiLineArithmetic2GameStarGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2GameStarGrid")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XUiLineArithmetic2Game : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2Game = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2Game")

function XUiLineArithmetic2Game:Ctor()
    ---@type XUiLineArithmetic2GameGrid[]
    self._UiGrids = {}

    ---@type XUiLineArithmetic2GameGrid[]
    self._UiGridPool = {}

    self._DictUiLine = {}

    self._UiLines = {}

    self._TimerGame = false

    ---@type XUiLineArithmetic2GameEventGrid[]
    self._GridDesc = {}

    ---@type XUiLineArithmetic2GameStarGrid[]
    self._StarGrids = {}

    self._Duration = 0

    self._Score = 0

    self._IsPlayingScoreAnimation = false
end

function XUiLineArithmetic2Game:OnAwake()
    self:BindExitBtns()
    self.AllGrid.gameObject:SetActiveEx(false)
    self.GridLine.gameObject:SetActiveEx(false)
    self.SpecialGrid.gameObject:SetActiveEx(false)
    self.GridTarget.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnClickReset)
    XUiHelper.RegisterClickEvent(self, self.BtnSettlement, self.OnClickManualSettle)

    ---@type XGoInputHandler
    local goInputHandler = self.PanelTouch
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)

    --self:BindHelpBtn(self.BtnHelp, "LineArithmeticHelp")
    self:RegisterClickEvent(self.BtnHelp, self.OnClickTip)
    XUiHelper.RegisterClickEvent(self, self.BtnTips, self.OnClickHelp)

    self.AddScore = self.AddScore or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelRight/PanelScore/PanelScorePreview/TxtScore", "Text")
end

function XUiLineArithmetic2Game:OnStart()
    ---@type UnityEngine.UI.GridLayoutGroup
    local gridLayoutGroup = self.AllGrid:GetComponent(typeof(CS.UnityEngine.UI.LayoutGroup))
    local gridSize = gridLayoutGroup.cellSize
    self._Control:StartGame(nil, gridSize)
    -- 只在一开始更新一次
    self:UpdateEmptyGrid()
    self:UpdateTipsBtn()
    self:UpdateGridDesc()

    -- 播放动画
    self._Control:PlayAnimationGridEnable()
end

function XUiLineArithmetic2Game:OnEnable()
    self:Update()
    if not self._TimerGame then
        self._TimerGame = XScheduleManager.ScheduleForever(function()
            self:UpdateGame()
        end, 0, 0)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_LINE, self.UpdateLine, self)
    XEventManager.AddEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME, self.UpdateFromEvent, self)

    self._Control:SetCurrentGameStageId()
end

function XUiLineArithmetic2Game:OnDisable()
    if self._TimerGame then
        XScheduleManager.UnSchedule(self._TimerGame)
        self._TimerGame = false
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_LINE, self.UpdateLine, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME, self.UpdateFromEvent, self)

    self._Control:ClearCurrentGameStageId()
end

function XUiLineArithmetic2Game:UpdateFromEvent()
    self:Update()
    self:UpdateTipsBtn()
    self:UpdateGridDesc()
end

function XUiLineArithmetic2Game:Update()
    self:UpdateMap()
    --self:UpdateEventGridDesc()
    self:UpdateTitle()
    self:UpdateScore()
end

---@param dataGrid XLineArithmetic2ControlMapData
function XUiLineArithmetic2Game:UpdateGrid(dataGrid, usedGrid)
    local uiGrid = self._UiGrids[dataGrid.Uid]

    -- 如果已经有uiGrid, 但是和之前的类型不同, 回收它, 重新创建
    if uiGrid then
        if uiGrid:GetType() ~= dataGrid.Type
                or uiGrid:GetColor() ~= dataGrid.Color
        then
            self._UiGrids[dataGrid.Uid] = nil
            self._UiGridPool[#self._UiGridPool + 1] = uiGrid
            uiGrid:Close()
            uiGrid = nil
        end
    end

    if not uiGrid then
        -- 尝试从池中获取
        for i = 1, #self._UiGridPool do
            local uiGridFromPool = self._UiGridPool[i]
            if uiGridFromPool:GetType() == dataGrid.Type
                    and uiGridFromPool:GetColor() == dataGrid.Color
            then
                table.remove(self._UiGridPool, i)
                self._UiGrids[dataGrid.Uid] = uiGridFromPool
                uiGrid = uiGridFromPool
                break
            end
        end

        -- 池里没有, new一个
        if not uiGrid then
            local toInstantiate = self:GetUiGridInstance(dataGrid)
            if toInstantiate then
                ---@type UnityEngine.UI.GridLayoutGroup
                local gridLayoutGroup = self.AllGrid:GetComponent(typeof(CS.UnityEngine.UI.LayoutGroup))

                ---@type UnityEngine.RectTransform
                local instance = CS.UnityEngine.Object.Instantiate(toInstantiate, self.PanelGrid)
                -- 设置宽高
                instance.sizeDelta = gridLayoutGroup.cellSize
                uiGrid = XUiLineArithmetic2GameGrid.New(instance, self, dataGrid.Type, dataGrid.Color)
            end
            self._UiGrids[dataGrid.Uid] = uiGrid
        end
    end

    if uiGrid then
        uiGrid:Open()
        uiGrid:Update(dataGrid)
        if usedGrid then
            usedGrid[dataGrid.Uid] = true
        end
    end
end

function XUiLineArithmetic2Game:UpdateMap(map)
    self._Control:UpdateMap()
    local uiData = self._Control:GetUiData()
    if not map then
        map = uiData.MapData
    end

    local usedGrid = {}

    -- 画格子
    if not map then
        return
    end
    for i = 1, #map do
        local dataGrid = map[i]
        if dataGrid then
            self:UpdateGrid(dataGrid, usedGrid)
        end
    end

    for uid, uiGrid in pairs(self._UiGrids) do
        if not usedGrid[uid] then
            self._UiGrids[uid] = nil
            self._UiGridPool[#self._UiGridPool + 1] = uiGrid
            uiGrid:Close()
        end
    end

    self:UpdateLine()
    self:UpdateStarTarget()
    self:UpdateResetButton()

    if uiData.IsCanManualSettle then
        self.BtnSettlement:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnSettlement:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiLineArithmetic2Game:UpdateLine(lineCurrent)
    self._Control:UpdateLine(lineCurrent)
    local uiData = self._Control:GetUiData()

    -- 画线
    local line = uiData.LineData
    if not line then
        return
    end
    for i = 1, #line do
        local dataLine = line[i]
        local uiLine = self._UiLines[i]
        if not uiLine then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridLine, self.GridLine.transform.parent)
            uiLine = ui
            self._UiLines[i] = uiLine
        end
        uiLine.gameObject:SetActiveEx(true)
        self._DictUiLine[dataLine.Index] = uiLine
        local x = dataLine.X
        local y = dataLine.Y
        local rotation = dataLine.Rotation
        ---@type UnityEngine.RectTransform
        local rectTransform = uiLine
        rectTransform.localPosition = Vector3(x, y, 0)
        rectTransform.localEulerAngles = Vector3(0, 0, rotation)
    end
    for i = #line + 1, #self._UiLines do
        local uiLine = self._UiLines[i]
        uiLine.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmetic2Game:OnDestroy()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelTouch
    goInputHandler:RemoveAllListeners()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmetic2Game:OnBeginDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    local x, y = self:GetPosByEventData(eventData)
    self._Control:SetTouchPosOnBegin(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmetic2Game:OnDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    local x, y = self:GetPosByEventData(eventData)
    self._Control:SetTouchPosOnDrag(x, y)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmetic2Game:OnEndDrag(eventData)
    if self:IsPlayingAnimation() then
        return
    end
    self._Control:ConfirmTouch()
    self._Control:ClearTouchPos()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiLineArithmetic2Game:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelTouch.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    local x, y = point.x, point.y
    return x, y
end

function XUiLineArithmetic2Game:UpdateGame()
    self._Control:UpdateGame(self)
    if self._Control:IsPlayingAnimation() then
        return
    end
    if self._Control:IsUpdateGame() then
        self:UpdateMap()
        self:UpdateScore()
        self._Control:ClearGameDirty()
    end
    -- 等待分数动画结束，否则结算弹窗的背景截图会停留在错误的分数
    if not self._IsPlayingScoreAnimation then
        self._Control:CheckFinish()
    end
end

function XUiLineArithmetic2Game:OnClickReset()
    if not self._Control:IsGamePlayed() then
        return
    end
    self._Control:OnClickReset()
    self._DictUiLine = {}
    self:Update()
    self:UpdateTipsBtn()
    self:UpdateScore()
end

function XUiLineArithmetic2Game:GetUiLineByIndex(index)
    return self._DictUiLine[index]
end

function XUiLineArithmetic2Game:HideUiLineByIndex(index)
    local line = self:GetUiLineByIndex(index)
    if line then
        line.gameObject:SetActiveEx(false)
    else
        XLog.Error("[XLineArithmetic2Animation] 移除箭头失败:", self._ArrowIndex)
    end
end

function XUiLineArithmetic2Game:RemoveOverLineByIndex(index)
    if not index then
        XLog.Error("[XUiLineArithmetic2Game] index为空")
        return
    end
    for i, uiLine in pairs(self._DictUiLine) do
        if i > index then
            uiLine.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLineArithmetic2Game:UpdateGridDesc()
    self._Control:UpdateGridDesc()
    local uiData = self._Control:GetUiData()
    local gridDescData = uiData.GridDescData

    for i = 1, #gridDescData do
        local gridDesc = gridDescData[i]
        local uiGrid = self._GridDesc[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.SpecialGrid, self.SpecialGrid.parent)
            uiGrid = XUiLineArithmetic2GameEventGrid.New(ui, self)
            self._GridDesc[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(gridDesc)
    end
    for i = #gridDescData + 1, #self._GridDesc do
        local uiGrid = self._GridDesc[i]
        uiGrid:Close()
    end
end

function XUiLineArithmetic2Game:UpdateStarTarget()
    self._Control:UpdateStarTarget()

    local uiData = self._Control:GetUiData()
    local stars = uiData.StarDescData
    -- ui逻辑: 第四颗星作为隐藏星
    local starAmount = math.min(3, #stars)

    for i = 1, starAmount do
        local starDesc = stars[i]
        local uiGrid = self._StarGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridTarget, self.GridTarget.parent)
            uiGrid = XUiLineArithmetic2GameStarGrid.New(ui, self)
            self._StarGrids[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(starDesc)
    end
    for i = starAmount + 1, #self._StarGrids do
        local uiGrid = self._StarGrids[i]
        uiGrid:Close()
    end
end

function XUiLineArithmetic2Game:OnClickManualSettle()
    -- 操作过程中，不能手动结算
    if not self._Control:IsCanManualSettle() then
        return
    end
    if self._Control:GetUiData().IsCanManualSettle then
        if self._Control:IsGameSettle() then
            XLog.Error("[XUiLineArithmetic2Game] 游戏已结算，不能手动结算")
            return
        end
        XLuaUiManager.Open("UiLineArithmetic2PopupCommon", function()
            self._Control:RequestManualSettle()
            self:UpdateTipsBtn()
        end, XUiHelper.GetText("LineArithmeticManualSettle"))
        --else
        --if XMain.IsWindowsEditor then
        --    XLog.Error("[XUiLineArithmetic2Game] 还不能手动结算")
        --end
    end
end

function XUiLineArithmetic2Game:UpdateTipsBtn()
    if self._Control:IsShowHelpBtn() then
        if not self.BtnTips.gameObject.activeInHierarchy then
            self.BtnTips.gameObject:SetActiveEx(true)
            XDataCenter.GuideManager.CheckGuideOpen()
        end
    else
        self.BtnTips.gameObject:SetActiveEx(false)
    end
end

function XUiLineArithmetic2Game:OnClickHelp()
    if self:IsPlayingAnimation() then
        return
    end
    self._Control:MarkOpenUiHelp()
    XLuaUiManager.Open("UiLineArithmetic2PopupTips")
end

function XUiLineArithmetic2Game:IsPlayingAnimation()
    return false
end

function XUiLineArithmetic2Game:UpdateResetButton()
    if self._Control:IsGamePlayed() then
        self.BtnResetting:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnResetting:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiLineArithmetic2Game:OnClickTip()
    if self:IsPlayingAnimation() then
        return
    end
    XUiManager.ShowHelpTip("LineArithmeticHelp")
end

function XUiLineArithmetic2Game:UpdateTitle()
    if self.Title then
        self.Title.text = self._Control:GetCurrentStageName()
    end
end

function XUiLineArithmetic2Game:UpdateEmptyGrid()
    self._Control:UpdateEmptyData()
    local emptyData = self._Control:GetUiData().MapEmptyData
    XUiHelper.RefreshCustomizedList(self.PanelEmpty.transform, self.GridEmpty, #emptyData, function(index, grid)
        local data = emptyData[index]
        grid.transform.localPosition = Vector3(data.X, data.Y, 0)
    end)
end

---@param grid XLineArithmetic2ControlMapData
function XUiLineArithmetic2Game:GetUiGridInstance(grid)
    local color = grid.Color
    local type = grid.Type

    local number = type
    if number < 10 then
        number = "0" .. number
    end
    local colorName
    if color == XLineArithmetic2Enum.COLOR.BLUE then
        colorName = "Blue"
    elseif color == XLineArithmetic2Enum.COLOR.RED then
        colorName = "Red"
    elseif color == XLineArithmetic2Enum.COLOR.PURPLE then
        colorName = "Purple"
    end
    local uiGrid
    if colorName then
        uiGrid = self[string.format("Grid%s_%s", number, colorName)]
    else
        uiGrid = self[string.format("Grid%s", number)]
    end
    if not uiGrid then
        XLog.Error("[XUiLineArithmetic2Game] 找不到对应的格子", tostring(type), tostring(color))
    end
    return uiGrid
end

function XUiLineArithmetic2Game:UpdateScore()
    local score = self._Control:GetScore()
    if score <= self._Score then
        self._IsPlayingScoreAnimation = false
        self.TxtScore.text = score
        self._Score = score
        return
    end

    self:StopAnimation("TxtScoreEnable")
    if self.AddScore then
        self.AddScore.text = "+" .. tostring(score - self._Score)
    end
    self._Score = score
    self._IsPlayingScoreAnimation = true
    self:PlayAnimation("TxtScoreEnable", function()
        self._IsPlayingScoreAnimation = false
        -- 播放动画结束后，可能重置游戏，或下一关，导致分数变化，这时应该获取最新的分数
        self.TxtScore.text = self._Control:GetScore()
    end)
end

---@return XUiLineArithmetic2GameGrid
function XUiLineArithmetic2Game:GetGrid(uid)
    return self._UiGrids[uid]
end

function XUiLineArithmetic2Game:RevertGridStateBeforeAnimation()
    for _, uiGrid in pairs(self._UiGrids) do
        if uiGrid:IsNodeShow() then
            uiGrid:RevertStateBeforeAnimation()
        end
    end
end

function XUiLineArithmetic2Game:PlaySound(name)
    self.AudioPlayer = self.AudioPlayer or XUiHelper.TryGetComponent(self.Transform, "XAudioObjectPlayer", "XAudioObjectPlayer")
    if self.AudioPlayer then
        self.AudioPlayer:PlayByKeyName(name)
    end
end

return XUiLineArithmetic2Game
