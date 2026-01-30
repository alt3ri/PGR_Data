local XUiLineArithmetic2MainStarGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2MainStarGrid")

---@class XUiLineArithmetic2MainStageGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2MainStageGrid = XClass(XUiNode, "XUiLineArithmetic2MainStageGrid")

function XUiLineArithmetic2MainStageGrid:OnStart()
    ---@type XUiLineArithmetic2MainStarGrid[]
    self._GridStar = {}
    self._Data = false
    self.GridStar.gameObject:SetActiveEx(false)
    local buttonComponent = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, buttonComponent, self.OnClick)
    --XUiHelper.RegisterClickEvent(self, self.BtnAbandon, self.OnClickAbandon)

    for i = 1, 4 do
        local ui = self["GridStar" .. i]
        if ui then
            local grid = XUiLineArithmetic2MainStarGrid.New(ui, self)
            self._GridStar[i] = grid
        end
    end

    self.RawImage = self.RawImage or XUiHelper.TryGetComponent(self.Transform, "Root/RawImage", "RawImage")
end

---@param data XLineArithmetic2ControlStageData
function XUiLineArithmetic2MainStageGrid:Update(data)
    self._Data = data
    for i = 1, data.MaxStarAmount do
        local grid = self._GridStar[i]
        if not grid then
            local ui = self["GridStar" .. i]
            if ui then
                grid = XUiLineArithmetic2MainStarGrid.New(ui, self)
                self._GridStar[i] = grid
            end
        end
        if grid then
            grid:Open()
            grid:Update(i <= data.StarAmount)
        end
    end
    for i = data.MaxStarAmount + 1, #self._GridStar do
        local grid = self._GridStar[i]
        if grid then
            grid:Close()
        end
    end
    self.TxtTitle.text = data.Name
    --self.ImgBg
    self.PanelLock.gameObject:SetActiveEx(data.IsLock)
    --self.PanelOngoing.gameObject:SetActiveEx(data.IsRunning)
    self.ImgClear.gameObject:SetActiveEx(data.StarAmount == data.MaxStarAmount)
    self.RawImage:SetRawImage(data.Icon)
end

function XUiLineArithmetic2MainStageGrid:OnClick()
    if self._Data.IsLock then
        XUiManager.TipText("LineArithmeticStageLock")
        --XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("LineArithmeticGoOnStage"))
        return
    end
    self._Control:OpenStageUi(self._Data.StageId)
end

--function XUiLineArithmetic2MainStageGrid:OnClickAbandon()
--    self._Control:AbandonCurrentGameData()
--end

return XUiLineArithmetic2MainStageGrid