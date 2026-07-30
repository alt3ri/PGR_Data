local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelMusicScene = require("XUi/XUiMusicScene/XUiPanelMusicScene")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CameraIndex = {
    Main = 1,
    MainEnter = 2,
    MainChatEnter = 3,
    MainRightMidSecondEnter = 4,
    MainLeftCalendarEnter = 5,
}

---@class XUiPaintingExperiencePassV4P2 : XLuaUi
local XUiPaintingExperiencePassV4P2 = XLuaUiManager.Register(XLuaUi, "UiPaintingExperiencePassV4P2")

function XUiPaintingExperiencePassV4P2:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, XLuaUiManager.RunMain))
    self.BtnStory:AddEventListener(handler(self, self.ShowDesc))
    self.BtnCloseTips:AddEventListener(handler(self, self.HideDesc))
    self.BtnSingleEnter:AddEventListener(handler(self, self.OnBtnSingleEnterClick))
    self.BtnPurchase:AddEventListener(handler(self, self.OnBtnPurchase))
    self.BtnPurchaseCombination:AddEventListener(handler(self, self.OnBtnPurchaseCombinationClick))
    self.BtnPurchaseScene:AddEventListener(handler(self, self.OnBtnPurchaseSceneClick))
    self.BtnPurchaseSkin:AddEventListener(handler(self, self.OnBtnPurchaseSkinClick))
    self.BtnArrowLeft:AddEventListener(handler(self, self.OnBtnArrowLeftClick))
    self.BtnArrowRight:AddEventListener(handler(self, self.OnBtnArrowRightClick))
    self.BtnSwitch:AddEventListener(handler(self, self.OnBtnSwitchClick))
end

---@param isShowSwitch boolean 是否显示切换按钮
function XUiPaintingExperiencePassV4P2:OnStart(trialLevelId, isShowSwitch)
    self.RewardPanelList = {}
    self.IsShowSwitch = isShowSwitch
    self.CurLevelId = trialLevelId
    self:InitData()
    self:InitView()
end

function XUiPaintingExperiencePassV4P2:OnDestroy()
    if self.MusicScene then
        self.MusicScene:OnDestroy()
    end
end

function XUiPaintingExperiencePassV4P2:InitData()
    self.TrialLevelInfo = XDataCenter.FubenExperimentManager.GetFashionTrailLevelById(self.CurLevelId)
    self.LevelIds = {}
    local levelCfgs = XDataCenter.FubenExperimentManager.GetTrialLevelByGroupID(self.TrialLevelInfo.GroupID)
    for i, level in ipairs(levelCfgs) do
        if level.Id == self.CurLevelId then
            self.CurLevelIndex = i
        end
        table.insert(self.LevelIds, level.Id)
    end
    self.LevelCount = #self.LevelIds
end

function XUiPaintingExperiencePassV4P2:InitView()
    self.BtnArrowLeft.gameObject:SetActiveEx(self.IsShowSwitch and self.LevelCount > 1)
    self.BtnArrowRight.gameObject:SetActiveEx(self.IsShowSwitch and self.LevelCount > 1)

    self:UpdateView()
end

function XUiPaintingExperiencePassV4P2:SwitchRole(isLeft)
    if isLeft then
        self.CurLevelIndex = self.CurLevelIndex == 1 and self.LevelCount or self.CurLevelIndex - 1
    else
        self.CurLevelIndex = self.CurLevelIndex >= self.LevelCount and 1 or self.CurLevelIndex + 1
    end
    self.CurLevelId = self.LevelIds[self.CurLevelIndex]

    local nextUiName = XDataCenter.FubenExperimentManager:GetPaintingExperiencePassName(self.CurLevelId)
    if self.Name == nextUiName then
        self.TrialLevelInfo = XDataCenter.FubenExperimentManager.GetFashionTrailLevelById(self.CurLevelId)
        self:UpdateView()
    else
        XDataCenter.FubenExperimentManager:PopThenOpenPaintingExperiencePass(self.CurLevelId, self.IsShowSwitch)
    end
end

function XUiPaintingExperiencePassV4P2:UpdateView()
    self.SkipIds = {}
    local skipIds = XDataCenter.FashionManager.GetFashionSkipIdParams(self.TrialLevelInfo.FashionId)
    if skipIds then
        for _, v in pairs(skipIds) do
            if XFunctionManager.CheckSkipInDuration(v, false) then
                table.insert(self.SkipIds, v)
            end
        end
    end
    
    self:UpdateRoleInfo()
    self:UpdateFirstReward()
    self:UpdateDes()
    self:UpdateSwitchScene()
end

