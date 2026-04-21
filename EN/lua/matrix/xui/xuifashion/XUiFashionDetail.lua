local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelLackResources = require("XUi/XUiSubPackage/XUiPanel/XUiPanelLackResources")
local CameraIndex = {
    Normal = 1,
    Near = 2,
}

local ViewType = {
    FashionGroup = 0,
    Character = 1,
    Weapon = 2,
}

local TitleName = {
    Title = {
        [ViewType.FashionGroup] = CSXTextManagerGetText("FashionDetailGroupSalesTitle1"),
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTitleWeapon"),
    },
    TipTitle = {
        [ViewType.FashionGroup] = CSXTextManagerGetText("FashionDetailGroupSalesTitle2"),
        [ViewType.Character] = CSXTextManagerGetText("UiFashionDetailTipTitleCharacter"),
        [ViewType.Weapon] = CSXTextManagerGetText("UiFashionDetailTipTitleWeapon"),
    },
}

-- v1.28 采购优化-时装购买CD
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000

---@class XUiFashionDetail:XLuaUi
---@field IsEnableGroupSales number 是否整套购买
local XUiFashionDetail = XLuaUiManager.Register(XLuaUi, "UiFashionDetail")

function XUiFashionDetail:OnAwake()
    self:AutoAddListener()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.SliderCharacterHight.gameObject:SetActiveEx(false)
    self.PanelBtnSwich.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
    self.OnDragModel = handler(self, self.DragModel)
    self:InitPriceHandler()

    -- PanelLackResources 初始化
    if self.PanelLackResources then
        self._PanelLackRes = XUiPanelLackResources.New(self.PanelLackResources, self)
    end
end

function XUiFashionDetail:OnStart(fashionId, isWeaponFashion, buyData, isShowFashionIconWithoutGift, isNeedCD, customWeaponFashionId, customDesc)
    self:InitSceneRoot() --设置摄像机
    self.FashionId = fashionId
    self.IsWeaponFashion = isWeaponFashion
    self.BuyData = buyData
    self.IsShowFashionIconWithoutGift = isShowFashionIconWithoutGift
    self.CustomDesc = customDesc
    self.CustomWeaponFashionId = customWeaponFashionId
    if self.IsWeaponFashion then
        local characterIds = XMVCA.XCharacter:GetCharacterIdsByWeaponFashion(fashionId)
        self.CharacterId = characterIds and characterIds[1] --注意：可能存在一个武器涂装对应多个角色的问题，这里取优先级最高的
    else
        self.CharacterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
    end

    if XWeaponFashionConfigs.IsWeaponFashion(self.FashionId) then 
        --v1.31武器时装
        self.IsHaveFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(self.FashionId) and
            not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.FashionId)
    else
        --v1.28-采购优化-记录是否当前皮肤是否已拥有
        self.IsHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId)})
    end

    -- 配置是否需要购买冷却
    self.IsNeedCD = isNeedCD or false
    -- 记录初始时间
    self.LastBuyTime = CS.UnityEngine.Time.realtimeSinceStartup
    self:CheckWeaponFashionBtnShow()

    self.TrialLevelInfo = XDataCenter.FubenExperimentManager.GetTrialLevelByFashionID(fashionId)
    local functionId = XFunctionManager.FunctionName.Experiment
    local isOpen = XFunctionManager.JudgeCanOpen(functionId)
    self.BtnPlay.gameObject:SetActiveEx(isOpen and self.TrialLevelInfo ~=nil)
    self._StartRun = true
end

function XUiFashionDetail:OnEnable()
    self:InitGroupSales()
    self:SetDetailData()
    
    if self._StartRun then
        self._StartRun = false
    else
        -- 二次显示需要重新刷新已拥有状态
        if XWeaponFashionConfigs.IsWeaponFashion(self.FashionId) then
            --武器时装
            local newIsHaveFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(self.FashionId) and
                    not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.FashionId)
            self.IsHaveFashionStateChanged = newIsHaveFashion ~= self.IsHaveFashion
            self.IsHaveFashion = newIsHaveFashion
        else
            --记录是否当前皮肤是否已拥有
            local newIsHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId)})
            self.IsHaveFashionStateChanged = newIsHaveFashion ~= self.IsHaveFashion
            self.IsHaveFashion = newIsHaveFashion
        end
    end

    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    CS.XGraphicManager.UseUiLightDir = true
    if self.IsWeaponFashion then
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    else
        self:LoadModelScene(false)
        self:UpdateCharacterModel()
    end
    self:InitBuyData()

    self:CheckAndUpdateLackResourcesPanel()
