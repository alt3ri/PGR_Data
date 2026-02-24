---@class XUiPanelCharacterElementAndGeneralSkillDetail : XUiNode
local XUiPanelCharacterElementAndGeneralSkillDetail = XClass(XUiNode, "XUiPanelCharacterElementAndGeneralSkillDetail")

local GridType = {
    Element = 1,
    GeneralSkill = 2,
    SpecialGeneralSkill = 3,
}

function XUiPanelCharacterElementAndGeneralSkillDetail:OnStart()
    self.ElementDetail.gameObject:SetActiveEx(false)
    self.Grid01.gameObject:SetActiveEx(false)
    self.Grid02.gameObject:SetActiveEx(false)
    self.Grid03.gameObject:SetActiveEx(false)
    self.BtnTeach:AddEventListener(handler(self, self.OnBtnTeachClick))

    ---@type { Btn: XUiComponent.XUiButton, Id: number, Type: number }[]
    self.GridElementList = {}
    ---@type { Btn: XUiComponent.XUiButton, Id: number, Type: number }[]
    self.GridGeneralSkillList = {}
    ---@type { Btn: XUiComponent.XUiButton, Id: number, Type: number }[]
    self.GridSpecialGeneralSkillList = {}

    self.CurSelectType = nil
    self.CurSelectId = nil
    ---@type { Btn: XUiComponent.XUiButton, Id: number, Type: number }
    self.CurSelectGrid = nil
    ---@type { Id: number, Type: number }
    self.DefaultSelectGridData = nil

    self.CachedDefaultElementName = XMVCA.XCharacter:GetClientConfig("DefaultElementName")
    self.CachedDefaultElementIcon = XMVCA.XCharacter:GetClientConfig("DefaultElementIcon")
end

function XUiPanelCharacterElementAndGeneralSkillDetail:OnDisable()
    if XTool.IsNumberValid(self.CurSelectId) and XTool.IsNumberValid(self.CurSelectType) then
        self.DefaultSelectGridData = { Id = self.CurSelectId, Type = self.CurSelectType }
    else
        self.DefaultSelectGridData = nil
    end

    -- 恢复上一个选中的Grid状态
    if self.CurSelectGrid and self.CurSelectGrid.Btn then
        self.CurSelectGrid.Btn:SetDisable(false)
    end

    -- 隐藏详情面板
    if self.ElementDetail then
        self.ElementDetail.gameObject:SetActiveEx(false)
    end

    -- 清空选中状态
    self.CurSelectType = nil
    self.CurSelectId = nil
    self.CurSelectGrid = nil
end

function XUiPanelCharacterElementAndGeneralSkillDetail:OnDestroy()
    self.DefaultSelectGridData = nil
end

function XUiPanelCharacterElementAndGeneralSkillDetail:Refresh(characterId)
    self.CharacterId = characterId
    self:RefreshElement()
    self:RefreshGeneralSkill()
    self:RefreshSpecialGeneralSkill()
    self:SetDefaultSelectedGrid()
end

-- 创建或获取Grid
---@param gridList { Btn: XUiComponent.XUiButton, Id: number, Type: number }[] 存储Grid的列表
---@param index number 索引
---@param gridTemplate XUiComponent.XUiButton Grid模板
---@param parent UnityEngine.Transform 父节点
---@param gridType number Grid类型
---@param id number Grid对应的Id
---@return { Btn: XUiComponent.XUiButton, Id: number, Type: number }
function XUiPanelCharacterElementAndGeneralSkillDetail:GetOrCreateGrid(gridList, index, gridTemplate, parent, gridType, id)
    local grid = gridList[index]
    if not grid then
        local btn = XUiHelper.Instantiate(gridTemplate, parent)
        grid = { Btn = btn, Id = id, Type = gridType }
        gridList[index] = grid
        btn:AddEventListener(function()
            if grid.Id <= 0 then
                return
            end
            self:OnElementGridClick(grid)
        end)
    else
        grid.Id = id
        grid.Type = gridType
    end
    return grid
end

-- 设置默认Grid显示
---@param button XUiComponent.XUiButton
function XUiPanelCharacterElementAndGeneralSkillDetail:SetDefaultGridDisplay(button)
    button:SetNameByGroup(0, self.CachedDefaultElementName)
    button:SetRawImageEx(self.CachedDefaultElementIcon)
    button:ShowTag(false)
    button:SetDisable(false)
end

