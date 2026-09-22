local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridMainSkill = require("XUi/XUiPartner/PartnerSkillInstall/MainSkill/XUiGridMainSkill")
local CSTextManagerGetText = CS.XTextManager.GetText

---@class XUiEquipOneClickCulturePartnerMainSkill : XUiNode
---@field _Control XPartnerControl
---@field PanelSkillOptionGroup UnityEngine.RectTransform
---@field GridSkillOption UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field ElementIcon UnityEngine.UI.RawImage
---@field TxtTitle UnityEngine.RectTransform
local XUiEquipOneClickCulturePartnerMainSkill = XClass(XUiNode, "XUiEquipOneClickCulturePartnerMainSkill")

function XUiEquipOneClickCulturePartnerMainSkill:OnStart()
    self._SkillSelectControl = self._Control:GetSkillSelectViewControl()
    self.Partner = self._SkillSelectControl:GetPartnerEntity()

    self:_InitDynamicTable()
    self:_InitPartnerInfo()
    self:_InitSkillGroup()
    self:_Refresh()
end

function XUiEquipOneClickCulturePartnerMainSkill:OnEnable()
end

function XUiEquipOneClickCulturePartnerMainSkill:OnDisable()
end

function XUiEquipOneClickCulturePartnerMainSkill:OnDestroy()
end

---region ui event

---endregion

---region event

---endregion

function XUiEquipOneClickCulturePartnerMainSkill:_Refresh()
    self.Partner = self._SkillSelectControl:GetPartnerEntity()
    local skillGroupList = self._SkillSelectControl:GetMainSkillGroupList()
    self.CurSkillGroup = self._SkillSelectControl:GetCarryMainSkillGroup() or skillGroupList[1]

    if not self._PageDatas then
        self:_SetupDynamicTable()
        return
    end

    self._PageDatas = skillGroupList
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:ShowGrid()
    end
end

function XUiEquipOneClickCulturePartnerMainSkill:Refresh()
    self:_Refresh()
end

function XUiEquipOneClickCulturePartnerMainSkill:_InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillOptionGroup)
    self.DynamicTable:SetProxy(XUiGridMainSkill)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillOption.gameObject:SetActiveEx(false)
end

function XUiEquipOneClickCulturePartnerMainSkill:_InitPartnerInfo()
    local charName = CSTextManagerGetText("PartnerNoBadyCarry")
    if self.Partner:GetIsCarry() then
        local charId = self.Partner:GetCharacterId()
        charName = XMVCA.XCharacter:GetCharacterLogName(charId)
        self.CharElement = XMVCA.XCharacter:GetCharacterElement(charId)
        local elementConfig = XMVCA.XCharacter:GetCharElement(self.CharElement)
        self.ElementIcon:SetRawImage(elementConfig.Icon2)
        self.ElementIcon.gameObject:SetActiveEx(true)
    else
        self.ElementIcon.gameObject:SetActiveEx(false)
    end

    self.TxtName.text = charName
end

function XUiEquipOneClickCulturePartnerMainSkill:_InitSkillGroup()
    local skillGroupList = self._SkillSelectControl:GetMainSkillGroupList()
    self.CurSkillGroup = self._SkillSelectControl:GetCarryMainSkillGroup() or skillGroupList[1]
    self.PreviewSkillGroup = self.CurSkillGroup
end

function XUiEquipOneClickCulturePartnerMainSkill:_SetupDynamicTable()
    self._PageDatas = self._SkillSelectControl:GetMainSkillGroupList()
    self.DynamicTable:SetDataSource(self._PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiEquipOneClickCulturePartnerMainSkill:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self._PageDatas[index], self, self)
    end
end

--- 兼容旧主动技能 Grid 的选择接口
---@param skillGroup XPartnerMainSkillGroup
function XUiEquipOneClickCulturePartnerMainSkill:SelectSkill(skillGroup)
    if not skillGroup or self.CurSkillGroup and self.CurSkillGroup:GetId() == skillGroup:GetId() then
        return
    end

    if self._SkillSelectControl:SelectMainSkill(skillGroup) then
        self.CurSkillGroup = skillGroup
        self.Parent:SetRequesting(true)
    end
end

---@param skillGroup XPartnerMainSkillGroup
function XUiEquipOneClickCulturePartnerMainSkill:SelectPreviewSkill(skillGroup)
    self.PreviewSkillGroup = skillGroup
end

function XUiEquipOneClickCulturePartnerMainSkill:GoElementView()
    if self.PreviewSkillGroup then
        self.Parent:OpenElementView()
    end
end

return XUiEquipOneClickCulturePartnerMainSkill
