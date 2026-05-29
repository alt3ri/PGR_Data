local XUiGridTheatre6Difficulty = require("XUi/XUiTheatre6/Stage/Grid/XUiGridTheatre6Difficulty")

---@class XUiTheatre6ChooseDifficulty : XLuaUi 玩法模式选择难度
---@field _Control XTheatre6Control
---@field _DynamicTable XDynamicTableCurve
local XUiTheatre6ChooseDifficulty = XLuaUiManager.Register(XLuaUi, "UiTheatre6ChooseDifficulty")

function XUiTheatre6ChooseDifficulty:OnAwake()
    self:InitComponents()
    self.GridDifficultyDeatil.gameObject:SetActiveEx(false)
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
end

function XUiTheatre6ChooseDifficulty:InitComponents()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self._DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve").New(self.ListDifficulty)
    self._DynamicTable:SetProxy(XUiGridTheatre6Difficulty, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiTheatre6ChooseDifficulty:OnStart(params)
    local groupCfg = self._Control:GetDifficultyGroupConfig(params.GroupId)
    self._DifficultyIds = groupCfg.DifficultyIds
    self._RoleId = params.RoleId
    self._FashionId = params.FashionId
    self._InitBuffId = params.InitBuffId
    self._InitIndex = self._Control:GetDifficultyChooseIndex(self._RoleId) or 0

    self._DynamicTable:SetDataSource(self._DifficultyIds)
    self._DynamicTable:ReloadData()
    self._DynamicTable:TweenToIndex(self._InitIndex)
    self._DifficultyId = self._DifficultyIds[1]

    self._Dots = {}
    XUiHelper.RefreshCustomizedList(self.Dot.parent, self.Dot, #self._DifficultyIds, function(index, go)
        local uiObj = {}
        XUiHelper.InitUiClass(uiObj, go)
        self._Dots[index] = uiObj
    end)
    self:UpdateFashionSelect(self._InitIndex + 1)
end

function XUiTheatre6ChooseDifficulty:OnDestroy()

end

function XUiTheatre6ChooseDifficulty:OnBtnStartClick()
    local config = self._Control:GetDifficultyConfig(self._DifficultyId)

    if XTool.IsNumberValid(config.ConditionId) then
        local ret, desc = XConditionManager.CheckCondition(config.ConditionId)
        if not ret then
            self._Control:ShowTip(desc)
            return
        end
    end
    
    self._Control:RequestPlayModeStartFight(self._RoleId, self._FashionId, self._InitBuffId, self._DifficultyId, function()
        XLuaUiManager.SafeClose("UiTheatre6ChooseCharacter")
        self._Control:SaveDifficultyChooseIndex(self._RoleId, table.indexof(self._DifficultyIds, self._DifficultyId) - 1)
        self:Close()
    end)
end

---@param grid XUiGridTheatre6Difficulty
function XUiTheatre6ChooseDifficulty:OnDynamicTableEvent(event, index, grid)
    ---@type XUiGridTheatre6Difficulty[]
    local grids = self._DynamicTable:GetGrids()
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index % self._DynamicTable.Imp.TotalCount + 1
        grid:Refresh(self._DifficultyIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_END_DRAG then
        local startIndex = self._DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self._DynamicTable.Imp.TotalCount + 1
        self._DifficultyId = self._DifficultyIds[selectIndex]
        self:UpdateFashionSelect(selectIndex)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._DynamicTable.Imp:TweenToIndex(index)
    end
end

function XUiTheatre6ChooseDifficulty:UpdateFashionSelect(startIndex)
    for i, grid in ipairs(self._Dots) do
        grid.ImgDotNormal.gameObject:SetActiveEx(i ~= startIndex)
        grid.ImgDotSelect.gameObject:SetActiveEx(i == startIndex)
    end
end

return XUiTheatre6ChooseDifficulty