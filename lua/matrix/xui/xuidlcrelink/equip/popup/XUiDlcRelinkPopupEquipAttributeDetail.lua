local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
---@class XUiDlcRelinkPopupEquipAttributeDetail : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
local XUiDlcRelinkPopupEquipAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipAttributeDetail")

function XUiDlcRelinkPopupEquipAttributeDetail:OnAwake()
    self.GridTab.gameObject:SetActiveEx(false)
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridSkillAttribute.gameObject:SetActiveEx(false)
    self.GridAttribute2.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    ---@type UiObject[]
    self.TabGridList = {}
    ---@type UiObject[]
    self.SkillAttributeGridList = {}
    ---@type XUiGridDlcRelinkEquipAttribute[]
    self.Attribute2GridList = {}
end

---@param equipUids table<number, number> 装备Uid列表 key: 装备栏位索引，value: 装备Uid
---@param characterId number 角色Id
function XUiDlcRelinkPopupEquipAttributeDetail:OnStart(equipUids, characterId, isNotSelf)
    self.EquipUids = equipUids
    self.CharacterId = characterId
    self.IsNotSelf = isNotSelf or false
    ---@type { FactorId: number, IsSkill:boolean, CurLevel:number }[]
    self.TotalAttributes = self._Control:GetEquipTotalAttributeList(equipUids, self.IsNotSelf)

    self.DefaultIndex = 1
    self.CurSelectIndex = 0

    self:InitPanelTab()
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupEquipAttributeDetail:OnEnable()
    -- 角色图像
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId).DefaultNpcFashtionId
    self.RImgHead:SetRawImage(XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId))
    -- 刷新属性
    self.PanelTab:SelectIndex(self.DefaultIndex)
end

function XUiDlcRelinkPopupEquipAttributeDetail:InitPanelTab()
    local btnTabList = {}
    for index, attribute in ipairs(self.TotalAttributes) do
        local grid = self.TabGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTab, self.PanelTab.transform)
            self.TabGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local maxLevel = self._Control:GetFactorDescMaxLevel(attribute.FactorId)
        local isMaxLevel = attribute.CurLevel >= maxLevel
        for i = 1, 3 do
            grid:GetObject("Normal" .. i).gameObject:SetActiveEx(not isMaxLevel)
            grid:GetObject("Max" .. i).gameObject:SetActiveEx(isMaxLevel)
        end
        ---@type XUiComponent.XUiButton
        local btnTab = grid:GetObject("BtnTab")
        btnTab:SetNameByGroup(0, attribute.CurLevel)
        btnTab:SetNameByGroup(1, self._Control:GetFactorDescName(attribute.FactorId))
        table.insert(btnTabList, btnTab)
    end

    self.PanelTab:Init(btnTabList, handler(self, self.OnPanelTabSelect))
end

function XUiDlcRelinkPopupEquipAttributeDetail:OnPanelTabSelect(index)
    if self.CurSelectIndex == index then
        return
    end
    self.CurSelectIndex = index

    local attribute = self.TotalAttributes[index]
    if not attribute then
        return
    end

    -- 刷新属性列表
    local attributeName = self._Control:GetFactorDescAttributeName(attribute.FactorId)
    local isShowSkill = attributeName == "DmgLimitP"

    self.PanelAttribute.gameObject:SetActiveEx(not isShowSkill)
    self.PanelSkillAttribute.gameObject:SetActiveEx(isShowSkill)

    -- 属性描述
    local desc = self._Control:GetFactorDescDesc(attribute.FactorId)
    if isShowSkill then
        self.TxtContent2.text = desc
        self:RefreshSkill()
        self:RefreshSkillAttribute(attribute)
    else
        self.TxtContent1.text = desc
        self:RefreshAttribute(attribute)
    end
end

function XUiDlcRelinkPopupEquipAttributeDetail:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAttributeDetails)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipAttribute, self)
    self.DynamicTable:SetDelegate(self)
end

---@param attribute { FactorId: number, IsSkill:boolean, CurLevel:number }
function XUiDlcRelinkPopupEquipAttributeDetail:RefreshAttribute(attribute)
    local maxLevel = self._Control:GetFactorDescMaxLevel(attribute.FactorId)
    if maxLevel <= 0 then
        return
    end

    self.AttributeLevelList = {}
    for level = 1, maxLevel do
        local curLevel = attribute.CurLevel >= maxLevel and maxLevel or attribute.CurLevel
        self.AttributeLevelList[level] = { FactorId = attribute.FactorId, IsSkill = attribute.IsSkill, IsCur = (level == curLevel), Level = level }
    end

    self.DynamicTable:SetDataSource(self.AttributeLevelList)
    self.DynamicTable:ReloadDataSync(attribute.CurLevel)
end

---@param grid XUiGridDlcRelinkEquipAttribute
function XUiDlcRelinkPopupEquipAttributeDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshAttributeDetails(self.AttributeLevelList[index])
    end
end

function XUiDlcRelinkPopupEquipAttributeDetail:RefreshSkill()
    local styleType = self._Control:GetStyleTypeByCharacterId(self.CharacterId, self.IsNotSelf)
    local curSkillIds = self._Control:GetCharacterSkillIdsByCharacterId(self.CharacterId, styleType, self.IsNotSelf)
    if XTool.IsTableEmpty(curSkillIds) then
        self.GridSkillAttributeList.gameObject:SetActiveEx(false)
        return
    end

    self.GridSkillAttributeList.gameObject:SetActiveEx(true)
    for index, skillId in pairs(curSkillIds) do
        local grid = self.SkillAttributeGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridSkillAttribute, self.GridSkillAttributeList)
            self.SkillAttributeGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        -- 伤害
        local curDamage = self._Control:GetSkillCurrentDamage(skillId, self.CharacterId, self.IsNotSelf)
        local maxDamage = self._Control:GetSkillMaxDamageLimit(skillId, self.CharacterId, self.IsNotSelf)
        if maxDamage > 0 then
            curDamage = math.min(curDamage, maxDamage)
        end
        grid:GetObject("TxtNum").text = string.format("%s/%s", curDamage, maxDamage > 0 and maxDamage or "∞")
        grid:GetObject("TxtName").text = self._Control:GetSkillDescTypeDesc(skillId)
        grid:GetObject("Icon"):SetSprite(self._Control:GetSkillDescIcon(skillId))
    end

    for i = #curSkillIds + 1, #self.SkillAttributeGridList do
        local grid = self.SkillAttributeGridList[i]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

---@param attribute { FactorId: number, IsSkill:boolean, CurLevel:number }
function XUiDlcRelinkPopupEquipAttributeDetail:RefreshSkillAttribute(attribute)
    local maxLevel = self._Control:GetFactorDescMaxLevel(attribute.FactorId)
    for level = 1, maxLevel do
        local grid = self.Attribute2GridList[level]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridAttribute2, self.GridAttributeList)
            grid = XUiGridDlcRelinkEquipAttribute.New(go, self)
            self.Attribute2GridList[level] = grid
        end
        grid:Open()
        local curLevel = attribute.CurLevel >= maxLevel and maxLevel or attribute.CurLevel
        grid:RefreshAttributeDetails({ FactorId = attribute.FactorId, IsSkill = attribute.IsSkill, IsCur = (level == curLevel), Level = level })
    end

    for i = maxLevel + 1, #self.Attribute2GridList do
        local grid = self.Attribute2GridList[i]
        if grid then
            grid:Close()
        end
    end
end

function XUiDlcRelinkPopupEquipAttributeDetail:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiDlcRelinkPopupEquipAttributeDetail:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipAttributeDetail
