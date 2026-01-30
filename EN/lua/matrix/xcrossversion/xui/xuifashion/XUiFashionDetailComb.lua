local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local CameraIndex = {
    Normal = 1,
    Near = 2,
}

local ViewType = {
    Character = 1,
    Weapon = 2,
}

local TitleName = {
    Title = {
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTitleWeapon"),
    },
    TipTitle = {
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTipTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTipTitleWeapon"),
    },
}

-- v1.28 采购优化-时装购买CD
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000

local XUiFashionDetailComb = XLuaUiManager.Register(XLuaUi, "UiFashionDetailComb")

local FashionIndex = 1

function XUiFashionDetailComb:OnAwake()
    self:AutoAddListener()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.PanelBtnSwich.gameObject:SetActiveEx(false)
    local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
end

function XUiFashionDetailComb:OnStart(fashionId, isWeaponFashion, buyData, isShowFashionIconWithoutGift, isNeedCD, customWeaponFashionId, customDesc)
    self:InitSceneRoot() --设置摄像机
    self.FashionId = fashionId
    self.IsWeaponFashion = isWeaponFashion
    self.BuyData = buyData
    self.IsShowFashionIconWithoutGift = isShowFashionIconWithoutGift
    self.CustomDesc = customDesc
    self.CustomWeaponFashionId = customWeaponFashionId

    if XWeaponFashionConfigs.IsWeaponFashion(self.FashionId[FashionIndex]) then 
        --v1.31武器时装
        self.IsHaveFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(self.FashionId[FashionIndex]) and
            not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.FashionId[FashionIndex])
    else
        --v1.28-采购优化-记录是否当前皮肤是否已拥有
        self.IsHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId[FashionIndex])})
    end

    -- 配置是否需要购买冷却
    self.IsNeedCD = isNeedCD or false
    -- 记录初始时间
    self.LastBuyTime = CS.UnityEngine.Time.realtimeSinceStartup
    self:SetDetailData()
    self:CheckWeaponFashionBtnShow()
    for i = 1, #fashionId do
        XUiHelper.RegisterClickEvent(self, self["Tog" .. i], function() 
            FashionIndex = i
            self:LoadModelScene(true)
            self:UpdateWeaponModel()
            self:SetDetailData()
            self:UpdateSelect()
        end)
    end
    for i = 1, 3 do
        self["Tog" .. i].gameObject:SetActiveEx(i <= #fashionId)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnLast, function()
        FashionIndex = FashionIndex - 1
        if FashionIndex <= 0 then
            FashionIndex = #self.FashionId
        end
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
        self:SetDetailData()
        self:UpdateSelect()
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, function()
        FashionIndex = FashionIndex + 1
        if FashionIndex > #self.FashionId then
            FashionIndex = 1
        end
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
        self:SetDetailData()
        self:UpdateSelect()
    end)
    self:UpdateSelect()
end

function XUiFashionDetailComb:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    CS.XGraphicManager.UseUiLightDir = true
    if self.IsWeaponFashion then
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    else
        self:LoadModelScene(false)
        self:UpdateCharacterModel()
    end
    self:InitBuyData()
end

function XUiFashionDetailComb:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiFashionDetailComb:OnUiSceneLoaded()
    --self:SetGameObject()
end

