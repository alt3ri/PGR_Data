local XUiConnectingLineGameAvatar = require("XUi/XUiConnectingLine/XUiConnectingLineGameAvatar")
local XConnectingLineOperation = require("XModule/XConnectingLine/XEntity/XConnectingLineOperation")
local XUiConnectingLineGameGrid = require("XUi/XUiConnectingLine/XUiConnectingLineGameGrid")
local OPERATION_TYPE = XEnumConst.CONNECTING_LINE.OPERATION_TYPE

---这个游戏用的配置和逻辑都是从预热活动ConnectLine复制过来的，配置是share的同一份，但是从战斗传递这个activityId，而不是来自服务端
---@class XUiHackerGameV440meV440:XLuaUi
---@field private _Control XConnectingLineControl
local XUiFightHackerGameV440 = XLuaUiManager.Register(XLuaUi, "UiFightHackerGameV440")

function XUiFightHackerGameV440:Ctor()
    ---@type XUiComponent.XUiLineRenderer
    self._LineNormal = {}
    ---@type XUiComponent.XUiLineRenderer
    self._LineEnable = {}
    ---@type XUiConnectingLineGameAvatar[][]
    self._Avatars = {}
    ---@type XUiConnectingLineGameGrid[]
    self._GridList = {}
end

function XUiFightHackerGameV440:OnAwake()
    -- 隐藏模板对象
    self.LineNormal.gameObject:SetActiveEx(false)
    self.LineEnable.gameObject:SetActiveEx(false)
    self.GridBoard.gameObject:SetActiveEx(false)
    self.GridBoardHead.gameObject:SetActiveEx(false)
    self.GridHead.gameObject:SetActiveEx(false)
    self.PanelBtn.gameObject:SetActiveEx(false)

    -- 初始化格子池：从 GridBoard 父节点按顺序获取所有子节点，不足时再动态创建
    self:InitGridList()

    -- 注册输入和按钮事件
    self:AddListenerInput()
    XUiHelper.RegisterClickEvent(self, self.ButtonReset, self.OnClickReset)
    XUiHelper.RegisterClickEvent(self, self.ButtonComplete, self.OnClickComplete)
end

---@param npc table@来自战斗的数据，无用
---@param gameId number@游戏ID，对应配置表ConnectingLineStage的ActivityId
function XUiFightHackerGameV440:OnGameInit(npc, gameId, buttonIcon, buttonScaleX, buttonScaleY)
    -- 重置UI状态
    self:ResetState()

    local stageId = self._Control:GetRandomStageIdByGameId(gameId)
    self._StageId = stageId
    if stageId > 0 then
        self:StartGame()
    else
        self.PanelGame.gameObject:SetActiveEx(false)
        self.PanelBtn.gameObject:SetActiveEx(true)
    end

    self:SetButtonParams(buttonIcon, buttonScaleX, buttonScaleY)
end

--- 重置界面状态（解决战斗中Close不销毁导致的状态残留问题）
function XUiFightHackerGameV440:ResetState()
    -- 重置面板显示状态
    self.PanelGame.gameObject:SetActiveEx(true)
    self.PanelBtn.gameObject:SetActiveEx(false)

    -- 隐藏所有连线
    for i = 1, #self._LineNormal do
        if self._LineNormal[i] then
            self._LineNormal[i].gameObject:SetActiveEx(false)
        end
    end
    for i = 1, #self._LineEnable do
        if self._LineEnable[i] then
            self._LineEnable[i].gameObject:SetActiveEx(false)
        end
    end

    -- 清理游戏逻辑层状态
    local game = self._Control:GetGame()
    if game then
        game:ClearBoard()
    end
end

--- 战斗侧关闭不会销毁，传参依靠OnEnable
function XUiFightHackerGameV440:OnEnable(...)
    self:OnGameInit(...)
    self.Timer = XScheduleManager.ScheduleForever(function()
        -- 按下esc
        if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.Escape) then
            self:Close()
        end
    end, 0)
    XEventManager.AddEventListener(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE, self.OnResetStage, self)
end

function XUiFightHackerGameV440:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    for i = 1, #self._GridList do
        self._GridList[i]:Close()
    end
    for _, avatars in pairs(self._Avatars) do
        for _, avatar in pairs(avatars) do
            avatar:Hide()
        end
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE, self.OnResetStage, self)
end

function XUiFightHackerGameV440:OnDestroy()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:RemoveAllListeners()
end

---------- 游戏初始化 ----------

function XUiFightHackerGameV440:InitGame()
    -- 临时替换 stageId，用完恢复
    local savedStageId = self._Control:GetCurrentStageId()
    self._Control:SetCurrentStageId(self._StageId)

    ---@type UnityEngine.RectTransform
    local grid = self.GridHead
    local gridSize = grid.rect.size
    self._Control:InitGame(gridSize.x, gridSize.y)
    self:SetUiGrids()
    self:UpdateBackgroundSize()

    self._Control:SetCurrentStageId(savedStageId)
