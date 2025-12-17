---@class XUiGridDlcRelinkEquipment : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkEquipment = XClass(XUiNode, "XUiGridDlcRelinkEquipment")

function XUiGridDlcRelinkEquipment:OnStart(callBack)
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.BtnEquip, self.OnBtnEquipClick, true)
end

function XUiGridDlcRelinkEquipment:GetEquipUId()
    return self.EquipUId
end

function XUiGridDlcRelinkEquipment:GetIndex()
    return self.Index
end

function XUiGridDlcRelinkEquipment:Refresh(equipUId, index)
    self.EquipUId = equipUId
    self.Index = index
    self:HideAll()

    if not XTool.IsNumberValid(equipUId) then
        return
    end

    local templateId = self._Control:GetEquipTemplateIdByEquipUId(self.EquipUId)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("XUiGridDlcRelinkEquipment:Refresh templateId is invalid, equipUId: " .. equipUId)
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
        self.IconEquipment:SetRawImage(equipOccupationTypeIcon)
    end

    -- 品质图标
    local equipQualityIcon = self._Control:GetEquipQualityAssetsByEquipId(templateId)
    if not string.IsNilOrEmpty(equipQualityIcon) then
        self.ImgQuality.gameObject:SetActiveEx(true)
        self.ImgQuality:SetSprite(equipQualityIcon)
    end

    -- 装备等级
    local equipAbility = self._Control:GetEquipAbilityByUid(self.EquipUId)
    self.ImgLv.gameObject:SetActiveEx(equipAbility > 0)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), equipAbility)

    -- 装备是否上锁
    local isLocked = self._Control:GetEquipIsLockedByEquipUId(self.EquipUId)
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

-- 设置角色头像 (当前装备被那个角色使用)
function XUiGridDlcRelinkEquipment:SetHead(characterId)
    if not XTool.IsNumberValid(characterId) then
        self.PanelHead.gameObject:SetActiveEx(false)
        return
    end
    self.PanelHead.gameObject:SetActiveEx(true)
    self.Head:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(characterId))
end

function XUiGridDlcRelinkEquipment:OnBtnEquipClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridDlcRelinkEquipment
