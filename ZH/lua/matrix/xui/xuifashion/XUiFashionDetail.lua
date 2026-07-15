local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelLackResources = require("XUi/XUiSubPackage/XUiPanel/XUiPanelLackResources")
local XUiFashionColor = require("XUi/XUiFashion/Panel/XUiFashionColor")
local XFashionControl = require("XModule/XFashion/XFashionControl")
local CameraIndex = {
    Normal = 1,
    Near = 2,
}

local FashionType = XFashionControl.FashionType

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
    --self.FashionColorPanel = XUiFashionColor.New(self.PanelDot, self)
    self.OnUiSceneLoadedCB = function() self:OnUiSceneLoaded() end
    self.OnDragModel = handler(self, self.DragModel)
    self:InitPriceHandler()
    
    -- PanelLackResources 初始化
    if self.PanelLackResources then
        self._PanelLackRes = XUiPanelLackResources.New(self.PanelLackResources, self)
    end
end

---@param buyData XPurchaseBuyData 礼包购买数据契约，定义见 XPurchaseConfigs
function XUiFashionDetail:OnStart(
    fashionId,
    fashionType,
    buyData,
    isShowFashionIconWithoutGift,
    isNeedCD,
    customWeaponFashionId,
    customDesc,
    customAssetItemIds)

    -- 初始化资源栏
    self._ShowAssetsItemIds = customAssetItemIds or { XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin }
    self._HideGroupSales = XMVCA.XFashionSuit:ConsumeFromSelfChoicePack() --来自自选礼包则隐藏成套购买开关

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, table.unpack(self._ShowAssetsItemIds))


    self:InitSceneRoot() --设置摄像机
    self.FashionId = fashionId
    -- fashionType 兼容旧的 bool 传参（isWeaponFashion=true 视为 Weapon）
    if fashionType == true then
        self.FashionType = FashionType.Weapon
    elseif fashionType == false or fashionType == nil then
        self.FashionType = FashionType.Normal
    else
        self.FashionType = fashionType
    end
    self.IsWeaponFashion = self.FashionType == FashionType.Weapon
    self.BuyData = buyData
    self.IsShowFashionIconWithoutGift = isShowFashionIconWithoutGift
    
    self.CustomDesc = customDesc
    self.CustomWeaponFashionId = customWeaponFashionId
    if self.IsWeaponFashion then
        local characterIds = XMVCA.XCharacter:GetCharacterIdsByWeaponFashion(fashionId)
        self.CharacterId = characterIds and characterIds[1] --注意：可能存在一个武器涂装对应多个角色的问题，这里取优先级最高的
    elseif self.FashionType == FashionType.Color then
        local fashionId = XMVCA.XFashion:GetFashionColorOriginalFashionId(self.FashionId)
        self.CharacterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
    else
        self.CharacterId = XDataCenter.FashionManager.GetCharacterId(fashionId)
    end

    if XWeaponFashionConfigs.IsWeaponFashion(self.FashionId) then
        --v1.31武器时装
        self.IsHaveFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(self.FashionId) and
            not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.FashionId)
    elseif self.FashionType == FashionType.Color then
        local originalFashionId = XMVCA.XFashion:GetFashionColorOriginalFashionId(fashionId)
        self.IsHaveFashion = XTool.IsNumberValid(originalFashionId) and XMVCA.XFashion:IsFashionColorHas(originalFashionId, fashionId)
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
    --if self.IsWeaponFashion or self.FashionType == FashionType.Color then
    --    self.FashionColorPanel:Close()
    --else
    --    self.FashionColorPanel:Refresh(fashionId)
    --end
    self:RefreshFashionDot(fashionId)
end

