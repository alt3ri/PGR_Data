---@class XUiGridLastSettleMember : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field ImgHead UnityEngine.UI.Image
---@field RImgQuality UnityEngine.UI.Image
---@field ImgNone UnityEngine.GameObject
---@field ImgKuangNormal UnityEngine.GameObject
---@field ImgKuangSpecial UnityEngine.GameObject
---@field ImgSelect UnityEngine.GameObject
---@field TagTry UnityEngine.GameObject
---@field PanelNow UnityEngine.GameObject
---@field BtnClick XUiComponent.XUiButton
local XUiGridLastSettleMember = XClass(XUiNode, "XUiGridLastSettleMember")

function XUiGridLastSettleMember:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridLastSettleMember:SetIsMvp(isMvp)
    self._IsMvp = isMvp
end

---刷新荣誉队员格
---@param data table { IsEmpty, FightId, Quality, IsSSSPlus, IsTrial }
function XUiGridLastSettleMember:Refresh(data)
    self._Data = data
    if not data or data.IsEmpty then
        self:ShowEmpty()
        return
    end
    self:ShowMember(data)
end

---空位态：仅显示 ImgNone
function XUiGridLastSettleMember:ShowEmpty()
    self.ImgNone.gameObject:SetActiveEx(true)
    self.ImgHead.gameObject:SetActiveEx(false)
    self.RImgQuality.gameObject:SetActiveEx(false)
    self.ImgKuangNormal.gameObject:SetActiveEx(false)
    self.ImgKuangSpecial.gameObject:SetActiveEx(false)
    self.TagTry.gameObject:SetActiveEx(false)
    if self.PanelNow then
        self.PanelNow.gameObject:SetActiveEx(false)
    end
end

---有角色态：立绘/头像 + 品阶框 + 外框（SSS+ 走特殊框）
function XUiGridLastSettleMember:ShowMember(data)
    self.ImgNone.gameObject:SetActiveEx(false)

    local icon = self._IsMvp and self._Control:GetFightHalfBodyImage(data.FightId)
        or self._Control:GetFightHeadIcon(data.FightId)
    self.ImgHead.gameObject:SetActiveEx(icon ~= nil)
    if icon then
        self.ImgHead:SetRawImage(icon)
    end

    self.RImgQuality.gameObject:SetActiveEx(not data.IsTrial)
    if not data.IsTrial then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(data.Quality))
    end

    self.ImgKuangNormal.gameObject:SetActiveEx(not data.IsSSSPlus)
    self.ImgKuangSpecial.gameObject:SetActiveEx(data.IsSSSPlus)
    self.TagTry.gameObject:SetActiveEx(data.IsTrial == true)
    local isCurrentMvp = data.IsCurrentMvp == true and not self._IsMvp
    if self.PanelNow then
        self.PanelNow.gameObject:SetActiveEx(isCurrentMvp)
    end
end

---设置选中态（MVP 切换弹窗用）
function XUiGridLastSettleMember:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiGridLastSettleMember:GetData()
    return self._Data
end

function XUiGridLastSettleMember:OnBtnClick()
    -- 本格子被结算界面与 MVP 切换弹窗共用，只有后者响应点击
    if self.Parent.OnCandidateClick then
        self.Parent:OnCandidateClick(self, self._Data)
    end
end

return XUiGridLastSettleMember
