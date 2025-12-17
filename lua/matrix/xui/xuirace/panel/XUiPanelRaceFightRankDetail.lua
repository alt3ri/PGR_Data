---@class XUiPanelRaceFightRankDetail : XUiNode 角色详情
---@field Parent XUiRacePredict
---@field _Control XRaceControl
local XUiPanelRaceFightRankDetail = XClass(XUiNode, "XUiPanelRaceFightRankDetail")
local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

function XUiPanelRaceFightRankDetail:OnStart()
    self._SignalSkillBallUi = {}
    self._SignalSkillBallCounUi = {}
    self._SkillDefaultCount = {}
    self._SkillCount = {}
    self._RankUI = {}
    self._Scene = XMVCA.XScene:GetScene(SceneIds.XRaceScene)
    self._rankFinishCount = 0
    self._rankData = {}
end

function XUiPanelRaceFightRankDetail:InitRace(count)
    for i = 1, count do
        self._rankData[i] = {
            Rank = i,
        }
    end
end

function XUiPanelRaceFightRankDetail:UpdateRank(selectIndex, skipAnim, isShowForce)
    local isShow = isShowForce or false
    local rankCount = self._Scene:GetRankFinishCount()
    if rankCount ~= self._rankFinishCount then
        local rankData = self._Scene:GetRankData()
        local add = 0
        for i = 0, rankData.Count - 1 do
            local rankData = rankData[i]
            local rankInfo = self._rankData[i + 1] or {}
            rankInfo.CharacterId = rankData.CharacterId
            rankInfo.Rank = rankData.Rank
            rankInfo.PassTime = rankData.PassTime
            rankInfo.AddTime = add
            if add == 0 then
                add = rankData.PassTime
            end
        end
        self._rankFinishCount = rankCount
    end

    if not isShow then
        for i = 1, #self._rankData do
            local rankData = self._rankData[i]
            if self._rankFinishCount >= rankData.Rank and rankData.CharacterId == self._characterId then
                isShow = true
                break
            end
        end
    end
    
    if isShow then
        self:ShowInfo(isShow, selectIndex, skipAnim)
        XTool.UpdateDynamicItemByUiCache(self._RankUI, self._rankData, self.GridRankData.transform.parent, nil, self)
        for i = 1, #self._RankUI do
            local rankInfo = self._rankData[i]
            local ui = self._RankUI[i]
            if self._rankFinishCount >= i and rankInfo.CharacterId and rankInfo.AddTime then
                local finishTime = math.floor(rankInfo.PassTime)
                local lastFinishTime = math.floor(rankInfo.AddTime)
                ui.TxtTime01.text = self._Control:GetPassTimeStr(finishTime)
                if rankInfo.AddTime > 0 then
                    ui.TxtTime02.text = "+" .. self._Control:GetPassTimeStr(finishTime - lastFinishTime)
                else
                    ui.TxtTime02.text = ""
                end

                local cCfg = self._Control:GetRaceCharacterById(rankInfo.CharacterId)
                ui.RImgHead:SetRawImage(cCfg.Icon)
                ui.TxtName.text = cCfg.Name
                
                ui.PanelDetail.gameObject:SetActive(true)
                ui.PanelNone.gameObject:SetActive(false)
            else
                ui.PanelDetail.gameObject:SetActive(false)
                ui.PanelNone.gameObject:SetActive(true)
            end
            ui.ImgRank:SetSprite(self._Control:GetClientConfig("RankNumIcon" .. i))
        end
    else
        if #self._RankUI > 0 then
            XTool.UpdateDynamicItemByUiCache(self._RankUI, {}, self.GridRankData.transform.parent, nil, self)
        end
        self:ShowInfo(isShow, selectIndex, skipAnim)
    end
end

function XUiPanelRaceFightRankDetail:ShowInfo(isShow, selectIndex, skipAnim)
    if self.GameObject.activeSelf == self.GameObject then
        return
    end
    if isShow then
        if self._selectIndex ~= selectIndex then
            if not skipAnim then
                self.Parent:PlayRaceDataEnable()
            end
            self._selectIndex = selectIndex
        end
    else
        self._selectIndex = nil
    end
    self.GameObject:SetActive(isShow)
end

function XUiPanelRaceFightRankDetail:SelectIndex(index, characterId)
    if self._index == index then
        return
    end
    self._index = index
    self._characterId = characterId
    self:UpdateRank(index)
end

return XUiPanelRaceFightRankDetail