end

function XUiFightHackerGameV440:StartGame()
    self:InitGame()
    self:SetUiAvatar()
    self:UpdatePainting()
    self:UpdateGameInfo()
end

function XUiFightHackerGameV440:SetEmpty()
    self:InitGame()
    self:ClearBoard()
    self:SetUiAvatar()
    self:UpdatePainting()
    self:UpdateGameInfo()
end

---------- 棋盘格子 ----------

--- 初始化格子池：从 GridBoard 父节点按顺序获取所有子节点（含模板）作为预置格子，不足时再动态创建
function XUiFightHackerGameV440:InitGridList()
    local parent = self.GridBoard.gameObject.transform.parent
    local childCount = parent.childCount
    self._GridList = {}
    for i = 0, childCount - 1 do
        local child = parent:GetChild(i)
        local uiGrid = XUiConnectingLineGameGrid.New(child, self)
        table.insert(self._GridList, uiGrid)
    end
end

function XUiFightHackerGameV440:SetUiGrids()
    local game = self._Control:GetGame()
    local map = game:GetAvatarMap()
    local count = 0
    for column = 1, #map do
        local grids = map[column]
        for row = 1, #grids do
            count = count + 1
            local uiGrid = self._GridList[count]
            if not uiGrid then
                local object = CS.UnityEngine.Object.Instantiate(self.GridBoard, self.GridBoard.gameObject.transform.parent)
                uiGrid = XUiConnectingLineGameGrid.New(object, self)
                self._GridList[count] = uiGrid
            end
            local grid = grids[row]
            uiGrid:SetPos(column, row, grid:GetPosUid())
            uiGrid:SetConnected(false)
            if grid:IsHole() then
                uiGrid:SetGridBg(grid:GetAvatarIcon())
                uiGrid:SetIsHole(true)
            else
                uiGrid:SetIsHole(false)
            end
            uiGrid:Open()
            -- GridLayout 会自动根据顺序排序
            ---@type UnityEngine.RectTransform
            local transform = uiGrid.Transform
            transform:SetSiblingIndex(count)
        end
    end
    -- 隐藏多余的格子
    for i = count + 1, #self._GridList do
        local grid = self._GridList[i]
        grid:Close()
        grid:Clear()
    end
end

---------- 头像 ----------

function XUiFightHackerGameV440:SetUiAvatar()
    -- 先隐藏所有头像
    for _, avatars in pairs(self._Avatars) do
        for _, avatar in pairs(avatars) do
            avatar:Hide()
        end
    end

    local game = self._Control:GetGame()
    local map = game:GetAvatarMap()
    for column = 1, #map do
        local array = map[column]
        for row = 1, #array do
            ---@type XConnectingLineGrid
            local grid = array[row]
            if grid:GetAvatarId() > 0 then
                local avatar = self._Avatars[column] and self._Avatars[column][row]
                if not avatar then
                    ---@type UnityEngine.RectTransform
                    local uiAvatar = CS.UnityEngine.Object.Instantiate(self.GridHead, self.GridHead.gameObject.transform.parent)
                    uiAvatar.gameObject:SetActiveEx(true)
                    ---@type UnityEngine.RectTransform
                    local uiAvatarBoard = CS.UnityEngine.Object.Instantiate(self.GridBoardHead, self.GridBoardHead.gameObject.transform.parent)
                    uiAvatarBoard.gameObject:SetActiveEx(true)

                    avatar = XUiConnectingLineGameAvatar.New(uiAvatar, self)
                    avatar:SetUiGridBoardHead(uiAvatarBoard)
                    self._Avatars[column] = self._Avatars[column] or {}
                    self._Avatars[column][row] = avatar
                end

                local posUi = grid:GetPosUI()
                avatar:SetPosition(posUi.X, posUi.Y)
                avatar:Update(grid:GetAvatarIcon(), grid:GetHeadBg())
                avatar:Show()
            end
        end
    end
end

function XUiFightHackerGameV440:GetAvatar(pos)
    if self._Avatars[pos.X] then
        return self._Avatars[pos.X][pos.Y]
    end
    return false
end

---------- 背景尺寸 ----------