function XUiFashionDetail:RefreshFashionDot(fashionId)
    --if self.IsWeaponFashion or self.FashionType == FashionType.Color then
        self.FashionDot.gameObject:SetActiveEx(false)
    --    return
    --end
    --local fashionTemplate = XFashionConfigs.GetFashionTemplate(fashionId)
    --local colorHex = fashionTemplate and fashionTemplate.FashionColorHex
    --if string.IsNilOrEmpty(colorHex) then
    --    self.FashionDot.gameObject:SetActiveEx(false)
    --    return
    --end
    --self.FashionDot.gameObject:SetActiveEx(true)
    --self.ImgColour.color = XUiHelper.Hexcolor2Color(string.sub(colorHex, 2, #colorHex))
end

function XUiFashionDetail:OnEnable()
    self:InitGroupSales()
    self:SetDetailData()
    
    if self._StartRun then
        self._StartRun = false
    else
        -- 二次显示需要重新刷新已拥有状态
        self:RefreshFashionHaveState()
    end
    
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    CS.XGraphicManager.UseUiLightDir = true
    if self.IsWeaponFashion then
        self:LoadModelScene(true)
        self:UpdateWeaponModel()
    elseif self.FashionType == FashionType.Color then
        self:LoadModelScene(false)
        self:UpdateFashionColorModel()
    else
        self:LoadModelScene(false)
        self:UpdateCharacterModel()
    end
    self:InitBuyData()

    self:_AddConsumeCountListener()
    self:CheckAndUpdateLackResourcesPanel()
end

function XUiFashionDetail:Close()
    XUiFashionDetail.Super.Close(self)

    -- PurchaseLBUpdateCb为外界自定义追加的界面刷新回调
    if self.IsHaveFashionStateChanged and self.BuyData.PurchaseLBUpdateCb then
        self.BuyData:PurchaseLBUpdateCb()
    end
end

function XUiFashionDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnFashionDownloadComplete, self)
    self:_RemoveConsumeCountListener()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiFashionDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_LB_UPDATE,
        XEventId.EVENT_SHOP_BUY_SUCCESS,
    }
end

function XUiFashionDetail:OnNotify(evt)
    if evt == XEventId.EVENT_LB_UPDATE or evt == XEventId.EVENT_SHOP_BUY_SUCCESS then
        self:RefreshFashionHaveState()
        self:SetDetailData()
        -- HideBuyBtn为外界自定义追加字段，与 InitBuyData 口径一致：隐藏购买按钮的入口下不刷新购买按钮
        if not self.BuyData or self.BuyData.HideBuyBtn then
            return
        end
        self:ShowBuyButton()
        self:ShowBuyPrice()
    end
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
    
    local itemIcon = self.BuyData.ItemIcon
    self.RawImageConsume.gameObject:SetActiveEx(not string.IsNilOrEmpty(itemIcon))
    if not string.IsNilOrEmpty(itemIcon) then
        self.RawImageConsume:SetRawImage(itemIcon)
    end
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
    local isMoneyEnough = self:_CheckBuyEnough()
    
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

        local readCountStr = isMoneyEnough and tostring(realPrice) or XUiHelper.GetText("PurchaseFashionDetailCoinNotEnough", realPrice)

        self.BtnBuy:SetNameByGroup(0, readCountStr)
        self.BtnBuy:SetNameByGroup(1, totalPrice)
        self.BtnBuy:ActiveTextByGroup(1, XTool.IsNumberValid(totalPrice))
    else
        local readCountStr = isMoneyEnough and tostring(self.BuyData.ItemCount) or XUiHelper.GetText("PurchaseFashionDetailCoinNotEnough", self.BuyData.ItemCount)
        
        self.BtnBuy:SetNameByGroup(0, readCountStr)
        self.BtnBuy:SetNameByGroup(1, self.BuyData.OriginCount or "")
        self.BtnBuy:ActiveTextByGroup(1, self.BuyData.OriginCount)
    end
end

--- 购买货币数量变化时，仅刷新购买价格的充足性显示（轻量，不重载模型/不重建界面）
function XUiFashionDetail:_OnConsumeCountChanged()
    if XTool.UObjIsNil(self.GameObject) then return end
    -- 与 InitBuyData/OnNotify 守卫口径一致
    if not self.BuyData or self.BuyData.HideBuyBtn then return end
    -- 已拥有/穿戴态下购买按钮已隐藏，无需刷新
    if XTool.UObjIsNil(self.BtnBuy) or not self.BtnBuy.gameObject.activeSelf then return end
    self:ShowBuyPrice()
