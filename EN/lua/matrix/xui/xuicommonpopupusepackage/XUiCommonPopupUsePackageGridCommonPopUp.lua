local XUiCommonPopupUsePackageGridCommonPopUp = XClass(nil, "XUiCommonPopupUsePackageGridCommonPopUp")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
function XUiCommonPopupUsePackageGridCommonPopUp:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = ui
    XTool.InitUiObject(self)
end

function XUiCommonPopupUsePackageGridCommonPopUp:UpdateGrid(itemid, parent, index)
    self.Parent = parent
    self.ItemId = itemid
    self.TxtCount.text = XDataCenter.ItemManager.GetCount(itemid)
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemid))
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.TxtSelectHide.gameObject:SetActiveEx(false)
    self.BtnMinusSelect.gameObject:SetActiveEx(false)
    local template = XDataCenter.ItemManager.GetItemTemplate(itemid)
    local sprite
    if not template or not template.TimelinessType or
        template.TimelinessType == XDataCenter.ItemManager.TimelinessType.Invalid then
        self.TxtTime.text = CS.XTextManager.GetText("Forever")
        sprite = XUiHelper.TagBgPath.Green
    else
        local LifeTime = XDataCenter.ItemManager.GetRecycleLeftTime(itemid)

        if LifeTime and LifeTime > 0 then
            local tmpTime = XUiHelper.GetTime(LifeTime, XUiHelper.TimeFormatType.MAINBATTERY)
            self.TxtTime.text = tmpTime
            if LifeTime > CS.XDateUtil.ONE_DAY_SECOND * 7 then
                sprite = XUiHelper.TagBgPath.Green
            elseif LifeTime > CS.XDateUtil.ONE_DAY_SECOND then
                sprite = XUiHelper.TagBgPath.Yellow
            else
                sprite = XUiHelper.TagBgPath.Red
            end
        else
            self.TxtTime.text = CS.XTextManager.GetText("TaskStateOverdue")
            sprite = XUiHelper.TagBgPath.Red
        end
    end
    parent:SetUiSprite(self.TimeTag, sprite)
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
    self.BtnMinusSelect:AddEventListener(handler(self, self.OnBtnMinusClick))
    self.Count = 0
    -- 添加长按事件
    local btnSelfClickPointer = self.BtnClick.gameObject:GetComponent("XUiPointer")
    self.BtnLongClick = XUiButtonLongClick.New(btnSelfClickPointer, 90, self, nil, self.OnBtnSelfLongClick, nil, true)
    local btnMinusPointer = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")
    self.BtnMinusLongClick = XUiButtonLongClick.New(btnMinusPointer, 10, self, nil, self.OnBtnMinusLongClick, nil, true)
end

function XUiCommonPopupUsePackageGridCommonPopUp:OnBtnSelfLongClick()
    if self.Count >= XDataCenter.ItemManager.GetCount(self.ItemId) then
        local itemName = XDataCenter.ItemManager.GetItemName(self.ItemId)
        if itemName ~= nil then
            XUiManager.TipMsg(CS.XTextManager.GetText("UsePackageOverMaxCount", itemName))
        end
        return
    end
    self:OnBtnClick()
end

function XUiCommonPopupUsePackageGridCommonPopUp:OnBtnMinusLongClick()
    self:OnBtnMinusClick()
end

function XUiCommonPopupUsePackageGridCommonPopUp:OnBtnClick()
    if self.Count >= XDataCenter.ItemManager.GetCount(self.ItemId) then
        return
    end
    self.Count = self.Count + 1
    self.ImgSelect.gameObject:SetActiveEx(true)
    self.TxtSelectHide.gameObject:SetActiveEx(true)
    self.BtnMinusSelect.gameObject:SetActiveEx(true)
    self.TxtSelectHide.text = self.Count
    self.Parent:OnItemBtnClick(self.ItemId, self.Count)
end

function XUiCommonPopupUsePackageGridCommonPopUp:OnBtnMinusClick()
    self.Count = self.Count - 1
    if self.Count <= 0 then
        self.ImgSelect.gameObject:SetActiveEx(false)
        self.TxtSelectHide.gameObject:SetActiveEx(false)
        self.BtnMinusSelect.gameObject:SetActiveEx(false)
        self.Count = 0
    end
    self.TxtSelectHide.text = self.Count
    self.Parent:OnItemBtnClick(self.ItemId, self.Count)
end

function XUiCommonPopupUsePackageGridCommonPopUp:OnRecycle()
    self.BtnLongClick:Destroy()
    self.BtnMinusLongClick:Destroy()
end

return XUiCommonPopupUsePackageGridCommonPopUp
