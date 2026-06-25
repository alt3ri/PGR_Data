---@class XUiSpecialTrainBreakthroughExchangeGrid
local XUiSpecialTrainBreakthroughExchangeGrid = XClass(nil, "XUiSpecialTrainBreakthroughExchangeGrid")

function XUiSpecialTrainBreakthroughExchangeGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiSpecialTrainBreakthroughExchangeGrid:InitUi()
    self.RImgHeadIcon = self.Transform:Find("PanelHead/RImgHeadIcon"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent(typeof(CS.UnityEngine.UI.Image))
    self.TxtCur = self.Transform:Find("TxtCur"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.Txt1 = self.Transform:Find("Txt1"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.Txt2 = self.Transform:Find("Txt2"):GetComponent(typeof(CS.UnityEngine.UI.Text))
end

function XUiSpecialTrainBreakthroughExchangeGrid:OnBtnCharacterClick()
end

function XUiSpecialTrainBreakthroughExchangeGrid:UpdateGrid(robotId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(robotId)
    self.RImgHeadIcon:SetRawImage(XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId))
    self.Txt1.text = XEntityHelper.GetCharacterName(robotId)
    self.Txt2.text = XEntityHelper.GetCharacterTradeName(robotId)
end

function XUiSpecialTrainBreakthroughExchangeGrid:SetSelected(isSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
end

function XUiSpecialTrainBreakthroughExchangeGrid:SetCurrentSign(isActive)
    self.TxtCur.gameObject:SetActiveEx(isActive)
end

return XUiSpecialTrainBreakthroughExchangeGrid