end

--- 注册购买货币数量变化监听（node 用 BtnBuy）
function XUiFashionDetail:_AddConsumeCountListener()
    self:_RemoveConsumeCountListener()   -- 先移除防重复叠加
    local consumeId = self.BuyData and self.BuyData.ConsumeId
    if not XTool.IsNumberValidEx(consumeId) then return end
    XDataCenter.ItemManager.AddCountUpdateListener(consumeId, handler(self, self._OnConsumeCountChanged), self.BtnBuy)
end

function XUiFashionDetail:_RemoveConsumeCountListener()
    if not XTool.UObjIsNil(self.BtnBuy) then
        XDataCenter.ItemManager.RemoveCountUpdateListener(self.BtnBuy)
    end
end

function XUiFashionDetail:RefreshFashionHaveState()
    if XWeaponFashionConfigs.IsWeaponFashion(self.FashionId) then
        --武器时装
        local newIsHaveFashion = XDataCenter.WeaponFashionManager.CheckHasFashion(self.FashionId) and
                not XDataCenter.WeaponFashionManager.IsFashionTimeLimit(self.FashionId)
        self.IsHaveFashionStateChanged = newIsHaveFashion ~= self.IsHaveFashion
        self.IsHaveFashion = newIsHaveFashion
    elseif self.FashionType == FashionType.Color then
        local originalFashionId = XMVCA.XFashion:GetFashionColorOriginalFashionId(self.FashionId)
        local newIsHaveFashion = XTool.IsNumberValid(originalFashionId) and XMVCA.XFashion:IsFashionColorHas(originalFashionId, self.FashionId)
        self.IsHaveFashionStateChanged = newIsHaveFashion ~= self.IsHaveFashion
        self.IsHaveFashion = newIsHaveFashion
    else
        --记录是否当前皮肤是否已拥有
        local newIsHaveFashion = XRewardManager.CheckRewardGoodsListIsOwnWithAll({XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.FashionId)})
        self.IsHaveFashionStateChanged = newIsHaveFashion ~= self.IsHaveFashion
        self.IsHaveFashion = newIsHaveFashion
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
        local isWear
        if self.IsEnableGroupSales then
            local fashionId, weaponFashionId = self:GetGroupFashionId()
            isWear = XMVCA.XFashionSuit:IsDressed(fashionId, weaponFashionId, self.CharacterId)
        else
            if self.IsWeaponFashion then
                isWear = XMVCA.XFashionSuit:IsDressed(nil, self.FashionId, self.CharacterId)
            elseif self.FashionType == FashionType.Color then
                local hasThisFashionColor = XMVCA.XFashion:IsFashionColorHas(
                    XMVCA.XFashion:GetFashionColorOriginalFashionId(self.FashionId),
                    self.FashionId)

                self.BtnBuy.gameObject:SetActiveEx(not hasThisFashionColor)
                return
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

        self.BtnBuy.gameObject:SetActiveEx(false)
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
    local goodIdList = self:_GetRewardDataList()

    local id = self.FashionId

    -- giftRewardId=额外礼物，在商店皮肤界面，没有额外礼物，就显示时装物品
    if self.FashionType == FashionType.Color then
        -- FashionColor：用 FashionColor.tab 的 FashionIcon 字段显示图标
        local icon = XMVCA.XFashion:GetFashionColorIcon(id)
        local originalFashionId = XMVCA.XFashion:GetFashionColorOriginalFashionId(id)
        local isHave = XTool.IsNumberValid(originalFashionId) and XMVCA.XFashion:IsFashionColorHas(originalFashionId, id)
        self.GridItem.gameObject:SetActiveEx(true)
        self.RewordGoodList.gameObject:SetActiveEx(false)
        if not self.GridItemObj then
            self.GridItemObj = XUiGridCommon.New(self, self.GridItem)
        end
        self.GridItemObj:ResetUi()
        self.GridItemObj:ShowIcon(icon)
        self.GridItemObj:SetUiActive(self.GridItemObj.TxtHave, isHave)
    elseif not XTool.IsTableEmpty(goodIdList) and not self.IsShowFashionIconWithoutGift then
        self.GridItem.gameObject:SetActiveEx(false)
        self.RewordGoodList.gameObject:SetActiveEx(true)
        self.GridGoodItem.gameObject:SetActiveEx(false)
        self.DynamicTable = XDynamicTableNormal.New(self.RewordGoodList)
        self.DynamicTable:SetProxy(XUiGridCommon)
        self.DynamicTable:SetDelegate(self)
        self.DynamicTable:SetDataSource(goodIdList)
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
        self.GridItemObj:Refresh(goodIdList, { Disable = true })
        self.GridItemObj:SetUiActive(self.GridItemObj.ImgIsHave, self.GridItemObj.TxtHave.gameObject.activeSelf)
    end

    if self.IsEnableGroupSales then
        self.Desc.text = self.FashionGroup.Name
        self.WorldDesc.text = XUiHelper.GetText("FashionGroupSalesDesc")
    elseif self.FashionType == FashionType.Color then
        self.WorldDesc.text = XUiHelper.ConvertLineBreakSymbol(XMVCA.XFashion:GetFashionColorWorldDescription(id))
        self.Desc.text = XUiHelper.ConvertLineBreakSymbol(XMVCA.XFashion:GetFashionColorDescription(id))
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
        local gridData = self.RewardDataList[index]
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

