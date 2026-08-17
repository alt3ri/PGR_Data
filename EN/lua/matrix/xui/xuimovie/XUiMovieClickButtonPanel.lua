local GameObject = CS.UnityEngine.GameObject

local MAX_BUTTON_COUNT = 4
local PRESS_BRIGHTNESS = 0.75
local NORMAL_BRIGHTNESS = 1
local ALPHA_HIT_TEST_THRESHOLD = 0.1

---@class XUiMovieClickButtonPanel
---@field RootUi XUiMovie
local XUiMovieClickButtonPanel = XClass(nil, "XUiMovieClickButtonPanel")

function XUiMovieClickButtonPanel:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Buttons = {}
    self.ActiveCount = 0
    self.SelectedActionId = 0
    self.IsClicked = false

    self.GameObject:SetActiveEx(false)
end

function XUiMovieClickButtonPanel:AddButton(buttonId, imagePath, x, y, targetActionId, clickCb)
    if string.IsNilOrEmpty(imagePath) then
        XLog.Error("XUiMovieClickButtonPanel:AddButton error: imagePath is empty, buttonId is " .. tostring(buttonId))
        return
    end

    if self.ActiveCount == 0 then
        self:ResetSelected()
    end

    local button = self.Buttons[buttonId]
    if not button then
        if self.ActiveCount >= MAX_BUTTON_COUNT then
            XLog.Error("XUiMovieClickButtonPanel:AddButton error: button count exceeds " .. MAX_BUTTON_COUNT)
            return
        end
        button = self:CreateButton(buttonId)
        self.Buttons[buttonId] = button
    elseif not button.Active then
        self.ActiveCount = self.ActiveCount + 1
    end

    button.TargetActionId = targetActionId
    button.ClickCb = clickCb
    button.Active = true

    button.Transform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
    button.Transform.localScale = CS.UnityEngine.Vector3.one
    button.Transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    self:SetButtonBrightness(button, NORMAL_BRIGHTNESS)

    button.GameObject:SetActiveEx(true)
    button.Transform:SetAsLastSibling()
    self.GameObject:SetActiveEx(true)

    button.Image:SetSprite(imagePath, function()
        if not XTool.UObjIsNil(button.Image) then
            button.Image:SetNativeSize()
        end
    end)
end

function XUiMovieClickButtonPanel:CreateButton(buttonId)
    local go = GameObject("MovieClickButton" .. tostring(buttonId), typeof(CS.UnityEngine.RectTransform))
    go.transform:SetParent(self.Transform, false)

    local image = go:AddComponent(typeof(CS.UnityEngine.UI.Image))
    image.raycastTarget = true
    image.alphaHitTestMinimumThreshold = ALPHA_HIT_TEST_THRESHOLD

    local inputHandler = go:AddComponent(typeof(CS.XGoInputHandler))
    local button = {
        GameObject = go,
        Transform = go.transform,
        Image = image,
        InputHandler = inputHandler,
        Active = true,
    }
    self.ActiveCount = self.ActiveCount + 1

    inputHandler:AddPointerDownListener(function()
        self:SetButtonBrightness(button, PRESS_BRIGHTNESS)
    end)
    inputHandler:AddPointerUpListener(function()
        self:SetButtonBrightness(button, NORMAL_BRIGHTNESS)
    end)
    inputHandler:AddPointerClickListener(function()
        self:OnClickButton(button)
    end)

    return button
end

function XUiMovieClickButtonPanel:OnClickButton(button)
    if self.IsClicked or not button.Active then
        return
    end

    self.IsClicked = true
    local clickCb = button.ClickCb
    self.SelectedActionId = button.TargetActionId or 0
    self:SetButtonBrightness(button, PRESS_BRIGHTNESS)
    self:HideButtons(true)

    if clickCb then
        clickCb()
    end
end

function XUiMovieClickButtonPanel:GetSelectedActionId()
    return self.SelectedActionId or 0
end

function XUiMovieClickButtonPanel:IsShowing()
    return self.ActiveCount > 0
end

function XUiMovieClickButtonPanel:Clear()
    self:HideButtons(false)
    self:ResetSelected()
end

function XUiMovieClickButtonPanel:HideButtons(keepSelected)
    for _, button in pairs(self.Buttons) do
        button.Active = false
        button.ClickCb = nil
        button.TargetActionId = 0
        if not XTool.UObjIsNil(button.GameObject) then
            button.GameObject:SetActiveEx(false)
        end
    end

    self.ActiveCount = 0
    self.GameObject:SetActiveEx(false)
    if not keepSelected then
        self:ResetSelected()
    end
end

function XUiMovieClickButtonPanel:ResetSelected()
    self.SelectedActionId = 0
    self.IsClicked = false
end

function XUiMovieClickButtonPanel:SetButtonBrightness(button, brightness)
    if XTool.UObjIsNil(button.Image) then
        return
    end

    local color = button.Image.color
    color.r = brightness
    color.g = brightness
    color.b = brightness
    color.a = 1
    button.Image.color = color
end

function XUiMovieClickButtonPanel:OnDestroy()
    self:Clear()
    self.Buttons = {}
end

return XUiMovieClickButtonPanel
