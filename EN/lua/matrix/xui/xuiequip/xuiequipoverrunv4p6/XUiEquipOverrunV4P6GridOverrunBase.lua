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

-- ImgDian 使用配置的节点空间点位；MASK/XUiLine01 使用连线局部点位
function XUiEquipOverrunV4P6GridOverrunBase:RefreshLine(overrunCfg)
    local positions = self:GetLinePositions(overrunCfg)
    local lastPosition = positions[#positions]

    local stateNodes = { self.Normal, self.Press, self.Disable }
    for _, node in ipairs(stateNodes) do
        local imgDian = node:GetObject("ImgDian")
        if imgDian and lastPosition then
            imgDian.transform.anchoredPosition = lastPosition
        end

        self:_RefreshLineRenderer(node, positions)
    end
end

function XUiEquipOverrunV4P6GridOverrunBase:GetLinePositions(overrunCfg)
    local layoutKey = self.Parent:GetUiLayoutKey()
    local linePointStr = overrunCfg.UiLinePointList and overrunCfg.UiLinePointList[layoutKey]
    local positions = {}

    if not linePointStr or linePointStr == "" then
        return positions
    end

    linePointStr = string.gsub(linePointStr, "\"", "")
    for pointStr in string.gmatch(linePointStr, "[^|]+") do
        local x, y = string.match(pointStr, "^%s*([^,]+)%s*,%s*([^,]+)%s*$")
        x = tonumber(x)
        y = tonumber(y)
        if x and y then
            positions[#positions + 1] = Vector2(x, y)
        end
    end

    return positions
end

function XUiEquipOverrunV4P6GridOverrunBase:SetLineVisible(isVisible)
    if isVisible then
        self:RefreshLine(self:GetOverrunConfig())
        return
    end

    local stateNodes = { self.Normal, self.Press, self.Disable }
    for _, node in ipairs(stateNodes) do
        local maskTrans = node and node.transform:Find("MASK")
        if not XTool.UObjIsNil(maskTrans) then
            maskTrans.gameObject:SetActiveEx(false)
        end
    end
end

function XUiEquipOverrunV4P6GridOverrunBase:_RefreshLineRenderer(node, positions)
    local maskTrans = node.transform:Find("MASK")
    local needDrawLine = #positions >= 2
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
