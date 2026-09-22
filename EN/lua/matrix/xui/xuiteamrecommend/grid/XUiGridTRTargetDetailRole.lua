-- 引用LuaUi：UiTeamRecommendRoleTargetDetail
---@class XUiGridTRTargetDetailRole : XUiNode
local XUiGridTRTargetDetailRole = XClass(XUiNode, "XUiGridTRTargetDetailRole")

function XUiGridTRTargetDetailRole:OnStart()
    self.BtnSelf.CallBack = function() self:OnBtnClick() end

    self.StateUiList = {
        self.Normal and XTool.InitUiObjectByUi({}, self.Normal) or nil,
        self.Press and XTool.InitUiObjectByUi({}, self.Press) or nil,
        self.Select and XTool.InitUiObjectByUi({}, self.Select) or nil,
    }
end

function XUiGridTRTargetDetailRole:Refresh(roleTargetDetailData, currentCharacterId)
    self.TargetRecommendCharData = roleTargetDetailData and roleTargetDetailData.RecommendCharData

    if not self.TargetRecommendCharData then
        self:Close()
        return
    end

    self:Open()

    -- 一个角色只有一个已存目标，选中态=本条目就是详情页正展示的角色
    self.IsSelected = currentCharacterId == self.TargetRecommendCharData.CharacterId

    self:RefreshIcon()
    self.BtnSelf:ShowReddot(XMVCA.XTeamRecommend:CheckTargetEquipCanWear(self.TargetRecommendCharData.CharacterId, self.TargetRecommendCharData))
    self.BtnSelf:SetButtonState(self.IsSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridTRTargetDetailRole:RefreshIcon()
    local characterId = self.TargetRecommendCharData.CharacterId
    local headIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    local qualityIcon = XMVCA.XCharacter:GetCharacterQualityIcon(self.TargetRecommendCharData.Quality)

    for _, ui in ipairs(self.StateUiList) do
        if ui then
            if ui.RImgHead then
                ui.RImgHead:SetRawImage(headIcon)
            end
            if ui.RImgCharacterRank then
                ui.RImgCharacterRank:SetRawImage(qualityIcon)
            end
            if ui.TagUsing then
                -- 侧栏中的每一项都是已设置目标；当前项另由按钮Select态表达。
                ui.TagUsing.gameObject:SetActiveEx(true)
            end
        end
    end
end

function XUiGridTRTargetDetailRole:OnBtnClick()
    if self.TargetRecommendCharData then
        self.Parent:OnLeftSwitchRoleGridClick(self.TargetRecommendCharData.CharacterId)
    end
end

return XUiGridTRTargetDetailRole