function XUiFashionDetailComb:InitBuyData()
    self.BtnBuy.gameObject:SetActiveEx(false)
    if not self.BuyData then
        return
    end

    self.BtnBuy.gameObject:SetActiveEx(true)
    self.TxtHave.gameObject:SetActiveEx(self.BuyData.IsHave)
    -- 礼包中已拥有涂装文本
    self.TxtRepeatWith.gameObject:SetActiveEx(not self.BuyData.IsHave and self.IsHaveFashion)
    --local isHave = self.BuyData.IsHave or (self.IsHaveFashion and not self.BuyData.IsConvert)
    --self.BtnBuy:SetDisable(isHave, not isHave)
    self.BtnBuy:SetDisable(self.BuyData.IsHave, not self.BuyData.IsHave)
    self.PanelInformation.gameObject:SetActiveEx(self.BuyData.LimitText ~= nil or self.BuyData.IsHave 
        or not string.IsNilOrEmpty(self.BuyData.FashionLabel) or self.IsHaveFashion)

    self.TxtLimitBuy.text = self.BuyData.LimitText or ""

    if self.BuyData.PayKeySuffix then
        self.RawImageConsume.gameObject:SetActiveEx(false)
        self.ImageYuan.gameObject:SetActiveEx(true)
        self.BtnBuy:SetName(self:GetPayAmount(self.BuyData.PayKeySuffix))
        if self.BuyData.IsHave then
            local path = CS.XGame.ClientConfig:GetString("LBBuyRiYuanIconPath1")
            self.ImageYuan:SetRawImage(path)
        else
            local path = CS.XGame.ClientConfig:GetString("LBBuyRiYuanIconPath")
            self.ImageYuan:SetRawImage(path)
        end
        self:ShowSpecialRegulationForJP()
    else
        self.BtnBuy:SetName(self.BuyData.ItemCount)
        self.RawImageConsume.gameObject:SetActiveEx(true)
        self.ImageYuan.gameObject:SetActiveEx(false)
        self.RawImageConsume:SetRawImage(self.BuyData.ItemIcon)
    end

    self.BtnBuy.CallBack = function()
        -- v1.28 采购优化 记录时间, 判断是否拦截
        if self.IsNeedCD then
            if self.LastBuyTime and CS.UnityEngine.Time.realtimeSinceStartup - self.LastBuyTime > PurchaseBuyPayCD then
                self.LastBuyTime = CS.UnityEngine.Time.realtimeSinceStartup
                self:OnBtnBuyClick()
            end
        else
            self:OnBtnBuyClick()
        end
    end

    -- 皮肤礼包提示
    if self.BuyData and self.BuyData.FashionLabel then
        if self.TxtFashionTip then 
            self.TxtFashionTip.gameObject:SetActiveEx(true)
            self.TxtFashionTip.text = self.BuyData.FashionLabel
        end
    end

    --BuyData={
    --    IsHave --------是否已经拥有
    --    LimitText -------------限购提示字符串
    --    ItemIcon -------------货币Icon
    --    ItemCount-------------货币数量
    --    BuyCallBack-----------购买时调用的接口
    --    FashionTip-----------皮肤礼包自定义提示
    --    }
end

function XUiFashionDetailComb:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.BtnBuy.transform:LoadPrefab(url)
            local data = {type = 2,consumeId = 1}
            data.content = CS.XTextManager.GetText("JPBusinessLawsBuyLimitedText02",1)
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CS.XTextManager.GetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(-107.8, 110, 0)
            self.ShowSpecialRegBtn.fontSize = 32
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiFashionDetailComb:GetPayAmount(PayKeySuffix)
    local key = XPayConfigs.GetProductKey(PayKeySuffix)

    local payConfig = XPayConfigs.GetPayTemplate(key)
    return payConfig and payConfig.Amount or 0
end

function XUiFashionDetailComb:OnSliderCharacterHightChanged()
    local pos = self.CameraNear[CameraIndex.Near].position
    self.CameraNear[CameraIndex.Near].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacterHight.value, pos.z)
end

--初始化摄像机
function XUiFashionDetailComb:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("UiModelParent"), self.Name, nil, true, nil, true)
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.CameraNear = {
        [CameraIndex.Normal] = root:FindTransform("FashionCamNearMain"),
        [CameraIndex.Near] = root:FindTransform("FashionCamNearest"),
    }
end

function XUiFashionDetailComb:UpdateCamera(camera)
    for _, cameraIndex in pairs(CameraIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActiveEx(cameraIndex == camera)
    end
end

function XUiFashionDetailComb:OnBtnLensOut()
    self.BtnLensOut.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(true)
    self:UpdateCamera(CameraIndex.Near)
end

function XUiFashionDetailComb:OnBtnLensIn()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashionDetailComb:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnGouxuan, self.OnBtnShowWeaponFashion)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacterHight, self.OnSliderCharacterHightChanged)
    self.BtnLensOut.CallBack = function() self:OnBtnLensOut() end
    self.BtnLensIn.CallBack = function() self:OnBtnLensIn() end
