local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
---@class XUiDlcRelinkPopupEquipCompose : XLuaUi
---@field private _Control XDlcRelinkControl
---@field InputSelect UnityEngine.UI.InputField
local XUiDlcRelinkPopupEquipCompose = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipCompose")

local Interval = 100
local SpeedBaseNumber = 150

function XUiDlcRelinkPopupEquipCompose:OnAwake()
    self._ItemId = tonumber(self._Control:GetConfig("TargetingComposeConsumeId"))
    self._ItemCount = tonumber(self._Control:GetConfig("TargetingComposeConsumeCount"))
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupEquipCompose:OnStart(composeId)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.ComposeId = composeId
    self.CurComposeCount = 1

    self:UpdateMaxComposeCount()
    self:SetInputSelectData()
    self.InputSelect.onValueChanged:AddListener((handler(self, self.OnInputSelectValueChanged)))
    self.InputSelect.onEndEdit:AddListener((handler(self, self.OnInputSelectEndEdit)))

    self.WgtBtnAddSelect = self.BtnAddSelect.gameObject:GetComponent("XUiPointer")
    self.WgtBtnMinusSelect = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")

    XUiButtonLongClick.New(self.WgtBtnAddSelect, Interval, self, nil, self.BtnAddSelectLongClickCallback, nil, true)
    XUiButtonLongClick.New(self.WgtBtnMinusSelect, Interval, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)

    ---@type XUiPanelDlcRelinkEquipChooseAttribute
    self._ChooseAttribute = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipChooseAttribute").New(self.PanelChooseAttribute, self)
end

function XUiDlcRelinkPopupEquipCompose:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshConsumes()
    self:RefreshBtnState()
    self.InputSelect.text = self.CurComposeCount
end

function XUiDlcRelinkPopupEquipCompose:UpdateMaxComposeCount()
    if self._ChooseAttribute and self._ChooseAttribute:IsChooseAttr() then
        local haveCount = XDataCenter.ItemManager.GetCount(self._ItemId)
        self.MaxComposeCount = math.floor(haveCount / self._ItemCount)
    else
        self.MaxComposeCount = self._Control:CalculateComposeMaxCount(self.ComposeId)
    end
    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    local bagSpace = maxCount > curCount and (maxCount - curCount) or 0
    self.MaxComposeCount = math.max(1, math.min(self.MaxComposeCount, bagSpace))
end

function XUiDlcRelinkPopupEquipCompose:OnChooseAttrChange()
    self:UpdateMaxComposeCount()
    if self.CurComposeCount > self.MaxComposeCount then
        self.CurComposeCount = self.MaxComposeCount
        self.InputSelect.text = self.CurComposeCount
    end
    self:RefreshConsumes()
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:SetInputSelectData()
    self.InputSelect.characterLimit = 4
    self.InputSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

function XUiDlcRelinkPopupEquipCompose:GetItemIdAndCount()
    if self._ChooseAttribute:IsChooseAttr() then
        --定向合成的消耗
        return self._ItemId, self._ItemCount
    else
        local consumeIds = self._Control:GetComposeConsumeIds(self.ComposeId)
        local consumeCounts = self._Control:GetComposeConsumeCounts(self.ComposeId)
        -- 默认取第一个消耗物品
        local itemId = consumeIds[1]
        local itemCount = consumeCounts[1]
        return itemId, itemCount
    end
end

function XUiDlcRelinkPopupEquipCompose:RefreshConsumes()
    local itemId, itemCount = self:GetItemIdAndCount()
    self.RImgCostIcon1:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(itemId))
    self.TxtCostCount1.text = itemCount * self.CurComposeCount
end

function XUiDlcRelinkPopupEquipCompose:RefreshBtnState()
    self.BtnMinusSelect:SetDisable(self.CurComposeCount <= 1)
    self.BtnAddSelect:SetDisable(self.CurComposeCount >= self.MaxComposeCount)
end

