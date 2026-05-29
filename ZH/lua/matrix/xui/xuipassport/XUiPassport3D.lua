local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiPassport3D : XUiNode
---@field _Control XPassportControl
local XUiPassport3D = XClass(XUiNode, "XUiPassport3D")

function XUiPassport3D:OnStart(uiModel, isFirstOpenInThisActivity)
    local aspectRatioId = self:AdaptScreenAspectRatio()
    local farRoot = self.Transform:FindTransform("UiFarRoot")
    local nearRoot = self.Transform:FindTransform("UiNearRoot")
    self.CamFar = farRoot:FindTransform("UiFarCamera")
    self.CamNearMain = nearRoot:FindTransform("FashionCamNearMain")
    self.CamNear = nearRoot:FindTransform("FashionNearCamera")
    self.UiModel = uiModel

    -- UiFarCamera 常开
    self.CamFar.gameObject:SetActiveEx(true)

    self.PanelRoleModel = XUiPanelRoleModel.New(
        self.UiModel.UiModelParent,
        "UiPassport3D",
        nil,
        true,
        nil,
        true)

    if isFirstOpenInThisActivity then
        self:PlayAnimation("Start" .. aspectRatioId)
    end
end

-- 简易适配分辨率
function XUiPassport3D:AdaptScreenAspectRatio()
    self.FashionCamNearMain.gameObject:SetActiveEx(false)

    local currentCameraId = 1
    local ratios = string.Split(
        CS.XGame.ClientConfig:GetString("PassportModelAdapt"))

    local width  = CS.XUiManager.RealScreenWidth
    local height = CS.XUiManager.RealScreenHeight
    local realRatio = math.max(width, height) / math.min(width, height)

    for _, targetRatio in pairs(ratios) do
        if realRatio > tonumber(targetRatio) then
            currentCameraId = currentCameraId + 1
        else
            break
        end
    end

    self.FashionCamNearMain = self["FashionCamNearMain" .. currentCameraId]
    self.FashionCamNearMain.gameObject:SetActiveEx(true)
    return currentCameraId
end

function XUiPassport3D:OnDestroy()
    if self._NewBPCharacterAnimationSchedule1 then
        XScheduleManager.UnSchedule(self._NewBPCharacterAnimationSchedule1)
        self._NewBPCharacterAnimationSchedule1 = false
    end

    if self._NewBPCharacterAnimationSchedule2 then
        XScheduleManager.UnSchedule(self._NewBPCharacterAnimationSchedule2)
        self._NewBPCharacterAnimationSchedule2 = false
    end
end

function XUiPassport3D:SetModel(fashionId, fashionType)
    if not fashionType or fashionType == 0 then
        -- 普通时装：从 Fashion.tab 取 ResourcesId 加载角色模型
        local fashionTemplate = XFashionConfigs.GetFashionTemplate(fashionId)
        if not fashionTemplate then
            return
        end

        self.PanelRoleModel:UpdateCharacterResModel(
            fashionTemplate.ResourcesId,
            fashionTemplate.CharacterId,
            "UiPassport3D",
            nil)

    elseif fashionType == 1 then
        -- 武器投影：从 WeaponFashionRes.tab 取 ModelId 加载武器模型
        local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(fashionId, nil, "UiPassport3D")
        if not modelConfig or not modelConfig.ModelId then
            return
        end

        XModelManager.LoadWeaponModel(
            modelConfig.ModelId,
            self.UiModel.UiModelParent,
            modelConfig.TransformConfig,
            "UiPassport3D",
            nil,
            {gameObject = self.GameObject})

    elseif fashionType == 2 then
        -- FashionColor：从 FashionColor.tab 取 ResourcesId，再查 NpcRes 得到 ModelId
        local fashionColor = XMVCA.XFashion:GetFashionColorById(fashionId)
        local resId = fashionColor.ResourcesId
        if not XTool.IsNumberValid(resId) then
            return
        end

        self.PanelRoleModel:SetDefaultAnimation(fashionColor.PreviewAnimation)

        self.PanelRoleModel:UpdateCharacterModelByModelId(
            XMVCA.XCharacter:GetCharResModel(resId),
            nil,
            nil,
            "UiPassport3D",
            nil)
    end
end

-- UiPassportCard 购买页使用
function XUiPassport3D:ShowCardCamera(isActive)
    self.FashionCamNearest.gameObject:SetActive(isActive)
end

function XUiPassport3D:ShowTaskCamera(isActive)
    self.FashionCamTask.gameObject:SetActive(isActive)
end

return XUiPassport3D