-- 隐藏多余的Grid
---@param gridList { Btn: XUiComponent.XUiButton, Id: number, Type: number }[] 存储Grid的列表
---@param startIndex number 起始索引
function XUiPanelCharacterElementAndGeneralSkillDetail:HideExtraGrids(gridList, startIndex)
    for i = startIndex, #gridList do
        local grid = gridList[i]
        if grid and grid.Btn then
            grid.Btn.gameObject:SetActiveEx(false)
        end
    end
end

-- 配置Grid显示内容和状态
---@param button XUiComponent.XUiButton
---@param name string Grid名称
---@param icon string Grid图标
---@param isActive boolean 是否激活
function XUiPanelCharacterElementAndGeneralSkillDetail:ConfigureGrid(button, name, icon, isActive)
    button:SetNameByGroup(0, name)
    button:SetRawImageEx(icon)
    button:ShowTag(isActive)
    button:SetDisable(false)
end

-- 根据类型获取对应的GridList
---@param gridType number Grid类型
---@return { Btn: XUiComponent.XUiButton, Id: number, Type: number }[]
function XUiPanelCharacterElementAndGeneralSkillDetail:GetGridListByType(gridType)
    if gridType == GridType.Element then
        return self.GridElementList
    elseif gridType == GridType.GeneralSkill then
        return self.GridGeneralSkillList
    elseif gridType == GridType.SpecialGeneralSkill then
        return self.GridSpecialGeneralSkillList
    end
    return nil
end

-- 在指定列表中查找并选中Grid
---@param gridList { Btn: XUiComponent.XUiButton, Id: number, Type: number }[]
---@param targetId number
---@return boolean 是否找到并选中
function XUiPanelCharacterElementAndGeneralSkillDetail:SelectGridById(gridList, targetId)
    if not gridList or not XTool.IsNumberValid(targetId) then
        return false
    end

    for _, grid in ipairs(gridList) do
        if grid.Id == targetId then
            self:OnElementGridClick(grid)
            return true
        end
    end
    return false
end

-- 设置默认选中的Grid
function XUiPanelCharacterElementAndGeneralSkillDetail:SetDefaultSelectedGrid()
    -- 优先恢复上次选中的Grid
    if self.DefaultSelectGridData and XTool.IsNumberValid(self.DefaultSelectGridData.Id) and XTool.IsNumberValid(self.DefaultSelectGridData.Type) then
        local gridList = self:GetGridListByType(self.DefaultSelectGridData.Type)
        if gridList and self:SelectGridById(gridList, self.DefaultSelectGridData.Id) then
            return
        end
    end

    -- 选中角色的第一个元素
    if XTool.IsNumberValid(self.CharacterId) then
        local obtainElementList = XMVCA.XCharacter:GetCharDetailObtainElementList(self.CharacterId)
        if not XTool.IsTableEmpty(obtainElementList) then
            local firstObtainElementId = obtainElementList[1]
            if self:SelectGridById(self.GridElementList, firstObtainElementId) then
                return
            end
        end
    end

    -- 选中第一个元素Grid
    if not XTool.IsTableEmpty(self.GridElementList) then
        self:OnElementGridClick(self.GridElementList[1])
    end
end

