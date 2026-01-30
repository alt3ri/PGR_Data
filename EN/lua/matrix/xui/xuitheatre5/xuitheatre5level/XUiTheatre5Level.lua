---@class XUiTheatre5Level : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5Level = XClass(XUiNode, "XUiTheatre5Level")

function XUiTheatre5Level:OnStart()
    if self.BtnUpgrade then
        self.BtnUpgrade:AddEventListener(function()
            self:OnClick()
            -- 服务端那边设置了 cd 1秒
        end, true, true, 1.5)
    end
end

function XUiTheatre5Level:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP, self.Update, self)
    self:Update()
end

function XUiTheatre5Level:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP, self.Update, self)
end

function XUiTheatre5Level:Update()
    local uiData = self._Control:GetUiDataLevel()
    self.TxtLevel.text = uiData.Level
    if uiData.IsMax then
        self.TxtExpNum.text = XUiHelper.GetText("TheatreDecorationMaxLevel")
        self.ImgBar.fillAmount = 1
        self.BtnUpgrade.gameObject:SetActiveEx(false)
    else
        if uiData.MaxExp then
            self.TxtExpNum.text = uiData.Exp .. "/" .. uiData.MaxExp
            if uiData.MaxExp ~= 0 then
                self.ImgBar.fillAmount = uiData.Exp / uiData.MaxExp
            else
                self.ImgBar.fillAmount = 0
            end
        else
            self.TxtExpNum.text = uiData.Exp
            self.ImgBar.fillAmount = 1
        end
        if uiData.Money and uiData.IsCanUpgrade then
            self.BtnUpgrade.gameObject:SetActiveEx(true)
            self.BtnUpgrade:SetNameByGroup(0, uiData.Money)
        else
            self.BtnUpgrade.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre5Level:OnClick()
    local exp = self._Control.CharacterControl:GetCharacterExpToNextLevel()
    if exp and exp > 0 then
        XMVCA.XTheatre5:XTheatre5BuyExpRequest(exp)
    else
        XLog.Error("[XUiTheatre5Level] 不够钱, 或者满级了")
    end
end

return XUiTheatre5Level