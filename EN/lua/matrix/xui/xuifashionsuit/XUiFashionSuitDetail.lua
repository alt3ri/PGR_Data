---@class XUiFashionSuitDetail : XLuaUi 涂装详情（三级界面）
---@field _Control XFashionSuitControl
local XUiFashionSuitDetail = XLuaUiManager.Register(XLuaUi, "UiFashionSuitDetail")

local XUiPanelLackResources = require("XUi/XUiSubPackage/XUiPanel/XUiPanelLackResources")
local XUiPanelFashionDetail = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionDetail")
local SkipType = XEnumConst.FashionSuit.SkipType
local CameraIndex = {
    Normal = 1,
    Near = 2,
    Far = 3,
    FarNormal = 4,
    Hide = 5,
    FarHide = 6,
    HideNear = 7,
    FarHideNear = 8,
}

function XUiFashionSuitDetail:OnAwake()
    self.BtnPic.CallBack = handler(self, self.OnBtnPicClick)
    self.BtnHideUi.CallBack = handler(self, self.OnBtnHideUiClick)
    self.BtnShowUi.CallBack = handler(self, self.OnBtnShowUiClick)
    self.BtnLensIn.CallBack = handler(self, self.OnBtnLensInClick)
    self.BtnLensOut.CallBack = handler(self, self.OnBtnLensOutClick)
    self.BtnLast.CallBack = handler(self, self.OnBtnLastClick)
    self.BtnNext.CallBack = handler(self, self.OnBtnNextClick)
    self.BtnTipsClose.CallBack = handler(self, self.OnBtnTipsCloseClick)
    self.BtnPlay.CallBack = handler(self, self.OnBtnPlayClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacterHight, self.OnSliderCharacterHightChanged)

    -- PanelLackResources 初始化
    if self.PanelLackResources then
        self._PanelLackRes = XUiPanelLackResources.New(self.PanelLackResources, self)
    end
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
end

function XUiFashionSuitDetail:GetContextUi()
    return self._Context
end

---@return XUiHelperFashionSuit
function XUiFashionSuitDetail:GetHelper()
    return self._Helper
end


---@param id number 角色涂装Id、武器涂装Id（WeaponFashion表里的Id，非itemId）
---@param updateCb fun(rewardList:table) 采购界面更新回调
function XUiFashionSuitDetail:OnStart(fashionSuitId, id, skipType, updateCb)
    self._SuitId = fashionSuitId
    self._SkipType = skipType
    self._UpdateCb = updateCb
    self._SuitConfig = self._Control:GetFashionSuitById(fashionSuitId)
    self._FashionCount = #self._SuitConfig.FashionIds
    self._IsModelDrag = self._Control:GetIntClientConfig("IsModelDrag") == 1
    ---@type XFashionContext
    self._Context = require("XModule/XFashionSuit/Data/XFashionContext").New()
    self._Context:InitData(id)
    ---@type XUiHelperFashionSuit
    self._Helper = require("XUi/XUiFashionSuit/Helper/XUiHelperFashionSuit").New()
    self._Helper:InitData(self._Context)
    ---@type XUiPanelFashionSuitButtonGroup

    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
    local panelDetailGo = self.PanelFashionDetailRoot:LoadPrefabEx(uiConfig.PanelFashionDetailPrefabPath)
    self._SuitDetail = XUiPanelFashionDetail.New(panelDetailGo,self,self._SuitId)
    self._SuitDetail:Open()
    self:InitModelHandler()
    self:InitSceneRoot(id)
    self:InitView()
    self:StartTimer()

    if self._SuitId == tonumber(self._Control:GetClientConfig("SpecialBackBtn")) then
        XUiHelper.NewPanelTopControl(self, self.TopControlWhite2)
        self.TopControlWhite.gameObject:SetActiveEx(false)
        self.TopControlWhite2.gameObject:SetActiveEx(true)
    else
        XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
        self.TopControlWhite2.gameObject:SetActiveEx(false)
        self.TopControlWhite.gameObject:SetActiveEx(true)

    end
    XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa }, self.PanelSpecialTool, self)
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_CLEAR_DATA, self.SignGetShopInfo, self)
end