end

function XUiFashionDetail:Close()
    self.Super.Close(self)
    
    -- PurchaseLBUpdateCb为外界自定义追加的界面刷新回调
    if self.IsHaveFashionStateChanged and self.BuyData.PurchaseLBUpdateCb then
        self.BuyData:PurchaseLBUpdateCb()
    end
end

function XUiFashionDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiFashionDetail:OnReleaseInst()
    return self.IsEnableGroupSales
end

function XUiFashionDetail:OnResume(value)
    self.IsEnableGroupSales = value
end

function XUiFashionDetail:OnUiSceneLoaded()
    --self:SetGameObject()
end

function XUiFashionDetail:InitBuyData()
    self.BtnBuy.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(false)
    self.BtnRandomWear.gameObject:SetActiveEx(false)
    -- HideBuyBtn为外界自定义追加字段
    if not self.BuyData or self.BuyData.HideBuyBtn then
        return
    end

    self.TxtHave.gameObject:SetActiveEx(self.BuyData.IsHave)
    -- 礼包中已拥有涂装文本
    self.TxtRepeatWith.gameObject:SetActiveEx(not self.BuyData.IsHave and self.IsHaveFashion)
    self:ShowBuyButton()
    self:UpdatePanelInformation()
    
    self.RawImageConsume:SetRawImage(self.BuyData.ItemIcon)
    self.TxtLimitBuy.text = self.BuyData.LimitText or ""
    self:ShowBuyPrice()

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

function XUiFashionDetail:InitPriceHandler()
    local purchase = XEnumConst.FashionSuit.GainType.Purchase
    local shop = XEnumConst.FashionSuit.GainType.Shop
    local agency = XMVCA.XFashionSuit

    self._PriceHandlers = {}
    self._PriceHandlers.SetDatas = {}
    self._PriceHandlers.TotalPrice = {}
    self._PriceHandlers.RealPrice = {}

    self._PriceHandlers.SetDatas[purchase] = function(tb, params)
        table.insert(tb, XDataCenter.PurchaseManager.GetPurchaseDataById(params[1]))
    end
    self._PriceHandlers.SetDatas[shop] = function(tb, params)
        local data = XShopManager.GetShopGoodsInfo(params[1], params[2])
        tb[data] = params[1]
    end

    self._PriceHandlers.TotalPrice[purchase] = handler(agency, agency.PurchaseConsumeCount)
    self._PriceHandlers.TotalPrice[shop] = handler(agency, agency.GoodsConsumeCount)

    self._PriceHandlers.RealPrice[purchase] = handler(agency, agency.GetRealPurchasePriceWithDiscount)
    self._PriceHandlers.RealPrice[shop] = handler(agency, agency.GetRealGoodsPriceWithDiscount)
end

function XUiFashionDetail:ShowBuyPrice()
    if self.IsEnableGroupSales then
        local dataDict = {}
        local gainType = self.FashionGroup.GainType
        local dict = XMVCA.XFashionSuit:GetGroupNeedToBuyInfo(self.FashionGroup.Id)
        for itemId, params in pairs(dict) do
            if not dataDict[gainType] then
                dataDict[gainType] = {}
            end
            self._PriceHandlers.SetDatas[gainType](dataDict[gainType], params)
        end
        local datas = dataDict[gainType]
        local totalPrice = self._PriceHandlers.TotalPrice[gainType](datas)
        local realPrice = self._PriceHandlers.RealPrice[gainType](datas)
        self.BtnBuy:SetNameByGroup(0, realPrice)
        self.BtnBuy:SetNameByGroup(1, totalPrice)
        self.BtnBuy:ActiveTextByGroup(1, XTool.IsNumberValid(totalPrice))
    else
        self.BtnBuy:SetNameByGroup(0, self.BuyData.ItemCount)
        self.BtnBuy:SetNameByGroup(1, self.BuyData.OriginCount or "")
        self.BtnBuy:ActiveTextByGroup(1, self.BuyData.OriginCount)
    end
