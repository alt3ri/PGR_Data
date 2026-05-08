local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiPassport3D : XUiNode
---@field _Control XPassportControl
local XUiPassport3D = XClass(XUiNode, "XUiPassport3D")

function XUiPassport3D:OnStart(uiModel)
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

    local activityId = tostring(self._Control:GetDefaultActivityId())
    local saveKey = "XUiPassport3D.OnStart.saveKey"
    local prevActivityId = XSaveTool.GetData(saveKey)
    if prevActivityId ~= activityId then
        XSaveTool.SaveData(saveKey, activityId)
        self.FashionCamNearMain.gameObject:SetActiveEx(false)
        self.FashionCamNew.gameObject:SetActiveEx(true)
        XScheduleManager.ScheduleNextFrame(function()
            self.FashionCamNearMain.gameObject:SetActiveEx(true)
        end)
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
        local resId = XMVCA.XFashion:GetFashionColorResourcesId(fashionId)
        if not XTool.IsNumberValid(resId) then
            return
        end
        local modelId = XMVCA.XCharacter:GetCharResModel(resId)
        self.PanelRoleModel:UpdateCharacterModelByModelId(modelId, nil, nil, "UiPassport3D", nil)
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
