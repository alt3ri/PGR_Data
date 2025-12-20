local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
---@class XUiDlcRelinkPopupEquipCompose : XLuaUi
---@field private _Control XDlcRelinkControl
---@field InputSelect UnityEngine.UI.InputField
local XUiDlcRelinkPopupEquipCompose = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipCompose")

local Interval = 100
local SpeedBaseNumber = 150

function XUiDlcRelinkPopupEquipCompose:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupEquipCompose:OnStart(composeId)
    self.ComposeId = composeId
    self.CurComposeCount = 0
    self.MaxComposeCount = self._Control:CalculateComposeMaxCount(composeId)

    self:SetInputSelectData()
    self.InputSelect.onValueChanged:AddListener((handler(self, self.OnInputSelectValueChanged)))
    self.InputSelect.onEndEdit:AddListener((handler(self, self.OnInputSelectEndEdit)))

    self.WgtBtnAddSelect = self.BtnAddSelect.gameObject:GetComponent("XUiPointer")
    self.WgtBtnMinusSelect = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")

    XUiButtonLongClick.New(self.WgtBtnAddSelect, Interval, self, nil, self.BtnAddSelectLongClickCallback, nil, true)
    XUiButtonLongClick.New(self.WgtBtnMinusSelect, Interval, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)
end

function XUiDlcRelinkPopupEquipCompose:OnEnable()
    self:RefreshConsumes()
    self:RefreshBtnState()
    self.InputSelect.text = self.CurComposeCount
end

function XUiDlcRelinkPopupEquipCompose:SetInputSelectData()
    self.InputSelect.characterLimit = 4
    self.InputSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

function XUiDlcRelinkPopupEquipCompose:GetItemIdAndCount()
    local consumeIds = self._Control:GetComposeConsumeIds(self.ComposeId)
    local consumeCounts = self._Control:GetComposeConsumeCounts(self.ComposeId)
    -- 默认取第一个消耗物品
    local itemId = consumeIds[1]
    local itemCount = consumeCounts[1]
    return itemId, itemCount
end

function XUiDlcRelinkPopupEquipCompose:RefreshConsumes()
    local itemId, itemCount = self:GetItemIdAndCount()
    self.RImgCostIcon1:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(itemId))
    self.TxtCostCount1.text = itemCount * self.CurComposeCount
end

function XUiDlcRelinkPopupEquipCompose:RefreshBtnState()
    self.BtnMinusSelect:SetDisable(self.CurComposeCount <= 0)
    self.BtnAddSelect:SetDisable(self.CurComposeCount >= self.MaxComposeCount)
end

function XUiDlcRelinkPopupEquipCompose:OnInputSelectValueChanged(value)
    if value == nil or value == "" then
        return
    end

    local num = tonumber(value) or 0
    if num > self.MaxComposeCount then
        num = self.MaxComposeCount
        self.InputSelect.text = num
    end

    self.CurComposeCount = num
    self:RefreshConsumes()
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:OnInputSelectEndEdit(value)
    if value == nil or value == "" then
        self.CurComposeCount = 0
        self.InputSelect.text = 0
        self:RefreshConsumes()
        self:RefreshBtnState()
    end
end

function XUiDlcRelinkPopupEquipCompose:BtnAddSelectLongClickCallback(time)
    if self.CurComposeCount >= self.MaxComposeCount then
        self._Control:OpenCommonTipText("EquipComposeCountLimitTips", 2)
        return
    end

    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.CurComposeCount = math.min(self.MaxComposeCount, self.CurComposeCount + delta)
    self:RefreshConsumes()
    self.InputSelect.text = self.CurComposeCount
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:BtnMinusSelectLongClickCallback(time)
    if self.CurComposeCount <= 0 then
        self._Control:OpenCommonTipText("EquipComposeCountLimitTips", 1)
        return
    end

    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.CurComposeCount = math.max(0, self.CurComposeCount - delta)
    self:RefreshConsumes()
    self.InputSelect.text = self.CurComposeCount
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnCompose, self.OnBtnComposeClick)
end

function XUiDlcRelinkPopupEquipCompose:OnBtnCloseClick()
    self:Close()
end

function XUiDlcRelinkPopupEquipCompose:OnBtnAddSelectClick()
    if self.CurComposeCount < self.MaxComposeCount then
        self.CurComposeCount = self.CurComposeCount + 1
        self:RefreshConsumes()
        self.InputSelect.text = self.CurComposeCount
        self:RefreshBtnState()
    else
        self._Control:OpenCommonTipText("EquipComposeCountLimitTips", 2)
    end
end

function XUiDlcRelinkPopupEquipCompose:OnBtnMinusSelectClick()
    if self.CurComposeCount > 0 then
        self.CurComposeCount = self.CurComposeCount - 1
        self:RefreshConsumes()
        self.InputSelect.text = self.CurComposeCount
        self:RefreshBtnState()
    else
        self._Control:OpenCommonTipText("EquipComposeCountLimitTips", 1)
    end
end

function XUiDlcRelinkPopupEquipCompose:OnBtnMaxClick()
    if self.CurComposeCount < self.MaxComposeCount then
        self.CurComposeCount = self.MaxComposeCount
        self:RefreshConsumes()
        self.InputSelect.text = self.CurComposeCount
        self:RefreshBtnState()
    end
end

function XUiDlcRelinkPopupEquipCompose:OnBtnComposeClick()
    if self.CurComposeCount <= 0 then
        self._Control:OpenCommonTipText("EquipComposeCountZero")
        return
    end

    local itemId, itemCount = self:GetItemIdAndCount()
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)
    if haveCount < itemCount * self.CurComposeCount then
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        local desc = string.format(self._Control:GetClientConfig("EquipComposeItemNotEnough"), itemName)
        self._Control:OpenCommonTipMsg(desc)
        return
    end

    self._Control:RequestEquipCompose(self.ComposeId, self.CurComposeCount, function(equipRewardGoodsList)
        self:Close()
        if XTool.IsTableEmpty(equipRewardGoodsList) then
            return
        end
        local equipUidList = {}
        for _, goods in ipairs(equipRewardGoodsList) do
            if XTool.IsNumberValid(goods.EquipUid) then
                table.insert(equipUidList, goods.EquipUid)
            end
        end
        XLuaUiManager.Open("UiDlcRelinkPopupEquipComposeResult", equipUidList)
    end)
end

return XUiDlcRelinkPopupEquipCompose