end

function XUiFashionDetail:ShowBuyButton()
    local isHave = false
    if self.IsEnableGroupSales then
        --套装组合是否已经购买
        local hasFashion, hasWeaponFashion = self:IsHaveGroupFashion()
        if hasFashion and hasWeaponFashion then
            isHave = true
        end
    else
        isHave = self.BuyData.IsHave or (self.IsHaveFashion and not self.BuyData.IsConvert)
    end
    
    if isHave then
        local isWear, isMulti
        if self.IsEnableGroupSales then
            local fashionId, weaponFashionId = self:GetGroupFashionId()
            isWear = XMVCA.XFashionSuit:IsDressed(fashionId, weaponFashionId, self.CharacterId)
        else
            if self.IsWeaponFashion then
                isWear = XMVCA.XFashionSuit:IsDressed(nil, self.FashionId, self.CharacterId)
            else
                isWear = XMVCA.XFashionSuit:IsDressed(self.FashionId, nil, self.CharacterId)
            end
        end
        
        local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
        local randomFashion = character and character.RandomFashion
        if randomFashion then
            local isRandom
            if self.IsEnableGroupSales then
                local fashionId, weaponFashionId = self:GetGroupFashionId()
                isRandom = XMVCA.XFashionSuit:IsRandom(fashionId, weaponFashionId)
            else
                if self.IsWeaponFashion then
                    isRandom = XMVCA.XFashionSuit:IsRandom(nil, self.FashionId)
                else
                    isRandom = XMVCA.XFashionSuit:IsRandom(self.FashionId, nil)
                end
            end
            self.BtnRandomWear.gameObject:SetActiveEx(true)
            self.BtnRandomWear:SetDisable(isRandom, not isRandom)
        else
            self.BtnWear.gameObject:SetActiveEx(true)
            self.BtnWear:SetDisable(isWear, not isWear)
        end
    else
        self.BtnBuy.gameObject:SetActiveEx(true)
    end
end

function XUiFashionDetail:UpdatePanelInformation()
    local isHave = self.BuyData.IsHave
    local hasLimitText = self.BuyData.LimitText ~= nil
    local hasFashionLabel = not string.IsNilOrEmpty(self.BuyData.FashionLabel)
    self.PanelInformation.gameObject:SetActiveEx(not self.IsEnableGroupSales and (hasLimitText or isHave or hasFashionLabel or self.IsHaveFashion))
end

function XUiFashionDetail:OnSliderCharacterHightChanged()
    local pos = self.CameraNear[CameraIndex.Near].position
    self.CameraNear[CameraIndex.Near].position = CS.UnityEngine.Vector3(pos.x, 1.7 - self.SliderCharacterHight.value, pos.z)
end

--初始化摄像机
function XUiFashionDetail:InitSceneRoot()
    local root = self.UiModelGo.transform

    self.RoleModelPanel = XUiPanelRoleModel.New(root:FindTransform("UiModelParent"), self.Name, nil, true, nil, true)
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.CameraNear = {
        [CameraIndex.Normal] = root:FindTransform("FashionCamNearMain"),
        [CameraIndex.Near] = root:FindTransform("FashionCamNearest"),
    }
end

function XUiFashionDetail:UpdateCamera(camera)
    for _, cameraIndex in pairs(CameraIndex) do
        self.CameraNear[cameraIndex].gameObject:SetActiveEx(cameraIndex == camera)
    end
end

function XUiFashionDetail:OnBtnLensOut()
    self.BtnLensOut.gameObject:SetActiveEx(false)
    self.BtnLensIn.gameObject:SetActiveEx(true)
    self.SliderCharacterHight.gameObject:SetActiveEx(true)
    self:UpdateCamera(CameraIndex.Near)
end

function XUiFashionDetail:OnBtnLensIn()
    self.BtnLensOut.gameObject:SetActiveEx(true)
    self.BtnLensIn.gameObject:SetActiveEx(false)
    self.SliderCharacterHight.gameObject:SetActiveEx(false)
    self:UpdateCamera(CameraIndex.Normal)
end

