--- 通用确认弹窗
---@class XUiPBRPopupComTips: XLuaUi
---@field protected _Control
local XUiPBRPopupComTips = XLuaUiManager.Register(XLuaUi, "UiPBRPopupComTips")

--region Ui生命周期

function XUiPBRPopupComTips:OnAwake()
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.CloseByHand))
    self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkipClick))
end

---@param extraData XUiPBRPopupComTipsExtraData
function XUiPBRPopupComTips:OnStart(content, closeCb, leftCb, rightCb, extraData)
    self.TxtDesc.text = content
    
    self.CloseCb = closeCb
    self.LeftCb = leftCb
    self.RightCb = rightCb

    if not XTool.IsTableEmpty(extraData) then
        if not string.IsNilOrEmpty(extraData.BtnLeftText) then
            self.BtnLeft:SetNameByGroup(0, extraData.BtnLeftText)
        end

        if not string.IsNilOrEmpty(extraData.BtnRightText) then
            self.BtnRight:SetNameByGroup(0, extraData.BtnRightText)
        end

        self.BtnSkip.gameObject:SetActiveEx(extraData.IsShowHint or false)

        if extraData.IsShowHint then
            if not string.IsNilOrEmpty(extraData.HintContent) then
                self.BtnSkip:SetNameByGroup(0, extraData.HintContent)
            end

            self:_UpdateBtnSkipShow(extraData.HintStatus)

            self.HintStatusChangedCb = extraData.HintStatusChangedCb

            self.CurHintStatus = extraData.HintStatus
        end
    else
        self.BtnSkip.gameObject:SetActiveEx(false)
    end
end

--endregion

function XUiPBRPopupComTips:_UpdateBtnSkipShow(isSkip)
    self.BtnSkip:SetButtonState(isSkip and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPBRPopupComTips:OnBtnLeftClick()
    local cb = self.LeftCb
    
    self:CloseByHand()

    if cb then
        cb()
    end
end

function XUiPBRPopupComTips:OnBtnRightClick()
    local cb = self.RightCb

    self:CloseByHand()

    if cb then
        cb()
    end
end

function XUiPBRPopupComTips:CloseByHand()
    local cb = self.CloseCb

    self:Close()

    if cb then
        cb()
    end
end

function XUiPBRPopupComTips:OnBtnSkipClick()
    -- 点击后交换
    self.CurHintStatus = not self.CurHintStatus

    self:_UpdateBtnSkipShow(self.CurHintStatus)

    if self.HintStatusChangedCb then
        self.HintStatusChangedCb(self.CurHintStatus)
    end
end

return XUiPBRPopupComTips


---@class XUiPBRPopupComTipsExtraData
---@field BtnLeftText string | nil
---@field BtnRightText string | nil
---@field IsShowHint boolean
---@field HintContent string | nil
---@field HintStatus boolean @ [false]: 未勾选, [true]: 已勾选
---@field HintStatusChangedCb function<boolean>