end

function XUiFashionDetailComb:SetDetailData()

    -- v1.28-采购优化-赠品队列展示
    -- 传入Data为单一rewardId的情况
    local giftRewardId = self.BuyData and self.BuyData.GiftRewardId
    if type(giftRewardId) == "number" then
        if giftRewardId ~= 0 then
            self.GoodIdList = XRewardManager.GetRewardList(giftRewardId)
        end
    elseif self.BuyData and self.BuyData.GiftRewardId then
        self.GoodIdList = self.BuyData.GiftRewardId
    end

    -- v1.31-采购优化-涂装增加CG展示道具
    if not self.IsWeaponFashion then
        local subItems = XDataCenter.FashionManager.GetFashionSubItems(self.FashionId[FashionIndex])
        if subItems then
            for _, itemTemplateId in ipairs(subItems) do
                if self.GoodIdList == nil then self.GoodIdList = {} end
                table.insert(self.GoodIdList, {TemplateId = itemTemplateId, Count = 1, IsSubItem = true})
            end
        end
    end
    
    local giftId = not self.IsWeaponFashion and XFashionConfigs.GetFashionTemplate(self.FashionId[FashionIndex]).GiftId or 0
    if XTool.IsNumberValid(giftId) then
        local giftGoodShowData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(giftId)
        giftGoodShowData.IsGift = true
        giftGoodShowData.Count = 1
        if self.GoodIdList == nil then
            self.GoodIdList = {}
        end
        table.insert(self.GoodIdList,giftGoodShowData)
    end

    -- giftRewardId=额外礼物，在商店皮肤界面，没有额外礼物，就显示时装物品
    if self.GoodIdList and #self.GoodIdList > 0 and not self.IsShowFashionIconWithoutGift then
        self.GridItem.gameObject:SetActiveEx(false)
        self.RewordGoodList.gameObject:SetActiveEx(true)
        self.GridGoodItem.gameObject:SetActiveEx(false)
        self.DynamicTable = XDynamicTableNormal.New(self.RewordGoodList)
        self.DynamicTable:SetProxy(XUiGridCommon)
        self.DynamicTable:SetDelegate(self)
        self.DynamicTable:SetDataSource(self.GoodIdList)
        self.DynamicTable:ReloadDataASync(1)
        self.Title.text = CS.XTextManager.GetText("SpecialFashionShopGiftTitle")
        self.BtnClick.gameObject:SetActiveEx(true)
    else
        self.GridItem.gameObject:SetActiveEx(true)
        self.RewordGoodList.gameObject:SetActiveEx(false)
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId[FashionIndex])
        if self.DetailRImgIcon then
            local icon = self.GoodsShowParams.Icon
            if icon and #icon > 0 then
                self.DetailRImgIcon:SetRawImage(icon)
            end
        end
        if self.DetailImgQuality and self.GoodsShowParams.Quality then
            XUiHelper.SetQualityIcon(self, self.DetailImgQuality, self.GoodsShowParams.Quality)
        end
    end

    if self.WorldDesc then
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(self.FashionId[FashionIndex])
        if worldDesc and #worldDesc then
            self.WorldDesc.text = worldDesc
        end
    end
    if self.Desc then
        local desc = XGoodsCommonManager.GetGoodsDescription(self.FashionId[FashionIndex])
        if desc and #desc > 0 then
            self.Desc.text = desc
        end
    end
end

-- v1.28-采购优化-时装礼包赠品动态列表更新
function XUiFashionDetailComb:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local gridData = self.GoodIdList[index]
        grid:Refresh(gridData)
        -- 已拥有图标显示
        local isHave = grid.TxtHave.gameObject.activeSelf
        grid.ImgIsHave.gameObject:SetActiveEx(isHave)
    end
end

