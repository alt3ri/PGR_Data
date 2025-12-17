---@class XUiTeamPrefabPartnerGridPartner
local XUiTeamPrefabPartnerGridPartner = XClass(nil, "XUiTeamPrefabPartnerGridPartner")
local TEAM_MEMBER_ORDER = {2, 1, 3} --队伍顺序（蓝，红，黄）

function XUiTeamPrefabPartnerGridPartner:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
end

function XUiTeamPrefabPartnerGridPartner:InitUi()
    --使用动态列表的点击
    self.BtnClick.gameObject:SetActiveEx(false)
end

--==============================
 ---@desc 刷新显示
 ---@partner @class XPartner
--==============================
function XUiTeamPrefabPartnerGridPartner:Refresh(partner, carriedDict, idx)
    if not partner then
        return
    end
    
    self.RImgHeadIcon:SetRawImage(partner:GetIcon())
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(partner:GetQuality()))
    self.PanelLv:GetObject("TxtLevel").text = partner:GetLevel()
    self.ImgLock.gameObject:SetActiveEx(partner:GetIsLock())
    self.ImgBreak:SetSprite(partner:GetBreakthroughIcon())

    local id = partner:GetId()
    local pos = carriedDict[id]
    self.ImgIsYellow.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[3])
    self.ImgIsBlue.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[1])
    self.ImgIsRed.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[2])
end

function XUiTeamPrefabPartnerGridPartner:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

return XUiTeamPrefabPartnerGridPartner