function XUiFashionDetail:UpdateFashionColorModel()
    local colorName = XUiHelper.ConvertLineBreakSymbol(XMVCA.XFashion:GetFashionColorNameVertical(self.FashionId))
    local resId = XMVCA.XFashion:GetFashionColorResourcesId(self.FashionId)

    self.TxtTitle.text = TitleName.Title[ViewType.Character]
    self.TxtTipTitle.text = TitleName.TipTitle[ViewType.Character]
    self.TxtFashionName.text = colorName
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.RoleModelPanel.GameObject:SetActiveEx(true)
    self.PanelBtnLens.gameObject:SetActiveEx(true)

    self.RoleModelPanel:UpdateCharacterResModel(
        resId,
        self.CharacterId,
        XModelManager.MODEL_UINAME.XUiFashionDetail,
        self.OnDragModel,
        nil,
        nil)
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
    
    -- 构建viewmodel

    ---@type CoatingBuyTipsViewModel
    local viewModel = {
        Title = self.TxtFashionName.text, -- 和UI文本一致即可
        SubTitle = self.Desc.text, -- 和UI文本一致即可
        DetailDesc = self.WorldDesc.text, -- 和UI文本一致即可
        RewardDataList = self.RewardDataList,
        RealCost = self.BuyData.ItemCount,
        OriginCost = self.BuyData.OriginCount,
        ItemId = self.BuyData.ConsumeId,
        AssetsItemIds = self._ShowAssetsItemIds,
        EndTime = self.BuyData.EndTime,
        IsTimeLimit = XTool.IsNumberValid(self.BuyData.EndTime),
    }

    -- 打开详情界面
    XLuaUiManager.Open("UiPurchaseBuyCoatingTips", viewModel, cb, handler(self, self.Close))
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

        if not self.BuyData.CloseByBuyCallBack then
            -- self:OnBtnBackClick()
        end
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
    if isDefault or self.FashionType == FashionType.Color then
        return self:GetDefaultSceneUrl()
    end

    local sceneUrl = XDataCenter.FashionManager.GetFashionSceneUrl(self.FashionId)
    if sceneUrl and sceneUrl ~= "" then
        return sceneUrl
    else
        return self:GetDefaultSceneUrl()
    end
end