function XUiPaintingExperiencePassV4P2:UpdateRoleInfo()
    self.IsExistScene = false
    self.TrialSceneInfo = XFubenExperimentConfigs.GetSceneShowConfig(self.CurLevelId)
    
    if self.TrialSceneInfo and XTool.IsNumberValid(self.TrialSceneInfo.BackgroundId) then
        local conditionId = self.TrialSceneInfo.Condition
        local timeId = self.TrialSceneInfo.TimeId
        local isCond = not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId, true)
        if isCond and isInTime then
            self.IsExistScene = true
        end
    end
    self.IsShow2D = not self.IsExistScene --有场景则默认显示场景

    self.TxtTitle.text = self.TrialLevelInfo.Name
    if self.TrialLevelInfo.DetailBackGroundIco then
        self.ImgFullScreen:SetRawImage(self.TrialLevelInfo.DetailBackGroundIco)
    end
    if self.TrialLevelInfo.HeadIcon then
        self.RImgNandu:SetRawImage(self.TrialLevelInfo.HeadIcon)
    end
    if self.IsExistScene then
        self.BtnSwitch:SetButtonState(self.IsShow2D and XUiButtonState.Select or XUiButtonState.Normal)
    end
    self:UpdatePurchase()
end

function XUiPaintingExperiencePassV4P2:UpdatePurchase()
    local isBigWorldMainBusiness = XMVCA.XBigWorldGamePlay:IsInGame() and XMVCA.XBigWorldFunction:GetShieldOfMainBusiness()
    local isNormal, isSpecialGroup, isSpecialScene, isSpecialFashion

    if not isBigWorldMainBusiness then
        local specialUiType = self.TrialSceneInfo and self.TrialSceneInfo.SkipUiType or nil
        local specialParams = self.TrialSceneInfo and self.TrialSceneInfo.SkipFunctionals or nil
        --普通涂装购买
        isNormal = not self.IsExistScene and #self.SkipIds > 0
        --特殊涂装购买组合包
        isSpecialGroup = self.IsExistScene and specialUiType == 1
        --特殊涂装购买场景
        isSpecialScene = self.IsExistScene and specialUiType == 2 and specialParams and XTool.IsNumberValid(specialParams[1])
        --特殊涂装购买涂装
        isSpecialFashion = self.IsExistScene and specialUiType == 2 and specialParams and XTool.IsNumberValid(specialParams[2])
    end

    self.BtnPurchase.gameObject:SetActiveEx(isNormal)
    self.BtnPurchaseCombination.gameObject:SetActiveEx(isSpecialGroup)
    self.BtnPurchaseScene.gameObject:SetActiveEx(isSpecialScene)
    self.BtnPurchaseSkin.gameObject:SetActiveEx(isSpecialFashion)
end

function XUiPaintingExperiencePassV4P2:UpdateFirstReward()
    self.GridCommon.gameObject:SetActiveEx(false)
    local stage = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.SingStageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.TrialLevelInfo.SingStageId)
    local rewardId = 0
    local IsFirst = false
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    rewardId = stage.FirstRewardShow
    if not stageInfo.Passed then
        IsFirst = true
    end

    if not rewardId or rewardId == 0 then
        return
    end

    local rewardsList = XRewardManager.GetRewardList(rewardId)
    if not rewardsList then
        return
    end

    for i = 1, #rewardsList do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.gameObject:SetActiveEx(true)
            ui.transform:SetParent(self.PanelDropContent, false)
            panel = XUiGridCommon.New(self, ui)
            table.insert(self.RewardPanelList, panel)
        end
        local temp = {
            ShowReceived = not IsFirst
        }
        panel:Refresh(rewardsList[i], temp)
    end
end

function XUiPaintingExperiencePassV4P2:UpdateDes()
    self.TxtDes.text = string.gsub(self.TrialLevelInfo.SingleDescription, "\\n", "\n")
end

function XUiPaintingExperiencePassV4P2:UpdateSwitchScene()
    self.ImgFullScreen.gameObject:SetActiveEx(self.TrialLevelInfo.DetailBackGroundIco and self.IsShow2D)
    self.BtnSwitch.gameObject:SetActiveEx(self.IsExistScene)

    local isShowScene = self.IsExistScene and not self.IsShow2D
    local backgroundId = self.TrialSceneInfo and self.TrialSceneInfo.BackgroundId or nil
    if not isShowScene or not XTool.IsNumberValid(backgroundId) then
        if self.UiSceneInfo then
            self.UiSceneInfo:SetActive(false)
        end
        if self.CurBackgroundId ~= backgroundId and self.MusicScene then
            self.MusicScene:Stop()
        end
        return
    end

    if self.CurBackgroundId == backgroundId and self.UiSceneInfo and not XTool.UObjIsNil(self.UiSceneInfo.Transform) then
        self.UiSceneInfo:SetActive(true)
        self:UpdateModelRole()
        self:PlayMusicScene(backgroundId)
        return
    end

    local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(backgroundId)
    local scenePath, _ = XSceneModelConfigs.GetSceneAndModelPathById(sceneTemplate.SceneModelId)
    local modelPath = self:GetDefaultUiModelUrl()
    self.CurBackgroundId = backgroundId

    self:LoadUiScene(scenePath, modelPath, function()
        self.UiSceneInfo:SetActive(true)
        self:InitCamera()
        self:InitModelRole()
        self:PlayMusicScene(backgroundId)
        XUiHelper.SetSceneAnimHandler(self)
    end, false)
