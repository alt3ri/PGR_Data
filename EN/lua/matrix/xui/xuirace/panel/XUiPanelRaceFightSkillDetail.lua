---@class XUiPanelRaceFightSkillDetail : XUiNode 角色详情
---@field Parent XUiRacePredict
---@field _Control XRaceControl
local XUiPanelRaceFightSkillDetail = XClass(XUiNode, "XUiPanelRaceFightSkillDetail")

function XUiPanelRaceFightSkillDetail:OnStart()
    self.GridSkillBall.gameObject:SetActive(false)
    self._SignalSkillBallUi = {}
    self._SignalSkillBallCounUi = {}
    self._SkillDefaultCount = {}
    self._SkillCount = {0,0,0,0}
end

function XUiPanelRaceFightSkillDetail:OnGetLuaEvents()
    return { XEventId.EVENT_RACE_GAME_POWER_UPDATE, }
end

function XUiPanelRaceFightSkillDetail:OnNotify(event, actorIndex, powerIndex, powerCnt)
    if actorIndex == self._index and event == XEventId.EVENT_RACE_GAME_POWER_UPDATE then
        self:UpdatePower()
    end
end

function XUiPanelRaceFightSkillDetail:UpdatePower()
    if not self._skConfig then return end
    
    local hasShow = self._Control:GetSkillShowList(self._index, self._skConfig)
    local singalBallCosts = self._skConfig.SignalBallCosts
    local cellIndex = 1
    for i = 1, 5 do
        local signalBallIndex = i == 5 and 0 or i
        local needCnt = singalBallCosts[signalBallIndex] or 0
        if needCnt > 0 then
            for j = 1, needCnt do
                local cell = self._SignalSkillBallUi[cellIndex]
                if not cell then
                    local go = CS.UnityEngine.Object.Instantiate(self.GridSkillBall, self.GridSkillBall.transform.parent)
                    cell = XUiNode.New(go, self)
                    self._SignalSkillBallUi[cellIndex] = cell
                end
                local iconPath = self._Control:GetRaceSignalBallIconById(signalBallIndex)
                cell.Off:SetRawImage(iconPath)
                cell.On:SetRawImage(iconPath)
                cell:Open()
                cell.On.gameObject:SetActive(j <= (hasShow[signalBallIndex] or 0))
                cellIndex = cellIndex + 1
            end
        end
    end
    for i = cellIndex, #self._SignalSkillBallUi do
        self._SignalSkillBallUi[i]:Close()
    end

    for i = 1, 4 do
        self._SignalSkillBallCounUi[i].TxtNum.text = "x" .. self._Control:GetRacePowerCount(self._index, i) or 0
    end
end

function XUiPanelRaceFightSkillDetail:SetRaceId(id, index)
    self._index = index
    self._config = self._Control:GetRaceCharacterById(id)
    
    self.RImgHead:SetRawImage(self._config.Icon)
    self.TxtName.text = self._config.Name
    self.TxtNum.text = self._Control:GetRoadNameByIndex(index)

    local skillConfig1 = self._Control:GetRaceCharacterSkillById(self._config.NormalSkill)
    self.TxtSSName.text = skillConfig1.Name
    self.TxtSSkillDetail.text = skillConfig1.Desc
    self._skConfig = self._Control:GetRaceCharacterSkillById(self._config.UltraSkill)
    self.TxtBSName.text = self._skConfig.Name
    self.TxtBSkillDetail.text = self._skConfig.Desc

    XTool.UpdateDynamicItemByUiCache(self._SignalSkillBallCounUi, self._SkillCount, self.GridSkillCountBall.transform.parent, nil, self, 1)

    for i = 1, 4 do
        local iconPath1 = self._Control:GetRaceSignalBallIconById(i)
        self._SignalSkillBallCounUi[i].ImgIconBall:SetRawImage(iconPath1)
    end

    self:UpdatePower()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Transform)
end

return XUiPanelRaceFightSkillDetail