function XUiPanelCharacterElementAndGeneralSkillDetail:RefreshElement()
    local elementIdList = XMVCA.XCharacter:GetClientConfigIntParams("ElementIdList")

    for index, elementId in ipairs(elementIdList) do
        local grid = self:GetOrCreateGrid(self.GridElementList, index, self.Grid01, self.List01, GridType.Element, elementId)
        grid.Btn.gameObject:SetActiveEx(true)

        if elementId <= 0 then
            self:SetDefaultGridDisplay(grid.Btn)
        else
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementId)
            if elementConfig then
                local isActive = XTool.IsNumberValid(self.CharacterId) and XMVCA.XCharacter:IsElementActive(self.CharacterId, elementId) or false
                self:ConfigureGrid(grid.Btn, elementConfig.ElementName, elementConfig.Icon2, isActive)
            else
                self:SetDefaultGridDisplay(grid.Btn)
            end
        end
    end

    self:HideExtraGrids(self.GridElementList, #elementIdList + 1)
end

-- 刷新通用技能（包含普通和特殊通用技能）
---@param skillIdList number[] 技能Id列表
---@param gridList { Btn: XUiComponent.XUiButton, Id: number, Type: number }[] 存储Grid的列表
---@param gridTemplate XUiComponent.XUiButton Grid模板
---@param parent UnityEngine.Transform 父节点
---@param gridType number Grid类型
function XUiPanelCharacterElementAndGeneralSkillDetail:RefreshGeneralSkillCommon(skillIdList, gridList, gridTemplate, parent, gridType)
    local generalSkillConfigs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()
    local currentGeneralSkillId = XTool.IsNumberValid(self.CharacterId) and XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.CharacterId) or {}

    for index, skillId in ipairs(skillIdList) do
        local grid = self:GetOrCreateGrid(gridList, index, gridTemplate, parent, gridType, skillId)
        grid.Btn.gameObject:SetActiveEx(true)

        if skillId <= 0 then
            self:SetDefaultGridDisplay(grid.Btn)
        else
            local skillConfig = generalSkillConfigs[skillId]
            if skillConfig then
                local isActive = table.contains(currentGeneralSkillId, skillId)
                self:ConfigureGrid(grid.Btn, skillConfig.Name, skillConfig.IconTranspose, isActive)
            else
                self:SetDefaultGridDisplay(grid.Btn)
            end
        end
    end

    self:HideExtraGrids(gridList, #skillIdList + 1)
end

function XUiPanelCharacterElementAndGeneralSkillDetail:RefreshGeneralSkill()
    local generalSkillIdList = XMVCA.XCharacter:GetClientConfigIntParams("GeneralSkillIdList")
    self:RefreshGeneralSkillCommon(generalSkillIdList, self.GridGeneralSkillList, self.Grid02, self.List02, GridType.GeneralSkill)
end

function XUiPanelCharacterElementAndGeneralSkillDetail:RefreshSpecialGeneralSkill()
    local specialGeneralSkillIdList = XMVCA.XCharacter:GetClientConfigIntParams("SpecialGeneralSkillIdList")
    self:RefreshGeneralSkillCommon(specialGeneralSkillIdList, self.GridSpecialGeneralSkillList, self.Grid03, self.List03, GridType.SpecialGeneralSkill)
end

---@param gridData { Btn: XUiComponent.XUiButton, Id: number, Type: number }
function XUiPanelCharacterElementAndGeneralSkillDetail:OnElementGridClick(gridData)
    if not gridData or not gridData.Btn or not XTool.IsNumberValid(gridData.Id) then
        return
    end

    -- 恢复上一个选中的Grid状态
    if self.CurSelectGrid and self.CurSelectGrid.Btn then
        self.CurSelectGrid.Btn:SetDisable(false)
    end

    -- 更新选中状态
    self.CurSelectType = gridData.Type
    self.CurSelectId = gridData.Id
    self.CurSelectGrid = gridData

    -- 设置当前Grid为选中状态
    gridData.Btn:SetDisable(true, false)

    -- 显示详情面板
    self.ElementDetail.gameObject:SetActiveEx(true)

    -- 根据类型显示不同的内容
    if gridData.Type == GridType.Element then
        self:ShowElementDetail(gridData.Id)
    elseif gridData.Type == GridType.GeneralSkill or gridData.Type == GridType.SpecialGeneralSkill then
        self:ShowSkillDetail(gridData.Id)
    end
end

-- 显示元素详情
---@param elementId number
function XUiPanelCharacterElementAndGeneralSkillDetail:ShowElementDetail(elementId)
    local elementConfig = XMVCA.XCharacter:GetCharElement(elementId)
    if elementConfig then
        self.TxtContent.text = elementConfig.Description
    end
    self.BtnTeach.gameObject:SetActiveEx(false)
end

-- 显示技能详情
---@param skillId number
function XUiPanelCharacterElementAndGeneralSkillDetail:ShowSkillDetail(skillId)
    local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[skillId]
    if generalSkillConfig then
        self.TxtContent.text = generalSkillConfig.Desc
    end
    self.BtnTeach.gameObject:SetActiveEx(true)
end

function XUiPanelCharacterElementAndGeneralSkillDetail:OnBtnTeachClick()
    -- 只有技能类型才能打开教学
    if not XTool.IsNumberValid(self.CurSelectId) then
        return
    end

    if self.CurSelectType ~= GridType.GeneralSkill and self.CurSelectType ~= GridType.SpecialGeneralSkill then
        return
    end

    XDataCenter.PracticeManager.OpenUiFubenPracticeWithGeneralSkill(self.CurSelectId)
end

return XUiPanelCharacterElementAndGeneralSkillDetail
