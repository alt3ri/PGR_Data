---@class XUiButtonLua
local XUiButton = XClass(nil, "XUiButton")

function XUiButton:Ctor(xButton)
    self._Button = xButton
    self._List = {
        (not XTool.UObjIsNil(xButton.NormalObj)) and xButton.NormalObj or nil,
        (not XTool.UObjIsNil(xButton.PressObj)) and xButton.PressObj or nil,
        (not XTool.UObjIsNil(xButton.PressCloseObj)) and xButton.PressCloseObj or nil,
        (not XTool.UObjIsNil(xButton.SelectObj)) and xButton.SelectObj or nil,
        (not XTool.UObjIsNil(xButton.SelectCloseObj)) and xButton.SelectCloseObj or nil,
        (not XTool.UObjIsNil(xButton.DisableObj)) and xButton.DisableObj or nil,
        (not XTool.UObjIsNil(xButton.TagObj)) and xButton.TagObj or nil,
        (not XTool.UObjIsNil(xButton.ReddotObj)) and xButton.ReddotObj or nil,
    }
end

function XUiButton:SetText(uiName, value)
    for i, gameObject in pairs(self._List) do
        local ui = XUiHelper.TryGetComponent(gameObject.transform, uiName, "Text")
        if ui then
            ui.text = value
        end
    end
end

---设置按钮下指定名称的 Text 组件的颜色
---@param uiName string 子节点名称（如 TxtNoFree）
---@param color UnityEngine.Color 目标颜色
function XUiButton:SetTextColor(uiName, color)
    if not color then
        return
    end
    for i, gameObject in pairs(self._List) do
        local ui = XUiHelper.TryGetComponent(gameObject.transform, uiName, "Text")
        if ui and ui.color then
            ui.color = color
        end
    end
end

function XUiButton:SetRawImage(uiName, value)
    for i, gameObject in pairs(self._List) do
        local ui = XUiHelper.TryGetComponent(gameObject.transform, uiName, "RawImage")
        if ui then
            ui:SetRawImage(value)
        end
    end
end

function XUiButton:SetActive(uiName, value)
    for i, gameObject in pairs(self._List) do
        local ui = XUiHelper.TryGetComponent(gameObject.transform, uiName, "Transform")
        if ui then
            ui.gameObject:SetActiveEx(value)
        end
    end
end

function XUiButton:SetFillAmount(uiName, value)
    for i, gameObject in pairs(self._List) do
        local ui = XUiHelper.TryGetComponent(gameObject.transform, uiName, "Image")
        if ui then
            ui.fillAmount = value
        end
    end
end

function XUiButton:GetUiButton()
    return self._Button
end

function XUiButton:ShowReddot(value)
    self._Button:ShowReddot(value)
end

function XUiButton:SetName(value)
    self._Button:SetName(value)
end

function XUiButton:SetButtonState(state)
    if state == XUiButtonState.Disable then
        self._Button:SetDisable(true)
    else
        self._Button:SetDisable(false)
    end
    self._Button:SetButtonState(state)
end

return XUiButton