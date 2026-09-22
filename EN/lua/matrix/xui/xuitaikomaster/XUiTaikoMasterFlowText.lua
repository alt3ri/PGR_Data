---@class XUiTaikoMasterFlowText
local XUiTaikoMasterFlowText = XClass(nil, "XUiTaikoMasterFlowText")

function XUiTaikoMasterFlowText:Ctor(text, mask)
    self._Text = text
    self._Mask = mask
    self._InitX = false
    self._Sequence = false
    self._StrText = false
    self._StrTextDouble = false
    self._UseRectWidth = false
end

function XUiTaikoMasterFlowText:IsPlaying()
    return self._Sequence and true or false
end

---设置是否用 mask.rect.width（实际渲染宽度）作为滚动判定依据
---sizeDelta.x 在锚点拉伸时为 0，开启后每次 Play 动态读 rect.width
---@param flag boolean
function XUiTaikoMasterFlowText:SetUseRectWidth(flag)
    self._UseRectWidth = flag
end

function XUiTaikoMasterFlowText:Play()
    if self._Sequence then
        self:Stop()
    end
    self._Sequence, self._InitX = self:CreateTextSequence(self._Text, self._Mask, self._InitX)
end

function XUiTaikoMasterFlowText:Stop()
    if self._Sequence then
        self._Sequence:Kill()
        self._Sequence = false
        if self._InitX then
            -- 复位
            local txtLocalPosition = self._Text.transform.localPosition
            self._Text.transform.localPosition = Vector3(self._InitX, txtLocalPosition.y, txtLocalPosition.z)
        end
    end
    -- 还原text
    if self._Text.text == self._StrTextDouble then
        self._Text.text = self._StrText
    end
    self._StrText = false
    self._StrTextDouble = false
end

---彻底重置：Stop + 清 _InitX，cell 回收复用时调用
function XUiTaikoMasterFlowText:Reset()
    self:Stop()
    self._InitX = false
end

function XUiTaikoMasterFlowText:DoubleText(txtName)
    local text = txtName.text
    local space = "     "
    if not string.find(text, space) then
        self._StrText = text
        self._StrTextDouble = string.format('%s%s%s', text, space, text)
        txtName.text = self._StrTextDouble
    end
end

function XUiTaikoMasterFlowText:CreateTextSequence(txtName, mask, initX)
    local txtNameWidth = XUiHelper.CalcTextWidth(txtName)
    local txtMaskWidth = mask.sizeDelta.x
    if self._UseRectWidth and mask.rect then
        txtMaskWidth = mask.rect.width
    end
    -- ==0 我认为是一种错误。ui错误初始化的情况。并且在这种情况下滚动其实也没意义
    if  txtMaskWidth == 0 or txtNameWidth <= txtMaskWidth then
        return
    end
    local txtTransform = txtName.transform
    local txtLocalPosition = txtTransform.localPosition
    initX = initX or txtLocalPosition.x

    -- 两个文本才可以循环滚动
    self:DoubleText(txtName)
    local doubleTxtNameWidth = XUiHelper.CalcTextWidth(txtName)
    local startX = initX
    local endX = initX - (doubleTxtNameWidth - txtNameWidth)

    local distance = math.abs(endX - startX)
    txtName.transform.localPosition = Vector3(startX, txtLocalPosition.y, txtLocalPosition.z)

    local DOTween = CS.DG.Tweening.DOTween
    local sequence = DOTween.Sequence()
    local pauseInterval = XEnumConst.TAIKO_MASTER.MUSIC_PLAYER_TEXT_MOVE_PAUSE_INTERVAL
    sequence:AppendInterval(pauseInterval)
    local moveSpeed = XEnumConst.TAIKO_MASTER.MUSIC_PLAYER_TEXT_MOVE_SPEED
    local time = distance / moveSpeed
    sequence:Append(txtTransform:DOLocalMoveX(endX, time))
    sequence:Append(txtTransform:DOLocalMoveX(startX, 0))
    sequence:SetLoops(-1)
    return sequence, initX
end

return XUiTaikoMasterFlowText
