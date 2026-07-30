local XUiPanelShopPeriod = require("XUi/XUiShop/XUiPanelShopPeriod")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiPanelItemList = require("XUi/XUiShop/XUiPanelItemList")
local XUiPanelFashionList = require("XUi/XUiShop/XUiPanelFashionList")
local XUiPanelGuildGoodsList = require("XUi/XUiShop/XUiPanelGuildGoodsList")
local XUiPanelCommanderDIYList = require("XUi/XUiShop/XUiPanelCommanderDIYList")
local XUiShopFashionDiscountActivity = require("XUi/XUiShop/XUiShopFashionDiscountActivity")
---@class XUiShop: XLuaUi
local XUiShop = XLuaUiManager.Register(XLuaUi, "UiShop")
local type = type
local ShopFunctionOpenIdDic = {
    [XShopManager.ShopType.Common] = XFunctionManager.FunctionName.ShopCommon,
    [XShopManager.ShopType.Activity] = XFunctionManager.FunctionName.ShopActive,
    [XShopManager.ShopType.Points] = XFunctionManager.FunctionName.ShopPoints,
    [XShopManager.ShopType.Recharge] = XFunctionManager.FunctionName.ShopRecharge
}

local ShopTypeDic = {
    [1] = XShopManager.ShopType.Common,
    [2] = XShopManager.ShopType.Points,
    [3] = XShopManager.ShopType.Activity,
    [4] = XShopManager.ShopType.Recharge
}

local PanelConfigs = {
    [XShopConfigs.ShowType.Normal] = {
        Class = XUiPanelItemList,
        Ui = "ItemList",
        UiPanel = "PanelItemList"
    },
    [XShopConfigs.ShowType.Fashion] = {
        Class = XUiPanelFashionList,
        Ui = "FashionList",
        UiPanel = "PanelFashionList"
    },
    [XShopConfigs.ShowType.CommanderDIY] = {
        Class = XUiPanelCommanderDIYList,
        Ui = "CommanderDIYList",
        UiPanel = "PanelDIYList"
    },
    [XShopConfigs.ShowType.GuildScene] = {
        Class = XUiPanelGuildGoodsList,
        Ui = "GuildGoodsList",
        UiPanel = "PanelGuildGoodsList"
    }
}

local ShopIndexDic = {
    [XShopManager.ShopType.Common] = 1,
    [XShopManager.ShopType.Activity] = 3,
    [XShopManager.ShopType.Points] = 2,
    [XShopManager.ShopType.Recharge] = 4
}

local SelectType = {
    Suit = 2,
    Weapon = 3
}

function XUiShop:OnAwake()
    self.TabBtnGroupSelectIndex = nil
    self:InitAutoScript()
end

function XUiShop:OnStart(typeId, cb, configShopId, screenId)
    if type(typeId) == "function" then
        cb = typeId
        typeId = nil
    end

    if typeId then
        self.Type = typeId
    else
        self.Type = XShopManager.ShopType.Common
    end

    self.cb = cb
    self.ConfigShopId = configShopId
    self.ScreenId = screenId

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    ---@type XUiPanelActivityAsset
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset, self, nil, self)
    -- 实例化面板
    for _, config in pairs(PanelConfigs) do
        self[config.Ui] = config.Class.New(self[config.UiPanel], self)
    end
    self.ShopPeriod = XUiPanelShopPeriod.New(self.PanelShopPeriod, self)
    self.RefreshTips = require("XUi/XUiShop/XUiShopRefreshTips").New(self.PanelSkillDetails)
    self.UiShopFashionDiscountActivity = XUiShopFashionDiscountActivity.New(self)

    self.PanelLists = {}
    for showType, config in pairs(PanelConfigs) do
        self.PanelLists[showType] = self[config.Ui]
    end

    self.AssetActivityPanel:HidePanel()
    for _, panel in pairs(self.PanelLists) do
        panel:HidePanel()
    end
    self.ShopPeriod:HidePanel()

    self.CallSerber = false
    self.BtnGoList = {}
    self.ShopTables = {}
    -- 按钮对象池: BtnPool[shopType][index] = uiButton, 跨类型切换时复用, 避免 Instantiate 堆积
    self.BtnPool = {}

    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)

    self.ScreenGroupIDList = {}
    self.ScreenNum = 1
    self.IsHasScreen = false
    self.RefreshBuyTime = 0

    self.TagBtnShopGroup = {}
    self.FilterResult = {}
    XShopManager.ClearBaseInfoData()

    -- XShopManager.GetBaseInfo(function()
    --     self:SetShopBtn(self.Type)
    --     self:UpdateTog()
    -- end)

    self:SetTitleName(typeId)

