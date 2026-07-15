---@class XUiPanelTheatre6TopSan : XUiNode 房间顶部San值显示面板
---@field _Control XTheatre6Control
---@field Parent XLuaUi
local XUiPanelTheatre6TopSan = XClass(XUiNode, "XUiPanelTheatre6TopSan")

local Mathf = CS.UnityEngine.Mathf
local Quaternion = CS.UnityEngine.Quaternion

function XUiPanelTheatre6TopSan:OnStart(isShowLineNum)
    self.BtnPointer:AddEventListener(handler(self, self.OnBtnPointerClick))

    self._AngleL = self._Control:GetIntClientConfigValue("SanCircleAngle", 1)
    self._AngleR = self._Control:GetIntClientConfigValue("SanCircleAngle", 2)
    self._SanTweenDuration = self._Control:GetIntClientConfigValue("TopSanTweenTime")
    self._Radius = self.ImgArrow.rect.width - self.ImgLine.transform.rect.height
    self._CenterY = self.ImgArrow.anchoredPosition.y
    self._IsShowLineNum = isShowLineNum
    
    ---@type UnityEngine.UI.Image[]
    self._Lines = {}
    ---@type UnityEngine.UI.Text[]
    self._TxtNums = {}
    
    if self.UiTxtNum then
        self.UiTxtNum.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre6TopSan:OnEnable()
    self._SkipNextTween = true
    self:UpdateView()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SAN_CHANGE, self.UpdateView, self)
end

function XUiPanelTheatre6TopSan:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SAN_CHANGE, self.UpdateView, self)
    self:StopSanTween()
end

function XUiPanelTheatre6TopSan:UpdateView()
    self._Min = self._Control:GetMinSanValue()
    self._Max = self._Control:GetMaxSanValue()
    self._CenterSan = (self._Max - self._Min) / 2
    
    local san = self._Control:GetSanValue()
    self.TxtCurSanL.text = san
    self.TxtCurSanR.text = san

    local sanIds = self._Control:GetSanIds()
    local curSan = self._Control:GetCurSanConfig()

    --画线
    for i, sanId in ipairs(sanIds) do
        local config = self._Control:GetSanConfigById(sanId)
        if string.IsNilOrEmpty(config.LineColor) then
            goto CONTINUE
        end

        local radius = self._Radius + config.LineOffset
        local angle = self:GetAngle(config.MinSan)
        local rad = angle * Mathf.Deg2Rad
        local x = radius * Mathf.Sin(rad)
        local y = self._CenterY - radius * Mathf.Cos(rad)
        local color = XUiHelper.Hexcolor2Color(config.LineColor)

        local line = self._Lines[i]
        if not line then
            line = i == 1 and self.ImgLine or XUiHelper.Instantiate(self.ImgLine, self.ImgLine.transform.parent)
            self._Lines[i] = line
        end

        line.color = color
        line.transform:SetAnchoredPosition(x, y)
        line.transform:SetEulerRotation(0, 0, angle)

        --在line正下方实例化UiTxtNum并赋值MinSan
        if self._IsShowLineNum then
            local txtNum = self._TxtNums[i]
            if not txtNum then
                txtNum = XUiHelper.Instantiate(self.UiTxtNum, line.transform.parent)
                self._TxtNums[i] = txtNum
            end
            txtNum.text = config.MinSan
            --沿line方向偏移到line末端正下方，再向下偏移一段距离
            local lineHeight = line.transform.rect.size.y
            local txtX = x + lineHeight * Mathf.Sin(rad)
            local txtY = y - lineHeight * Mathf.Cos(rad)
            txtNum.color = color
            txtNum.transform:SetAnchoredPosition(txtX, txtY)
            txtNum.transform:SetEulerRotation(0, 0, 0)
            txtNum.gameObject:SetActiveEx(true)
        end

        ::CONTINUE::
    end
    
    --设置颜色
    local sanColor = XUiHelper.Hexcolor2Color(curSan.Color)
    self.ImgArrowColor.color = sanColor
    self.TxtCurSanL.color = sanColor
    self.TxtCurSanR.color = sanColor

    local isShowRight = san > self._CenterSan
    self.CurPanelSanL.gameObject:SetActiveEx(not isShowRight)
    self.CurPanelSanR.gameObject:SetActiveEx(isShowRight)

    --UI动画（缓动）
    self:PlaySanTween(san)

    if self.UiTxtNumMin then
        self.UiTxtNumMin.text = self._Min
    end

    if self.UiTxtNumMax then
        self.UiTxtNumMax.text = self._Max
    end
end

---缓动箭头角度和进度条fillAmount到当前San值对应位置
function XUiPanelTheatre6TopSan:PlaySanTween(san)
    local targetAngle = self:GetAngle(san) + 90
    local targetFill = san / self._Max

    local startAngle, startFill
    if self._SkipNextTween then
        startAngle = targetAngle
        startFill = targetFill
        self._SkipNextTween = false
    else
        startAngle = self.ImgArrow.transform.localEulerAngles.z
        startFill = self.ImgSan.fillAmount
    end

    self:StopSanTween()

    self.ImgArrow.transform.localRotation = Quaternion.Euler(0, 0, startAngle)
    self.ImgSan.fillAmount = startFill

    if startAngle == targetAngle and startFill == targetFill then
        return
    end

    self._SanTweenTimer = XUiHelper.Tween(self._SanTweenDuration, function(t)
        local angle = Mathf.Lerp(startAngle, targetAngle, t)
        self.ImgArrow.transform.localRotation = Quaternion.Euler(0, 0, angle)
        self.ImgSan.fillAmount = Mathf.Lerp(startFill, targetFill, t)
    end)
end

function XUiPanelTheatre6TopSan:StopSanTween()
    if self._SanTweenTimer then
        XScheduleManager.UnSchedule(self._SanTweenTimer)
        self._SanTweenTimer = nil
    end
end

function XUiPanelTheatre6TopSan:OnBtnPointerClick()
    XLuaUiManager.Open("UiTheatre6PopupSanDetail")
end

function XUiPanelTheatre6TopSan:GetAngle(sanValue)
    return Mathf.Lerp(self._AngleL, self._AngleR, sanValue / self._Max)
end

return XUiPanelTheatre6TopSan