function XUiFightHackerGameV440:UpdateBackgroundSize()
    local game = self._Control:GetGame()
    local column = game:GetColumn()
    ---@type UnityEngine.UI.GridLayoutGroup
    local gridLayoutGroup = self.BgGridLayout
    gridLayoutGroup.constraintCount = column

    ---@type UnityEngine.RectTransform
    local rectTransform = gridLayoutGroup:GetComponent("RectTransform")
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rectTransform)
    local rect = rectTransform.rect
    local width, height = rect.width, rect.height

    local enumHorizontal = CS.UnityEngine.RectTransform.Axis.Horizontal
    local enumVertical = CS.UnityEngine.RectTransform.Axis.Vertical

    -- 统一设置面板尺寸
    local panels = { self.Panel, self.ImageBoard, self.Canvas1 }
    for _, panel in ipairs(panels) do
        panel:SetSizeWithCurrentAnchors(enumHorizontal, width)
        panel:SetSizeWithCurrentAnchors(enumVertical, height)
    end

    self.Canvas1.gameObject:SetActiveEx(true)
    self.Canvas2.gameObject:SetActiveEx(true)
    self.Canvas3.gameObject:SetActiveEx(true)

    -- 更新格子的 UI 坐标
    for i = 1, #self._GridList do
        local uiGrid = self._GridList[i]
        local pos = uiGrid:GetPos()
        local grid = game:GetGrid(pos.X, pos.Y)
        if grid then
            local x, y = uiGrid:GetPosUi()
            grid:SetPosUi(x, y)
        end
    end
end

---------- 连线渲染 ----------

function XUiFightHackerGameV440:UpdatePainting()
    local game = self._Control:GetGame()
    local bufferList = game:GetBuffer()
    local lineCountNormal = 0
    local lineCountEnable = 0

    -- 由于 grid 的 x，y 坐标以中心为锚点，line 坐标需转换
    ---@type UnityEngine.RectTransform
    local panelGrid = self.GridHead
    local gridSize = panelGrid.rect.size
    local boardHeight = self.BgGridLayout:GetComponent("RectTransform").rect.height
    local offset = { X = -gridSize.x / 2, Y = boardHeight - gridSize.y / 2 }

    -- 绘制连线
    for i = 1, #bufferList do
        local buffer = bufferList[i]
        local lineDataList = buffer:GetLine()
        local isLineEnable = buffer:IsLinked()
        for j = 1, #lineDataList do
            local line
            if isLineEnable then
                lineCountEnable = lineCountEnable + 1
                line = self:GetLine(lineCountEnable, true)
            else
                lineCountNormal = lineCountNormal + 1
                line = self:GetLine(lineCountNormal, false)
            end

            local lineData = lineDataList[j]
            local pointCount = #lineData
            line:SetPositionCount(pointCount)
            line.gameObject:SetActiveEx(true)
            line:SetColor(XUiHelper.Hexcolor2Color(buffer:GetLineColor()))
            for k = 1, pointCount do
                local point = lineData[k]
                line:SetPosition(k - 1, point.X + offset.X, point.Y + offset.Y)
            end
        end
    end

    -- 隐藏未使用的连线
    self:HideUnusedLines(self._LineNormal, lineCountNormal)
    self:HideUnusedLines(self._LineEnable, lineCountEnable)

    -- 构建已连接格子的背景映射
    local lightGridBgMap = {}
    for i = 1, #bufferList do
        ---@type XConnectingLineGridBuffer
        local buffer = bufferList[i]
        if buffer:IsLinked() then
            local grids = buffer:GetGrids()
            local headGridBg = buffer:GetHeadGrid():GetGridBg()
            for j = 1, #grids do
                lightGridBgMap[grids[j]:GetPosUid()] = headGridBg
            end
        else
            local headGrid = buffer:GetHeadGrid()
            if headGrid then
                lightGridBgMap[headGrid:GetPosUid()] = headGrid:GetGridBg()
            end
        end
    end

    -- 应用连接状态到格子和头像
    for i = 1, #self._GridList do
        local uiGrid = self._GridList[i]
        local gridBg = lightGridBgMap[uiGrid:GetPosUid()]
        local connected = gridBg ~= nil
        uiGrid:SetConnected(connected)
        if gridBg then
            uiGrid:SetGridBg(gridBg)
        end
        local avatar = self:GetAvatar(uiGrid:GetPos())
        if avatar then
            avatar:SetConnected(connected)
        end
    end
end