end

function XUiShop:OnEnable()
    XUiShop.Super.OnEnable(self)
    XShopManager.GetBaseInfo(function()
        self:SetShopBtn(self.Type)
        self:UpdateTog()
    end)
    XEventManager.AddEventListener(XEventId.EVENT_SHOP_ITEM_NOT_ENOUGH, self.OnShopItemNotEnough, self)
end

function XUiShop:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_SHOP_ITEM_NOT_ENOUGH, self.OnShopItemNotEnough, self)
end

function XUiShop:OnShopItemNotEnough(code, shopId, isHasCache)
    if isHasCache then
        if self.Type and self.Type == XShopManager.ShopType.Recharge then
            local isHasCharacterCoin = XDataCenter.ItemManager.CheckItemCountById(
                XDataCenter.ItemManager.ItemId.OptionalCharacterCoin, 1)
            local isHasEquipCoin = XDataCenter.ItemManager.CheckItemCountById(
                XDataCenter.ItemManager.ItemId.OptionalEquipCoin, 1)
            local isHasPartner = XDataCenter.ItemManager.CheckItemCountById(
                XDataCenter.ItemManager.ItemId.OptionalPartnerCoin, 1)

            if (shopId == XShopManager.RechargeShopType.CharacterShop and not isHasCharacterCoin) or
                (shopId == XShopManager.RechargeShopType.EquipShop and not isHasEquipCoin) or
                (shopId == XShopManager.RechargeShopType.PartnerShop and not isHasPartner) then
                self:UpdateInfo(shopId)
                return
            end
        end
        XUiManager.TipCode(code)
    else
        XUiManager.TipCode(code)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiShop:InitAutoScript()
    self:AutoAddListener()
end

function XUiShop:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiShop:AutoAddListener()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))

    -- self.BtnScreenGroup.CallBack = function()
    --     self:OnBtnScreenGroupClick()
    -- end
    self.BtnScreenWords.onValueChanged:AddListener(function()
        self:UpdateList(self.CurShopId, false)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnDetails, function()
        self.RefreshTips:Show()
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, function()
        self:OnBtnScreenSuitClick()
    end)
    self.BtnSwitch:ShowReddot(false)
    XUiHelper.RegisterClickEvent(self, self.BtnScreening, function()
        self:OnBtnScreenSuitClick()
    end)
    self.BtnFilterSuit:AddEventListener(handler(self, self.OpenSuitSelect))
    self.BtnFilterWeapon:AddEventListener(handler(self, self.OpenWeaponSelect))
    self.BtnFilter:AddEventListener(handler(self, self.OnBtnFilterClick))

    self.BtnScreening:ShowReddot(false)
end

function XUiShop:OnBtnBackClick()
    self:Close()
    if self.cb then
        self.cb()
    end
    self.AssetActivityPanel:HidePanel()
    for _, panel in pairs(self.PanelLists) do
        panel:HidePanel()
    end
    self.ShopPeriod:HidePanel()
end

function XUiShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
    self.AssetActivityPanel:HidePanel()
    for _, panel in pairs(self.PanelLists) do
        panel:HidePanel()
    end
    self.ShopPeriod:HidePanel()
end

function XUiShop:OnBtnScreenGroupClick()
    if self.ScreenGroupIDList and #self.ScreenGroupIDList > 0 then
        self.ScreenNum = self.ScreenNum + 1
        if self.ScreenNum > #self.ScreenGroupIDList then
            self.ScreenNum = 1
        end
    end
end

function XUiShop:OnDestroy()
    self.AssetActivityPanel:HidePanel()
    for _, panel in pairs(self.PanelLists) do
        panel:HidePanel()
    end
    self.ShopPeriod:HidePanel()
    self.UiShopFashionDiscountActivity:OnDestroy()
    self.UiShopFashionDiscountActivity = nil

end

