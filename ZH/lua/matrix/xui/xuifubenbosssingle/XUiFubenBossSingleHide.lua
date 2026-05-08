---@class XUiFubenBossSingleHide : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleHide = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleHide")

function XUiFubenBossSingleHide:OnAwake()
    self:AutoAddListener()
    self.GridFeatureList = {}
    self.GridBuffDetailList = {}
end

function XUiFubenBossSingleHide:OnStart(sectionConf, bossStageConf, showInfoPage)
    self:Init(sectionConf, bossStageConf)
    self:SelectTab(showInfoPage)
end

function XUiFubenBossSingleHide:SelectTab(isInfoPage)
    if isInfoPage then
        self.BtnTab1:SetButtonState(CS.UiButtonState.Select)
        self.BtnTab2:SetButtonState(CS.UiButtonState.Normal)
        self.PanelInfo.gameObject:SetActiveEx(true)
        self.PanelFeatures.gameObject:SetActiveEx(false)
    else
        self.BtnTab1:SetButtonState(CS.UiButtonState.Normal)
        self.BtnTab2:SetButtonState(CS.UiButtonState.Select)
        self.PanelInfo.gameObject:SetActiveEx(false)
        self.PanelFeatures.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleHide:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTab1, function() self:SelectTab(true) end)
    XUiHelper.RegisterClickEvent(self, self.BtnTab2, function() self:SelectTab(false) end)
end

function XUiFubenBossSingleHide:Init(sectionConf, bossStageConf)
    self.SectionConf = sectionConf
    self.BossStageConf = bossStageConf
    self.GridFeatures.gameObject:SetActiveEx(false)
    self.GridBuffTitle.gameObject:SetActiveEx(false)
    self.GridBuffDetails.gameObject:SetActiveEx(false)
    self.IsHideBoss = self.BossStageConf.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide

    local buffDetailIds = self.BossStageConf.BuffDetailsId
    local featuresIds = self.BossStageConf.FeaturesId
    local showFeatures = featuresIds and #featuresIds > 0
    local showBuff = buffDetailIds and #buffDetailIds > 0

    if not showBuff and not showFeatures then
        return
    end

    self:InitInfoPage()
    self:SetFeatures(showFeatures)
    -- self:SetBuffTitle(showBuff)
    self:SetBuffDetails(showBuff)
end

function XUiFubenBossSingleHide:InitInfoPage()
    self.TxtBossName.text = self.BossStageConf.BossName
    self.TxtBossDesc.text = self.SectionConf.Desc

    for i, skillTitle in pairs(self.BossStageConf.SkillTitle) do
        local go = self.GridSkillInfo.gameObject
        if i ~= 1 then
            go = XUiHelper.Instantiate(go, go.transform.parent)
        end

        go.transform
            :FindTransform("UiTxtName")
            :GetComponent("Text")
            .text = skillTitle

        go.transform
            :FindTransform("UiTxtDesc")
            :GetComponent("Text")
            .text = self.BossStageConf.SkillDesc[i]
    end
end

function XUiFubenBossSingleHide:SetFeatures(showFeatures)
    if not showFeatures then
        return
    end

    for _, grid in pairs(self.GridFeatureList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #self.BossStageConf.FeaturesId do
        local grid = self.GridFeatureList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.GridBuffDetails)
            grid.transform:SetParent(self.PanelContent, false)
            self.GridFeatureList[i] = grid
        end

        local desc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
        local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")
        local bg = XUiHelper.TryGetComponent(grid.transform, "ImgfTriangleBg", "Image")
        local featuresCfg = XMVCA.XFuben:GetFeaturesById(self.BossStageConf.FeaturesId[i])
        desc.text = featuresCfg.Desc
        name.text = featuresCfg.Name
        icon:SetRawImage(featuresCfg.Icon)

        if featuresCfg.TriangleBg then
            self:SetUiSprite(bg, featuresCfg.TriangleBg)
        end


        grid.gameObject:SetActiveEx(true)
    end
end

-- function XUiFubenBossSingleHide:SetBuffTitle(showBuff)
--     if not showBuff then
--         return
--     end

--     local grid = CS.UnityEngine.Object.Instantiate(self.GridBuffTitle)
--     grid.transform:SetParent(self.PanelContent, false)
--     local hide = XUiHelper.TryGetComponent(grid.transform, "PanelBuffHideTitle")
--     local normal = XUiHelper.TryGetComponent(grid.transform, "PanelBuffTitle")
--     hide.gameObject:SetActiveEx(self.IsHideBoss)
--     normal.gameObject:SetActiveEx(not self.IsHideBoss)
--     grid.gameObject:SetActiveEx(true)
-- end

function XUiFubenBossSingleHide:SetBuffDetails(showBuff)
    if not showBuff then
        return
    end

    for _, grid in pairs(self.GridBuffDetailList) do
        grid.gameObject:SetActiveEx(false)
    end

    for i = 1, #self.BossStageConf.BuffDetailsId do
        local grid = self.GridBuffDetailList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.GridBuffDetails)
            grid.transform:SetParent(self.PanelContent, false)
            self.GridBuffDetailList[i] = grid
        end

        local desc = XUiHelper.TryGetComponent(grid.transform, "TxtDesc", "Text")
        local name = XUiHelper.TryGetComponent(grid.transform, "TxtName", "Text")
        local icon = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")
        local bg = XUiHelper.TryGetComponent(grid.transform, "ImgfTriangleBg", "Image")
        local buffDetailsCfg = XFubenBabelTowerConfigs.GetBabelBuffConfigs(self.BossStageConf.BuffDetailsId[i])
        desc.text = buffDetailsCfg.Desc
        name.text = buffDetailsCfg.Name
        icon:SetRawImage(buffDetailsCfg.BuffBg)
        if buffDetailsCfg.BuffTriangleBg then
            self:SetUiSprite(bg, buffDetailsCfg.BuffTriangleBg)
        end

        grid.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleHide:OnBtnBackClick()
    self:Close()
end