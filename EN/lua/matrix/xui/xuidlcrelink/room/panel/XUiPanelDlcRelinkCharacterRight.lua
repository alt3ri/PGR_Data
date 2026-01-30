local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiGridDlcRelinkCharacterProperty = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterProperty")
local XUiGridDlcRelinkCharacterSkill = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterSkill")
---@class XUiPanelDlcRelinkCharacterRight : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkCharacter
---@field BtnTab XUiButtonGroup
local XUiPanelDlcRelinkCharacterRight = XClass(XUiNode, "XUiPanelDlcRelinkCharacterRight")

function XUiPanelDlcRelinkCharacterRight:OnStart()
    self.PropertyItem.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitBtnTab()

    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}
    ---@type XUiGridDlcRelinkCharacterProperty[]
    self.PropertyGridList = {}
    ---@type XUiGridDlcRelinkCharacterSkill[]
    self.SkillGridList = {}
    self.CurSelectSkillId = 0
    self.CurSelectSkillGrid = nil
end

function XUiPanelDlcRelinkCharacterRight:Refresh(characterId)
    self.CharacterId = characterId
    self.OccupationType = self._Control:GetOccupationTypeByCharacterId(characterId)
    self:RefreshInfo()
    self:RefreshAttributes()
    self.BtnTab:SelectIndex(1)
    self:RefreshBtn()
end

function XUiPanelDlcRelinkCharacterRight:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_USE_EQUIP_PRESET,
        XEventId.EVENT_DLC_RELINK_SWITCH_OCCUPATION,
    }
end

function XUiPanelDlcRelinkCharacterRight:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_DLC_RELINK_USE_EQUIP_PRESET then
        if args[1] == self.CharacterId then
            self:RefreshAttributes()
            self:RefreshPanelEquipment()
        end
    elseif event == XEventId.EVENT_DLC_RELINK_SWITCH_OCCUPATION then
        if args[1] == self.CharacterId then
            self:RefreshAttributes()
        end
    end
end

function XUiPanelDlcRelinkCharacterRight:InitBtnTab()
    local btnTabList = { self.BtnEquipment, self.BtnSkill }
    self.BtnTab:Init(btnTabList, handler(self, self.OnBtnTabClick))
end

function XUiPanelDlcRelinkCharacterRight:OnBtnTabClick(index)
    if index == 1 then
        self.PanelEquipment.gameObject:SetActiveEx(true)
        self.PanelSkill.gameObject:SetActiveEx(false)
        self:RefreshPanelEquipment()
        self:CloseSkillGrid()
    elseif index == 2 then
        self.PanelEquipment.gameObject:SetActiveEx(false)
        self.PanelSkill.gameObject:SetActiveEx(true)
        self:RefreshPanelSkill()
        self:CloseEquipmentGrid()
    end
end

function XUiPanelDlcRelinkCharacterRight:RefreshPanelEquipment()
    -- 装备总战力
    local totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(self.CharacterId)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalAbility)
    -- 装备槽位
    local isShowRedDot = false
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
        local equipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, slotIndex)
        local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
        grid:Refresh(equipUid, slotIndex)
        grid:SetLock(not isUnLock)
        grid:SetAdd(isUnLock and not XTool.IsNumberValid(equipUid))
        local unWeareEquipUids = self._Control:GetUnWearEquipUidListBySlot(slotIndex)
        local hasRedDot = isUnLock and not XTool.IsNumberValid(equipUid) and not XTool.IsTableEmpty(unWeareEquipUids)
        grid:SetRedDot(hasRedDot)
        isShowRedDot = isShowRedDot or hasRedDot
    end
    self.BtnEquipment:ShowReddot(isShowRedDot)
end

---@param grid XUiGridDlcRelinkEquipment
function XUiPanelDlcRelinkCharacterRight:OnEquipGridCallBack(grid)
    -- 检查槽位是否解锁
    local slotIndex = grid:GetSlotIndex()
    local isUnLock, unlockDesc = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
    if not isUnLock then
        self._Control:OpenCommonTipMsg(unlockDesc)
        return
    end
    -- 打开装备背包
    local curCount, _ = self._Control:GetEquipBagCurCountAndMaxCount()
    if curCount <= 0 then
        self._Control:OpenCommonTipText("EquipBagEmpty")
        return
    end
    XLuaUiManager.Open("UiDlcRelinkEquipBag", self.CharacterId, slotIndex)
end