function XUiShop:SetShopBtn(shopType)
    local btnList = nil

    if self.BtnOptionalShop then
        local isHasCharacterCoin = XDataCenter.ItemManager.CheckItemCountById(
            XDataCenter.ItemManager.ItemId.OptionalCharacterCoin, 1)
        local isHasEquipCoin = XDataCenter.ItemManager.CheckItemCountById(
            XDataCenter.ItemManager.ItemId.OptionalEquipCoin, 1)
        local isHasPartner = XDataCenter.ItemManager.CheckItemCountById(
            XDataCenter.ItemManager.ItemId.OptionalPartnerCoin, 1)
        local isOptionalOpen = isHasCharacterCoin or isHasEquipCoin or isHasPartner

        self.BtnOptionalShop.gameObject:SetActiveEx(isOptionalOpen)
        if not isOptionalOpen and shopType == XShopManager.ShopType.Recharge then
            shopType = XShopManager.ShopType.Common
        end
        btnList = {self.BtnEcerdayShop, self.BtnPointsShop, self.BtnActivityShop, self.BtnOptionalShop}
    else
        btnList = {self.BtnEcerdayShop, self.BtnPointsShop, self.BtnActivityShop}
    end

    self.ShopBtnGroup:Init(btnList, function(index)
        self:OnSelectedShopBtn(index)
    end)

    for index, bth in ipairs(btnList) do
        self:CheckBtnState(ShopTypeDic[index], bth)
    end

    if shopType == XShopManager.ShopType.Common then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(ShopIndexDic[shopType])
    elseif shopType == XShopManager.ShopType.Activity then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(ShopIndexDic[shopType])
    elseif shopType == XShopManager.ShopType.Points then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(ShopIndexDic[shopType])
    elseif self.BtnOptionalShop and shopType == XShopManager.ShopType.Recharge then
        self.ShopBtnGroup.gameObject:SetActiveEx(true)
        self.ShopBtnGroup:SelectIndex(ShopIndexDic[shopType])
    else
        self.ShopBtnGroup.gameObject:SetActiveEx(false)
    end
end

function XUiShop:CheckBtnState(shopType, btn)
    -- 检查功能是否开启
    local functionOpenId = ShopFunctionOpenIdDic[shopType]

    if XTool.IsNumberValidEx(functionOpenId) and not XFunctionManager.DetectionFunction(functionOpenId, true, true) then
        btn:SetButtonState(CS.UiButtonState.Disable)
        return
    end

    local togActlist = self:GetShopBaseInfoByTypeAndTag(shopType)
    if #togActlist <= 0 then
        btn:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiShop:OnSelectedShopBtn(index)
    local shopType = ShopTypeDic[index]
    local functionOpenId = ShopFunctionOpenIdDic[shopType]
    if not XFunctionManager.DetectionFunction(functionOpenId) then
        return
    end

    if self.Type == shopType then
        return
    end

    local togActlist = self:GetShopBaseInfoByTypeAndTag(shopType)
    if #togActlist <= 0 then
        XUiManager.TipText("ShopIsNotOpen")
        self.ShopBtnGroup:SelectIndex(ShopIndexDic[self.Type])
        return
    end

    self.Type = shopType
    self:UpdateTog()
end