function XUiFashionDetailComb:UpdateCharacterModel()
    local template = XDataCenter.FashionManager.GetFashionTemplate(self.FashionId[FashionIndex])
    local func = function(model)
        self.PanelDrag:GetComponent("XDrag").Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end

    local weaponFashionId
    if XTool.IsNumberValid(self.CustomWeaponFashionId) then
        -- 勾选则显示自定义武器涂装，不勾选则显示当前穿戴武器涂装
        if self.IsCustomWeaponFashion then
            weaponFashionId = self.CustomWeaponFashionId
        else
            weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(template.CharacterId)
        end
    end

    self.TxtTitle.text = TitleName.Title[ViewType.Character]
    self.TxtTipTitle.text = TitleName.TipTitle[ViewType.Character]
    self.TxtFashionName.text = template.Name
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashionDetail, func, nil, weaponFashionId)

    if XTool.DebugIsShowItemIdOnUi() then
        self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s)", template.Id)
        self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 800)
    end
end

function XUiFashionDetailComb:UpdateWeaponModel()
    local weaponFashionId = self.FashionId[FashionIndex]
    local uiName = XModelManager.MODEL_UINAME.XUiFashionDetail
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(weaponFashionId, nil, uiName)
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)

    self.TxtTitle.text = TitleName.Title[ViewType.Weapon]
    self.TxtTipTitle.text = TitleName.TipTitle[ViewType.Weapon]
    self.TxtFashionName.text = fashionName
    self.RoleModelPanel.GameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, uiName, nil, { gameObject = self.GameObject ,IsDragRotation = true}, self.PanelDrag)


    if XTool.DebugIsShowItemIdOnUi() then
        local itemId
        if self.BuyData and self.BuyData.CurRewardGoods then
            itemId = self.BuyData.CurRewardGoods.TemplateId
        end
        if itemId then
            self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s, Item:%s)", self.FashionId[FashionIndex], itemId)
            self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 1500)
        else
            self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s)", self.FashionId[FashionIndex])
            self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 800)
        end
    end
end

function XUiFashionDetailComb:OnBtnBackClick()
    self:Close()
end

function XUiFashionDetailComb:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFashionDetailComb:OnBtnBuyClick()
    local title = XUiHelper.GetText("PurchaseFashionRepeatTipsTitle")
    local content = XUiHelper.GetText("PurchaseFashionRepeatTipsContent")
    local sureCb = function ()
        self.BuyData.BuyCallBack()
        self:OnBtnBackClick()
    end
    -- 已有涂装则二次确认
    if self.IsHaveFashion then
        XUiManager.DialogTip(title, content, nil, nil, sureCb)
    else
        sureCb()
    end
end

function XUiFashionDetailComb:LoadModelScene(isDefault)
    local sceneUrl = self:GetSceneUrl(isDefault)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, self.OnUiSceneLoadedCB, false)
end

function XUiFashionDetailComb:UpdateSelect()
    for i = 1, #self.FashionId do
        if FashionIndex == i then
            self["Tog" .. i]:SetButtonState(CS.UiButtonState.Select)
        else
            self["Tog" .. i]:SetButtonState(CS.UiButtonState.Normal)
        end
    end
end

function XUiFashionDetailComb:GetSceneUrl(isDefault)
    if isDefault then
        return self:GetDefaultSceneUrl()
    end

    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(self.FashionId[FashionIndex])
    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end

--region 显示武器时装

function XUiFashionDetailComb:CheckWeaponFashionBtnShow()
    if XTool.IsNumberValid(self.CustomWeaponFashionId) then
        self.PanelAdd.gameObject:SetActiveEx(true)
        self.TxtToggleDesc.text = self.CustomDesc or ""
        self.BtnGouxuan:SetButtonState(CS.UiButtonState.Select)
        self.IsCustomWeaponFashion = true
    else
        self.PanelAdd.gameObject:SetActiveEx(false)
    end
end

function XUiFashionDetailComb:OnBtnShowWeaponFashion()
    self.IsCustomWeaponFashion = self.BtnGouxuan:GetToggleState()
    self:LoadModelScene(false)
    self:UpdateCharacterModel()
end

--endregion