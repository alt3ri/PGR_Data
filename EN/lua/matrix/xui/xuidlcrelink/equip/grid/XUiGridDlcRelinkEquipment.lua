---@class XUiGridDlcRelinkEquipment : XUiNode
---@field private _Control XDlcRelinkControl
---@field Pointer XUguiPointerEventListener
local XUiGridDlcRelinkEquipment = XClass(XUiNode, "XUiGridDlcRelinkEquipment")

function XUiGridDlcRelinkEquipment:OnStart(callBack, RemoveCallBack)
    self.CallBack = callBack
    self.RemoveCallBack = RemoveCallBack
    self.BtnEquip:AddEventListener(handler(self, self.OnBtnEquipClick))
    self.BtnRemove:AddEventListener(handler(self, self.OnBtnRemoveClick))
    if self.BtnRemove2 then
        self.BtnRemove2:AddEventListener(handler(self, self.OnBtnRemoveClick))
    end
    if self.Pointer then
        self.Pointer.OnDown = function(eventData) self:OnPointerDown(eventData) end
        self.Pointer.OnClick = function(eventData) self:OnBtnEquipClick(eventData) end
        self.Pointer.OnPress = function(pressTime) self:OnPress(pressTime) end
        self.Pointer.OnUp = function(eventData) self:OnPointerUp(eventData) end
        self.Pointer.OnExit = function(eventData) self:OnPointerExit(eventData) end
        if self.BtnEquip then
            self.BtnEquip.gameObject:SetActiveEx(false)
        end
        if self.BtnRemove then
            self.BtnRemove.gameObject:SetActiveEx(false)
        end

        self.IsDragClone = false  -- 是否是拖拽出来的克隆
        self.IsEquipSlot = false  -- 是否是装备槽位

        self.PressProgressTarget = self.ImgQuality.transform -- 长按进度条的目标位置
    end
end

function XUiGridDlcRelinkEquipment:GetEquipUid()
    return self.EquipUid
end

function XUiGridDlcRelinkEquipment:GetSlotIndex()
    return self.SlotIndex
end

function XUiGridDlcRelinkEquipment:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_EQUIP_CHANGE,
    }
end

function XUiGridDlcRelinkEquipment:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_RELINK_EQUIP_CHANGE then
        if args[1] == self.EquipUid then
            self:RefreshIsLocked()
            self:RefreshIsDiscard()
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
    local equipOccupationTypeIcon = self._Control:GetEquipOccupationIcon(templateId)
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
    self.TxtLv.text = equipAbility

    self:RefreshIsLocked()
    self:RefreshIsDiscard()
end

-- 刷新锁定状态
function XUiGridDlcRelinkEquipment:RefreshIsLocked()
    if self.IsNotSelf or not XTool.IsNumberValid(self.EquipUid) then
        self.Lock.gameObject:SetActiveEx(false)
        return
    end
    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.EquipUid, self.IsNotSelf)
    self.Lock.gameObject:SetActiveEx(isLocked)
end

-- 刷新弃置状态
function XUiGridDlcRelinkEquipment:RefreshIsDiscard()
    if self.IsNotSelf or not XTool.IsNumberValid(self.EquipUid) then
        if self.Discard then
            self.Discard.gameObject:SetActiveEx(false)
        end
        return
    end
    local isDiscard = self._Control:GetEquipIsDiscardedByEquipUid(self.EquipUid, self.IsNotSelf)
    if self.Discard then
        self.Discard.gameObject:SetActiveEx(isDiscard)
    end
end

---装备展示
function XUiGridDlcRelinkEquipment:RefreshByEquipId(templateId)
    self:HideAll()

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
    local equipOccupationTypeIcon = self._Control:GetEquipOccupationIcon(templateId)
    if not string.IsNilOrEmpty(equipOccupationTypeIcon) then
        self.EquipmentBg.gameObject:SetActiveEx(true)
        self.IconEquipment:SetSprite(equipOccupationTypeIcon)
    end
end

