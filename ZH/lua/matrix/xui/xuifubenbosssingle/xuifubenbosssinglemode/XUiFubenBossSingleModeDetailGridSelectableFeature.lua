---@class XUiFubenBossSingleModeDetailGridSelectableFeature : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field TxtScoreRate UnityEngine.UI.Text  -- v4.2 新增：讨伐值倍率显示
---@field RImgIcon UnityEngine.UI.RawImage  -- v4.2 新增：词缀图标
---@field CheckBox XUiComponent.XUiButton
---@field _Control XFubenBossSingleControl
---@field Parent XUiFubenBossSingleModeDetail|XUiFubenBossSingleModeDetailGridBuff
local XUiFubenBossSingleModeDetailGridSelectableFeature = XClass(XUiNode, "XUiFubenBossSingleModeDetailGridSelectableFeature")

-- region 生命周期

function XUiFubenBossSingleModeDetailGridSelectableFeature:OnStart()
    ---@type XBossSingleFeature
    self._Feature = nil
    self._IsSelected = false
    
    self:_RegisterButtonClicks()
end

-- endregion

---@param feature XBossSingleFeature
function XUiFubenBossSingleModeDetailGridSelectableFeature:Refresh(feature)
    if not feature then
        return
    end
    
    self._Feature = feature
    
    -- 设置名字和描述
    if self.TxtName then
        self.TxtName.text = feature:GetName()
    end
    if self.TxtDesc then
        self.TxtDesc.text = feature:GetDesc()
    end
    
    -- v4.2 新增：显示讨伐值倍率
    if self.TxtScoreRate then
        local scoreRate = feature:GetScoreRate()
        self.TxtScoreRate.text = string.format("+%.1f%%", scoreRate / 100)
    end
    
    -- v4.2 新增：设置词缀图标
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(feature:GetIcon())
    end
    
    -- 初始化选中状态
    self:SetSelected(false)
end

--- 设置选中状态
---@param isSelected boolean
function XUiFubenBossSingleModeDetailGridSelectableFeature:SetSelected(isSelected)
    self._IsSelected = isSelected
    
    if self.CheckBox then
        -- 设置checkbox的选中状态
        if self.CheckBox.SetButtonState then
            self.CheckBox:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        end
        -- 或者如果有专门的选中标记UI
        -- if self.ImgSelected then
        --     self.ImgSelected.gameObject:SetActiveEx(isSelected)
        -- end
    end
end

--- 获取选中状态
---@return boolean
function XUiFubenBossSingleModeDetailGridSelectableFeature:GetSelected()
    return self._IsSelected
end

--- 获取词缀数据
---@return XBossSingleFeature
function XUiFubenBossSingleModeDetailGridSelectableFeature:GetFeature()
    return self._Feature
end

-- region 按钮事件

function XUiFubenBossSingleModeDetailGridSelectableFeature:OnCheckBoxClick(isSelected)
    if isSelected == nil then
        isSelected = not self._IsSelected
    end
    -- 切换选中状态
    self:SetSelected(isSelected)
    
    -- 通知父节点选中状态改变（Parent应该是XUiFubenBossSingleModeDetailGridBuff）
    if self.Parent and self.Parent.OnSelectableFeatureChanged then
        self.Parent:OnSelectableFeatureChanged(self._Feature, isSelected)
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleModeDetailGridSelectableFeature:_RegisterButtonClicks()
    if self.CheckBox then
        self.CheckBox:AddEventListener(function (value)
            self:OnCheckBoxClick(value == 1)
        end)
    end
end

-- endregion

return XUiFubenBossSingleModeDetailGridSelectableFeature

