---@class XUiGridDlcRelinkEquipment : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkEquipment = XClass(XUiNode, "XUiGridDlcRelinkEquipment")

function XUiGridDlcRelinkEquipment:OnStart(callBack, RemoveCallBack)
    self.CallBack = callBack
    self.RemoveCallBack = RemoveCallBack
    XUiHelper.RegisterClickEvent(self, self.BtnEquip, self.OnBtnEquipClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRemove, self.OnBtnRemoveClick, true, true)
end

function XUiGridDlcRelinkEquipment:GetEquipUid()
    return self.EquipUid
end

function XUiGridDlcRelinkEquipment:GetSlotIndex()
    return self.SlotIndex
end

function XUiGridDlcRelinkEquipment:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_EQUIP_LOCK_CHANGE,
    }
end

function XUiGridDlcRelinkEquipment:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_RELINK_EQUIP_LOCK_CHANGE then
        if args[1] == self.EquipUid then
            self:RefreshIsLocked()
        end
    end
end

function XUiGridDlcRelinkEquipment:Refresh(equipUid, slotIndex, isNotSelf)
    self.EquipUid = equipUid
    self.SlotIndex = slotIndex
    self.IsNotSelf = isNotSelf or false
    self:HideAll()

    if not XTool.IsNumberValid(equipUid) then
        local isMainSlot = slotIndex == XEnumConst.DlcRelink.EquipSlotIndex.MainSlot
        self.IconBg01.gameObject:SetActiveEx(isMainSlot)
        self.IconBg02.gameObject:SetActiveEx(not isMainSlot)
        return
    end

    local templateId = self._Control:GetEquipTemplateIdByEquipUid(self.EquipUid, self.IsNotSelf)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("XUiGridDlcRelinkEquipment:Refresh templateId is invalid, equipUid: " .. equipUid)
        return
    end

    -- 装备类型
    local equipType = self._Control:GetEquipType(templateId)
    self.IconBg01.gameObject:SetActiveEx(equipType == XEnumConst.DlcRelink.EquipType.Main)
    self.IconBg02.gameObject:SetActiveEx(equipType == XEnumConst.DlcRelink.EquipType.Normal)

    -- 装备图标
    local equipIcon = self._Control:GetEquipIcon(templateId)
    if not string.IsNilOrEmpty(equipIcon) then
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon:SetRawImage(equipIcon)
    end

    -- 装备职业类型图标
    local equipOccupationTypeIcon = self._Control:GetOccupationIconByEquipId(templateId)
    if not string.IsNilOrEmpty(equipOccupationTypeIcon) then
        self.EquipmentBg.gameObject:SetActiveEx(true)
        self.IconEquipment:SetSprite(equipOccupationTypeIcon)
    end

    -- 品质图标
    local equipQualityIcon = self._Control:GetEquipQualityAssetsByEquipId(templateId)
    if not string.IsNilOrEmpty(equipQualityIcon) then
        self.ImgQuality.gameObject:SetActiveEx(true)
        self.ImgQuality:SetSprite(equipQualityIcon)
    end

    -- 装备战力
    local equipAbility = self._Control:GetEquipAbilityByUid(self.EquipUid, self.IsNotSelf)
    self.ImgLv.gameObject:SetActiveEx(equipAbility > 0)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), equipAbility)

    self:RefreshIsLocked()
end

-- 刷新锁定状态
function XUiGridDlcRelinkEquipment:RefreshIsLocked()
    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.EquipUid, self.IsNotSelf)
    self.Lock.gameObject:SetActiveEx(isLocked)
end

function XUiGridDlcRelinkEquipment:HideAll()
    self.IconBg01.gameObject:SetActiveEx(false)
    self.IconBg02.gameObject:SetActiveEx(false)
    self.RImgIcon.gameObject:SetActiveEx(false)
    self.EquipmentBg.gameObject:SetActiveEx(false)
    self.ImgQuality.gameObject:SetActiveEx(false)
    self.ImgLv.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.ImgAdd.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.ImgNon.gameObject:SetActiveEx(false)
    self.PanelHead.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
end

-- 选中状态
-- isShowMinus: 是否显示减号
function XUiGridDlcRelinkEquipment:SetSelect(isSelect, isShowMinus)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.PanelSelect:GetObject("Image1").gameObject:SetActiveEx(isShowMinus)
        self.PanelSelect:GetObject("Image2").gameObject:SetActiveEx(isShowMinus)
    end
end

-- 显示添加标识 (当前槽位无装备)
function XUiGridDlcRelinkEquipment:SetAdd(isAdd)
    self.ImgAdd.gameObject:SetActiveEx(isAdd)
end

-- 当前槽位是否解锁
function XUiGridDlcRelinkEquipment:SetLock(isLock)
    self.ImgLock.gameObject:SetActiveEx(isLock)
end

-- 装备无效(不可用)
function XUiGridDlcRelinkEquipment:SetNon(isNon)
    self.ImgNon.gameObject:SetActiveEx(isNon)
end

-- 设置预设
function XUiGridDlcRelinkEquipment:SetPreset(isPreset)
    if self.PanelPreset then
        self.PanelPreset.gameObject:SetActiveEx(isPreset)
    end
end

-- 设置角色头像 (当前装备被那个角色使用)
function XUiGridDlcRelinkEquipment:SetHead(characterId)
    if not XTool.IsNumberValid(characterId) then
        self.PanelHead.gameObject:SetActiveEx(false)
        return
    end
    self.PanelHead.gameObject:SetActiveEx(true)
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    self.Head:SetRawImage(XDataCenter.FashionManager.GetFashionRoundnessHeadIcon(fashionId))
end

-- 红点
function XUiGridDlcRelinkEquipment:SetRedDot(isShow)
    self.Red.gameObject:SetActiveEx(isShow)
end

function XUiGridDlcRelinkEquipment:OnBtnEquipClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

function XUiGridDlcRelinkEquipment:OnBtnRemoveClick()
    if self.RemoveCallBack then
        self.RemoveCallBack(self)
    end
end

return XUiGridDlcRelinkEquipment