function XUiShop:UpdateTog()
    local shopId = self.ConfigShopId
    self.ConfigShopId = nil
    local infoList = self:GetShopBaseInfoByTypeAndTag(self.Type)
    local selectIndex = self.TabBtnGroupSelectIndex and self.TabBtnGroupSelectIndex[self.Type]
    local subGroupIndexMemo = 0

    if #infoList == 0 then
        self.Type = XShopManager.ShopType.Common
        infoList = self:GetShopBaseInfoByTypeAndTag(self.Type)
        selectIndex = self.TabBtnGroupSelectIndex and self.TabBtnGroupSelectIndex[self.Type]
    end

    -- 隐藏所有已创建页签(含其他类型), 当前类型在下方按需显示
    for _, pool in pairs(self.BtnPool) do
        for _, uiButton in pairs(pool) do
            uiButton.gameObject:SetActiveEx(false)
        end
    end

    -- 重建当前类型页签列表: 只含当前类型按钮, 交给 TabBtnGroup 管理
    -- index 全程使用"当前 infoList 的局部索引", 与 OnSelectedTog 收到的 index 一致
    self.BtnGoList = {}
    self.ShopTables = {}
    self.ShopIndex2IdDic = {}
    self.BtnPool[self.Type] = self.BtnPool[self.Type] or {}

    for index, info in ipairs(infoList) do
        local uiButton = self.BtnPool[self.Type][index]

        -- 一级页签: 记录其局部 index, 作为后续二级页签的 SubGroupIndex(新建/复用均需更新, 否则复用一级后新建的二级会取到错误分组)
        if info.SecondType == 0 then
            subGroupIndexMemo = index
        end

        -- 首次访问该页签时实例化, 之后从池中复用
        if not uiButton then
            local btn
            local subGroupIndex
            if info.SecondType == 0 then
                if info.IsHasSnd then
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd)
                else
                    btn = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
                end
                subGroupIndex = 0
            else
                local prefab = self.BtnSecondAll
                if info.SecondTagType == XShopManager.SecondTagType.Top then
                    prefab = self.BtnSecondTop
                elseif info.SecondTagType == XShopManager.SecondTagType.Mid then
                    prefab = self.BtnSecond
                elseif info.SecondTagType == XShopManager.SecondTagType.Btm then
                    prefab = self.BtnSecondBottom
                end
                btn = CS.UnityEngine.Object.Instantiate(prefab)
                subGroupIndex = subGroupIndexMemo
            end

            btn.transform:SetParent(self.TabBtnContent, false)
            uiButton = btn:GetComponent("XUiButton")
            uiButton.SubGroupIndex = subGroupIndex
            uiButton:SetName(info.Name)
            btn.gameObject.name = info.Id

            local shopDetail = XShopConfigs.GetShopDetailById(info.Id)
            if shopDetail and not XTool.IsTableEmpty(shopDetail.ShopBtnRedPointConditions) then
                local redPointArgs = { Id = info.Id, IsNeedFirstBluePoint = shopDetail.IsNeedFirstBluePoint }
                self:AddRedPointEvent(uiButton, function(_, count) uiButton:ShowReddot(count >= 0) end, self,
                    shopDetail.ShopBtnRedPointConditions, redPointArgs)
            end

            local isShowTag = XShopManager.CheckShopActivityPeriod(info.Id)
            uiButton:ShowTag(isShowTag)
            local tagObj = uiButton.TagObj
            if not XTool.UObjIsNil(tagObj) then
                local txObjg = tagObj:FindTransform("TxtTag")
                txObjg:GetComponent(typeof(CS.UnityEngine.UI.Text)).text = XUiHelper.GetText("UiShopBtnActivityTagName")
            end

            self.BtnPool[self.Type][index] = uiButton
        end

        uiButton.gameObject:SetActiveEx(true)
        table.insert(self.BtnGoList, uiButton)
        self.ShopTables[index] = info
        self.ShopIndex2IdDic[index] = info.Id
        self.TagBtnShopGroup[uiButton] = info

        if shopId and info.Id == shopId then
            selectIndex = index
        end
    end

    if #infoList <= 0 then
        return
    end

    selectIndex = selectIndex or self:GetDefaultSelectIndex(infoList)
    self.TabBtnGroup:Init(self.BtnGoList, function(index)
        self:OnSelectedTog(index)
    end)
    self.TabBtnGroup:SelectIndex(selectIndex)
    self.UiShopFashionDiscountActivity:ResetDiscountActivityTag()
end

-- 默认选中页签(返回当前 infoList 的局部索引): Recharge 类型按持有代币优先定位, 其余类型取首个
function XUiShop:GetDefaultSelectIndex(infoList)
    if self.Type ~= XShopManager.ShopType.Recharge then
        return 1
    end

    -- 优先级: 装备 > 共鸣 > 角色
    local optionalCoinList = {
        { itemId = XDataCenter.ItemManager.ItemId.OptionalEquipCoin,     rechargeType = XShopManager.RechargeShopType.EquipShop },
        { itemId = XDataCenter.ItemManager.ItemId.OptionalPartnerCoin,   rechargeType = XShopManager.RechargeShopType.PartnerShop },
        { itemId = XDataCenter.ItemManager.ItemId.OptionalCharacterCoin, rechargeType = XShopManager.RechargeShopType.CharacterShop },
    }
    for _, data in ipairs(optionalCoinList) do
        if XDataCenter.ItemManager.CheckItemCountById(data.itemId, 1) then
            return self:GetRechargeTagIndex(infoList, data.rechargeType)
        end
    end
    return 2
end

function XUiShop:GetRechargeTagIndex(infoList, rechargeType)
    local index = 2

    for i = 1, #infoList do
        if infoList[i].Id == rechargeType then
            index = i
        end
    end

    return index
end

function XUiShop:SetTitleName(typeId)
    if typeId ~= XShopManager.ShopType.Common and typeId ~= XShopManager.ShopType.Activity and typeId ~=
        XShopManager.ShopType.Points then
        self.BtnTitle.gameObject:SetActiveEx(true)
    else
        self.BtnTitle.gameObject:SetActiveEx(false)
    end
    self.BtnEcerdayShop:SetNameByGroup(0, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Common).TypeName)
    self.BtnActivityShop:SetNameByGroup(0, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Activity).TypeName)
    self.BtnPointsShop:SetNameByGroup(0, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Points).TypeName)
    self.BtnTitle:SetNameByGroup(0, XShopManager.GetShopTypeDataById(typeId).TypeName)

    self.BtnEcerdayShop:SetNameByGroup(1, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Common).Desc)
    self.BtnActivityShop:SetNameByGroup(1, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Activity).Desc)
    self.BtnPointsShop:SetNameByGroup(1, XShopManager.GetShopTypeDataById(XShopManager.ShopType.Points).Desc)
    self.BtnTitle:SetNameByGroup(1, XShopManager.GetShopTypeDataById(typeId).Desc)