function XUiDlcRelinkPopupEquipCompose:OnInputSelectValueChanged(value)
    local num = tonumber(value)
    if not num or num <= 0 then
        return
    end

    num = num or 1
    if num > self.MaxComposeCount then
        num = self.MaxComposeCount
        self.InputSelect.text = num
    end

    self.CurComposeCount = num
    self:RefreshConsumes()
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:OnInputSelectEndEdit(value)
    local num = tonumber(value)
    if not num or num <= 0 then
        self.CurComposeCount = 1
        self.InputSelect.text = 1
        self:RefreshConsumes()
        self:RefreshBtnState()
        self._Control:OpenCommonTipText("EquipComposeInputTip")
    end
end

function XUiDlcRelinkPopupEquipCompose:BtnAddSelectLongClickCallback(time)
    if self.CurComposeCount >= self.MaxComposeCount then
        self:ShowLimitTip(true)
        return
    end

    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.CurComposeCount = math.min(self.MaxComposeCount, self.CurComposeCount + delta)
    self:RefreshConsumes()
    self.InputSelect.text = self.CurComposeCount
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:BtnMinusSelectLongClickCallback(time)
    if self.CurComposeCount <= 1 then
        self:ShowLimitTip(false)
        return
    end

    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.CurComposeCount = math.max(1, self.CurComposeCount - delta)
    self:RefreshConsumes()
    self.InputSelect.text = self.CurComposeCount
    self:RefreshBtnState()
end

function XUiDlcRelinkPopupEquipCompose:RegisterUiEvents()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnAddSelect:AddEventListener(handler(self, self.OnBtnAddSelectClick))
    self.BtnMinusSelect:AddEventListener(handler(self, self.OnBtnMinusSelectClick))
    self.BtnMax:AddEventListener(handler(self, self.OnBtnMaxClick))
    self.BtnCompose:AddEventListener(handler(self, self.OnBtnComposeClick))
end

function XUiDlcRelinkPopupEquipCompose:OnBtnCloseClick()
    self:Close()
end

function XUiDlcRelinkPopupEquipCompose:ShowLimitTip(isAdd)
    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    local isFull = false
    if isAdd then
        isFull = curCount + self.CurComposeCount >= maxCount
    else
        isFull = curCount >= maxCount
    end

    if isFull then
        self._Control:OpenCommonTipCode(XCode.RelinkEquipBagIsFull)
    else
        local tipType = isAdd and 2 or 1
        self._Control:OpenCommonTipText("EquipComposeCountLimitTips", tipType)
    end
end

function XUiDlcRelinkPopupEquipCompose:OnBtnAddSelectClick()
    if self.CurComposeCount < self.MaxComposeCount then
        self.CurComposeCount = self.CurComposeCount + 1
        self:RefreshConsumes()
        self.InputSelect.text = self.CurComposeCount
        self:RefreshBtnState()
    else
        self:ShowLimitTip(true)
    end
end

function XUiDlcRelinkPopupEquipCompose:OnBtnMinusSelectClick()
    if self.CurComposeCount > 1 then
        self.CurComposeCount = self.CurComposeCount - 1
        self:RefreshConsumes()
        self.InputSelect.text = self.CurComposeCount
        self:RefreshBtnState()
    else
        self:ShowLimitTip(false)
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

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    if curCount + self.CurComposeCount > maxCount then
        self._Control:OpenCommonTipCode(XCode.RelinkEquipBagIsFull)
        return
    end

    local factorId = self._ChooseAttribute:GetAttrId() or 0
    local composeId = XTool.IsNumberValid(factorId) and 0 or self.ComposeId

    self._Control:RequestEquipCompose(composeId, self.CurComposeCount, factorId, function(equipRewardGoodsList)
        if XTool.IsTableEmpty(equipRewardGoodsList) then
            return
        end
        local equipUidList = {}
        for _, goods in ipairs(equipRewardGoodsList) do
            if XTool.IsNumberValid(goods.EquipUid) then
                table.insert(equipUidList, goods.EquipUid)
            end
        end
        self:OnChooseAttrChange()
        XLuaUiManager.Open("UiDlcRelinkPopupEquipComposeResult", equipUidList)
    end)
end

return XUiDlcRelinkPopupEquipCompose
