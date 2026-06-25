local UNSELECTED_ALPHA = 0.8  -- 有谐振等级被选中时，未选中等级的透明度
local LINE_EDGE_PADDING = 1.2  -- 九宫格留白补偿（像素），抵消ImgLine透明边导致的接缝空白

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

-- 刷新名称
function XUiEquipOverrunV4P6GridOverrunBase:RefreshName(overrunCfg)
    self.BtnlLevel:SetNameByGroup(0, overrunCfg.Name)
end

-- 刷新选中状态（未激活显示 Disable，激活后显示 Normal；选中状态由 TagSelect 控制）
function XUiEquipOverrunV4P6GridOverrunBase:RefreshSelectState()
    local overrunCfg = self:GetOverrunConfig()
    local isActive = self:IsOverrunActive(overrunCfg)
    local selectIndex = self.Parent:GetSelectIndex()
    local isSelect = selectIndex == self.Index
    local state = isActive and CS.UiButtonState.Normal or CS.UiButtonState.Disable
    self.BtnlLevel:SetButtonState(state)
    self.BtnlLevel.TempState = state
    self.TagSelect.gameObject:SetActiveEx(isSelect)
    -- 有等级被选中时，未选中的等级降低透明度
    self.CanvasGroup.alpha = (selectIndex ~= nil and not isSelect) and UNSELECTED_ALPHA or 1
end

-- 刷新下一等级标签
function XUiEquipOverrunV4P6GridOverrunBase:RefreshNextTag(overrunCfg)
    local lv = self.Parent.Equip:GetOverrunLevel()
    self.BtnlLevel:ShowTag(lv + 1 == overrunCfg.Level)
end

-- 当前谐振等级是否已激活
function XUiEquipOverrunV4P6GridOverrunBase:IsOverrunActive(overrunCfg)
    local lv = self.Parent.Equip:GetOverrunLevel()
    return lv >= overrunCfg.Level
end

-- 刷新激活状态背景
function XUiEquipOverrunV4P6GridOverrunBase:RefreshActiveBg(overrunCfg)
    local isActive = self:IsOverrunActive(overrunCfg)
    self.ImgBgLevelOn.gameObject:SetActiveEx(isActive)
    self.ImgBgLevelOff.gameObject:SetActiveEx(not isActive)
end

-- 刷新连线（最多3个点位、2条线段；分散到 Normal/Press/TagSelect/Disable 四个状态节点）
function XUiEquipOverrunV4P6GridOverrunBase:RefreshLine(overrunCfg)
    local isDetail = self.Parent:GetIsShowPanelDetail()
    local xList = isDetail and overrunCfg.LinePosXDetailList or overrunCfg.LinePosXList
    local yList = isDetail and overrunCfg.LinePosYDetailList or overrunCfg.LinePosYList
    if not xList or #xList == 0 then
        return
    end

    local positions = {}
    for i = 1, #xList do
        positions[i] = CS.UnityEngine.Vector2(xList[i], yList[i])
    end

    -- 预先计算两条线段的几何参数（足够 2 个点才能画 1 条线）
    local line1Data = positions[1] and positions[2] and self:_CalcLineData(positions[1], positions[2]) or nil
    local line2Data = positions[2] and positions[3] and self:_CalcLineData(positions[2], positions[3]) or nil

    local stateNodes = { self.Normal, self.Press, self.Disable }
    for _, node in ipairs(stateNodes) do
        local imgDian = node:GetObject("ImgDian")
        local imgLine1 = node:GetObject("ImgLine1")
        local imgLine2 = node:GetObject("ImgLine2")
        -- ImgDian 显示在第一个点位
        if imgDian and positions[1] then
            imgDian.transform.anchoredPosition = positions[1]
        end
        -- ImgLine1：pos1 → pos2
        if imgLine1 then
            if line1Data then
                imgLine1.gameObject:SetActiveEx(true)
                self:_ApplyLineTransform(imgLine1, line1Data)
            else
                imgLine1.gameObject:SetActiveEx(false)
            end
        end
        -- ImgLine2：pos2 → pos3
        if imgLine2 then
            if line2Data then
                imgLine2.gameObject:SetActiveEx(true)
                self:_ApplyLineTransform(imgLine2, line2Data)
            else
                imgLine2.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 计算两点间线段几何参数（width 在两端各加 LINE_EDGE_PADDING 抵消九宫格透明边）
function XUiEquipOverrunV4P6GridOverrunBase:_CalcLineData(startPos, endPos)
    local rotationAxis = startPos.y > endPos.y and CS.UnityEngine.Vector3(0, 0, -1) or CS.UnityEngine.Vector3(0, 0, 1)
    local position, width, angle = XUiHelper.CalculateLineWithTwoPosition(startPos, endPos, rotationAxis)
    return { Position = position, Width = width + LINE_EDGE_PADDING * 2, Angle = angle }
end

-- 将线段几何参数写入 RectTransform（保留高度）
function XUiEquipOverrunV4P6GridOverrunBase:_ApplyLineTransform(img, data)
    local rectTrans = img.transform
    rectTrans.anchoredPosition = data.Position
    local size = rectTrans.sizeDelta
    rectTrans.sizeDelta = CS.UnityEngine.Vector2(data.Width, size.y)
    rectTrans.localRotation = data.Angle
end

-- 获取本节点配置（供子类 Refresh 使用）
function XUiEquipOverrunV4P6GridOverrunBase:GetOverrunConfig()
    return self._Control:GetWeaponOverrunConfigById(self.OverrunCfgId)
end

return XUiEquipOverrunV4P6GridOverrunBase
