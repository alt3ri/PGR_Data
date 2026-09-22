---@class XUiEquipOneClickCulturePartnerPassiveSkill : XUiNode
---@field _Control XPartnerControl
---@field PanelSkillDetails UnityEngine.RectTransform
---@field GridSkillDetail UnityEngine.RectTransform
---@field TxtCurSkillCount UnityEngine.UI.Text
---@field TxtMaxSkillCount UnityEngine.UI.Text
---@field PanelTitle UnityEngine.RectTransform
---@field PanelTitle2 UnityEngine.RectTransform
local XUiEquipOneClickCulturePartnerPassiveSkill = XClass(XUiNode, "XUiEquipOneClickCulturePartnerPassiveSkill")

function XUiEquipOneClickCulturePartnerPassiveSkill:OnStart()
    self._SkillSelectControl = self._Control:GetSkillSelectViewControl()
    self.Partner = self._SkillSelectControl:GetPartnerEntity()

    self:_InitDynamicTable()
    self:_Refresh()
end

function XUiEquipOneClickCulturePartnerPassiveSkill:OnEnable()
end

function XUiEquipOneClickCulturePartnerPassiveSkill:OnDisable()
end

function XUiEquipOneClickCulturePartnerPassiveSkill:OnDestroy()
end

---region ui event

---endregion

---region event

---endregion

function XUiEquipOneClickCulturePartnerPassiveSkill:_Refresh()
    self.Partner = self._SkillSelectControl:GetPartnerEntity()
    self:_RefreshTitle()
    self:_RefreshCount()

    if not self.PageDatas then
        self:_SetupDynamicTable()
        return
    end

    self.PageDatas = self._SkillSelectControl:GetPassiveSkillGroupList()
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:ShowSelect()
    end
end

function XUiEquipOneClickCulturePartnerPassiveSkill:Refresh()
    self:_Refresh()
end

function XUiEquipOneClickCulturePartnerPassiveSkill:_InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridPassiveSkill = require("XUi/XUiPartner/PartnerSkillInstall/PassiveSkill/XUiGridPassiveSkill")

    self.DynamicTable = XDynamicTableNormal.New(self.PanelSkillDetails)
    self.DynamicTable:SetProxy(XUiGridPassiveSkill)
    self.DynamicTable:SetDelegate(self)
    self.GridSkillDetail.gameObject:SetActiveEx(false)
end

function XUiEquipOneClickCulturePartnerPassiveSkill:_SetupDynamicTable()
    self.PageDatas = self._SkillSelectControl:GetPassiveSkillGroupList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiEquipOneClickCulturePartnerPassiveSkill:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiEquipOneClickCulturePartnerPassiveSkill:_RefreshTitle()
    local isPreview = self.Partner and self.Partner:GetIsComposePreview()
    if self.PanelTitle then
        self.PanelTitle.gameObject:SetActiveEx(not isPreview)
    end
    if self.PanelTitle2 then
        self.PanelTitle2.gameObject:SetActiveEx(isPreview)
    end
end

function XUiEquipOneClickCulturePartnerPassiveSkill:_RefreshCount()
    local count = self._SkillSelectControl:GetCarryPassiveSkillCount()
    local limit = self._SkillSelectControl:GetPassiveSkillLimit()
    self.TxtCurSkillCount.text = tostring(count)
    self.TxtMaxSkillCount.text = string.format("/ %d", limit)
end

--- 兼容旧被动技能 Grid 的选择接口
---@param skillGroup XPartnerPassiveSkillGroup
---@param isAdd boolean
function XUiEquipOneClickCulturePartnerPassiveSkill:SetSelectSkill(skillGroup, isAdd)
    if self._SkillSelectControl:SetPassiveSkillWear(skillGroup, isAdd) then
        self.Parent:SetRequesting(true)
    end
end

---@param skillGroupId number
---@return boolean
function XUiEquipOneClickCulturePartnerPassiveSkill:CheckIsSelectSkill(skillGroupId)
    return self._SkillSelectControl:IsPassiveSkillCarry(skillGroupId)
end

return XUiEquipOneClickCulturePartnerPassiveSkill
