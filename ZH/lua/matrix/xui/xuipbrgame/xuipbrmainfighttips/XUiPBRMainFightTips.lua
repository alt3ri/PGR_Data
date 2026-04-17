---
---@class XUiPBRMainFightTips: XLuaUi
---@field protected _Control
local XUiPBRMainFightTips = XLuaUiManager.Register(XLuaUi, "UiPBRMainFightTips")

function XUiPBRMainFightTips:OnAwake()
    self:InitComponents()
end

function XUiPBRMainFightTips:InitComponents()
    -- Button
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnContinueClick))
    self.BtnSettle:AddEventListener(handler(self, self.OnBtnSettleClick))

    if self.BtnTanchuangCloseBig then
        self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.Close))
    end
end


function XUiPBRMainFightTips:OnStart(continueCb, settleCb)
    self.ContinueCb = continueCb
    self.SettleCb = settleCb
end

function XUiPBRMainFightTips:OnEnable()
end

function XUiPBRMainFightTips:OnDisable()
end

function XUiPBRMainFightTips:OnDestroy()
end


function XUiPBRMainFightTips:OnBtnContinueClick()
    self:Close()

    if self.ContinueCb then
        self.ContinueCb()
    end
end

function XUiPBRMainFightTips:OnBtnSettleClick()
    self:Close()

    if self.SettleCb then
        self.SettleCb()
    end
end

return XUiPBRMainFightTips