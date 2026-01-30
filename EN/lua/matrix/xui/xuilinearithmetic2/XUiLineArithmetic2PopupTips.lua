local XUiLineArithmetic2GameGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2GameGrid")
local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XUiLineArithmetic2PopupTips : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2PopupTips = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2PopupTips")

function XUiLineArithmetic2PopupTips:OnAwake()
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    self._Timer = false
    
    ---@type XUiLineArithmetic2GameGrid[]
    self._UiGrids = {}

    ---@type XUiLineArithmetic2GameGrid[]
    self._UiGridPool = {}

    ---@type XUiLineArithmetic2GameGrid[]
    self._UiGrids = {}

    self._UiLines = {}

    self.AllGrid.gameObject:SetActiveEx(false)
    --self.BtnGrid.gameObject:SetActiveEx(false)
    --self.GridLine.gameObject:SetActiveEx(false)
    
    self.PanelLine.gameObject:SetActiveEx(true)
    self.GridLine.gameObject:SetActiveEx(false)
end

function XUiLineArithmetic2PopupTips:OnStart()
    self:UpdateEmptyGrid()
end

function XUiLineArithmetic2PopupTips:OnEnable()
    self.TxtSpeak.text = XUiHelper.GetText("LineArithmeticHelpText")
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0)
    end
    ---@type UnityEngine.UI.GridLayoutGroup
    local gridLayoutGroup = self.AllGrid:GetComponent(typeof(CS.UnityEngine.UI.LayoutGroup))
    local cellSize = gridLayoutGroup.cellSize
    self._Control:SetGridSize(cellSize.x, cellSize.y)
    self._Control:StartHelpGame()
    self:UpdateMap()
end

function XUiLineArithmetic2PopupTips:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiLineArithmetic2PopupTips:Update()
    if self._Control:UpdateHelpGame() then
        self:UpdateMap()
    end
end

function XUiLineArithmetic2PopupTips:UpdateMap()
    self._Control:UpdateHelpMap()
    local uiData = self._Control:GetUiData()

    -- 画格子
    local map = uiData.HelpMapData
    if not map then
        return
    end
    local usedGrid = {}
    for i = 1, #map do
        local dataGrid = map[i]
        if dataGrid then
            local uid = dataGrid.Uid
            local uiGrid = self._UiGrids[uid]

            -- 如果已经有uiGrid, 但是和之前的类型不同, 回收它, 重新创建
            if uiGrid then
                if uiGrid:GetType() ~= dataGrid.Type
                        or uiGrid:GetColor() ~= dataGrid.Color
                then
                    self._UiGrids[uid] = nil
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
                        self._UiGrids[uid] = uiGridFromPool
                        uiGrid = uiGridFromPool
                        break
                    end
                end

                -- 池里没有, new一个
                if not uiGrid then
                    local toInstantiate = self:GetUiGrid(dataGrid)
                    if toInstantiate then
                        ---@type UnityEngine.UI.GridLayoutGroup
                        local gridLayoutGroup = self.AllGrid:GetComponent(typeof(CS.UnityEngine.UI.LayoutGroup))

                        ---@type UnityEngine.RectTransform
                        local instance = CS.UnityEngine.Object.Instantiate(toInstantiate, self.PanelGrid)
                        -- 设置宽高
                        instance.sizeDelta = gridLayoutGroup.cellSize
                        uiGrid = XUiLineArithmetic2GameGrid.New(instance, self, dataGrid.Type, dataGrid.Color)
                    end
                    self._UiGrids[uid] = uiGrid
                end
            end

            if uiGrid then
                uiGrid:Open()
                uiGrid:Update(dataGrid)
                usedGrid[uid] = true
            end
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
end

function XUiLineArithmetic2PopupTips:UpdateLine()
    self._Control:UpdateHelpLine()
    local uiData = self._Control:GetUiData()

    -- 画线
    local line = uiData.HelpLineData
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

function XUiLineArithmetic2PopupTips:UpdateEmptyGrid()
    self._Control:UpdateEmptyData()
    local emptyData = self._Control:GetUiData().MapEmptyData
    XUiHelper.RefreshCustomizedList(self.PanelEmpty.transform, self.GridEmpty, #emptyData, function(index, grid)
        local data = emptyData[index]
        grid.transform.localPosition = Vector3(data.X, data.Y, 0)
    end)
end

---@param grid XLineArithmetic2ControlMapData
function XUiLineArithmetic2PopupTips:GetUiGrid(grid)
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

return XUiLineArithmetic2PopupTips