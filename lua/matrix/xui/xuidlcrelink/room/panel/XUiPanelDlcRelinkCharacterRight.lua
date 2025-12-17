local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiPanelDlcRelinkCharacterRight : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkCharacter
---@field BtnTab XUiButtonGroup
local XUiPanelDlcRelinkCharacterRight = XClass(XUiNode, "XUiPanelDlcRelinkCharacterRight")

function XUiPanelDlcRelinkCharacterRight:OnStart()
    self.PropertyItem.gameObject:SetActiveEx(false)
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
    self.RoleModelUi = self.Parent.UiModelGo.transform:FindTransform("PanelRoleModel")
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(self.RoleModelUi, self.Parent.Name, nil, true)
    self:RegisterUiEvents()
    self:InitBtnTab()
    self.CurSelectIndex = 1

    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}
end

function XUiPanelDlcRelinkCharacterRight:Refresh(characterId)
    self.CharacterId = characterId
    self.OccupationType = self._Control:GetOccupationTypeByCharacterId(characterId)
    self:RefreshInfo()
    self:RefreshAttributes()
    self.BtnTab:SelectIndex(self.CurSelectIndex)
    self:RefreshModel()
    self:RefreshBtn()
end

function XUiPanelDlcRelinkCharacterRight:InitBtnTab()
    local btnTabList = { self.BtnEquipment, self.BtnSkill }
    self.BtnTab:Init(btnTabList, handler(self, self.OnBtnTabClick))
end

function XUiPanelDlcRelinkCharacterRight:OnBtnTabClick(index)
    self.CurSelectIndex = index
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

function XUiPanelDlcRelinkCharacterRight:RefreshPanelEquipment()
    -- 装备总等级
    local totalLv = self._Control:GetEquipTotalAbilityByCharacterId(self.CharacterId)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalLv)
    -- 装备槽位
    for index = 1, XEnumConst.DlcRelink.EquipSlotCount do
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
        local equipUId = self._Control:GetEquipUIdByCharacterId(self.CharacterId, index)
        local isUnLock = true -- TODO 装备槽位是否解锁
        grid:Refresh(equipUId, index)
        grid:SetLock(not isUnLock)
        grid:SetAdd(isUnLock and not XTool.IsNumberValid(equipUId))
        -- TODO 当装备有空槽,并且有可穿戴装备时,需要有蓝点,穿戴后消失
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiPanelDlcRelinkCharacterRight:OnEquipGridCallBack(grid)
    -- TODO 未解锁的装备槽需要显示上锁标识,点击出现toast:xxx后可解锁该槽位
    -- TODO 未装备任何装备,并且库存也无任何装备时,点击无法进入详情,并且出现toast:暂未获得任何装备哦
    -- TODO 打开15界面-装备详情,并且选中对应位置
    XLuaUiManager.Open("UiDlcRelinkEquipBag", self.CharacterId, grid:GetIndex())
end

function XUiPanelDlcRelinkCharacterRight:RefreshPanelSkill()

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
    -- TODO 刷新属性
end

function XUiPanelDlcRelinkCharacterRight:RefreshModel()
    self.RoleModel:ShowRoleModel()
    self.RoleModel:UpdateCharacterModel(self.CharacterId, self.RoleModelUi, self.Parent.Name, function(model)
        self.Parent.PanelDrag.Target = model.transform
    end, nil)
end

function XUiPanelDlcRelinkCharacterRight:RefreshBtn()
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", self.OccupationType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.BtnSwitch:SetRawImage(occupationIcon)
    end

    local isOriginal = self.CharacterId == self.Parent.OriginalCharacterId
    local btnDesc = self._Control:GetClientConfig("CharacterBtnBattleDesc", isOriginal and 2 or 1)
    self.BtnBattle:SetNameByGroup(0, btnDesc)
    self.BtnBattle:SetButtonState(isOriginal and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiPanelDlcRelinkCharacterRight:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMore, self.OnBtnMoreClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnPresets, self.OnBtnPresetsClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBattle, self.OnBtnBattleClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLv, self.OnBtnLvClick, true)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnSwitchClick()
    -- TODO 打开10弹窗-切换职业 固定显示5条
end

function XUiPanelDlcRelinkCharacterRight:OnBtnMoreClick()
    -- TODO 打开11弹窗·属性总览
end

function XUiPanelDlcRelinkCharacterRight:OnBtnPresetsClick()
    -- TODO 打开13弹窗·装备预设
end

function XUiPanelDlcRelinkCharacterRight:OnBtnBattleClick()
    if self.CharacterId == self.Parent.OriginalCharacterId then
        return
    end

    if XMVCA.XDlcRoom:IsInRoom() then
        XMVCA.XDlcRoom:SelectCharacter(self.CharacterId)
        return
    end

    if XMVCA.XDlcRoom:IsMatching() then
        XUiManager.TipCode(XCode.MatchPlayerIsMatching)
        return
    end

    local configId = self._Control:GetCharacterConfigId(self.CharacterId, self.OccupationType)
    self._Control:RequestSwitchBattleCharacter(configId, function()
        self.Parent:EndSelectingAndClose()
    end)
end

function XUiPanelDlcRelinkCharacterRight:OnBtnLvClick()
    -- TODO 打开11弹窗-属性总览
end

return XUiPanelDlcRelinkCharacterRight
