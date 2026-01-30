local XUiHyxGyroTest = XLuaUiManager.Register(XLuaUi, "UiHyxGyroTest")

function XUiHyxGyroTest:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnBack,function() self:Close() end)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, function() self:OnBtnHelpClick() end)

    self.SceneUiObj = self.UiSceneInfo.Transform:GetComponent("UiObject")
    self.RotationRoot = self.SceneUiObj:GetObject("RotationRoot")
    local root = self.UiModelGo.transform
    root:FindTransform("UiNearRoot").gameObject:SetActiveEx(false)
    root:FindTransform("UiRoot").gameObject:SetActiveEx(false)
    local farCamTransRoot = root:FindTransform("UiFarRoot")
    -- 隐藏所有子节点
    for i = 0, farCamTransRoot.childCount - 1 do
        farCamTransRoot:GetChild(i).gameObject:SetActiveEx(false)
    end
    farCamTransRoot:FindTransform("UiFarCamera").gameObject:SetActiveEx(true)
    farCamTransRoot:FindTransform("UiCamFarMain").gameObject:SetActiveEx(true)
    farCamTransRoot:FindTransform("UiCamFarMain").transform.localPosition = Vector3(0.2, 1.18, -30)
end

function XUiHyxGyroTest:OnBtnHelpClick()
    self.RotationRoot:Calibrate()
end

function XUiHyxGyroTest:OnEnable()
    local gyroData = self.RotationRoot:GetGyroData()
    print("========== hyx GyroData ==========")
    print("rotationRate: ", gyroData.rotationRate)
    print("rotationRateUnbiased: ", gyroData.rotationRateUnbiased)
    print("attitude: ", gyroData.attitude)
    print("gravity: ", gyroData.gravity)
    print("userAcceleration: ", gyroData.userAcceleration)
    print("accumulatedRotation: ", gyroData.accumulatedRotation)
    print("enabled: ", gyroData.enabled)
    print("updateInterval: ", gyroData.updateInterval)
    print("==================================")
end