function XUiFashionSuitDetail:OnEnable()
    -- 从采购界面回来时，礼包数据会被清空
    if self._ReqShopInfo then
        XDataCenter.PurchaseManager.LBInfoDataReq(function()
            self:UpdateView()
        end)
    else
        self:UpdateView()
    end
    self._ReqShopInfo = false

    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    self:_AddConsumeCountListener()
end

function XUiFashionSuitDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    self:_RemoveConsumeCountListener()
end

--历史遗留逻辑：XPurchaseManager.ClearData和UiPurchase绑定
--在进入试玩时，涂装套装界面先于采购界面关闭，所以监听不到事件
function XUiFashionSuitDetail:OnReleaseInst()
    return self._ReqShopInfo or XLuaUiManager.IsUiLoad("UiPurchase")
end

function XUiFashionSuitDetail:OnResume(reqShopInfo)
    self._ReqShopInfo = reqShopInfo
end

function XUiFashionSuitDetail:OnDestroy()
    if self._PanelDetailPrefabPath then
        self._Control:GetLoader():Unload(self._PanelDetailPrefabPath)
        self._PanelDetailPrefabPath = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_CLEAR_DATA, self.SignGetShopInfo, self)
end

--- 购买货币数量变化时刷新购买按钮价格充足性（复用全链路，正确处理免费/下架/折扣分支，不重载模型）
function XUiFashionSuitDetail:_OnConsumeCountChanged()
    if XTool.UObjIsNil(self.GameObject) then return end
    if not self._SuitDetail then return end
    self._SuitDetail:UpdateBuyBtn()
end

--- 注册购买货币数量变化监听（监听界面声明货币 FreeGem/PaidGem/HongKa，node 用 PanelSpecialTool）
function XUiFashionSuitDetail:_AddConsumeCountListener()
    self:_RemoveConsumeCountListener()   -- 先移除防重复叠加
    -- 以表传入会跳过 AddCountUpdateListener 内 FreeGem→{FreeGem,PaidGem} 的自动扩展，故显式补 PaidGem，与资源栏币种口径一致
    local ids = { XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.PaidGem, XDataCenter.ItemManager.ItemId.HongKa }
    XDataCenter.ItemManager.AddCountUpdateListener(ids, handler(self, self._OnConsumeCountChanged), self.PanelSpecialTool)
end

function XUiFashionSuitDetail:_RemoveConsumeCountListener()
    if not XTool.UObjIsNil(self.PanelSpecialTool) then
        XDataCenter.ItemManager.RemoveCountUpdateListener(self.PanelSpecialTool)
    end
end

function XUiFashionSuitDetail:InitView()
    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
 
    if uiConfig.SliderMax and uiConfig.SliderMax > 0 then
        self.SliderCharacterHight.maxValue = uiConfig.SliderMax
    end
    self.SliderCharacterHight.value = uiConfig.SliderMax

    self:OnBtnShowUiClick()
    self:OnBtnTipsCloseClick()


end

function XUiFashionSuitDetail:SignGetShopInfo()
    self._ReqShopInfo = true
end

function XUiFashionSuitDetail:CallPurchaseCb(rewardList)
    if self._UpdateCb then
        self._UpdateCb(rewardList)
    end
end

function XUiFashionSuitDetail:UpdateView()
    self:UpdateFashionDetail()
    self:UpdatePlayBtn()
    self._SuitDetail:ShowGift()
    self:UpdateModel()
    self:UpdateSwitchBtn()
    self._SuitDetail:UpdateBuyBtn()
    self:CheckAndUpdateLackResourcesPanel()
end



function XUiFashionSuitDetail:UpdateFashionDetail()
    self._SuitDetail:UpdateFashionDetail()
    local fashionId = self._Context.FashionId
    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)

    self.PanelLeftBtnGroup.gameObject:SetActiveEx(not self._Helper:IsWeapon())
    self.BtnPic.gameObject:SetActiveEx(self._Helper:IsBtnPicVisible())
    --self.RImgLogoBg.gameObject:SetActiveEx(not self._Helper:IsWeapon())
    self._Control:SetFashionViewed(fashionId)
end


function XUiFashionSuitDetail:OnBtnPicClick()
    XLuaUiManager.Open("UiFashionSuitPopupPic", self._Context.FashionId)
end

