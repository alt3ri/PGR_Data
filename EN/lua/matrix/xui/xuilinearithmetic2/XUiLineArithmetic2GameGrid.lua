local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

---@class XUiLineArithmetic2GameGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2GameGrid = XClass(XUiNode, "UiLineArithmetic2GameGrid")

function XUiLineArithmetic2GameGrid:OnStart(type, color)
    self._Data = false
    -- 从一开始就固定好这个格子的类型，中途不能发生改变
    -- 因为不同类型的格子，使用了不同ui
    self._Type = type
    self._Color = color
    self._IsSelected = false
    self._IsRedCount = false
end

function XUiLineArithmetic2GameGrid:OnDisable()
    -- 播放动画后恢复默认状态
    self.ImgSelected.gameObject:SetActiveEx(false)
    self._IsSelected = nil
    -- 复用时,需要修改默认颜色
    if not self._IsRedCount then
        local image = self.PanelCount:GetComponent("Image")
        if image then
            image.color = XUiHelper.Hexcolor2Color("5C658BFF")
        end
    end
    self._IsRedCount = nil
end

-- 恢复默认状态
function XUiLineArithmetic2GameGrid:RevertStateBeforeAnimation()
    if self._IsPreview then
        self:PlayAnimation("GridRefresh")
    end
end

---@param data XLineArithmetic2ControlMapData
function XUiLineArithmetic2GameGrid:Update(data)
    self.Transform.name = data.UiName
    self._Data = data

    if data.IsPreview ~= self._IsPreview then
        self._IsPreview = data.IsPreview
        if data.IsPreview then
            self:PlayAnimation("GridDisablePreview", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        else
            self:PlayAnimation("GridRefresh")
        end
    end

    ---@type UnityEngine.RectTransform
    local transform = self.Transform
    transform.localPosition = Vector3(data.UiX, data.UiY, 0)
    if self._IsSelected ~= data.IsSelected then
        self._IsSelected = data.IsSelected
        if data.IsSelected then
            self.ImgSelected.gameObject:SetActiveEx(true)
            -- playAnimation有bug, 会导致音效播放两次, 所以改用原生的Director.Play直接播放
            local enableAnimation = XUiHelper.TryGetComponent(self.Transform, "Animation/SelectedEnable", "PlayableDirector")
            if enableAnimation then
                enableAnimation:Play()
            end
            --self:PlayAnimation("SelectedEnable")
            self:StopAnimation("SelectedDisable")
        else
            --self:StopAnimation("SelectedEnable")
            ---@type UnityEngine.Playables.PlayableDirector
            local enableAnimation = XUiHelper.TryGetComponent(self.Transform, "Animation/SelectedEnable", "PlayableDirector")
            if enableAnimation then
                enableAnimation:Stop()
            end
            self:PlayAnimation("SelectedDisable")
        end
    end

    if self.ImgSelected2 then
        self.ImgSelected2.gameObject:SetActiveEx(data.IsToShot)
    end

    local content = self:GetUiContent()
    if content then
        if self._Data.Type == XLineArithmetic2Enum.GRID.END
                or self._Data.Type == XLineArithmetic2Enum.GRID.END_FILL
                or self._Data.Type == XLineArithmetic2Enum.GRID.END_COLOR_ONE
                or self._Data.Type == XLineArithmetic2Enum.GRID.END_COLOR_THROUGH
        then
            local txtCapacityNum = XUiHelper.TryGetComponent(content, "Normal/TxtCapacityNum", "Text")
            txtCapacityNum.text = data.Capacity

            local txtBullet = XUiHelper.TryGetComponent(content, "TxtNum", "Text")
            if txtBullet then
                txtBullet.text = data.Number
            end

            if self._Data.Capacity == 0 then
                local complete = content:Find("Complete")
                if complete then
                    complete.gameObject:SetActiveEx(true)
                end
            else
                local complete = content:Find("Complete")
                if complete then
                    complete.gameObject:SetActiveEx(false)
                end
            end
            self:UpdateArrow()
        else
            local txtNum = XUiHelper.TryGetComponent(content, "TxtNum", "Text")
            if txtNum then
                txtNum.text = data.Number
            end

            local panelArrow = content:Find("PanelArrow")
            if panelArrow then
                panelArrow.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.PanelCount then
        if data.PreviewEatCount then
            self.PanelCount.gameObject:SetActiveEx(true)
            if data.IsEatRed ~= self._IsRedCount then
                self._IsRedCount = data.IsEatRed
                if data.IsEatRed then
                    local image = self.PanelCount:GetComponent("Image")
                    if image then
                        image.color = XUiHelper.Hexcolor2Color("A64059FF")
                    end
                else
                    local image = self.PanelCount:GetComponent("Image")
                    if image then
                        image.color = XUiHelper.Hexcolor2Color("5C658BFF")
                    end
                end
            end
            self.TxtCount.text = data.PreviewEatCount
        else
            self.PanelCount.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLineArithmetic2GameGrid:GetType()
    return self._Type
end

function XUiLineArithmetic2GameGrid:GetColor()
    return self._Color
end

function XUiLineArithmetic2GameGrid:GetUiContent()
    return self.Content:GetChild(0)
end

function XUiLineArithmetic2GameGrid:UpdateArrow()
    local content = self:GetUiContent()
    local panelArrow = content:Find("PanelArrow")
    if panelArrow then
        panelArrow.gameObject:SetActiveEx(true)

        -- 上下左右的箭头
        local up = panelArrow:Find("Up")
        local down = panelArrow:Find("Down")
        local left = panelArrow:Find("Left")
        local right = panelArrow:Find("Right")
        local data = self._Data
        local direction = data.ShotDirection
        if direction.y > 0 and direction.x == 0 then
            up.gameObject:SetActiveEx(true)
            down.gameObject:SetActiveEx(false)
            left.gameObject:SetActiveEx(false)
            right.gameObject:SetActiveEx(false)
        elseif direction.y < 0 and direction.x == 0 then
            up.gameObject:SetActiveEx(false)
            down.gameObject:SetActiveEx(true)
            left.gameObject:SetActiveEx(false)
            right.gameObject:SetActiveEx(false)
        elseif direction.x > 0 and direction.y == 0 then
            up.gameObject:SetActiveEx(false)
            down.gameObject:SetActiveEx(false)
            left.gameObject:SetActiveEx(false)
            right.gameObject:SetActiveEx(true)
        elseif direction.x < 0 and direction.y == 0 then
            up.gameObject:SetActiveEx(false)
            down.gameObject:SetActiveEx(false)
            left.gameObject:SetActiveEx(true)
            right.gameObject:SetActiveEx(false)
        else
            up.gameObject:SetActiveEx(false)
            down.gameObject:SetActiveEx(false)
            left.gameObject:SetActiveEx(false)
            right.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLineArithmetic2GameGrid:GetUiData()
    return self._Data
end

return XUiLineArithmetic2GameGrid