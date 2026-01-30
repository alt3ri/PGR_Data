---@class XUiFashionSuitDetail : XLuaUi 涂装详情（三级界面）
---@field _Control XFashionSuitControl
local XUiFashionSuitDetail = XLuaUiManager.Register(XLuaUi, "UiFashionSuitDetail")

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
    self._ItemPools = {}
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
end

---@param updateCb fun(rewardList:table) 采购界面更新回调
function XUiFashionSuitDetail:OnStart(fashionSuitId, fashionId, updateCb)
    self._SuitId = fashionSuitId
    self._Id = fashionId
    self._UpdateCb = updateCb
    self._SuitConfig = self._Control:GetFashionSuitById(fashionSuitId)
    self._FashionConfig = XFashionConfigs.GetFashionTemplate(fashionId)
    self._FashionCount = #self._SuitConfig.FashionIds
    self._IsModelDrag = self._Control:GetIntClientConfig("IsModelDrag") == 1
    ---@type XUiPanelFashionSuitButtonGroup
    self._ButtonGroup = require("XUi/XUiFashionSuit/Panel/XUiPanelFashionSuitButtonGroup").New(self.PanelBtnGroup, self)
    
    self:InitSceneRoot()
    self:InitView()
    self:StartTimer()

    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.HongKa, XDataCenter.ItemManager.ItemId.PaintingDesign }, self.PanelSpecialTool, self)
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
end

function XUiFashionSuitDetail:OnDisable()

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
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_CLEAR_DATA, self.SignGetShopInfo, self)
end

function XUiFashionSuitDetail:InitView()
    local color = XUiHelper.Hexcolor2Color(self._SuitConfig.LineColor)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.RImgDetailBg:SetRawImage(self._SuitConfig.DetailBg)
    self.RImgLogoBg:SetRawImage(self._SuitConfig.LogoBg)
    self.ImgLine1.color = color
    self.ImgLine2.color = color
    self.ImgWord1.color = color
    self.ImgWord2.color = color
    self._ButtonGroup:SetButtonBg(self._SuitConfig.BtnBuyBg, self._SuitConfig.BtnGetBg, self._SuitConfig.BtnWearBg)
    
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
    self:ShowGift()
    self:UpdateModel()
    self:UpdateSwitchBtn()
    self._ButtonGroup:UpdateBuyBtn(self._Id)
end

function XUiFashionSuitDetail:UpdateFashionDetail()
    self.TxtFashionName.text = self._FashionConfig.Name
    self.TxtCharacterName.text = XMVCA.XCharacter:GetCharacterTemplate(self._FashionConfig.CharacterId).Name
    self.ImgTagNew.gameObject:SetActiveEx(not self._Control:IsFashionViewed(self._Id))
    self.TxtSuitName.text = self._SuitConfig.Name
    self.RImgSuitIcon:SetRawImage(self._SuitConfig.SuitBanner)
    self.TxtStoryTips.text = self._FashionConfig.WorldDescription
    self.BtnPic.gameObject:SetActiveEx(not string.IsNilOrEmpty(self._FashionConfig.FashionSuitPic))
    self._Control:SetFashionViewed(self._Id)
end

function XUiFashionSuitDetail:ShowGift()
    local goodIdList = {}
    local subItems = XDataCenter.FashionManager.GetFashionSubItems(self._Id)
    if subItems then
        for _, itemTemplateId in ipairs(subItems) do
            table.insert(goodIdList, { TemplateId = itemTemplateId, Count = 1, IsSubItem = true })
        end
    end

    local giftId = XFashionConfigs.GetFashionTemplate(self._Id).GiftId
    if XTool.IsNumberValid(giftId) then
        local giftGoodShowData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(giftId)
        giftGoodShowData.IsGift = true
        giftGoodShowData.Count = 1
        table.insert(goodIdList, giftGoodShowData)
    end

    if XTool.IsTableEmpty(goodIdList) then
        self.PanelGift.gameObject:SetActiveEx(false)
    else
        self.PanelGift.gameObject:SetActiveEx(true)
        local isHaveFashion = XDataCenter.FashionManager.CheckHasFashion(self._Id) and XDataCenter.FashionManager.IsFashionInTime(self._Id)
        local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
        XUiHelper.CreateTemplates(self, self._ItemPools, goodIdList, XUiGridCommon.New, self.Grid256New, self.Grid256New.parent, function(grid, data)
            grid:Refresh(data)
            -- 已拥有图标显示
            -- 涂装子道具随绑定涂装的拥有而显示已拥有状态
            grid.ImgReceived.gameObject:SetActiveEx(isHaveFashion)
        end)
    end
end

function XUiFashionSuitDetail:OnBtnPicClick()
    XLuaUiManager.Open("UiFashionSuitPopupPic", self._Id)
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
    local near = self.ModelCamera[self._IsHideUi and CameraIndex.HideNear or CameraIndex.Near]
    local far = self.ModelCamera[self._IsHideUi and CameraIndex.FarHideNear or CameraIndex.Far]
    local pos = near.position
    local target = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacterHight.value, pos.z)
    near.position = target
    far.position = target
end

--endregion

--region 场景