function XUiFashionSuitDetail:OnBtnTipsCloseClick()
    self.BtnTipsClose.gameObject:SetActiveEx(false)
end

--region 隐藏Ui

function XUiFashionSuitDetail:OnBtnHideUiClick()
    self.PanelOther.gameObject:SetActiveEx(false)
    self.BtnPic.gameObject:SetActiveEx(false)
    self.BtnHideUi.gameObject:SetActiveEx(false)
    self.BtnShowUi.gameObject:SetActiveEx(true)
    self._IsHideUi = true
    self:OnBtnLensInClick()
    self:UpdateCamera(CameraIndex.Hide)
end

function XUiFashionSuitDetail:OnBtnShowUiClick()
    self.PanelOther.gameObject:SetActiveEx(true)
    self.BtnPic.gameObject:SetActiveEx(true)
    self.BtnHideUi.gameObject:SetActiveEx(true)
    self.BtnShowUi.gameObject:SetActiveEx(false)
    self._IsHideUi = false
    self:OnBtnLensInClick()
end

--endregion

--region 放大

function XUiFashionSuitDetail:OnBtnLensInClick()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.SliderCharacterHight.gameObject:SetActiveEx(false)
    self:UpdateSwitchBtn()
    if self._IsHideUi then
        self:UpdateCamera(CameraIndex.Hide)
    else
        self:UpdateCamera(CameraIndex.Normal)
    end
end

function XUiFashionSuitDetail:OnBtnLensOutClick()
    self.BtnLensOut.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(true)
    self.SliderCharacterHight.gameObject:SetActiveEx(true)
    self:SetSwitchBtnVisible(false, false)
    if self._IsHideUi then
        self:UpdateCamera(CameraIndex.HideNear)
    else
        self:UpdateCamera(CameraIndex.Near)
    end
    self:OnSliderCharacterHightChanged()
end

function XUiFashionSuitDetail:UpdateCamera(camera)
    self.ModelCamera[CameraIndex.Normal].gameObject:SetActiveEx(CameraIndex.Normal == camera)
    self.ModelCamera[CameraIndex.FarNormal].gameObject:SetActiveEx(CameraIndex.Normal == camera)
    self.ModelCamera[CameraIndex.Near].gameObject:SetActiveEx(CameraIndex.Near == camera)
    self.ModelCamera[CameraIndex.Far].gameObject:SetActiveEx(CameraIndex.Near == camera)
    self.ModelCamera[CameraIndex.Hide].gameObject:SetActiveEx(CameraIndex.Hide == camera)
    self.ModelCamera[CameraIndex.FarHide].gameObject:SetActiveEx(CameraIndex.Hide == camera)
    self.ModelCamera[CameraIndex.HideNear].gameObject:SetActiveEx(CameraIndex.HideNear == camera)
    self.ModelCamera[CameraIndex.FarHideNear].gameObject:SetActiveEx(CameraIndex.HideNear == camera)
end

function XUiFashionSuitDetail:OnSliderCharacterHightChanged()
    local pos = self.OriginalCameraPosition[self._IsHideUi and CameraIndex.HideNear or CameraIndex.Near]
    local posX, posY, posZ = pos.x, pos.y - self.SliderCharacterHight.value, pos.z
    self.ModelCamera[self._IsHideUi and CameraIndex.HideNear or CameraIndex.Near]:SetLocalPosition(posX, posY, posZ)
    self.ModelCamera[self._IsHideUi and CameraIndex.FarHideNear or CameraIndex.Far]:SetLocalPosition(posX, posY, posZ)
end

--endregion

--region 场景

function XUiFashionSuitDetail:InitSceneRoot(id)
    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
    local cameraPath = uiConfig.CameraPrefabPath
    self.ModelCamera = {}
    self:LoadUiScene(uiConfig.ScenePrefabPath, cameraPath, function()
        local root = self.UiModelGo.transform
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, root)
        ---@type XUiPanelRoleModel
        self.RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(uiObject.UiModelParent, self.Name, nil, true, nil, true)
        self.PanelWeapon = root:FindTransform("PanelWeapon")
        self.UiModelParent = uiObject.UiModelParent
        self.ModelCamera[CameraIndex.Normal] = uiObject.FashionCamNearMain
        self.ModelCamera[CameraIndex.FarNormal] = uiObject.FashionCamFarMain
        self.ModelCamera[CameraIndex.Near] = uiObject.FashionCamNearest
        self.ModelCamera[CameraIndex.Far] = uiObject.FashionCamFarest
        self.ModelCamera[CameraIndex.Hide] = uiObject.UiNearHideUiCamera
        self.ModelCamera[CameraIndex.FarHide] = uiObject.UiFarHideUiCamera
        self.ModelCamera[CameraIndex.HideNear] = uiObject.UiNearHideUiCameraNearest
        self.ModelCamera[CameraIndex.FarHideNear] = uiObject.UiFarHideUiCameraFarest
        self.WeaponDOFBurAnim = root:Find("Animation/WeaponDOFBur")
        
            
        self.ImgEffectHuanren = uiObject.ImgEffectHuanren
        self.ImgEffectHuanren1 = uiObject.ImgEffectHuanren1
        self:OnBtnLensInClick()
        self.OriginalCameraPosition = {}
        self.OriginalCameraPosition[CameraIndex.Far] = self.ModelCamera[CameraIndex.Far].transform.localPosition
        self.OriginalCameraPosition[CameraIndex.Near] = self.ModelCamera[CameraIndex.Near].transform.localPosition
        self.OriginalCameraPosition[CameraIndex.HideNear] = self.ModelCamera[CameraIndex.HideNear].transform.localPosition
        self.OriginalCameraPosition[CameraIndex.FarHideNear] = self.ModelCamera[CameraIndex.FarHideNear].transform.localPosition
        -- self:InitCameraTransform()
        self.OriginalCameraAngles = {}
        self.OriginalCameraAngles[CameraIndex.Normal] = self.ModelCamera[CameraIndex.Normal].transform.localEulerAngles
        self._SuitDetail:UpdateGroupSales(id)
    end)
end

function XUiFashionSuitDetail:InitModelHandler()
    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
    -- self._FashionModelPos = Vector3(uiConfig.RolePosX, uiConfig.RolePosY, uiConfig.RolePosZ)
    self._WeaponModelPos = Vector3(uiConfig.WeaponPosX, uiConfig.WeaponPosY, uiConfig.WeaponPosZ)
    -- self._FashionModleRotation = Vector3(uiConfig.RoleRotationX, uiConfig.RoleRotationY, uiConfig.RoleRotationZ)
    self._UiFashionNearCamAngle = Vector3(2.25, 0, 0)

    self._ModelHander = {}
    self._ModelHander[true] = handler(self, self.UpdateWeaponModel)
    self._ModelHander[false] = handler(self, self.UpdateFashionModel)
end

function XUiFashionSuitDetail:UpdateModel()
    local isShowWeapon = self._Helper:IsWeapon() and not self._Helper:IsEnableGroupSales()
    self._ModelHander[isShowWeapon]()
end

function XUiFashionSuitDetail:UpdateFashionModel()
    local fashionConfig = XFashionConfigs.GetFashionTemplate(self._Context.FashionId)
    if self._VirtualNearCameraTran then
        self._VirtualNearCameraTran.localEulerAngles = self.OriginalCameraAngles[CameraIndex.Normal] --使用UiFashionDetail界面的相机旋转角度
    end
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.UiModelParent.gameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(fashionConfig.ResourcesId, fashionConfig.CharacterId, XModelManager.MODEL_UINAME.XUiFashionSuitDetail, function(model)
        if self._IsModelDrag then
            self.PanelDrag.gameObject:SetActiveEx(true)
            self.PanelDrag:GetComponent("XDrag").Target = model.transform
        else
            self.PanelDrag.gameObject:SetActiveEx(false)
        end
        self:ShowImgEffectHuanren(fashionConfig.CharacterId)
    end, nil, self._Context.WeaponFashionId)

    if not XTool.UObjIsNil(self.WeaponDOFBurAnim) then
        self.WeaponDOFBurAnim:StopTimelineAnimation()
    end
end