function XUiFashionDetail:AutoAddListener()
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnGouxuan:AddEventListener(handler(self, self.OnBtnShowWeaponFashion))
    self.BtnPlay:AddEventListener(handler(self, self.OnPlayClick))

    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacterHight, self.OnSliderCharacterHightChanged)
    self.BtnLensOut.CallBack = function() self:OnBtnLensOut() end
    self.BtnLensIn.CallBack = function() self:OnBtnLensIn() end
    self.BtnBuySuit:AddEventListener(handler(self, self.OnBtnBuySuitClick))
    self.BtnWear:AddEventListener(handler(self, self.OnBtnWearClick))
    self.BtnRandomWear:AddEventListener(handler(self, self.OnBtnRandomWearClick))
end

function XUiFashionDetail:SetDetailData()
    self.GoodIdList = {}
    -- v1.28-采购优化-赠品队列展示
    -- 传入Data为单一rewardId的情况
    local giftRewardId = self.BuyData and self.BuyData.GiftRewardId
    if type(giftRewardId) == "number" then
        if giftRewardId ~= 0 then
            local datas = XRewardManager.GetRewardList(giftRewardId)
            if datas then
                self.GoodIdList = datas
            end
        end
    elseif self.BuyData and self.BuyData.GiftRewardId then
        self.GoodIdList = self.BuyData.GiftRewardId
    end

    local id = self.FashionId
    local fashionId = self.IsEnableGroupSales and self.FashionGroup.FashionId or (self.IsWeaponFashion and 0 or id)
    local weaponFashionId = self.IsEnableGroupSales and self.FashionGroup.WeaponFashionId or (self.IsWeaponFashion and id or 0)

    if XTool.IsNumberValid(fashionId) then
        -- v1.31-采购优化-涂装增加CG展示道具
        local subItems = XDataCenter.FashionManager.GetFashionSubItems(fashionId)
        if subItems then
            for _, itemTemplateId in ipairs(subItems) do
                table.insert(self.GoodIdList, { TemplateId = itemTemplateId, Count = 1, IsSubItem = true })
            end
        end

        local giftId = XFashionConfigs.GetFashionTemplate(fashionId).GiftId
        if XTool.IsNumberValid(giftId) then
            local giftGoodShowData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(giftId)
            giftGoodShowData.IsGift = true
            giftGoodShowData.Count = 1
            table.insert(self.GoodIdList, giftGoodShowData)
        end
    end

    --若开启套装购买，则显示全部（角色+武器）
    if self.IsEnableGroupSales then
        table.insert(self.GoodIdList, 1, { TemplateId = weaponFashionId, Count = 1, Disable = true })
        table.insert(self.GoodIdList, 1, { TemplateId = fashionId, Count = 1, Disable = true })
    end

    -- giftRewardId=额外礼物，在商店皮肤界面，没有额外礼物，就显示时装物品
    if self.GoodIdList and #self.GoodIdList > 0 and not self.IsShowFashionIconWithoutGift then
        --显示商品本身
        if not self.IsEnableGroupSales then
            table.insert(self.GoodIdList, 1, { TemplateId = id, Count = 1, Disable = true })
        end
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
        if not self.GridItemObj then
            ---@type XUiGridCommon
            self.GridItemObj = XUiGridCommon.New(self, self.GridItem)
        end
        self.GridItemObj:Refresh({ TemplateId = id, Count = 1 }, { Disable = true })
        self.GridItemObj:SetUiActive(self.GridItemObj.ImgIsHave, self.GridItemObj.TxtHave.gameObject.activeSelf)
    end

    if self.IsEnableGroupSales then
        self.Desc.text = self.FashionGroup.Name
        self.WorldDesc.text = XUiHelper.GetText("FashionGroupSalesDesc")
    else
        local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(id)
        if worldDesc and #worldDesc then
            self.WorldDesc.text = worldDesc
        end

        local desc = XGoodsCommonManager.GetGoodsDescription(id)
        if desc and #desc > 0 then
            self.Desc.text = desc
        end
    end
end