function XUiPanelDlcRelinkCharacterRight:RefreshPanelSkill()
    local originalSkillIds = self._Control:GetCharacterSkillIds(self.CharacterId, self.OccupationType)
    local curSkillIds = self._Control:GetCharacterSkillIdsByCharacterId(self.CharacterId, self.OccupationType)
    for index, skillId in pairs(curSkillIds) do
        local grid = self.SkillGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSkill, self.PanelSkill)
            grid = XUiGridDlcRelinkCharacterSkill.New(go, self, handler(self, self.OnSkillGridCallBack))
            self.SkillGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(skillId, self.CharacterId, skillId ~= originalSkillIds[index])
    end
    for i = #curSkillIds + 1, #self.SkillGridList do
        self.SkillGridList[i]:Close()
    end
end

---@param grid XUiGridDlcRelinkCharacterSkill
function XUiPanelDlcRelinkCharacterRight:OnSkillGridCallBack(grid)
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
    XLuaUiManager.Open("UiDlcRelinkPopupSkillDetail", skillId, self.CharacterId, grid:GetIsRemodel(), handler(self, self.OnSkillDetailClose))
end

function XUiPanelDlcRelinkCharacterRight:OnSkillDetailClose()
    if self.CurSelectSkillGrid then
        self.CurSelectSkillGrid:SetSelect(false)
    end
    self.CurSelectSkillId = 0
    self.CurSelectSkillGrid = nil
end

function XUiPanelDlcRelinkCharacterRight:CloseEquipmentGrid()
    for _, grid in pairs(self.EquipmentGridList) do
        grid:Close()
    end
end

function XUiPanelDlcRelinkCharacterRight:CloseSkillGrid()
    for _, grid in pairs(self.SkillGridList) do
        grid:Close()
    end
end

function XUiPanelDlcRelinkCharacterRight:RefreshInfo()
    self.TxtName01.text = XMVCA.XCharacter:GetCharacterName(self.CharacterId)
    self.TxtName02.text = XMVCA.XCharacter:GetCharacterTradeName(self.CharacterId)
    local elementId = XMVCA.XCharacter:GetCharacterElement(self.CharacterId)
    local charElement = XMVCA.XCharacter:GetCharElement(elementId)
    self.RawImage:SetRawImage(charElement.Icon2)
    self.Txt.text = charElement.ElementName
end

function XUiPanelDlcRelinkCharacterRight:RefreshAttributes()
    local curPlayerLevel = self._Control:GetCurrentPlayerLevel()
    local equipUids = self._Control:GetWearEquipUidsByCharacterId(self.CharacterId)
    local totalAttributes = self._Control:GetTotalAttributes(self.CharacterId, curPlayerLevel, equipUids)

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

function XUiPanelDlcRelinkCharacterRight:RefreshBtn()
    -- 切换职业按钮
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", self.OccupationType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.BtnSwitch:SetRawImage(occupationIcon)
    end
    -- 红点
    local isShowRedPoint = self._Control:CheckCharacterHasAnyNewOccupation(self.CharacterId)
    self.BtnSwitch:ShowReddot(isShowRedPoint)

    -- 出战按钮
    local isOriginal = self.CharacterId == self.Parent.OriginalCharacterId
    local btnDesc = self._Control:GetClientConfig("CharacterBtnBattleDesc", isOriginal and 2 or 1)
    self.BtnBattle:SetNameByGroup(0, btnDesc)
    self.BtnBattle:SetButtonState(isOriginal and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiPanelDlcRelinkCharacterRight:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMore, self.OnBtnMoreClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnPresets, self.OnBtnPresetsClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBattle, self.OnBtnBattleClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLv, self.OnBtnLvClick, true, true)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnSwitchClick()
    XLuaUiManager.Open("UiDlcRelinkPopupSwitchCareer", self.CharacterId, self.OccupationType, function()
        self.OccupationType = self._Control:GetOccupationTypeByCharacterId(self.CharacterId)
        self:RefreshBtn()
    end)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnMoreClick()
    XLuaUiManager.Open("UiDlcRelinkPopupCharacterAttributeDetail", self.CharacterId)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnPresetsClick()
    XLuaUiManager.Open("UiDlcRelinkPopupEquipPresets", self.CharacterId)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnBattleClick()
    if self.CharacterId == self.Parent.OriginalCharacterId then
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    self._Control:RequestSwitchBattleCharacter(self.CharacterId)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnLvClick()
    local equipDict = self._Control:GetWearEquipUidsByCharacterId(self.CharacterId)
    if XTool.IsTableEmpty(equipDict) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupEquipAttributeDetail", XTool.CloneEx(equipDict), self.CharacterId)
end

return XUiPanelDlcRelinkCharacterRight