function XUiFashionSuitDetail:UpdateWeaponModel()
    self._VirtualNearCameraTran = self.ModelCamera[CameraIndex.Normal].transform
    self._VirtualNearCameraTran.localEulerAngles = self._UiFashionNearCamAngle --使用UiFashionDetail界面的相机旋转角度
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self.PanelWeapon.localPosition = self._WeaponModelPos
    self.UiModelParent.gameObject:SetActiveEx(false)
    local uiName = XModelManager.MODEL_UINAME.XUiFashionDetail
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(self._Context.WeaponFashionId, nil, uiName)
    XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, uiName, nil, { gameObject = self.GameObject, IsDragRotation = self._IsModelDrag }, self.PanelDrag)

    if not XTool.UObjIsNil(self.WeaponDOFBurAnim) then
        self.WeaponDOFBurAnim:PlayTimelineAnimation()
    end
end

function XUiFashionSuitDetail:ShowImgEffectHuanren(templateId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    if templateId and XMVCA.XCharacter:GetIsIsomer(templateId) then
        self.ImgEffectHuanren1.gameObject:SetActiveEx(true)
    else
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
end

function XUiFashionSuitDetail:InitCameraTransform(modelUrl)
    local virtualNearCameraTran = self.ModelCamera[CameraIndex.Normal].transform
    local virtualFarCameraTran = self.ModelCamera[CameraIndex.FarNormal]
    local hideUiNearCameraTran = self.ModelCamera[CameraIndex.Hide]
    local hideUiFarCameraTran = self.ModelCamera[CameraIndex.FarHide]
    if XTool.UObjIsNil(virtualNearCameraTran) or XTool.UObjIsNil(virtualFarCameraTran) then
        XLog.Error("虚拟相机【FashionCamNearMain】不存在")
        return
    end
    if XTool.UObjIsNil(hideUiNearCameraTran) or XTool.UObjIsNil(hideUiFarCameraTran) then
        XLog.Error("隐藏相机【UiNearHideUiCamera】不存在")
        return
    end

    local uiConfig = self._Control:GetFashionSuitUiConfigById(self._SuitId)
    local position = Vector3(uiConfig.CameraPosX, uiConfig.CameraPosY, uiConfig.CameraPosZ)
    local angles = Vector3(uiConfig.CameraRotationX, uiConfig.CameraRotationY, uiConfig.CameraRotationZ)

    virtualNearCameraTran.localPosition = position
    virtualFarCameraTran.localPosition = position
    virtualFarCameraTran.localEulerAngles = angles

    local nearPosition = Vector3(uiConfig.HideCameraPosX, uiConfig.HideCameraPosY, uiConfig.HideCameraPosZ)
    local nearAngles = Vector3(uiConfig.HideCameraRotationX, uiConfig.HideCameraRotationY, uiConfig.HideCameraRotationZ)
    hideUiNearCameraTran.localPosition = nearPosition
    hideUiFarCameraTran.localPosition = nearPosition
    hideUiFarCameraTran.localEulerAngles = nearAngles

    local nearVirtualCamera = virtualNearCameraTran:GetComponent("CinemachineVirtualCamera")
    if not XTool.UObjIsNil(nearVirtualCamera) then
        local newLens = nearVirtualCamera.m_Lens
        newLens.FieldOfView = uiConfig.CameraFov
        nearVirtualCamera.m_Lens = newLens
    end

    local farVirtualCamera = virtualFarCameraTran:GetComponent("CinemachineVirtualCamera")
    if not XTool.UObjIsNil(farVirtualCamera) then
        local newLens = farVirtualCamera.m_Lens
        newLens.FieldOfView = uiConfig.CameraFov
        farVirtualCamera.m_Lens = newLens
    end
    self._VirtualNearCameraTran = virtualNearCameraTran
    self._VirtualNearCameraAngles = angles
end

--endregion

--region 切换涂装

function XUiFashionSuitDetail:OnBtnLastClick()
    local index = table.indexof(self._SuitConfig.FashionIds, self._Context.FashionId)
    if index == 1 then
        index = self._FashionCount
    else
        index = index - 1
    end
    self:SwitchFashionId(index)
end

function XUiFashionSuitDetail:OnBtnNextClick()
    local index = table.indexof(self._SuitConfig.FashionIds, self._Context.FashionId)
    if index == self._FashionCount then
        index = 1
    else
        index = index + 1
    end
    self:SwitchFashionId(index)
end

function XUiFashionSuitDetail:SwitchFashionId(index)
    local id = self._SuitConfig.FashionIds[index]
    self._Context:InitData(id)
    self._SuitDetail:UpdateGroupSales(id)
end

function XUiFashionSuitDetail:UpdateSwitchBtn()
    local isShow = self._FashionCount > 1
    if self._FashionCount <= 1 or self._SkipType ~= SkipType.SuitMain then --只有从涂装套装二级界面进来时才显示切换按钮
        self:SetSwitchBtnVisible(false, false)
    elseif self._FashionCount == 2 then
        local fashionId = self._Context.FashionId
        local first = self._SuitConfig.FashionIds[1]
        local second = self._SuitConfig.FashionIds[2]
        self:SetSwitchBtnVisible(fashionId ~= first, fashionId ~= second)
    else
        self:SetSwitchBtnVisible(true, true)
    end
end

function XUiFashionSuitDetail:SetSwitchBtnVisible(lastVisible, nextVisible)
    self.BtnLast.gameObject:SetActiveEx(lastVisible)
    self.BtnNext.gameObject:SetActiveEx(nextVisible)
end

--endregion

--region 试玩

function XUiFashionSuitDetail:UpdatePlayBtn()
    self._TrialLevelInfo = XDataCenter.FubenExperimentManager.GetTrialLevelByFashionID(self._Context.FashionId)
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Experiment)
    self.BtnPlay.gameObject:SetActiveEx(isOpen and self._TrialLevelInfo ~= nil)
