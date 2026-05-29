---@class XUiGridDlcRelinkPopupFilterTab : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkPopupFilterTab = XClass(XUiNode, "XUiGridDlcRelinkPopupFilterTab")

function XUiGridDlcRelinkPopupFilterTab:OnStart(callBack)
    self.CallBack = callBack
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridDlcRelinkPopupFilterTab:Refresh(factorId)
    self.FactorId = factorId
    -- 属性名称
    local name = self._Control:GetFactorDescName(factorId)
    self.TxtType1.text = name
    self.TxtType2.text = name
    -- 属性所属的角色图标
    local characterIcon = self._Control:GetFactorDescCharacterIcon(factorId)
    local isShowIcon = not string.IsNilOrEmpty(characterIcon)
    self.ImgAvatar1.gameObject:SetActiveEx(isShowIcon)
    self.ImgAvatar2.gameObject:SetActiveEx(isShowIcon)
    if isShowIcon then
        self.ImgAvatar1:SetSprite(characterIcon)
        self.ImgAvatar2:SetSprite(characterIcon)
    end
end

function XUiGridDlcRelinkPopupFilterTab:SetSelect(isSelect)
    self.Normal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

function XUiGridDlcRelinkPopupFilterTab:OnBtnClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridDlcRelinkPopupFilterTab
