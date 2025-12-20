local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiGridDlcRelinkCharacterProperty = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterProperty")
local XUiGridDlcRelinkCharacterSkill = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterSkill")
---@class XUiPanelDlcRelinkCharacterRightOther : XUiNode
---@field private _Control XDlcRelinkControl
---@field BtnTab XUiButtonGroup
local XUiPanelDlcRelinkCharacterRightOther = XClass(XUiNode, "XUiPanelDlcRelinkCharacterRightOther")

function XUiPanelDlcRelinkCharacterRightOther:OnStart()
    self.PropertyItem.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitBtnTab()

    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}
    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0
    ---@type XUiGridDlcRelinkCharacterProperty[]
    self.PropertyGridList = {}
    ---@type XUiGridDlcRelinkCharacterSkill[]
    self.SkillGridList = {}
    self.CurSelectSkillId = 0
    self.CurSelectSkillGrid = nil
end

---@param member XDlcMember 克隆后的成员数据
function XUiPanelDlcRelinkCharacterRightOther:Refresh(member)
    self.Member = member
    self:RefreshInfo()
    self:RefreshAttributes()
    self.BtnTab:SelectIndex(1)
end

function XUiPanelDlcRelinkCharacterRightOther:InitBtnTab()
    local btnTabList = { self.BtnEquipment, self.BtnSkill }
    self.BtnTab:Init(btnTabList, handler(self, self.OnBtnTabClick))
end

function XUiPanelDlcRelinkCharacterRightOther:OnBtnTabClick(index)
    if index == 1 then
        self.PanelEquipment.gameObject:SetActiveEx(true)
        self.PanelSkill.gameObject:SetActiveEx(false)
        self:RefreshPanelEquipment()
    elseif index == 2 then
        self.PanelEquipment.gameObject:SetActiveEx(false)
        self.PanelSkill.gameObject:SetActiveEx(true)
        self:RefreshPanelSkill()
    end
end

function XUiPanelDlcRelinkCharacterRightOther:RefreshPanelEquipment()
    -- 装备总战力
    local totalAbility = self.Member:GetRelinkEquipTotalAbility()
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalAbility)
    -- 装备槽位
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for index, slotIndex in ipairs(equipSlotIndexMap) do
        local grid = self.EquipmentGridList[index]
        if not grid then
            local parent = self[string.format("GridEquipment0%d", index)]
            if not parent then
                XLog.Error("XUiPanelDlcRelinkCharacterRight:RefreshPanelEquipment - GridEquipment0" .. index .. " not found")
                return
            end
            local go = XUiHelper.Instantiate(self.GridEquipment, parent)
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipGridCallBack))
            self.EquipmentGridList[index] = grid
        end
        grid:Open()
        local equipUid = self._Control.OtherMemberControl:GetEquipWearEquipUidBySlot(slotIndex)
        local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.Member:GetCharacterId(), slotIndex, true)
        grid:Refresh(equipUid, slotIndex, true)
        grid:SetLock(not isUnLock)
        grid:SetAdd(isUnLock and not XTool.IsNumberValid(equipUid))
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiPanelDlcRelinkCharacterRightOther:OnEquipGridCallBack(grid)
    local slotIndex = grid:GetSlotIndex()
    local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.Member:GetCharacterId(), slotIndex, true)
    if not isUnLock then
        self._Control:OpenCommonTipText("EquipSlotNoUnlock")
        return
    end

    local equipUid = grid:GetEquipUid()
    if not XTool.IsNumberValid(equipUid) then
        self._Control:OpenCommonTipText("NoWearEquip")
        return
    end

    if self.CurSelectEquipUid == equipUid then
        return
    end

    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectGrid = grid
    self.CurSelectEquipUid = equipUid

    local mainEquipUid = self._Control.OtherMemberControl:GetEquipWearSlotIndexByEquipUid(equipUid)
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, self.PanelEquipment.transform, handler(self, self.OnBubbleEquipDetailClose), {
        SlotIndex = slotIndex,
        MainEquipUid = mainEquipUid,
        IsNotSelf = true
    })
end

function XUiPanelDlcRelinkCharacterRightOther:OnBubbleEquipDetailClose()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
end