end

function XUiFashionSuitDetail:OnBtnPlayClick()
    XDataCenter.FubenExperimentManager:OpenPaintingExperiencePass(self._TrialLevelInfo.Id)
end

--endregion

--region 时间检测

function XUiFashionSuitDetail:StartTimer()
    self._UpdateTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), 1000)
    self:_AddTimerId(self._UpdateTimerId)
end

function XUiFashionSuitDetail:DestroyTimer()
    if self._UpdateTimerId then
        XScheduleManager.UnSchedule(self._UpdateTimerId)
        self:_RemoveTimerIdAndDoCallback(self._UpdateTimerId)
        self._UpdateTimerId = nil
    end
end

function XUiFashionSuitDetail:UpdateTimer()
    if not XTool.IsTableEmpty(self._TimeFuns) then
        for _, timerFun in pairs(self._TimeFuns) do
            if timerFun then
                timerFun()
            end
        end
        return
    end
    self:DestroyTimer()
end

function XUiFashionSuitDetail:RemoveTimerFun(id)
    if self._TimeFuns then
        self._TimeFuns[id] = nil
    end
end

function XUiFashionSuitDetail:RegisterTimerFun(id, fun)
    if not self._TimeFuns then
        self._TimeFuns = {}
    end
    self._TimeFuns[id] = fun
end

--endregion

--region 资源缺失面板

function XUiFashionSuitDetail:CheckAndUpdateLackResourcesPanel()
    if not self._PanelLackRes then return end
    local fashionId = self._Context and self._Context.FashionId
    if not XTool.IsNumberValid(fashionId) then
        self._PanelLackRes:Close()
        self._isFashionLacking = false
        return
    end
    local isDownloaded = XMVCA.XSubPackage:CheckFashionDownloaded(fashionId)
    if isDownloaded then
        self._PanelLackRes:Close()
        self._isFashionLacking = false
    else
        local characterId = self._Context and self._Context.CharacterId or 0
        self._PanelLackRes:SetData(characterId, fashionId)
        self._PanelLackRes:Open()
        self._isFashionLacking = true
    end
end

function XUiFashionSuitDetail:OnFashionDownloadComplete()
    if not self._isFashionLacking then
        self:CheckAndUpdateLackResourcesPanel()
        return
    end
    local fashionId = self._Context and self._Context.FashionId
    if XTool.IsNumberValid(fashionId)
       and XMVCA.XSubPackage:CheckFashionDownloaded(fashionId) then
        self:UpdateModel()
        local fashionTemplate = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("DownloadFashionFinishedRefresh", fashionTemplate and fashionTemplate.Name or ""))
    end
    self:CheckAndUpdateLackResourcesPanel()
end

--endregion

return XUiFashionSuitDetail