-- v1.28-采购优化-时装礼包赠品动态列表更新
---@param grid XUiGridCommon
function XUiFashionDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local gridData = self.GoodIdList[index]
        if gridData.Disable then
            local params = { Disable = true } --屏蔽点击
            grid:Refresh(gridData, params)
        else
            grid:Refresh(gridData)
        end
        -- 已拥有图标显示
        -- 涂装子道具随绑定涂装的拥有而显示已拥有状态
        if (gridData.IsSubItem and self.IsHaveFashion) or (self.BuyData and self.BuyData.ItemCount == 0) then
            grid:SetUiActive(grid.TxtHave, true)
        end
        grid:SetUiActive(grid.ImgIsHave, grid.TxtHave.gameObject.activeSelf)
    end
end

function XUiFashionDetail:DragModel(model)
    self.PanelDrag:GetComponent("XDrag").Target = model.transform
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(true)
end

function XUiFashionDetail:UpdateCharacterModel()
    local template = XDataCenter.FashionManager.GetFashionTemplate(self.FashionId)

    local weaponFashionId
    if XTool.IsNumberValid(self.CustomWeaponFashionId) then
        -- 勾选则显示自定义武器涂装，不勾选则显示当前穿戴武器涂装
        if self.IsCustomWeaponFashion then
            weaponFashionId = self.CustomWeaponFashionId
        else
            weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(template.CharacterId)
        end
    elseif self.IsEnableGroupSales then
        weaponFashionId = self.FashionGroup.WeaponFashionId
    end

    self.TxtTitle.text = TitleName.Title[self.IsEnableGroupSales and ViewType.FashionGroup or ViewType.Character]
    self.TxtTipTitle.text = TitleName.TipTitle[self.IsEnableGroupSales and ViewType.FashionGroup or ViewType.Character]
    self.TxtFashionName.text = template.Name
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(true)
    self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashionDetail, self.OnDragModel, nil, weaponFashionId)

    if XTool.DebugIsShowItemIdOnUi() then
        self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s)", template.Id)
        self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 800)
    end
end

function XUiFashionDetail:UpdateWeaponModel()
    local weaponFashionId = self.FashionId
    local uiName = XModelManager.MODEL_UINAME.XUiFashionDetail
    local modelConfig = XDataCenter.WeaponFashionManager.GetWeaponModelCfg(weaponFashionId, nil, uiName)
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)

    self.TxtTitle.text = TitleName.Title[self.IsEnableGroupSales and ViewType.FashionGroup or ViewType.Weapon]
    self.TxtTipTitle.text = TitleName.TipTitle[self.IsEnableGroupSales and ViewType.FashionGroup or ViewType.Weapon]
    self.TxtFashionName.text = fashionName
    self.RoleModelPanel.GameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)

    if self.IsEnableGroupSales then
        local fashionId, weaponFashionId = self:GetGroupFashionId()
        local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        self.PanelWeapon.gameObject:SetActiveEx(false)
        self.RoleModelPanel.GameObject:SetActiveEx(true)
        self.RoleModelPanel:UpdateCharacterResModel(template.ResourcesId, template.CharacterId, XModelManager.MODEL_UINAME.XUiFashionDetail, self.OnDragModel, nil, weaponFashionId)
    else
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, uiName, nil, { gameObject = self.GameObject, IsDragRotation = true }, self.PanelDrag)
    end

    if XTool.DebugIsShowItemIdOnUi() then
        local itemId
        if self.BuyData and self.BuyData.CurRewardGoods then
            itemId = self.BuyData.CurRewardGoods.TemplateId
        end
        if itemId then
            self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s, Item:%s)", self.FashionId, itemId)
            self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 1500)
        else
            self.TxtTitle.text = self.TxtTitle.text .. string.format("(Id:%s)", self.FashionId)
            self.TxtTitle.transform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, 800)
        end
    end
end

function XUiFashionDetail:OnBtnBackClick()
    self:Close()
end

function XUiFashionDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--- 执行正常购买流程前的处理，用于特殊逻辑
function XUiFashionDetail:OnBeforeBtnBuyClick(cb)
    --3.1莉莉丝可肝卡池特殊涂装
    local lilithFashionId = XGachaConfigs.GetClientConfigNumber('SpeicalFashionFromPurchaseToGachaShop', 1)

    if XTool.IsNumberValid(lilithFashionId) and lilithFashionId == self.FashionId and not self.BuyData.FromGachaShop then
        local skipCondition = XGachaConfigs.GetClientConfigNumber('SpecialConditionFromPurchaseToGachaShop', 1)
        -- 判断条件满足，因为具有特殊性，未配置视为不可跳转
        if XTool.IsNumberValid(skipCondition) and XConditionManager.CheckCondition(skipCondition) then
            local skipId = XGachaConfigs.GetClientConfigNumber('SpecialSkipToGachaShop', 1)
            if XTool.IsNumberValid(skipId) then
                XLuaUiManager.Open('UiGachaCanLiverDialog', cb, skipId)
                return
            end
        end
    end
    
    -- 未执行特殊逻辑，则直接执行回调
    if cb then
        cb()
    end