--- 隐藏未使用的连线
function XUiFightHackerGameV440:HideUnusedLines(linePool, usedCount)
    for i = usedCount + 1, #linePool do
        if linePool[i] then
            linePool[i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiFightHackerGameV440:GetLine(index, isEnable)
    local pool = isEnable and self._LineEnable or self._LineNormal
    local line = pool[index]
    if not line then
        local uiLine = isEnable and self.LineEnable or self.LineNormal
        line = CS.UnityEngine.GameObject.Instantiate(uiLine, uiLine.gameObject.transform.parent)
        pool[index] = line
        line:SetPositionCount(0)
        line.gameObject:SetActiveEx(true)
    end
    return line
end

---------- 输入处理 ----------

function XUiFightHackerGameV440:AddListenerInput()
    ---@type XGoInputHandler
    local goInputHandler = self.PanelDrag
    goInputHandler:AddPointerDownListener(function(...)
        self:OnBeginDrag(...)
    end)
    goInputHandler:AddDragListener(function(...)
        self:OnDrag(...)
    end)
    goInputHandler:AddPointerUpListener(function(...)
        self:OnEndDrag(...)
    end)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiFightHackerGameV440:GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.PanelDrag.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
        transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end
    return point.x + transform.rect.width / 2, point.y - transform.rect.height / 2
end

--- 执行操作并更新画面
function XUiFightHackerGameV440:ExecuteOperation(eventData, operationType)
    local game = self._Control:GetGame()
    local operation = XConnectingLineOperation.New()
    local x, y = self:GetPosByEventData(eventData)
    operation:SetPos(x, y)
    operation.Type = operationType
    game:Execute(operation)
    self:UpdatePainting()
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiFightHackerGameV440:OnBeginDrag(eventData)
    self:ExecuteOperation(eventData, OPERATION_TYPE.POINT_DOWN)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiFightHackerGameV440:OnDrag(eventData)
    self:ExecuteOperation(eventData, OPERATION_TYPE.POINT_MOVE)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiFightHackerGameV440:OnEndDrag(eventData)
    self:ExecuteOperation(eventData, OPERATION_TYPE.POINT_UP)
    self:CheckFinish()
    self:UpdateGameInfo()
    self:ResetAnimation()
end

---------- 游戏状态 ----------

function XUiFightHackerGameV440:UpdateGameInfo()
    ---@type XConnectingLineGame
    local game = self._Control:GetGame()
    local uiData = self._Control:GetUiData()

    -- 独立关卡只依赖当前局内状态，不依赖活动进度
    if game and uiData then
        local finishState = game:GetFinishState()
        local isFinish = finishState == XEnumConst.CONNECTING_LINE.FINISH_STATE.PERFECT_COMPLETE

        local avatarCount = game:GetAvatarAmount()
        local linkedAmount
        if isFinish then
            linkedAmount = avatarCount
        else
            linkedAmount = game:GetLinkedAmount()
        end

        uiData.IsEnableReset = linkedAmount > 0 and not isFinish
    end

    ---@type XUiComponent.XUiButton
    local buttonReset = self.ButtonReset
    if buttonReset then
        if uiData and uiData.IsEnableReset then
            buttonReset:SetButtonState(CS.UiButtonState.Normal)
        else
            buttonReset:SetButtonState(CS.UiButtonState.Disable)
        end
    end
end

function XUiFightHackerGameV440:CheckFinish()
    local game = self._Control:GetGame()
    if game:GetFinishState() == XEnumConst.CONNECTING_LINE.FINISH_STATE.PERFECT_COMPLETE then
        self:ClearBoard()
        self.PanelGame.gameObject:SetActiveEx(false)
        self.PanelBtn.gameObject:SetActiveEx(true)
    end
end

function XUiFightHackerGameV440:OnResetStage()
    self:StartGame()
end

function XUiFightHackerGameV440:OnClickReset()
    ---@type XUiComponent.XUiButton
    local button = self.ButtonReset
    if button.ButtonState == CS.UiButtonState.Normal then
        XUiManager.DialogTip(
            XUiHelper.GetText("ConnectingLineReset1"),
            XUiHelper.GetText("ConnectingLineReset2"),
            nil, nil,
            function()
                XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_RESET_STAGE)
            end)
    end
end

function XUiFightHackerGameV440:ResetAnimation()
    for i = 1, #self._GridList do
        self._GridList[i]:ResetAnimation()
    end
end

function XUiFightHackerGameV440:ClearBoard()
    self._Control:GetGame():ClearBoard()
end

function XUiFightHackerGameV440:OnClickComplete()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyUp)
    end
    self:Close()
end

function XUiFightHackerGameV440:SetButtonParams(buttonIcon, buttonScaleX, buttonScaleY)
    if self.ButtonComplete then
        if buttonIcon then
            local rawImage = XUiHelper.TryGetComponent(self.ButtonComplete.transform, "", "RawImage")
            rawImage:SetImage(buttonIcon)
        end
    end

    if self.PanelToScale then
        if buttonScaleX and buttonScaleY then
            local scale = CS.UnityEngine.Vector3.one
            scale.x = buttonScaleX or 1
            scale.y = buttonScaleY or 1
            self.PanelToScale.transform.localScale = scale
        end
    end
end

function XUiFightHackerGameV440:Close()
    local startSuccess = false
    -- 战斗UI关闭时不会等待AnimDisable播放完，手动等待
    self:PlayAnimationWithMask("AnimDisable", function()
        XLuaUi.Close(self)
    end, function()
        startSuccess = true
    end)

    if not startSuccess then
        XLuaUi.Close(self)
    end
end

return XUiFightHackerGameV440
