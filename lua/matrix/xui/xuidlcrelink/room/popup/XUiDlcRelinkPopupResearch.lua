local XUiGridDlcRelinkResearchProperty = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkResearchProperty")
---@class XUiDlcRelinkPopupResearch : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupResearch = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupResearch")

function XUiDlcRelinkPopupResearch:OnAwake()
    self.PropertyItem.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupResearch:OnStart(callBack)
    self.CallBack = callBack
    self:PlayAnimation("AnimBegin")

    ---@type XUiGridDlcRelinkResearchProperty[]
    self.PropertyGridList = {}
end

function XUiDlcRelinkPopupResearch:OnEnable()
    self:RefreshInfo()
    self:RefreshPropertyList()
    self:RefreshRedPoint()
end

function XUiDlcRelinkPopupResearch:RefreshInfo()
    local curLevel = self._Control:GetCurrentPlayerLevel()
    self.TxtTitle.text = curLevel

    local isMaxLevel = self._Control:GetPlayerLevelIsMax(curLevel)
    self.PanelBottom.gameObject:SetActiveEx(not isMaxLevel)
    if isMaxLevel then
        self.TxtCondition.text = self._Control:GetClientConfig("PlayerNextLevelDesc")
        self.ImgProgress.fillAmount = 1
    else
        local curExp = self._Control:GetCurrentPlayerExp()
        local nextLevelExp = self._Control:GetNextPlayerLevelExp(curLevel)
        self.TxtCondition.text = math.max(0, nextLevelExp - curExp)
        self.ImgProgress.fillAmount = nextLevelExp > 0 and (curExp / nextLevelExp) or 0
        -- 刷新消耗
        self:RefreshCost()
    end
end

function XUiDlcRelinkPopupResearch:RefreshCost()
    -- 图标
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin)
    self.Icon:SetRawImage(icon)
    -- 数量
    local needCost = self._Control:GetUpgradeNeedCostCoin()
    self.TxtATNums.text = needCost
    -- 拥有数量
    local hasCost = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin)
    local color = self._Control:GetClientConfig("PlayerLevelNotEnoughCoinColor", hasCost < needCost and 2 or 1)
    self.TxtATNums.color = XUiHelper.Hexcolor2Color(color)
end

function XUiDlcRelinkPopupResearch:RefreshPropertyList()
    local curLevel = self._Control:GetCurrentPlayerLevel()
    local isMaxLevel = self._Control:GetPlayerLevelIsMax(curLevel)

    local curAttributes = self._Control:GetPlayerLevelAttributes(curLevel)
    local nextAttributes = not isMaxLevel and self._Control:GetPlayerLevelAttributes(curLevel + 1) or {}

    ---@type table<string, { CurValue:number, NextValue:number }>
    local propertyDataMap = {}
    for attrStr, attrValue in pairs(curAttributes) do
        propertyDataMap[attrStr] = {
            CurValue = attrValue,
            NextValue = 0,
        }
    end
    for attrStr, attrValue in pairs(nextAttributes) do
        if propertyDataMap[attrStr] then
            propertyDataMap[attrStr].NextValue = attrValue
        else
            propertyDataMap[attrStr] = {
                CurValue = 0,
                NextValue = attrValue,
            }
        end
    end

    local index = 1
    for attrStr, attrData in pairs(propertyDataMap) do
        local grid = self.PropertyGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.PropertyItem, self.Properties)
            grid = XUiGridDlcRelinkResearchProperty.New(go, self)
            self.PropertyGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(attrStr, attrData.CurValue, attrData.NextValue, isMaxLevel)
        index = index + 1
    end

    for i = index, #self.PropertyGridList do
        self.PropertyGridList[i]:Close()
    end
end

function XUiDlcRelinkPopupResearch:RefreshRedPoint()
    local isShowRedPoint = self._Control:CheckPlayerLevelUpRedPoint()
    self.BtnEnter:ShowReddot(isShowRedPoint)
end

function XUiDlcRelinkPopupResearch:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiDlcRelinkPopupResearch:OnBtnCloseClick()
    self:OnClose()
end

function XUiDlcRelinkPopupResearch:OnClose()
    self:PlayAnimation("AnimEnd", function()
        self:Close()
        if self.CallBack then
            self.CallBack()
        end
    end)
end

function XUiDlcRelinkPopupResearch:OnBtnEnterClick()
    local curLevel = self._Control:GetCurrentPlayerLevel()
    if self._Control:GetPlayerLevelIsMax(curLevel) then
        return
    end

    local nextLevel = curLevel + 1
    local isUp, desc = self._Control:CheckPlayerLevelUpCondition(nextLevel)
    if not isUp then
        self._Control:OpenCommonTipMsg(desc)
        return
    end

    local needCost = self._Control:GetUpgradeNeedCostCoin()
    local hasCost = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin)
    if hasCost < needCost then
        local itemName = XDataCenter.ItemManager.GetItemName(XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin)
        local desc2 = string.format(self._Control:GetClientConfig("PlayerLevelNotEnoughCoinDesc"), itemName)
        self._Control:OpenCommonTipMsg(desc2)
        return
    end

    self._Control:RequestBuyExp(function()
        self:RefreshInfo()
        self:RefreshPropertyList()
        self:RefreshRedPoint()
    end)
end

return XUiDlcRelinkPopupResearch