function XUiPanelDlcRelinkCharacterRightOther:RefreshPanelSkill()
    local characterId = self.Member:GetCharacterId()
    local occupationType = self.Member:GetOccupationType()
    local originalSkillIds = self._Control:GetCharacterSkillIds(characterId, occupationType)
    local curSkillIds = self._Control:GetCharacterSkillIdsByCharacterId(characterId, occupationType, true)
    for index, skillId in pairs(curSkillIds) do
        local grid = self.SkillGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSkill, self.PanelSkill)
            grid = XUiGridDlcRelinkCharacterSkill.New(go, self, handler(self, self.OnSkillGridCallBack))
            self.SkillGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(skillId, characterId, skillId ~= originalSkillIds[index], true)
    end
    for i = #curSkillIds + 1, #self.SkillGridList do
        self.SkillGridList[i]:Close()
    end
end

---@param grid XUiGridDlcRelinkCharacterSkill
function XUiPanelDlcRelinkCharacterRightOther:OnSkillGridCallBack(grid)
    local skillId = grid:GetSkillId()
    if not XTool.IsNumberValid(skillId) then
        return
    end
    if self.CurSelectSkillId == skillId then
        return
    end
    if self.CurSelectSkillGrid then
        self.CurSelectSkillGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectSkillId = skillId
    self.CurSelectSkillGrid = grid
    -- 打开技能详情
    XLuaUiManager.Open("UiDlcRelinkPopupSkillDetail", skillId, self.Member:GetCharacterId(), grid:GetIsRemodel(),
        handler(self, self.OnSkillDetailClose), true)
end

function XUiPanelDlcRelinkCharacterRightOther:OnSkillDetailClose()
    if self.CurSelectSkillGrid then
        self.CurSelectSkillGrid:SetSelect(false)
    end
    self.CurSelectSkillId = 0
    self.CurSelectSkillGrid = nil
end

function XUiPanelDlcRelinkCharacterRightOther:RefreshInfo()
    -- 角色信息
    local characterId = self.Member:GetCharacterId()
    self.TxtName01.text = XMVCA.XCharacter:GetCharacterName(characterId)
    self.TxtName02.text = XMVCA.XCharacter:GetCharacterTradeName(characterId)
    local elementId = XMVCA.XCharacter:GetCharacterElement(characterId)
    local charElement = XMVCA.XCharacter:GetCharElement(elementId)
    self.RawImage:SetRawImage(charElement.Icon2)
    self.Txt.text = charElement.ElementName
    -- 角色职业图标
    local occupationType = self.Member:GetOccupationType()
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupationType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.RImgOcc:SetRawImage(occupationIcon)
    end
end

function XUiPanelDlcRelinkCharacterRightOther:RefreshAttributes()
    local curPlayerLevel = self._Control.OtherMemberControl:GetPlayerLevel()
    local equipUids = self._Control.OtherMemberControl:GetWearEquipUids()
    local totalAttributes = self._Control:GetTotalAttributes(self.Member:GetCharacterId(), curPlayerLevel, equipUids, true)

    local maxCount = XEnumConst.DlcRelink.MaxAttributeCount
    local showCount = 0
    local totalLen = #totalAttributes
    local loopCount = math.min(totalLen, maxCount)

    for index = 1, loopCount do
        local attribute = totalAttributes[index]
        local grid = self.PropertyGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.PropertyItem, self.Properties)
            grid = XUiGridDlcRelinkCharacterProperty.New(go, self)
            self.PropertyGridList[index] = grid
        end
        grid:Open()
        local attrValue = attribute.CharacterValue + attribute.PlayerValue + attribute.EquipValue
        grid:Refresh(attribute.AttrStr, attrValue)
        grid:SetBg(index % 2 ~= 0)
        showCount = index
    end

    for i = showCount + 1, #self.PropertyGridList do
        self.PropertyGridList[i]:Close()
    end
end

function XUiPanelDlcRelinkCharacterRightOther:OnDestroy()
    self.Member = nil
end

function XUiPanelDlcRelinkCharacterRightOther:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnMore, self.OnBtnMoreClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLv, self.OnBtnLvClick, true, true)
end

function XUiPanelDlcRelinkCharacterRightOther:OnBtnMoreClick()
    XLuaUiManager.Open("UiDlcRelinkPopupCharacterAttributeDetail", self.Member:GetCharacterId(), true)
end

function XUiPanelDlcRelinkCharacterRightOther:OnBtnLvClick()
    local equipUids = self._Control.OtherMemberControl:GetWearEquipUids()
    if XTool.IsTableEmpty(equipUids) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupEquipAttributeDetail", equipUids, self.Member:GetCharacterId(), true)
end

return XUiPanelDlcRelinkCharacterRightOther
