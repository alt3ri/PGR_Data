---@class XUiLineArithmetic2MainChapterGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2MainChapterGrid = XClass(XUiNode, "XUiLineArithmetic2MainChapterGrid")

function XUiLineArithmetic2MainChapterGrid:OnStart()
    ---@type XLineArithmetic2ControlChapterData
    self._Data = false
    local buttonComponent = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, buttonComponent, self.OnClick)
end

---@param data XLineArithmetic2ControlChapterData
function XUiLineArithmetic2MainChapterGrid:Update(data)
    self._Data = data
    --self.PanelOngoing.gameObject:SetActiveEx(data.isRunning)
    --self.TxtNew.gameObject:SetActiveEx(data.IsNew)
    --self.PanelLock.gameObject:SetActiveEx(not data.IsOpen)
    --self.TxtStar.text = data.TxtStar
    self.Button:SetNameByGroup(0, data.TxtStar)
    self.Button:SetNameByGroup(1, data.Name)
    self.Button:ShowReddot(data.IsNew)
    if data.IsOpen then
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    else
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end
    local uiText = self.Text1 or self.Text2 or self.Text3 or self.Text4
    -- 美术提交了非text，兼容错误
    if uiText and uiText.text then
        uiText.text = data.TxtLock
    end
end

function XUiLineArithmetic2MainChapterGrid:OnClick()
    self._Control:OnClickChapter(self._Data)
end

return XUiLineArithmetic2MainChapterGrid