---@class XUiRaceMemberDetail : XLuaUi 角色详情弹框
---@field _Control XRaceControl
local XUiRaceMemberDetail = XLuaUiManager.Register(XLuaUi, "UiRaceMemberDetail")

function XUiRaceMemberDetail:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self._BarWidth = self.ImgSpeedProgress.transform.rect.width
    self._BarHeight = self.ImgSpeedProgress.transform.rect.height
    self._MaxValue = self._Control:GetMaxCharacterGrade()
end

function XUiRaceMemberDetail:OnStart(roleId, dimObj, alignment)
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
    
    local roleCfg = self._Control:GetRaceCharacterById(roleId)
    self.BtnClose.gameObject:SetActive(true)
    self.TxtName.text = roleCfg.Name
    self.ImgSpeed:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowSpeed))
    self.ImgDrift:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowDrift))
    self.ImgAcc:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowAcc))
    self.ImgLuck:SetSprite(self._Control:GetCharacterGradeIcon(roleCfg.ShowLuck))

    self.ImgSpeedProgress.transform.sizeDelta = Vector2(self:GetW(roleCfg.ShowSpeed), self._BarHeight)
    self.ImgDriftProgress.transform.sizeDelta = Vector2(self:GetW(roleCfg.ShowDrift), self._BarHeight)
    self.ImgAccProgress.transform.sizeDelta = Vector2(self:GetW(roleCfg.ShowAcc), self._BarHeight)
    self.ImgLuckProgress.transform.sizeDelta = Vector2(self:GetW(roleCfg.ShowLuck), self._BarHeight)

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
    XUiHelper.RefreshCustomizedList(self.RImgPoint.transform.parent, self.RImgPoint, #balls, function(i, go)
        local ballId = balls[i]
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        if ballId == 0 then
            uiObject.RImgPoint:SetRawImage(self._Control:GetClientConfig("ZeroBallIcon"))
            uiObject.TxtTag.gameObject:SetActiveEx(true)
        else
            uiObject.RImgPoint:SetRawImage(self._Control:GetRaceSignalBallById(ballId).Icon)
            uiObject.TxtTag.gameObject:SetActiveEx(false)
        end
    end)

    if XTool.UObjIsNil(dimObj) then
        return
    end

    --防止Ui闪一下
    self.PanelSkill.gameObject:SetActive(false)
    XScheduleManager.ScheduleNextFrame(function()
        self.PanelSkill.gameObject:SetActive(true)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelSkill)
        self:UpdatePos(alignment, dimObj)
    end)
end

function XUiRaceMemberDetail:UpdatePos(alignment, dimObj)
    local posX = 0
    local pos = self.PanelSkill.parent:InverseTransformPoint(dimObj.position)
    local centerW = self.SafeAreaContentPane.rect.width / 2
    local centerH = self.SafeAreaContentPane.rect.height / 2
    local tipW = self.PanelSkill.rect.width
    local tipH = self.PanelSkill.rect.height
    local minW = tipW - centerW
    local maxW = centerW - tipW
    local minH = tipH - centerH
    local maxH = centerH

    if alignment == XEnumConst.Race.TipAlign.Left then
        self.PanelSkill.pivot = Vector2(1, 1)
        posX = pos.x - dimObj.rect.width * dimObj.localScale.x * dimObj.pivot.x
        posX = math.max(posX, minW)
    else
        self.PanelSkill.pivot = Vector2(0, 1)
        posX = pos.x + dimObj.rect.width * dimObj.localScale.x * (1 - dimObj.pivot.x)
        posX = math.min(posX, maxW)
    end
    local posY = pos.y + dimObj.rect.height * dimObj.localScale.y * (1 - dimObj.pivot.y)
    posY = math.min(math.max(posY, minH), maxH)

    self.PanelSkill.localPosition = Vector3(posX, posY, 0)
end

function XUiRaceMemberDetail:GetW(value)
    if not value or value <= 0 then
        return 0
    end
    return self._BarWidth * value / self._MaxValue
end

return XUiRaceMemberDetail