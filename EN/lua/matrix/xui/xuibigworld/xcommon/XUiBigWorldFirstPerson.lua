
---@class XUiBigWorldFirstPerson : XBigWorldUi
local XUiBigWorldFirstPerson = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldFirstPerson")

local CSNormal = CS.UiButtonState.Normal
local CSSelect = CS.UiButtonState.Select

function XUiBigWorldFirstPerson:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldFirstPerson:OnStart(levelId, isShowClose, txtExplain, confirmCb)
    self._LevelId = levelId
    self._ConfirmCb = confirmCb
    if txtExplain then
        self.TxtExplain.text = XUiHelper.ReplaceTextNewLine(txtExplain)
    else
        self.TxtExplain.text = XUiHelper.ReplaceTextNewLine(XMVCA.XBigWorldService:GetText("BigWorldPerspectiveDefaultExplain"))
    end
    self.BtnTanchuangClose.gameObject:SetActiveEx(isShowClose)
    self:InitView()
end

function XUiBigWorldFirstPerson:InitUi()
    self._Perspective = -1
    self.BtnLeft:SetButtonState(CSNormal)
    self.BtnRight:SetButtonState(CSNormal)
end

function XUiBigWorldFirstPerson:InitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    
    self.BtnLeft:AddEventListener(handler(self, self.OnBtnLeftClick))
    self.BtnRight:AddEventListener(handler(self, self.OnBtnRightClick))
end

function XUiBigWorldFirstPerson:InitView()
    self:RefreshConfirm()
end

function XUiBigWorldFirstPerson:OnBtnConfirmClick()
    --还在引导中，战斗不会通知事件下来，直接通知服务器
    if XMVCA.XBigWorldGamePlay:GetCurrentAgency():IsInOpenGuide() then
        XMVCA.XBigWorldGamePlay:SavePerspectiveRequest(self._LevelId, self._Perspective, function()
            self:Close()
            if self._ConfirmCb then
                self._ConfirmCb()
            end
        end)
    else
        XMVCA.XBigWorldGamePlay:SetFightPerspective(self._Perspective, true)
        self:Close()
        if self._ConfirmCb then
            self._ConfirmCb()
        end
    end
end

function XUiBigWorldFirstPerson:OnBtnLeftClick()
    if self._Perspective == XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson then
        return
    end
    self.BtnLeft:SetButtonState(CSSelect)
    self.BtnRight:SetButtonState(CSNormal)
    self._Perspective = XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson
    self:RefreshConfirm()
end

function XUiBigWorldFirstPerson:OnBtnRightClick()
    if self._Perspective == XMVCA.XBigWorldGamePlay.PerspectiveType.ThirdPerson then
        return
    end
    self.BtnRight:SetButtonState(CSSelect)
    self.BtnLeft:SetButtonState(CSNormal)
    self._Perspective = XMVCA.XBigWorldGamePlay.PerspectiveType.ThirdPerson
    self:RefreshConfirm()
end

function XUiBigWorldFirstPerson:RefreshConfirm()
    local disable = self._Perspective == -1
    
    self.BtnConfirm:SetDisable(disable, not disable)
end