function XUiGridDlcRelinkEquipment:HideAll()
    self.IconBg01.gameObject:SetActiveEx(false)
    self.IconBg02.gameObject:SetActiveEx(false)
    self.RImgIcon.gameObject:SetActiveEx(false)
    self.EquipmentBg.gameObject:SetActiveEx(false)
    self.ImgQuality.gameObject:SetActiveEx(false)
    self.ImgLv.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    if self.Discard then
        self.Discard.gameObject:SetActiveEx(false)
    end
    self.PanelSelect.gameObject:SetActiveEx(false)
    self.ImgAdd.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.ImgNon.gameObject:SetActiveEx(false)
    self.PanelHead.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
    if self.ImgOnDrag then
        self.ImgOnDrag.gameObject:SetActiveEx(false)
    end
end

-- 选中状态
function XUiGridDlcRelinkEquipment:SetSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
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

-- 设置拖拽状态
function XUiGridDlcRelinkEquipment:SetOnDrag(isOnDrag)
    if self.ImgOnDrag then
        self.ImgOnDrag.gameObject:SetActiveEx(isOnDrag)
    end
end

-- 设置是否响应穿透事件
function XUiGridDlcRelinkEquipment:SetRespondPassEvent(isRespond)
    self.BtnEquip.IsRespondPassEvent = isRespond
end

function XUiGridDlcRelinkEquipment:OnBtnEquipClick()
    if self.IsDragClone then
        return
    end
    if self.CallBack then
        self.CallBack(self)
    end
end

function XUiGridDlcRelinkEquipment:OnBtnRemoveClick()
    if self.IsDragClone then
        return
    end
    if self.RemoveCallBack then
        self.RemoveCallBack(self)
    end
end

--region 拖拽相关

function XUiGridDlcRelinkEquipment:SetIsDragClone(isDragClone)
    self.IsDragClone = isDragClone
end

function XUiGridDlcRelinkEquipment:SetIsEquipSlot(isEquipSlot)
    self.IsEquipSlot = isEquipSlot
end

function XUiGridDlcRelinkEquipment:GetIsEquipSlot()
    return self.IsEquipSlot
end

-- 手指按下
function XUiGridDlcRelinkEquipment:OnPointerDown(eventData)
    if self.IsDragClone then
        return
    end
    if not XTool.IsNumberValid(self.EquipUid) then
        return
    end
    if self.Parent.OnGridPointerDown then
        self.Parent:OnGridPointerDown(self)
    end
end

--- 长按触发拖拽
function XUiGridDlcRelinkEquipment:OnPress(pressTime)
    if self.IsDragClone then
        return
    end
    -- 无装备不可拖拽
    if not XTool.IsNumberValid(self.EquipUid) then
        return
    end
    if self.Parent.OnGridPress then
        self.Parent:OnGridPress(self)
    end
end

--- 手指抬起
function XUiGridDlcRelinkEquipment:OnPointerUp(eventData)
    if self.IsDragClone then
        return
    end
    if self.Parent.OnGridPointerUp then
        self.Parent:OnGridPointerUp(self)
    end
end

--- 移出Grid范围
function XUiGridDlcRelinkEquipment:OnPointerExit(eventData)
    if self.IsDragClone then
        return
    end
    if self.Parent.OnGridPointerExit then
        self.Parent:OnGridPointerExit(self)
    end
end

--- 设置 Canvas
function XUiGridDlcRelinkEquipment:SetOverrideSorting(isOverride, sortingOrder)
    if XTool.UObjIsNil(self.Canvas) then
        ---@type UnityEngine.Canvas
        self.Canvas = self.GameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
        if XTool.UObjIsNil(self.Canvas) then
            self.Canvas = self.GameObject:AddComponent(typeof(CS.UnityEngine.Canvas))
        end
    end
    self.Canvas.overrideSorting = isOverride
    if isOverride then
        self.Canvas.sortingOrder = sortingOrder or 0
    end
end

--endregion

return XUiGridDlcRelinkEquipment
