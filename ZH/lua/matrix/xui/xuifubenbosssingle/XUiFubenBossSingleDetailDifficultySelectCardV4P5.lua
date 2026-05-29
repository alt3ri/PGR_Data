local XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff = require(
    "XUi/XUiFubenBossSingle/XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff")

---@class XUiFubenBossSingleDetailDifficultySelectCard : XUiNode

local XUiFubenBossSingleDetailDifficultySelectCardV4P5 =
    XClass(XUiNode, "XUiFubenBossSingleDetailDifficultySelectCard")

function XUiFubenBossSingleDetailDifficultySelectCardV4P5:OnStart(
    stageInfo,
    bossConf,
    onClickCallback,
    playSmallAnimation,
    playBigAnimation)

    self.TxtDifficulty.text = stageInfo.DifficultyDesc
    self.GameObject:GetComponent("XUiButton").CallBack = onClickCallback

    local control = self._Control
    local stageId = stageInfo.StageId
    local score = stageInfo.Score + control:GetBaseScoreByStageId(stageId)
    local curScore = self.Parent:_GetStageCurrentScore(stageInfo.StageId)
    local showHistoryTeam = self.Parent:_ShowHistoryTeam()

    self.TxtMyScore.text = tostring(curScore)
    self.TxtScoreMax.text = "/" .. score

    if not showHistoryTeam then
        local txtTeam = self.Transform:FindTransform("TxtTeam")
        if txtTeam then txtTeam.gameObject:SetActiveEx(false) end

        if self.ListRole then
            self.ListRole.gameObject:SetActiveEx(false)
        end
    end

    if self.GridRole and self.ListRole and showHistoryTeam then
        local characterIds = self.Parent:_GetHistoryTeam(stageId)

        local hasRecord = false
        self.GridRole.gameObject:SetActiveEx(false)

        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)

        if characterIds then
            for _, charId in pairs(characterIds) do
                hasRecord = true

                local go = XUiHelper.Instantiate(
                    self.GridRole.gameObject,
                    self.ListRole.transform)

                go:SetActiveEx(true)

                go.transform
                    :FindTransform("UiRImgRole")
                    :GetComponent("RawImage")
                    :SetRawImage(characterAgency
                        :GetCharSmallHeadIcon(charId))
            end
        end

        if not hasRecord then
            self.TxtEmpty.gameObject:SetActiveEx(true)
        end
    end

    -- 显示buffs
    if self.ContentGridBuffs then
        self:_RefreshBuffs(bossConf)
    end

    if playSmallAnimation then
        self:PlayAnimation("Small")
    end

    if playBigAnimation then
        self:PlayAnimation("Big")
    end
end

function XUiFubenBossSingleDetailDifficultySelectCardV4P5:_RefreshBuffs(bossConf)
    local gridBuffsArgs = {}

    if bossConf.FeaturesId then
        for _, featureId in pairs(bossConf.FeaturesId) do
            local feature = XMVCA.XFuben:GetFeaturesById(featureId)

            table.insert(gridBuffsArgs, {
                feature.Name,
                feature.Icon,
                feature.Desc,
                feature.TriangleBg
            })
        end
    end

    if bossConf.BuffDetailsId then
        for _, buffId in pairs(bossConf.BuffDetailsId) do
            local buff = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)

            table.insert(gridBuffsArgs, {
                buff.Name,
                buff.BuffBg,
                buff.Desc,
                buff.BuffTriangleBg
            })
        end
    end

    self._BuffGrids = self._BuffGrids or {}

    XTool.SetDataForGenericGrid(
        self._BuffGrids,
        gridBuffsArgs,
        self.GridBuffDetails.gameObject,
        self.ContentGridBuffs,
        self,
        XUiGridFubenBossSingleDetailDifficultySelectCardV4P5Buff)
end

return XUiFubenBossSingleDetailDifficultySelectCardV4P5