end

function XUiPaintingExperiencePassV4P2:ShowDesc()
    self.PanelNor.gameObject:SetActiveEx(true)
end

function XUiPaintingExperiencePassV4P2:HideDesc()
    self.PanelNor.gameObject:SetActiveEx(false)
end

function XUiPaintingExperiencePassV4P2:SkipFunction(skipId)
    if XLuaUiManager.IsUiLoad("UiFashionDetail") or XLuaUiManager.IsUiLoad("UiFashionSuitDetail")
            or XLuaUiManager.IsStackUiOpen("UiFashionDetail") or XLuaUiManager.IsStackUiOpen("UiFashionSuitDetail") then
        self:Close()
    else
        local fromMsg = XDataCenter.FubenExperimentManager:GetPaintingExperiencePassName(self.CurLevelId)
        XFunctionManager.SkipInterface(skipId, fromMsg)
    end
end

function XUiPaintingExperiencePassV4P2:OnBtnSingleEnterClick()
    if self.TrialLevelInfo.TimeId and self.TrialLevelInfo.TimeId ~= 0 then
        if XFunctionManager.CheckInTimeByTimeId(self.TrialLevelInfo.TimeId) then
            XMVCA.XFuben:OpenUiBattleRoleRoom(self.TrialLevelInfo.SingStageId)
        else
            XUiManager.TipText("ActivityBranchNotOpen")
        end
    else
        XMVCA.XFuben:OpenUiBattleRoleRoom(self.TrialLevelInfo.SingStageId)
    end
end

function XUiPaintingExperiencePassV4P2:OnBtnPurchase()
    self:SkipFunction(self.SkipIds[1])
end

function XUiPaintingExperiencePassV4P2:OnBtnPurchaseCombinationClick()
    self:SkipFunction(self.TrialSceneInfo.SkipFunctionals[1])
end

function XUiPaintingExperiencePassV4P2:OnBtnPurchaseSceneClick()
    self:SkipFunction(self.TrialSceneInfo.SkipFunctionals[1])
end

function XUiPaintingExperiencePassV4P2:OnBtnPurchaseSkinClick()
    self:SkipFunction(self.TrialSceneInfo.SkipFunctionals[2])
end

function XUiPaintingExperiencePassV4P2:OnBtnArrowLeftClick()
    self:SwitchRole(true)
end

function XUiPaintingExperiencePassV4P2:OnBtnArrowRightClick()
    self:SwitchRole(false)
end

function XUiPaintingExperiencePassV4P2:OnBtnSwitchClick()
    self.IsShow2D = self.BtnSwitch.ButtonState == CS.UiButtonState.Select
    self:UpdateSwitchScene()
end

--region 场景

function XUiPaintingExperiencePassV4P2:InitCamera()
    self.CameraFar = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamFarMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamFarMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamFarMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamFarMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamFarTolist"),
    }
    self.CameraNear = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamNearMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamNearMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamNearMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamNearMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamNearTolist"),
    }
end

---执行音乐场景相关逻辑
function XUiPaintingExperiencePassV4P2:PlayMusicScene(backgroundId)
    if not self.MusicScene then
        ---@type XUiPanelMusicScene
        self.MusicScene = XUiPanelMusicScene.New(self)
        self.MusicScene:SetForceFullMusic()
        self.MusicScene:SetPlayExclusiveMusic()
    end
    self.MusicScene:Play(backgroundId, self.UiSceneInfo.Transform)
end

---加载角色和武器模型
function XUiPaintingExperiencePassV4P2:InitModelRole()
    ---@type XUiPanelRoleModel
    self.RoleModelPanel = XUiPanelRoleModel.New(self.UiModel.UiModelParent.transform, self.Name, false, true)
    self:UpdateModelRole()
end

function XUiPaintingExperiencePassV4P2:UpdateModelRole()
    local fashionId = self.TrialLevelInfo.FashionId
    local characterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
    self.RoleModelPanel:UpdateCharacterModel(characterId, nil, self.Name, function(_)
        self.RoleModelPanel:PlayAnima(self.TrialSceneInfo.StandbyAnimName, true)
    end, nil, fashionId, nil, nil, nil, true, self.TrialSceneInfo.WeaponFashionId)
    self:UpdateCamera(CameraIndex.Main)
end

function XUiPaintingExperiencePassV4P2:UpdateCamera(camera)
    if not self.CameraFar or not self.CameraNear then
        return
    end
    for _, cameraIndex in pairs(CameraIndex) do
        local nearCamera = self.CameraNear[cameraIndex]
        if not XTool.UObjIsNil(nearCamera) then
            nearCamera.gameObject:SetActive(cameraIndex == camera)
        end
        local farCamera = self.CameraFar[cameraIndex]
        if not XTool.UObjIsNil(farCamera) then
            farCamera.gameObject:SetActive(cameraIndex == camera)
        end
    end
end

--endregion

return XUiPaintingExperiencePassV4P2
