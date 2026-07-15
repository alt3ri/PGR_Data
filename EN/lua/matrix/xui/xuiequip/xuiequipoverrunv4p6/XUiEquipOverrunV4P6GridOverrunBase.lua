local UNSELECTED_ALPHA = 0.8
local Vector2 = CS.UnityEngine.Vector2
local XUiLineRendererSimpleType = typeof(CS.XUiComponent.XUiLineRendererSimple)
local MAX_LINE_POINT_COUNT = 10

---@class XUiEquipOverrunV4P6GridOverrunBase : XUiNode
---@field _Control XEquipControl
---@field Parent XUiEquipOverrunV4P6
---@field BtnlLevel CS.XUiButton
---@field CanvasGroup UnityEngine.CanvasGroup
---@field Normal UiObject
---@field Press UiObject
---@field TagSelect UiObject
---@field Disable UiObject
local XUiEquipOverrunV4P6GridOverrunBase = XClass(XUiNode, "UiEquipOverrunV4P6GridOverrunBase")

function XUiEquipOverrunV4P6GridOverrunBase:RefreshName(overrunCfg)
    self.BtnlLevel:SetNameByGroup(0, overrunCfg.Name)
end

function XUiEquipOverrunV4P6GridOverrunBase:RefreshSelectState()
    local overrunCfg = self:GetOverrunConfig()
    local isActive = self:IsOverrunActive(overrunCfg)
    local selectIndex = self.Parent:GetSelectIndex()
    local isSelect = selectIndex == self.Index
    local state = isActive and CS.UiButtonState.Normal or CS.UiButtonState.Disable
    self.BtnlLevel:SetButtonState(state)
    self.BtnlLevel.TempState = state
    self.TagSelect.gameObject:SetActiveEx(isSelect)
    self.CanvasGroup.alpha = (selectIndex ~= nil and not isSelect) and UNSELECTED_ALPHA or 1
end

function XUiEquipOverrunV4P6GridOverrunBase:RefreshNextTag(overrunCfg)
    local lv = self.Parent.Equip:GetOverrunLevel()
    self.BtnlLevel:ShowTag(lv + 1 == overrunCfg.Level)
end

function XUiEquipOverrunV4P6GridOverrunBase:IsOverrunActive(overrunCfg)
    local lv = self.Parent.Equip:GetOverrunLevel()
    return lv >= overrunCfg.Level
end

function XUiEquipOverrunV4P6GridOverrunBase:RefreshActiveBg(overrunCfg)
    local isActive = self:IsOverrunActive(overrunCfg)
    self.ImgBgLevelOn.gameObject:SetActiveEx(isActive)
    self.ImgBgLevelOff.gameObject:SetActiveEx(not isActive)
end

-- ImgDian uses the configured node-space point. MASK/XUiLine01 uses line-local points.
function XUiEquipOverrunV4P6GridOverrunBase:RefreshLine(overrunCfg)
    local isDetail = self.Parent:GetIsShowPanelDetail()
    local xList = isDetail and overrunCfg.LinePosXDetailList or overrunCfg.LinePosXList
    local yList = isDetail and overrunCfg.LinePosYDetailList or overrunCfg.LinePosYList

    local positions = {}
    if xList and yList then
        for i = 1, #xList do
            positions[i] = Vector2(xList[i], yList[i])
        end
    end

    local stateNodes = { self.Normal, self.Press, self.Disable }
    for _, node in ipairs(stateNodes) do
        local imgDian = node:GetObject("ImgDian")
        if imgDian and positions[1] then
            imgDian.transform.anchoredPosition = positions[1]
        end

        self:_RefreshLineRenderer(node, positions)
    end
end

function XUiEquipOverrunV4P6GridOverrunBase:_RefreshLineRenderer(node, positions)
    local line1Trans = node.transform:Find("ImgLine1")
    if line1Trans then
        line1Trans.gameObject:SetActiveEx(false)
    end

    local line2Trans = node.transform:Find("ImgLine2")
    if line2Trans then
        line2Trans.gameObject:SetActiveEx(false)
    end

    local maskTrans = node.transform:Find("MASK")
    local needDrawLine = #positions > 2
    maskTrans.gameObject:SetActiveEx(needDrawLine)
    if not needDrawLine then
        return
    end

    local lineTrans = maskTrans:Find("XUiLine01")
    local lineRenderer = lineTrans:GetComponent(XUiLineRendererSimpleType)
    if XTool.UObjIsNil(lineRenderer) then
        return
    end

    self:_SetLineRendererPoints(lineRenderer, positions, maskTrans.anchoredPosition, lineTrans.anchoredPosition)
end

function XUiEquipOverrunV4P6GridOverrunBase:_SetLineRendererPoints(lineRenderer, positions, maskPosition, linePosition)
    local count = math.min(#positions, MAX_LINE_POINT_COUNT)
    lineRenderer:SetActivePointCount(count)
    lineRenderer:SetPositionCount(count)

    for i = 1, count do
        local point = positions[i] - maskPosition - linePosition
        lineRenderer:SetPoint(i - 1, point.x, point.y)
        lineRenderer:SetPosition(i - 1, point.x, point.y)
    end
end

function XUiEquipOverrunV4P6GridOverrunBase:GetOverrunConfig()
    return self._Control:GetWeaponOverrunConfigById(self.OverrunCfgId)
end

return XUiEquipOverrunV4P6GridOverrunBase
