--- 肉鸽6攻击详情气泡（普攻/技能）
---@class XUiPanelTheatre6AttackDetail : XUiNode
---@field _Control XTheatre6Control
local XUiPanelTheatre6AttackDetail = XClass(XUiNode, "XUiPanelTheatre6AttackDetail")

function XUiPanelTheatre6AttackDetail:OnStart()
    self.uiPanelDetail = {}
    XUiHelper.InitUiClass(self.uiPanelDetail, self.PanelDetail)
    
    self.uiPanelDetail.UiTxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiPanelTheatre6AttackDetail:Refresh(skillId)
    self._SkillId = skillId
    local skillConfig = self._Control:GetSkillCfgById(self._SkillId)
    self.uiPanelDetail.UiTxtName.text = skillConfig.Name
    self.uiPanelDetail.UiTxtType.text = self._Control:GetClientConfigValue("SkillType", skillConfig.Type) --技能类型
    self.uiPanelDetail.TxtNum.text = skillConfig.CostTL
    self.uiPanelDetail.UiTxtDesc.text = self._Control:GetSkillDesc(skillId, false)
    self.uiPanelDetail.ImgIconSp:SetSprite(self._Control:GetClientConfigValue("IconSp"))               --SP图标
end

return XUiPanelTheatre6AttackDetail