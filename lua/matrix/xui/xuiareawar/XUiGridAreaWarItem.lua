---@class XUiGridAreaWarItem : XUiNode
---@field private _Control XAreaWarControl
local XUiGridAreaWarItem = XClass(XUiNode, "XUiGridAreaWarItem")

function XUiGridAreaWarItem:OnStart()
    self.IgnoreNumX = false
    self:RegisterUiEvents()
end

function XUiGridAreaWarItem:RegisterUiEvents()
    self.Button = self.Button or self.Transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
    if self.Button then
        XUiHelper.RegisterClickEvent(self, self.Button, self.OnButtonClick, nil, true)
    end
end

function XUiGridAreaWarItem:OnButtonClick()
    if self.ClickCb then
        self.ClickCb()
    end
end

-- 刷新道具，基于拥有数量的显示
function XUiGridAreaWarItem:RefreshItem(itemId, num, ignoreNumX)
    self.ItemId = itemId
    self.Num = num or self._Control:GetItemRoom():GetItemNum(itemId)
    self.IgnoreNumX = ignoreNumX == true -- 是否忽略数量的X
    
    self:RefreshName()
    self:RefreshIcon()
    self:RefreshQuality()
    self:RefreshNum()
    self:RefreshTagNew()
    self:ShowEffect()
end

-- 刷新道具用于消耗
---@param itemId number 道具Id
---@param needNum number 需要消耗的数量
function XUiGridAreaWarItem:RefreshItemByCost(itemId, needNum)
    self.ItemId = itemId
    self.NeedNum = needNum

    self:RefreshIcon()
    self:RefreshQuality()
    self:RefreshNeedNum()
    self:SetDefaultClickCallBack()
end

function XUiGridAreaWarItem:RefreshName()
    local name = self._Control:GetConfig():GetItemName(self.ItemId)
    if self.Normal then
        local txtNameNormal = self.Normal:GetObject("TxtName", false)
        if txtNameNormal then
            txtNameNormal.text = name
        end
    end

    if self.Press then
        local txtNamePress = self.Press:GetObject("TxtName", false)
        if txtNamePress then
            txtNamePress.text = name
        end
    end

    if self.Disable then
        local txtNameDisable = self.Disable:GetObject("TxtName", false)
        if txtNameDisable then
            txtNameDisable.text = name
        end
    end
end

function XUiGridAreaWarItem:RefreshIcon()
    local icon = self._Control:GetConfig():GetItemIcon(self.ItemId)
    self.Normal:GetObject("RImgIcon"):SetRawImage(icon)
    if self.Press then
        self.Press:GetObject("RImgIcon"):SetRawImage(icon)
    end
    if self.Disable then
        self.Disable:GetObject("RImgIcon"):SetRawImage(icon)
    end
end

function XUiGridAreaWarItem:RefreshQuality()
    local quality = self._Control:GetConfig():GetItemQuality(self.ItemId)
    local icon = self._Control:GetConfig():GetItemQualityIcon(quality)
    self.Normal:GetObject("ImgQuality"):SetSprite(icon)
    if self.Press then
        self.Press:GetObject("ImgQuality"):SetSprite(icon)
    end
    if self.Disable then
        self.Disable:GetObject("ImgQuality"):SetSprite(icon)
    end
end

-- 刷新数量
function XUiGridAreaWarItem:RefreshNum()
    local isHave = self.Num > 0
    local panelNumNormal = self.Normal and self.Normal:GetObject("PanelNum", false)
    if panelNumNormal then
        panelNumNormal.gameObject:SetActiveEx(isHave)
    end
    if self.Press then
        local panelNumPress = self.Press:GetObject("PanelNum", false)
        if panelNumPress then
            panelNumPress.gameObject:SetActiveEx(isHave)
        end
    end

    if isHave then
        local numStr = self.IgnoreNumX and tostring(self.Num) or "x" .. tostring(self.Num)
        local txtNumNormal = self.Normal and self.Normal:GetObject("TxtNum", false)
        if txtNumNormal then
            txtNumNormal.text = numStr
        end
        if self.Press then
            local txtNumPress = self.Press:GetObject("TxtNum", false)
            if txtNumPress then
                txtNumPress.text = numStr
            end
        end
    end

    if self.ImgMask then
        local isShowMask = not isHave and self:IsUnlock()
        self.ImgMask.gameObject:SetActiveEx(isShowMask)
    end
end

-- 刷新需要的数量
function XUiGridAreaWarItem:RefreshNeedNum()
    local ownNum = self._Control:GetItemRoom():GetItemNum(self.ItemId)
    local txt
    if ownNum >= self.NeedNum then
        txt = string.format(XAreaWarConfigs.GetItemRoomLvUpCost(), ownNum, self.NeedNum)
    else
        txt = string.format(XAreaWarConfigs.GetItemRoomLvUpCostNoEnough(), ownNum, self.NeedNum)
    end
    self.Normal:GetObject("TxtNeed").text = txt
    if self.Press then
        self.Press:GetObject("TxtNeed").text = txt
    end
end

function XUiGridAreaWarItem:RefreshTagNew()
    if self.TagNew then
        local isNewGet = self._Control:GetItemRoom():IsItemNewGet(self.ItemId)
        self.TagNew.gameObject:SetActiveEx(isNewGet)
    end
end

-- 刷新上锁状态
function XUiGridAreaWarItem:RefreshLockState()
    local isUnlock = self:IsUnlock() or self.Num > 0
    self.Button:SetButtonState(isUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

-- 刷新上锁提示
function XUiGridAreaWarItem:RefreshUnlockTips()
    if self.Disable then
        local txtNameDisable = self.Disable:GetObject("TxtName", false)
        if txtNameDisable then
            local unlockLv = self._Control:GetConfig():GetItemUnlockLv(self.ItemId)
            local unlockTips = XAreaWarConfigs.GetItemUnlockTips()
            txtNameDisable.text = string.format(unlockTips, unlockLv)
        end
    end
end

function XUiGridAreaWarItem:IsUnlock()
    return self._Control:IsItemUnlock(self.ItemId)
end

-- 设置默认点击回调
function XUiGridAreaWarItem:SetDefaultClickCallBack()
    self.ClickCb = function()
        XLuaUiManager.Open("UiAreaWarPopupCollectionTip", self.ItemId)
    end
end

-- 显示特效
function XUiGridAreaWarItem:ShowEffect()
    self.Effect = self.Effect or self.Transform:Find("Effect")
    if self.Effect then
        local quality = self._Control:GetConfig():GetItemQuality(self.ItemId)
        local effectPath = self._Control:GetConfig():GetItemQualityEffect(quality)
        if not string.IsNilOrEmpty(effectPath) then
            self.Effect.gameObject:SetActiveEx(true)
            self.Effect:LoadPrefab(effectPath)
        end
    end
end

-- 隐藏特效
function XUiGridAreaWarItem:HideEffect()
    self.Effect = self.Effect or self.Transform:Find("Effect")
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

return XUiGridAreaWarItem