--- 判断当前是否足够资源购买，参数依赖外部传参
function XUiFashionDetail:_CheckBuyEnough()
    local consumeId = self.BuyData.ConsumeId
    local consumeNeedCount = self.BuyData.ItemCount

    if not XTool.IsNumberValidEx(consumeNeedCount) or not XTool.IsNumberValidEx(consumeId) then
        -- 参数不充分默认足够
        return true
    end
    
    local haveCount = XDataCenter.ItemManager.GetCount(consumeId)
    
    return haveCount >= consumeNeedCount
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
    local isVisible = XMVCA.XFashionSuit:IsAllowGroupSales(self.FashionId) and not self._HideGroupSales
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
    -- 注意：货币监听在 OnEnable 时按当时的 BuyData.ConsumeId 注册，此处切换成套/单件后未重注册。
    -- 若成套购买与单件购买使用不同 ConsumeId，切换后停留期间该币种变动不会实时刷新购买按钮
    -- （切换瞬间 InitBuyData→ShowBuyPrice 仍会刷一次，仅"停留期实时"有盲区）。当前两者货币一致，暂不处理。
    self:SetDetailData()
    if self.IsWeaponFashion then
        self:UpdateWeaponModel()
    elseif self.FashionType == FashionType.Color then
        self:UpdateFashionColorModel()
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
        -- self:OnBtnBackClick()
        return
    end
    if not self.BuyData.GroupBuyCallBack then
        XLog.Error("购买套装组合失败：未注册GroupBuyCallBack方法.")
        return
    end
    self.BuyData.GroupBuyCallBack(self.FashionGroup.Id)
    -- self:OnBtnBackClick()
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
        elseif self.FashionType == FashionType.Color then
            self:UpdateFashionColorModel()
        else
            self:UpdateCharacterModel()
        end
        local fashionTemplate = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("DownloadFashionFinishedRefresh", fashionTemplate and fashionTemplate.Name or ""))
    end
    self:CheckAndUpdateLackResourcesPanel()
end

--endregion

--- 封装获取标准奖励格式的对象列表
function XUiFashionDetail:_GetRewardDataList()
    if self.RewardDataList == nil then
        self.RewardDataList = {}

        -- v1.28-采购优化-赠品队列展示
        -- 传入Data为单一rewardId的情况
        local giftRewardId = self.BuyData and self.BuyData.GiftRewardId
        
        if type(giftRewardId) == "number" then
            if giftRewardId ~= 0 then
                local datas = XRewardManager.GetRewardList(giftRewardId)
                if datas then
                    self.RewardDataList = datas
                end
            end
        elseif self.BuyData and self.BuyData.GiftRewardId then
            self.RewardDataList = self.BuyData.GiftRewardId
        end

        local id = self.FashionId
        local fashionId = self.IsEnableGroupSales and self.FashionGroup.FashionId or (self.IsWeaponFashion and 0 or (self.FashionType == FashionType.Color and 0 or id))
        local weaponFashionId = self.IsEnableGroupSales and self.FashionGroup.WeaponFashionId or (self.IsWeaponFashion and id or 0)

        if XTool.IsNumberValid(fashionId) then
            -- v1.31-采购优化-涂装增加CG展示道具
            local subItems = XDataCenter.FashionManager.GetFashionSubItems(fashionId)
            if subItems then
                for _, itemTemplateId in ipairs(subItems) do
                    table.insert(self.RewardDataList, { TemplateId = itemTemplateId, Count = 1, IsSubItem = true })
                end
            end

            local giftId = XFashionConfigs.GetFashionTemplate(fashionId).GiftId
            if XTool.IsNumberValid(giftId) then
                local giftGoodShowData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(giftId)
                giftGoodShowData.IsGift = true
                giftGoodShowData.Count = 1
                table.insert(self.RewardDataList, giftGoodShowData)
            end
        end

        --若开启套装购买，则显示全部（角色+武器）
        if self.IsEnableGroupSales then
            table.insert(self.RewardDataList, 1, { TemplateId = weaponFashionId, Count = 1, Disable = true })
            table.insert(self.RewardDataList, 1, { TemplateId = fashionId, Count = 1, Disable = true })
        elseif not XTool.IsTableEmpty(self.RewardDataList) and not self.IsShowFashionIconWithoutGift then
            --显示商品本身
            table.insert(self.RewardDataList, 1, { TemplateId = id, Count = 1, Disable = true })
        else
            self.RewardDataList = { { TemplateId = id, Count = 1, Disable = true } }
        end
    end

    return self.RewardDataList
end

return XUiFashionDetail