end

function XUiShop:ShowShop(shopId)
    XShopManager.GetShopInfo(shopId, function()
        self:UpdateInfo(shopId)
    end)
end

-- 显示商品信息
function XUiShop:OnSelectedTog(index)
    local shopId = self.ShopIndex2IdDic[index]
    if XTool.IsNumberValid(shopId) then
        local key = string.format("ShopTabFirstBluePoint_%s_%s", tostring(shopId), tostring(XPlayer.Id))
        XSaveTool.SaveData(key, true)

        local redPointKey = string.format("IsShopTabRedPoint%s", tostring(XPlayer.Id))
        if XSaveTool.GetData(redPointKey) == 1 then
            XSaveTool.SaveData(redPointKey, 0)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_SHOP_TAB_BTN_RED_POINT_UPDATE)
    end
    self.TabBtnGroupSelectIndex = self.TabBtnGroupSelectIndex or {}
    self.TabBtnGroupSelectIndex[self.Type] = index
    shopId = self.ShopTables[index].Id
    self.LastShopId = self.CurShopId
    self.CurShopId = shopId
    self:ShowShop(shopId)
    self:PlayAnimation("AnimQieHuan")
end

function XUiShop:GetCurShopId()
    return self.CurShopId
end

-- 初始化列表
function XUiShop:UpdateInfo(shopId)
    self.ShopPeriod:HidePanel()
    self.ShopPeriod:ShowPanel(shopId)
    self:InitScreen(shopId)
    self:RefreshSelectFilter(shopId)
    self:UpdateList(shopId, false)

    self.UiShopFashionDiscountActivity:ResetDiscountActivityTime(shopId)
end

function XUiShop:InitScreen(shopId)
    self.BtnScreenGroup.gameObject:SetActiveEx(false)

    self.ScreenGroupIDList = XShopManager.GetShopScreenGroupIDList(shopId)
    if self.ScreenGroupIDList and #self.ScreenGroupIDList > 0 then
        self.IsHasScreen = true
        self.ScreenNum = #self.ScreenGroupIDList
        -- self.BtnScreenGroup.gameObject:SetActiveEx(#self.ScreenGroupIDList > 1)
    else
        self.IsHasScreen = false
    end
    self.PanelShaixuan.gameObject:SetActiveEx(self.IsHasScreen)
end

function XUiShop:UpdateList(shopId, is4RequestRefresh)
    local isKeepOrder = os.clock() - self.RefreshBuyTime < 0.5 -- 刚购买之后0.5秒内的刷新, 不改变商品顺序
    if is4RequestRefresh then
        isKeepOrder = false
    end
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(shopId))
    local selectTag = nil
    if self.FilterResult[shopId] then
        selectTag = self.FilterResult[shopId].TagText
    end
    -- 先隐藏所有面板
    for _, panel in pairs(self.PanelLists) do
        panel:HidePanel()
    end
    -- 显示匹配的面板
    local shopShowTypeCfg = XShopConfigs.GetShopShowTypeTemplateById(shopId)
    if shopShowTypeCfg and self.PanelLists[shopShowTypeCfg.ShowType] then
        self.PanelLists[shopShowTypeCfg.ShowType]:ShowScreenPanel(shopId, self.ScreenGroupIDList[self.ScreenNum],
            selectTag, isKeepOrder)
    else
        self.PanelLists[XShopConfigs.ShowType.Normal]:ShowScreenPanel(shopId, self.ScreenGroupIDList[self.ScreenNum],
            selectTag, isKeepOrder)
    end
    self:UpdateRefreshTips(shopId)
end

function XUiShop:GetScreenNotExistTips()
    if not XTool.IsNumberValid(self.ScreenId) then
        return ""
    end
    -- screenId 武器则为类型，意识则为套装Id
    if self.ScreenId <= XEnumConst.EQUIP.EQUIP_TYPE.FOOD then
        return XUiHelper.GetText("TypeWeapon")
    else
        return XUiHelper.GetText("TypeWafer")
    end
end