function XUiFashionSuitDetail:InitSceneRoot()
    local cameraPath = self._Control:GetClientConfig("CameraPrefabPath")
    self.ModelCamera = {}
    self:LoadUiScene(self._SuitConfig.ScenePrefabPath, cameraPath, function()
        local root = self.UiModelGo.transform
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, root)
        ---@type XUiPanelRoleModel
        self.RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(uiObject.UiModelParent, self.Name, nil, true, nil, true)
        self.ModelCamera[CameraIndex.Normal] = uiObject.FashionCamNearMain
        self.ModelCamera[CameraIndex.FarNormal] = uiObject.FashionCamFarMain
        self.ModelCamera[CameraIndex.Near] = uiObject.FashionCamNearest
        self.ModelCamera[CameraIndex.Far] = uiObject.FashionCamFarest
        self.ModelCamera[CameraIndex.Hide] = uiObject.UiNearHideUiCamera
        self.ModelCamera[CameraIndex.FarHide] = uiObject.UiFarHideUiCamera
        self.ModelCamera[CameraIndex.HideNear] = uiObject.UiNearHideUiCameraNearest
        self.ModelCamera[CameraIndex.FarHideNear] = uiObject.UiFarHideUiCameraFarest
        
        self.ImgEffectHuanren = uiObject.ImgEffectHuanren
        self.ImgEffectHuanren1 = uiObject.ImgEffectHuanren1
        self:OnBtnLensInClick()
        self:InitCameraTransform()
    end)
end

function XUiFashionSuitDetail:UpdateModel()
    self.RoleModelPanel:UpdateCharacterResModel(self._FashionConfig.ResourcesId, self._FashionConfig.CharacterId, "UiFashionSuitDetail", function(model)
        model.transform.localPosition = Vector3(self._SuitConfig.RolePosX, self._SuitConfig.RolePosY, self._SuitConfig.RolePosZ)
        if self._IsModelDrag then
            self.PanelDrag.gameObject:SetActiveEx(true)
            self.PanelDrag:GetComponent("XDrag").Target = model.transform
        else
            self.PanelDrag.gameObject:SetActiveEx(false)
        end
        self:ShowImgEffectHuanren(self._FashionConfig.CharacterId)
    end)
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
    local virtualNearCameraTran = self.UiModelGo.transform:FindTransform("FashionCamNearMain")
    local virtualFarCameraTran = self.UiModelGo.transform:FindTransform("FashionCamFarMain")
    if XTool.UObjIsNil(virtualNearCameraTran) or XTool.UObjIsNil(virtualFarCameraTran) then
        XLog.Error("虚拟相机【FashionCamNearMain】不存在")
        return
    end

    local position = Vector3(self._SuitConfig.CameraPosX, self._SuitConfig.CameraPosY, self._SuitConfig.CameraPosZ)
    local angles = Vector3(self._SuitConfig.CameraRotationX, self._SuitConfig.CameraRotationY, self._SuitConfig.CameraRotationZ)
    virtualNearCameraTran.localPosition = position
    virtualFarCameraTran.localPosition = position
    virtualNearCameraTran.localEulerAngles = angles
    virtualFarCameraTran.localEulerAngles = angles

    local nearVirtualCamera = virtualNearCameraTran:GetComponent("CinemachineVirtualCamera")
    if not XTool.UObjIsNil(nearVirtualCamera) then
        local newLens = nearVirtualCamera.m_Lens
        newLens.FieldOfView = self._SuitConfig.CameraFov
        nearVirtualCamera.m_Lens = newLens
    end

    local farVirtualCamera = virtualFarCameraTran:GetComponent("CinemachineVirtualCamera")
    if not XTool.UObjIsNil(farVirtualCamera) then
        local newLens = farVirtualCamera.m_Lens
        newLens.FieldOfView = self._SuitConfig.CameraFov
        farVirtualCamera.m_Lens = newLens
    end
end

--endregion

--region 切换涂装

function XUiFashionSuitDetail:OnBtnLastClick()
    local index = table.indexof(self._SuitConfig.FashionIds, self._Id)
    if index == 1 then
        index = self._FashionCount
    else
        index = index - 1
    end
    self:SwitchFashionId(index)
end

function XUiFashionSuitDetail:OnBtnNextClick()
    local index = table.indexof(self._SuitConfig.FashionIds, self._Id)
    if index == self._FashionCount then
        index = 1
    else
        index = index + 1
    end
    self:SwitchFashionId(index)
end

function XUiFashionSuitDetail:SwitchFashionId(index)
    self._Id = self._SuitConfig.FashionIds[index]
    self._FashionConfig = XFashionConfigs.GetFashionTemplate(self._Id)
    self:UpdateView()
end

function XUiFashionSuitDetail:UpdateSwitchBtn()
    local isShow = self._FashionCount > 1
    if self._FashionCount <= 1 then
        self:SetSwitchBtnVisible(false, false)
    elseif self._FashionCount == 2 then
        local first = self._SuitConfig.FashionIds[1]
        local second = self._SuitConfig.FashionIds[2]
        self:SetSwitchBtnVisible(self._Id ~= first, self._Id ~= second)
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
    self._TrialLevelInfo = XDataCenter.FubenExperimentManager.GetTrialLevelByFashionID(self._Id)
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Experiment)
    self.BtnPlay.gameObject:SetActiveEx(isOpen and self._TrialLevelInfo ~= nil)
end

function XUiFashionSuitDetail:OnBtnPlayClick()
    XLuaUiManager.Open("UiPaintingExperiencePassV4P2", self._TrialLevelInfo.Id)
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

return XUiFashionSuitDetail