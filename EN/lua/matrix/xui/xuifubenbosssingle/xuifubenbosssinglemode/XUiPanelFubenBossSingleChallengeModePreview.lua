local XUiPanelFubenBossSingleChallengeModePreview = XClass(
    XUiNode,
    "XUiPanelFubenBossSingleModePreview")

function XUiPanelFubenBossSingleChallengeModePreview:OnStart()
    local pool = XPool.New(
        function()
            return XUiHelper.Instantiate(
                self.GridSelectedMode.gameObject,
                self.ListSelectedMode)
        end,
        function(toRelease)
            toRelease:SetActiveEx(false)
        end,
        false)

    self.GridSelectedMode.gameObject:SetActiveEx(false)
    self._PoolGridSelectedMode = pool
    self._ArenaGridSelectedMode = {}
end

function XUiPanelFubenBossSingleChallengeModePreview:_CreateIcon(icon)
    local obj = self._PoolGridSelectedMode:GetItemFromPool()
    local order = self._ComponentInstanceCount
    self._ComponentInstanceCount = self._ComponentInstanceCount + 1
    table.insert(self._ArenaGridSelectedMode, obj)
    obj.transform:SetSiblingIndex(order)
    obj:SetActiveEx(true)

    local iconUiObj = {}
    XTool.InitUiObjectByInstance(obj:GetComponent("UiObject"), iconUiObj)
    iconUiObj.RImgIcom:SetRawImage(icon)
end

-- 传入 XBossSingleDefine @ class BossSingleChallengeBuffGroup
function XUiPanelFubenBossSingleChallengeModePreview:SetData(
    bossSingleChallengeBuffGroup)

    self:_Clear()

    if not bossSingleChallengeBuffGroup then
        self.TransformEmpty.gameObject:SetActiveEx(true)
        self.TransformScoreUp.gameObject:SetActiveEx(false)
        return
    end

    local succ, buffGroupIndexes =
        XMVCA.XFubenBossSingle:TryGetBossSingleChallengeBuffGroupConfigByBuffGroupId(
            bossSingleChallengeBuffGroup.BuffGroupId)

    if not succ then buffGroupIndexes = {} end

    local empty = true
    local allScoreUp = 0

    if bossSingleChallengeBuffGroup.BuffChoices then
        for _, buffGroupIndex in pairs(buffGroupIndexes) do
            local buffGroupIndexId = buffGroupIndex.Index
            local selectedBuffIndex = bossSingleChallengeBuffGroup.BuffChoices[buffGroupIndexId]

            if selectedBuffIndex then
                local buffId = buffGroupIndex.Buff[selectedBuffIndex]
                local buff = XMVCA.XFubenBossSingle:GetFeatureConfigById(buffId)
                allScoreUp = allScoreUp + buff.ScoreRate
                self:_CreateIcon(buff.Icon)
                empty = false
            end
        end
    end

    self.TransformEmpty.gameObject:SetActiveEx(empty)
    self.TransformScoreUp.gameObject:SetActiveEx(allScoreUp > 0)
    self.TxtScoreUp.text = string.format("+%.1f%%", allScoreUp / 100)
end

function XUiPanelFubenBossSingleChallengeModePreview:_Clear()
    local pool = self._PoolGridSelectedMode

    for _, instance in pairs(self._ArenaGridSelectedMode) do
        pool:ReturnItemToPool(instance)
    end

    self._ArenaGridSelectedMode = {}
    self._ComponentInstanceCount = 0
end

return XUiPanelFubenBossSingleChallengeModePreview