-- v1.29 商店优化
-- 在shop表里新增字段refreshtips，控制对应的商店页签倒计时旁是否显示刷新tips，以及tips文本内容，若填写内容则显示tips按钮以及点击按钮后显示配置文本，若未填写，则不显示按钮。
function XUiShop:UpdateRefreshTips(shopId)
    local refreshTips = XShopManager.GetShopShowRefreshTips(shopId)
    if refreshTips then
        self.BtnDetails.gameObject:SetActiveEx(true)
        self:UpdateRefreshTipsContent()
    else
        self.BtnDetails.gameObject:SetActiveEx(false)
        self.RefreshTips:Hide()
    end
end

function XUiShop:UpdateRefreshTipsContent()
    local refreshTips = XShopManager.GetShopShowRefreshTips(self.CurShopId)
    if refreshTips then
        self.RefreshTips:SetText(refreshTips)
    end
end

function XUiShop:UpdateBuy(data, cb, proxy)
    XLuaUiManager.Open("UiShopItem", self, data, cb, nil, proxy)
    self:PlayAnimation("AnimTanChuang")
end

function XUiShop:RefreshBuy(is4RequestRefresh)
    self.RefreshBuyTime = os.clock()
    self.AssetActivityPanel:Refresh(XShopManager.GetShopShowIdList(self.CurShopId))
    self.ShopPeriod:UpdateShopBuyInfo()
    self:UpdateList(self.CurShopId, is4RequestRefresh)
end

function XUiShop:GetShopBaseInfoByTypeAndTag(shopType)
    if shopType == XShopManager.ShopType.Common then
        local shopList1 = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Common)
        local shopList2 = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Boss)
        local shopList3 = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Arena)
        local shopList4 = XShopManager.GetShopBaseInfoByTypeAndTag(XShopManager.ShopType.Guild)
        return XTool.MergeArray(shopList1, shopList2, shopList3, shopList4)
    end
    return XShopManager.GetShopBaseInfoByTypeAndTag(shopType)
end

-- region v1.29 优化当前分解商店-意识商店的筛选功能
function XUiShop:IsShowSuitScreen(shopId)
    return XShopConfigs.IsShowSuitScreen(shopId)
end

function XUiShop:FindFirstSuitId()
    local shopItemList = self.ItemList.GoodsList
    for i = 1, #shopItemList do
        local templateId = shopItemList[i].RewardGoods.TemplateId
        if XArrangeConfigs.GetType(templateId) == XArrangeConfigs.Types.Wafer then
            return XMVCA.XEquip:GetEquipSuitId(templateId)
        end
    end
    return false
end

