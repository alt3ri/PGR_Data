---@class XUiPanelRaceCharacterDetail : XUiNode 角色详情
---@field Parent XUiRacePredict
---@field _Control XRaceControl
local XUiPanelRaceCharacterDetail = XClass(XUiNode, "XUiPanelRaceCharacterDetail")

function XUiPanelRaceCharacterDetail:OnStart()
    self.BtnDetail.CallBack = handler(self, self.OnBtnDetailClick)
    self.TxtSpeedDetail.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("RaceSpeedDesc"))
    self.TxtAccDetail.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("RaceAccDesc"))
    self.TxtDriftDetail.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("RaceDriftDesc"))
    self.TxtLuckDetail.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("RaceLuckDesc"))
end

function XUiPanelRaceCharacterDetail:ShowDetail(roleId)
    self._RoleId = roleId

    local roleCfg = self._Control:GetRaceCharacterById(roleId)
    local maxValue = self._Control:GetMaxCharacterGrade()
    local roleCfg = self._Control:GetRaceCharacterById(roleId)

    self.ImgSpeed:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowSpeed))
    self.ImgDrift:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowDrift))
    self.ImgAcc:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowAcc))
    self.ImgLuck:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowLuck))
    self.ImgSpeedProgress.fillAmount = maxValue <= 0 and 0 or roleCfg.ShowSpeed / maxValue
    self.ImgAccProgress.fillAmount = maxValue <= 0 and 0 or roleCfg.ShowAcc / maxValue
    self.ImgDriftProgress.fillAmount = maxValue <= 0 and 0 or roleCfg.ShowDrift / maxValue
    self.ImgLuckProgress.fillAmount = maxValue <= 0 and 0 or roleCfg.ShowLuck / maxValue

    local normalSkill = self._Control:GetRaceCharacterSkillById(roleCfg.NormalSkill)
    self.TxtNormalName.text = normalSkill.Name
    self.TxtNormalSkillDetail.text = normalSkill.Desc

    local ultraSkill = self._Control:GetRaceCharacterSkillById(roleCfg.UltraSkill)
    self.TxtUltraName.text = ultraSkill.Name
    self.TxtUltraSkillDetail.text = ultraSkill.Desc
    local balls = {}
    for ballType, ballCount in pairs(ultraSkill.SignalBallCosts) do
        if ballCount and ballCount > 0 then
            for i = 1, ballCount do
                table.insert(balls, ballType)
            end
        end
    end
    XUiHelper.RefreshCustomizedList(self.RImgPoint.parent, self.RImgPoint, #balls, function(i, go)
        local ballId = balls[i]
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        if ballId == 0 then
            --万能球
            uiObject.RImgPoint:SetRawImage(self._Control:GetClientConfig("ZeroBallIcon"))
            uiObject.TxtTag.gameObject:SetActiveEx(true)
        else
            uiObject.RImgPoint:SetRawImage(self._Control:GetRaceSignalBallById(ballId).Icon)
            uiObject.TxtTag.gameObject:SetActiveEx(false)
        end
    end)
end

function XUiPanelRaceCharacterDetail:OnBtnDetailClick()
    self.ImgDetailBg.gameObject:SetActiveEx(true)
    self.Parent.BtnBubbleClose.gameObject:SetActiveEx(true)
end

function XUiPanelRaceCharacterDetail:OnCloseDetail()
    self.ImgDetailBg.gameObject:SetActiveEx(false)
end

return XUiPanelRaceCharacterDetail