end

function XUiFashionDetail:ShowBuyPopup()
    if self.IsEnableGroupSales then
        self:BuyFashionGroup()
        return
    end
    local title = XUiHelper.GetText("PurchaseFashionRepeatTipsTitle")
    local content = XUiHelper.GetText("PurchaseFashionRepeatTipsContent")
    local sureCb = function ()
        if self.BuyData.QuickBuyCallBack~=nil and XOverseaManager.IsTWRegion() then
            self.BuyData.QuickBuyCallBack()
        else
            self.BuyData.BuyCallBack()
        end

        self:OnBtnBackClick()
    end
    -- 已有涂装则二次确认，V1.31折价礼包不弹二次确认提示
    if self.IsHaveFashion and not self.BuyData.IsConvert then
        XUiManager.DialogTip(title, content, nil, nil, sureCb)
    else
        sureCb()
    end
end

function XUiFashionDetail:LoadModelScene(isDefault)
    local sceneUrl = self:GetSceneUrl(isDefault)
    local modelUrl = self:GetDefaultUiModelUrl()
    self:LoadUiScene(sceneUrl, modelUrl, self.OnUiSceneLoadedCB, false)
end

function XUiFashionDetail:GetSceneUrl(isDefault)
    if isDefault then
        return self:GetDefaultSceneUrl()
    end

    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(self.FashionId)
    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end

--region 显示武器时装

function XUiFashionDetail:CheckWeaponFashionBtnShow()
    if XTool.IsNumberValid(self.CustomWeaponFashionId) then
        self.PanelAdd.gameObject:SetActiveEx(true)
        self.TxtToggleDesc.text = self.CustomDesc or ""
        self.BtnGouxuan:SetButtonState(CS.UiButtonState.Select)
        self.IsCustomWeaponFashion = true
    else
        self.PanelAdd.gameObject:SetActiveEx(false)
    end
end

function XUiFashionDetail:OnBtnShowWeaponFashion()
    self.IsCustomWeaponFashion = self.BtnGouxuan:GetToggleState()
    self:LoadModelScene(false)
    self:UpdateCharacterModel()
end

function XUiFashionDetail:OnBtnBuyClick()
    -- v1.28 采购优化 记录时间, 判断是否拦截
    if self.IsNeedCD then
        if self.LastBuyTime and CS.UnityEngine.Time.realtimeSinceStartup - self.LastBuyTime > PurchaseBuyPayCD then
            self.LastBuyTime = CS.UnityEngine.Time.realtimeSinceStartup
            self:OnBeforeBtnBuyClick(handler(self, self.ShowBuyPopup))
        end
    else
        self:OnBeforeBtnBuyClick(handler(self, self.ShowBuyPopup))
    end
end

--endregion

--region 跳转试玩
function XUiFashionDetail:OnPlayClick()
    XLuaUiManager.Open("UiPaintingExperiencePassV4P2",self.TrialLevelInfo.Id)
end
    
--endregion

--region 成套购买（武器涂装+角色涂装）

function XUiFashionDetail:InitGroupSales()
    local isVisible = XMVCA.XFashionSuit:IsAllowGroupSales(self.FashionId)
    if isVisible then
        self.FashionGroup = XMVCA.XFashionSuit:GetFashionGroupByFashionId(self.FashionId)
        if not self.FashionGroup then
            XLog.Error(string.format("【涂装：%s 是否武器：%s】找不到对应配置！", self.FashionId, self.IsWeaponFashion))
        end
    end
    self.BtnBuySuit.gameObject:SetActiveEx(isVisible)
    self.BtnBuySuit:SetButtonState(self.IsEnableGroupSales and XUiButtonState.Select or XUiButtonState.Normal)
