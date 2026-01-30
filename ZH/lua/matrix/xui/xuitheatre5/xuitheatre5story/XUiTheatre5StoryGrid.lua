---@class XUiTheatre5StoryGrid : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5StoryGrid = XClass(XUiNode, "XUiTheatre5StoryGrid")

function XUiTheatre5StoryGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.StoryBtn, self.OnClick)
    self.GridLock = self.GridLock or XUiHelper.TryGetComponent(self.Transform, "GridStory/GridLock", "RectTransform")
    ---@type UnityEngine.UI.RawImage
    local rawImage = self.GridLock:GetComponent("RawImage")
    if rawImage then
        rawImage.raycastTarget = false
    end
end

---@param config XTableTheatre5Story
function XUiTheatre5StoryGrid:Update(config)
    self._Config = config
    self.StoryTitle.text = config.StoryTitle
    self.RImg:SetRawImage(config.StoryIcon)

    if XConditionManager.CheckCondition(config.Condition) then
        self.GridLock.gameObject:SetActiveEx(false)
    else
        self.GridLock.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre5StoryGrid:OnClick()
    if not XConditionManager.CheckCondition(self._Config.Condition) then
        local desc = XConditionManager.GetConditionDescById(self._Config.Condition)
        XUiManager.TipMsg(desc)
        return
    end
    XLuaUiManager.Open("UiTheatre5PopupHandBook", self._Config)
end

return XUiTheatre5StoryGrid