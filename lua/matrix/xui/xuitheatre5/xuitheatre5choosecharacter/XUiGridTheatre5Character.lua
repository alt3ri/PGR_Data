---@class XUiGridTheatre5Character: XUiNode
---@field private _Control XTheatre5Control
local XUiGridTheatre5Character = XClass(XUiNode, 'XUiGridTheatre5Character')

function XUiGridTheatre5Character:OnStart()
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.GridButton.CallBack = handler(self, self.OnBtnClickEvent)
end

---@param cfg XTableTheatre5Character
function XUiGridTheatre5Character:Update(cfg, index)
    self.Config = cfg
    self.Index = index

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self._IsUnlock = self._Control.PVPControl:CheckHasPVPCharacterDataById(cfg.Id)
    end

    -- 无论是否解锁，选择列表中均不锁定
    self.PanelLock.gameObject:SetActiveEx(false)
    
    local portrait = self._Control.CharacterControl:GetPortraitByCharacterIdCurMode(self.Config.Id)

    if not string.IsNilOrEmpty(portrait) then
        self.RImgHeadIcon:SetRawImage(portrait)
    end
end

function XUiGridTheatre5Character:OnBtnClickEvent()
    self.Parent:OnBtnSelect(self.Index)
end

function XUiGridTheatre5Character:OnSelectedShow()
    self.PanelSelected.gameObject:SetActiveEx(true)
end

function XUiGridTheatre5Character:OnUnselectShow()
    self.PanelSelected.gameObject:SetActiveEx(false)
end

return XUiGridTheatre5Character