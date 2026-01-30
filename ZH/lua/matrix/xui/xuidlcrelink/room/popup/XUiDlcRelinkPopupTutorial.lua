local XUiGridDlcRelinkPopupTutorial = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkPopupTutorial")

---@class XUiDlcRelinkPopupTutorial : XLuaUi 机制教学弹框
---@field _Control XDlcRelinkControl
local XUiDlcRelinkPopupTutorial = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupTutorial")

function XUiDlcRelinkPopupTutorial:OnAwake()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
end

function XUiDlcRelinkPopupTutorial:OnStart(id)
    self._Config = self._Control:GetMechanismTeachById(id)
    self._Wiki = self._Control:GetWikiConfigById(self._Config.MechanismId)
    self._Dots = {}

    self._TotalPage = #self._Wiki.Desc
    local isMulti = self._TotalPage > 1
    self.GridContent.gameObject:SetActiveEx(not isMulti)
    self.PanelTutorial.gameObject:SetActiveEx(isMulti)
    self.Tab.gameObject:SetActiveEx(isMulti)
    self.BtnLeft.gameObject:SetActiveEx(isMulti)
    self.BtnRight.gameObject:SetActiveEx(isMulti)
    self.PanelTutorial.gameObject:SetActiveEx(isMulti)

    if isMulti then
        ---@type XDynamicTableCurve
        self.DynamicTable = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve").New(self.PanelTutorial)
        self.DynamicTable:SetProxy(XUiGridDlcRelinkPopupTutorial, self)
        self.DynamicTable:SetDelegate(self)
        local datas = {}
        for i = 1, self._TotalPage do
            local dot = i == 1 and self.TabGrid or XUiHelper.Instantiate(self.TabGrid, self.Tab)
            local uiObj = {}
            XUiHelper.InitUiClass(uiObj, dot)
            self._Dots[i] = uiObj
            table.insert(datas, i)
        end
        self.DynamicTable:SetDataSource(datas)
        self.DynamicTable:ReloadData(0)
        self:UpdateSelect(1)
    else
        ---@type XUiGridDlcRelinkPopupTutorial
        local grid = XUiGridDlcRelinkPopupTutorial.New(self.GridContent, self)
        grid:SetData(self._Wiki.VideoConfigIds[1], self._Wiki.ImageUrl[1], self._Wiki.Desc[1])
    end
    self.TxtTitle.text = self._Config.Name
    self._Control:SetMechanismTeachHasBeenViewed(id)
end

---@param grid XUiGridDlcRelinkPopupTutorial
function XUiDlcRelinkPopupTutorial:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index % self.DynamicTable.Imp.TotalCount + 1
        grid:SetData(self._Wiki.VideoConfigIds[index], self._Wiki.ImageUrl[index], self._Wiki.Desc[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount + 1
        self._SelectIndex = selectIndex
        self:UpdateSelect(selectIndex)
    end
end

function XUiDlcRelinkPopupTutorial:UpdateSelect(startIndex)
    self._CurPage = startIndex
    local index = self.DynamicTable.Imp.StartIndex
    for i, grid in ipairs(self._Dots) do
        grid.Off.gameObject:SetActiveEx(i ~= startIndex)
        grid.On.gameObject:SetActiveEx(i == startIndex)
    end
end

function XUiDlcRelinkPopupTutorial:OnBtnLeftClick()
    if self._CurPage <= 1 then
        self._CurPage = self._TotalPage
    else
        self._CurPage = self._CurPage - 1
    end
    self.DynamicTable.Imp:TweenToIndex(self._CurPage - 1)
end

function XUiDlcRelinkPopupTutorial:OnBtnRightClick()
    if self._CurPage >= self._TotalPage then
        self._CurPage = 1
    else
        self._CurPage = self._CurPage + 1
    end
    self.DynamicTable.Imp:TweenToIndex(self._CurPage - 1)
end

return XUiDlcRelinkPopupTutorial