function XUiShop:GetSuitScreenDataProvider(ignoreOther)
    local dataProvider = {}
    local hasOther = false
    local groupId = XShopManager.ScreenType.SuitName
    local shopId = self.CurShopId
    local screenTagList = XShopManager.GetScreenTagListById(shopId, groupId)
    local tagScreenAll = XShopManager.GetTagScreenAll()
    local tagScreenOther = XShopManager.GetTagScreenOther()

    for _, v in pairs(screenTagList or {}) do
        if v.Text == tagScreenOther then
            hasOther = true
        else
            if v.Text ~= tagScreenAll then
                local goodsList = XShopManager.GetScreenGoodsListByTag(shopId, groupId, v.Text)
                if #goodsList > 0 then
                    local firstGood = goodsList[1]
                    local templateId = firstGood.RewardGoods.TemplateId
                    local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
                    dataProvider[#dataProvider + 1] = XMVCA.XEquip:GetSuitFilterProvider(v.Text, suitId)
                end
            end
        end
    end
    if ignoreOther == nil and hasOther then
        local other = {
            text = XShopManager.GetTagScreenOther(),
            icon = CS.XGame.ClientConfig:GetString("UiShopOthers"),
            description = CS.XTextManager.GetText("ShopOthersDescription" .. shopId)
        }
        table.insert(dataProvider, 1, other)
    end
    return dataProvider
end

-- endregion

-- region V4.1商店筛选逻辑
function XUiShop:OpenSuitSelect()
    local shopId = self.CurShopId
    if self.ScreenGroupIDList == nil then
        return
    end
    self.ScreenTagList = XShopManager.GetScreenTagListById(shopId, self.ScreenGroupIDList[self.ScreenNum])
    if self.ScreenTagList == nil then
        return
    end
    local allProvider = self:GetSuitScreenDataProvider(true)
    local dataProvider = {}
    local tagSet = {}
    for _, k in pairs(self.ScreenTagList) do
        tagSet[k.Text] = true
    end

    for _, v in pairs(allProvider) do
        if tagSet[v.text] then
            table.insert(dataProvider, v)
        end
    end

    local selectData = {}

    if self.FilterResult[shopId] ~= nil then
        for i = 1, #dataProvider do
            local data = dataProvider[i]
            if data.text == self.FilterResult[shopId].TagText then
                selectData.WaferData = data
                break
            end
        end
        selectData.TagId = self.FilterResult[shopId].TagId
    end

    XLuaUiManager.Open('UiShopWaferSelect', selectData, dataProvider, function(data)
        self:CloseSuitSelect(shopId, data)
    end)
end

function XUiShop:CloseSuitSelect(shopId, data)
    self.FilterResult[shopId] = {}
    self.FilterResult[shopId].TagId = data.TagId
    if data.WaferData then
        self.FilterResult[shopId].TagText = data.WaferData.text
    else
        self.FilterResult[shopId].TagText = CS.XTextManager.GetText("ScreenAll")
    end
    self:UpdateList(shopId, false)
    self:RefreshSelectFilter(shopId)
end

function XUiShop:OnBtnScreenSuitClick()
    local shopId = self.CurShopId

    local dataProvider = self:GetSuitScreenDataProvider(true)
    local selectData = {}
    if self.FilterResult[shopId] then
        selectData.TagId = self.FilterResult[shopId].TagId
    end
    if self.FilterResult[shopId] ~= nil then
        for i = 1, #dataProvider do
            local data = dataProvider[i]
            if data.text == self.FilterResult[shopId].TagId then
                selectData.WaferData = data
                break
            end
        end
    end
    XLuaUiManager.Open('UiShopWaferSelect', selectData, dataProvider, function(data)
        self:CloseSuitSelect(shopId, data)
    end)
end

function XUiShop:OpenWeaponSelect()
    local shopId = self.CurShopId
    if self.ScreenGroupIDList == nil then
        return
    end
    local screenGroupCfg = XShopConfigs.GetShopScreenGroupTemplate()[self.ScreenGroupIDList[self.ScreenNum]]

    local goodsList = XShopManager.GetShopGoodsList(self.CurShopId, true, true)
    local dataProvider = {}
    local dataProviderMap = {}
    local weaponNameMap = {}
    -- 获取商品里对应的角色Id
    if not XTool.IsTableEmpty(goodsList) then
        for i, goods in pairs(goodsList) do
            if not XMVCA.XEquip:CheckTemplateIdIsEquip(goods.RewardGoods.TemplateId) then
                goto continue
            end
            local characterId = XMVCA.XEquip:GetEquipRecommendCharacterId(goods.RewardGoods.TemplateId)

            dataProviderMap[characterId] = XMVCA.XEquip:GetEquipType(goods.RewardGoods.TemplateId)
            dataProvider[#dataProvider + 1] = {
                characterId = characterId
            }

            for j, id in pairs(screenGroupCfg.ScreenID) do
                if dataProviderMap[characterId] == id then
                    weaponNameMap[characterId] = screenGroupCfg.ScreenName[j]
                    break
                end
            end
            ::continue::
        end
    end
    local selectData = nil
    if self.FilterResult[shopId] then
        selectData = {
            selectId = self.FilterResult[shopId].TagId,
            careerTags = self.FilterResult[shopId].CareerTags,
            elementTags = self.FilterResult[shopId].ElementTags,
            weaponData = self.FilterResult[shopId].TagText
        }
    else
        selectData = {}
    end

    XLuaUiManager.Open('UiShopFashionFilter', selectData, dataProvider, function(resultData)
        self:CloseFashionSelect(resultData, function()
            if screenGroupCfg then
                for i, id in pairs(screenGroupCfg.ScreenID) do
                    if dataProviderMap[resultData.selectId] == id then
                        self.FilterResult[shopId].TagText = screenGroupCfg.ScreenName[i]
                        break
                    end
                end
            end
        end)
    end, weaponNameMap)
end

function XUiShop:CloseFashionSelect(closeData, cb)
    local shopId = self.CurShopId
    if closeData ~= nil then
        self.FilterResult[shopId] = {}
        self.FilterResult[shopId].CareerTags = closeData.careerTags
        self.FilterResult[shopId].ElementTags = closeData.elementTags
        self.FilterResult[shopId].TagId = closeData.selectId
        if cb then
            cb()
        end
    else
        self.FilterResult[shopId] = nil
    end
    self:UpdateList(shopId, false)
    self:RefreshSelectFilter(shopId)
end

function XUiShop:OnBtnFilterClick()
    local shopId = self.CurShopId
    -- 将selectTag转成characterId
    local screenGroupCfg = XShopConfigs.GetShopScreenGroupTemplate()[self.ScreenGroupIDList[self.ScreenNum]]
    local characterId = nil
    if screenGroupCfg and self.FilterResult[shopId] then
        for i, name in pairs(screenGroupCfg.ScreenName) do
            if self.FilterResult[shopId].TagId == name then
                characterId = screenGroupCfg.ScreenID[i]
                break
            end
        end
    end
    local goodsList = XShopManager.GetShopGoodsList(self.CurShopId, true, true)
    local dataProvider = {}
    -- 获取商品里对应的角色Id
    if not XTool.IsTableEmpty(goodsList) then
        for i, goods in pairs(goodsList) do
            local characterId = XDataCenter.FashionManager.GetCharacterId(goods.RewardGoods.TemplateId)
            dataProvider[#dataProvider + 1] = {
                characterId = characterId
            }
        end
    end
    local selectData = nil
    if self.FilterResult[shopId] then
        selectData = {
            selectId = characterId,
            careerTags = self.FilterResult[shopId].CareerTags,
            elementTags = self.FilterResult[shopId].ElementTags,
            weaponData = self.FilterResult[shopId].TagText
        }
    else
        selectData = {}
    end

    XLuaUiManager.Open('UiShopFashionFilter', selectData, dataProvider, function(resultData)
        self:CloseFashionSelect(resultData, function()
            if screenGroupCfg then
                for i, id in pairs(screenGroupCfg.ScreenID) do
                    if resultData.selectId == id then
                        self.FilterResult[shopId].TagText = screenGroupCfg.ScreenName[i]
                        break
                    end
                end
            end
        end)
    end)
end

function XUiShop:RefreshSelectFilter(shopId)
    self.BtnFilterSuit.gameObject:SetActiveEx(false)
    self.BtnFilterWeapon.gameObject:SetActiveEx(false)
    self.BtnFilter.gameObject:SetActiveEx(false)
    self.BtnSwitch.gameObject:SetActiveEx(false)
    self.BtnScreening.gameObject:SetActiveEx(false)
    for id, _ in pairs(self.FilterResult) do
        if id ~= shopId then
            self.FilterResult[id] = nil
        end
    end
    if self.ScreenGroupIDList == nil then
        return
    end
    self.ScreenTagList = XShopManager.GetScreenTagListById(self.CurShopId, self.ScreenGroupIDList[self.ScreenNum])

    if self.ScreenTagList == nil then
        return
    end
    if self.ScreenGroupIDList[self.ScreenNum] == SelectType.Weapon then
        self.BtnFilterWeapon.gameObject:SetActiveEx(true)
        if not self.FilterResult[shopId] then
            self.BtnFilterWeapon:SetName(CS.XTextManager.GetText("ScreenAll"))
        else
            self.BtnFilterWeapon:SetName(self.FilterResult[shopId].TagText or CS.XTextManager.GetText("ScreenAll"))
        end
    elseif self.ScreenGroupIDList[self.ScreenNum] == SelectType.Suit then
        if self:IsShowSuitScreen(shopId) then
            local tagOfOthers = XShopManager.GetTagScreenOther()
            local others = XShopManager.GetScreenGoodsListByTagEx(shopId, self.ScreenNum, tagOfOthers)
            if others and #others > 0 then
                self.BtnSwitch.gameObject:SetActiveEx(false)
                self.BtnScreening.gameObject:SetActiveEx(true)
                self.BtnFilterSuit.gameObject:SetActiveEx(false)
            else
                self.BtnSwitch.gameObject:SetActiveEx(true)
                self.BtnScreening.gameObject:SetActiveEx(false)
                self.BtnFilterSuit.gameObject:SetActiveEx(false)
            end
        else
            self.BtnSwitch.gameObject:SetActiveEx(false)
            self.BtnScreening.gameObject:SetActiveEx(false)
            self.BtnFilterSuit.gameObject:SetActiveEx(true)
            if not self.FilterResult[shopId] then
                self.BtnFilterSuit:SetName(CS.XTextManager.GetText("ScreenAll"))
            else
                self.BtnFilterSuit:SetName(self.FilterResult[shopId].TagText)
            end
        end
    else
        self.BtnFilter.gameObject:SetActiveEx(true)
        if not self.FilterResult[shopId] then
            self.BtnFilter:SetName(CS.XTextManager.GetText("ScreenAll"))
        else
            self.BtnFilter:SetName(self.FilterResult[shopId].TagText or CS.XTextManager.GetText("ScreenAll"))
        end
    end
end

-- endregion

return XUiShop