end

---角色涂装Id、武器涂装Id
---@return number,number
function XUiFashionDetail:GetGroupFashionId()
    return self.FashionGroup.FashionId, self.FashionGroup.WeaponFashionId
end

---是否拥有角色涂装、是否拥有武器涂装
---@return boolean,boolean
function XUiFashionDetail:IsHaveGroupFashion()
    local fashionId, weaponFashionId = self:GetGroupFashionId()
    local hasFashion = XDataCenter.FashionManager.CheckHasFashion(fashionId) and XDataCenter.FashionManager.IsFashionInTime(fashionId)
    local hasWeaponFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(weaponFashionId) and not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(weaponFashionId)
    return hasFashion, hasWeaponFashion
end

function XUiFashionDetail:OnBtnBuySuitClick()
    self.IsEnableGroupSales = self.BtnBuySuit.ButtonState == CS.UiButtonState.Select
    self:InitBuyData()
    self:SetDetailData()
    if self.IsWeaponFashion then
        self:UpdateWeaponModel()
    else
        self:UpdateCharacterModel()
    end
end

function XUiFashionDetail:OnBtnWearClick()
    local needDressed = {}
    if self.IsEnableGroupSales then
        --找到套装组合里还没有穿戴的涂装
        local fashionId, weaponFashionId = self:GetGroupFashionId()
        if not XMVCA.XFashionSuit:IsFashionDressed(fashionId) then
            table.insert(needDressed, fashionId)
        end
        if not XMVCA.XFashionSuit:IsWeaponFashionDressed(weaponFashionId, self.CharacterId) then
            table.insert(needDressed, weaponFashionId)
        end
    else
        table.insert(needDressed, self.FashionId)
    end
    
    XMVCA.XFashionSuit:RecursionUseFashion(self.CharacterId, needDressed, function()
        XUiManager.TipText("UseSuccess")
        self.BtnWear:SetDisable(true, false)
    end)
end

function XUiFashionDetail:OnBtnRandomWearClick()
    local fashionId, weaponFashionId
    if self.IsEnableGroupSales then
        fashionId, weaponFashionId = self:GetGroupFashionId()
    elseif self.IsWeaponFashion then
        weaponFashionId = self.FashionId
    else
        fashionId = self.FashionId
    end

    XMVCA.XFashionSuit:JoinFashionToRandom(self.CharacterId, fashionId, weaponFashionId, function()
        XUiManager.TipText("FashionAddToRandomTip")
        self.BtnRandomWear:SetDisable(true, false)
    end)
end

function XUiFashionDetail:BuyFashionGroup()
    if self.BuyData.PurchaseLBUpdateCb then
        XMVCA.XFashionSuit:PurchaseBuyFashionGroup(self.FashionGroup.Id, self.BuyData.PurchaseLBUpdateCb)
        self:OnBtnBackClick()
        return
    end
    if not self.BuyData.GroupBuyCallBack then
        XLog.Error("购买套装组合失败：未注册GroupBuyCallBack方法.")
        return
    end
    self.BuyData.GroupBuyCallBack(self.FashionGroup.Id)
    self:OnBtnBackClick()
end

--endregion

--region 资源缺失面板

function XUiFashionDetail:CheckAndUpdateLackResourcesPanel()
    if not self._PanelLackRes then return end
    local fashionId = self.FashionId
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
        local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        local characterId = template and template.CharacterId or 0
        self._PanelLackRes:SetData(characterId, fashionId)
        self._PanelLackRes:Open()
        self._isFashionLacking = true
    end
end

function XUiFashionDetail:OnFashionDownloadComplete()
    if not self._isFashionLacking then
        self:CheckAndUpdateLackResourcesPanel()
        return
    end
    local fashionId = self.FashionId
    if XTool.IsNumberValid(fashionId)
       and XMVCA.XSubPackage:CheckFashionDownloaded(fashionId) then
        if self.IsWeaponFashion then
            self:UpdateWeaponModel()
        else
            self:UpdateCharacterModel()
        end
        local fashionTemplate = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("DownloadFashionFinishedRefresh", fashionTemplate and fashionTemplate.Name or ""))
    end
    self:CheckAndUpdateLackResourcesPanel()
end

--endregion