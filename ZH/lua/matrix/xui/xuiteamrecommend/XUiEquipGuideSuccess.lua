---@class XUiEquipGuideSuccess : XLuaUi
local XUiEquipGuideSuccess = XLuaUiManager.Register(XLuaUi, "UiEquipGuideSuccess")

function XUiEquipGuideSuccess:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

--- 刷新达成目标的角色信息
---@param characterId number
function XUiEquipGuideSuccess:OnStart(characterId)
    self.RImgIcon:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(characterId)
end

--- 关闭成功界面并移除已完成目标的详情界面
function XUiEquipGuideSuccess:OnBtnCloseClick()
    local removeUiNameList = {
        "UiEquipAwarenessEnhanceMain",
        "UiEquipOneClickCultureDetailMain",
        "UiEquipOneClickCulturePartnerMain",
        "UiTeamRecommendRoleTargetDetail",
    }
    for _, uiName in ipairs(removeUiNameList) do
        if XLuaUiManager.IsUiLoad(uiName) then
            XLuaUiManager.Remove(uiName)
        end
    end
    self:Close()
end

return XUiEquipGuideSuccess
