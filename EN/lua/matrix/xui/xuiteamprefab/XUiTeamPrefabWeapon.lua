
local XUiTeamPrefabWeapon = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabWeapon")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local ATTR_COLOR = {
    EQUAL = XUiHelper.Hexcolor2Color("1B3750"), -- 属性与当前装备一样
    OVER = XUiHelper.Hexcolor2Color("188649"), -- 属性超出当前装备
    BELOW = XUiHelper.Hexcolor2Color("d11e38"), -- 属性低于当前装备
}

function XUiTeamPrefabWeapon:OnAwake()
    self.IsAscendOrder = false --初始降序
    self.PriorSortType = XEnumConst.EQUIP.PRIOR_SORT_TYPE.STAR
    self.ChangeEquipSuccess = false
    self.IsShowExtend = false -- 当前是否显示扩展面板

    self.ImgAscend.gameObject:SetActiveEx(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not self.IsAscendOrder)
    self.GridEquip.gameObject:SetActiveEx(false)
    self.PanelExtend.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:SetButtonCallBack()
    self:InitDynamicTable()

    self.PanelAddEffect = self.PanelAdd.transform:Find("Effect")
    self.PanelAdd2Effect = self.PanelAdd2.transform:Find("Effect")
    self.GridEquipResonanceEffect1 = self.GridEquipResonance1.transform:Find("Effect")
    self.GridEquipResonanceEffect2 = self.GridEquipResonance2.transform:Find("Effect")
    self.GridEquipResonanceEffect3 = self.GridEquipResonance3.transform:Find("Effect")
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect = self.BtnOverrunBlind.transform:Find("Normal/Effect")

    self.CurrentPos = 1 -- 当前选中的队伍位置(1-3)
    ---@type XTeamPrefab
    self.TeamPrefab = nil -- 队伍预设数据
    self.RoleGrids = {} -- 存储3个角色位置格子

    -- 初始化角色位置格子(克隆3个)
    self:InitTeamRoleGrids()
end

-- 初始化3个角色位置格子
function XUiTeamPrefabWeapon:InitTeamRoleGrids()
    self.GridTeamRole.gameObject:SetActiveEx(false)
    for pos = 1, 3 do
        local grid = XUiHelper.Instantiate(self.GridTeamRole, self.GridTeamRole.transform.parent)
        grid.gameObject:SetActiveEx(true)
        grid.gameObject.name = "GridTeamRole_" .. pos
        local t = { Transform = grid.transform }
        XTool.InitUiObject(t)
        self.RoleGrids[pos] = t
        -- 绑定点击事件
        self:RegisterClickEvent(self.RoleGrids[pos].BtnClick, function()
            self:OnTeamRoleClick(pos)
        end)
        t.ImgLeftSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
        t.ImgRightSkill.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
        t.DiagonalLeft.color = XDataCenter.TeamManager.GetTeamMemberDiagonalColor(pos)
        t.DiagonalRight.color = XDataCenter.TeamManager.GetTeamMemberDiagonalColor(pos)
        t.ImgSelect.color = XDataCenter.TeamManager.GetTeamMemberSelectColor(pos)
    end

    self.RoleGrids[2].Transform:SetAsFirstSibling() -- 显示位置调整
end

-- 角色位置点击事件
function XUiTeamPrefabWeapon:OnTeamRoleClick(pos)
    if self.CurrentPos == pos then return end
    local characterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)
    if not XTool.IsNumberValid(characterId) then 
        XUiManager.TipText("TeamPrefabNoMemberCannotSetWeapon")
        return
    end

    self.CurrentPos = pos
    self:UpdateTeamRoleGrids() -- 更新选中状态
    self:UpdateView() -- 刷新武器列表和详情
end

-- 更新角色位置格子显示
function XUiTeamPrefabWeapon:UpdateTeamRoleGrids()
    for pos = 1, 3 do
        local grid = self.RoleGrids[pos]
        local characterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)
        local hasCharacter = characterId ~= 0
        
        -- 显示有无角色状态
        grid.PanelHave.gameObject:SetActiveEx(hasCharacter)
        grid.PanelEmpty.gameObject:SetActiveEx(not hasCharacter)
        grid.GridWeapon.gameObject:SetActiveEx(hasCharacter)
        
        -- 有角色时设置头像、武器
        if hasCharacter then
            local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
            local character = XMVCA.XCharacter:GetCharacter(characterId)
            grid.ImgIcon:SetRawImage(icon)
            grid.ImgQuality:SetSprite(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))

            local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
            grid.WeaponGrid = grid.WeaponGrid or XUiGridEquip.New(grid.GridWeapon, self)
            local weaponData = self.TeamPrefab:GetWeaponData(pos)
            local usingWeaponId = (weaponData and weaponData.EquipId) or XMVCA.XEquip:GetCharacterWeaponId(characterId)
            grid.WeaponGrid:Refresh(usingWeaponId)
        end
        
        -- 选中状态高亮(假设BtnClick有选中样式)
        grid.ImgSelect.gameObject:SetActiveEx(pos == self.CurrentPos)
    end
end

---@param teamPrefab XTeamPrefab
---@param defaultPos number
---@param closecallback function
---@param notShowStrengthenBtn bool
function XUiTeamPrefabWeapon:OnStart(teamPrefab, defaultPos, closecallback, notShowStrengthenBtn)
    self.TeamPrefab = teamPrefab
    self.DefaultPos = defaultPos
    self.CurrentPos = defaultPos or 1
    self.CloseCallback = closecallback
    self.NotShowStrengthenBtn = notShowStrengthenBtn == true

    self.TxtTeamName.text = teamPrefab:GetName()

    -- 初始选中预设中当前位置的武器
    local weaponData = teamPrefab:GetWeaponData(self.CurrentPos)
    self.SelectEquipId = weaponData and weaponData.EquipId or 0
    
    -- 初始化角色位置显示
    self:UpdateTeamRoleGrids()
end

function XUiTeamPrefabWeapon:OnEnable()
    -- 播放扩展面板动画，动画切到最后一帧
    local anim = self.IsShowExtend and self.AnimFold or self.AnimUnFold
    anim:Play()
    anim.time = anim.duration
    anim:Evaluate()
    anim:Stop()
    
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
    self:UpdateView()
end

function XUiTeamPrefabWeapon:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback(nil, self.ChangeEquipSuccess)
    end
end

function XUiTeamPrefabWeapon:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)
    self:RegisterClickEvent(self.BtnTakeOn, self.OnBtnTakeOnClick)

    self:RegisterClickEvent(self.BtnOrder, self.OnBtnOrderClick)
    self.DrdSort.onValueChanged:AddListener(function()
        self.PriorSortType = self.DrdSort.value
        self:OnSortTypeChange()
    end)

    self:RegisterClickEvent(self.PanelAdd, self.ShowPanelSkill)
    self:RegisterClickEvent(self.PanelAdd2, self.ShowPanelExtend)

    -- 武器共鸣
    self:RegisterClickEvent(self.GridEquipResonance1, function() self:OnBtnResonanceSkill(1) end)
    self:RegisterClickEvent(self.GridEquipResonance2, function() self:OnBtnResonanceSkill(2) end)
    self:RegisterClickEvent(self.GridEquipResonance3, function() self:OnBtnResonanceSkill(3) end)
    self:RegisterClickEvent(self.BtnResonance, function() self:OnBtnResonanceSkill() end)

    -- 武器超限
    self:RegisterClickEvent(self.BtnOverrun, self.OnBtnOverrun)
    self:RegisterClickEvent(self.BtnOverrunBlind, self.OnBtnOverrunClick)
    self:RegisterClickEvent(self.BtnOverrunEmpty, self.OnBtnOverrunClick)
end

function XUiTeamPrefabWeapon:OnBtnBackClick()
    self:Close()
end

function XUiTeamPrefabWeapon:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTeamPrefabWeapon:OnBtnStrengthenClick()
end

-- 穿戴按钮点击：仅更新队伍预设数据，不影响实际装备
function XUiTeamPrefabWeapon:OnBtnTakeOnClick()
    local characterId = self.TeamPrefab:GetEntityIdByTeamPos(self.CurrentPos)
    
    -- 检查角色是否存在
    if not XTool.IsNumberValid(characterId) then
        return
    end

    local isConflict, conflictPos = self.TeamPrefab:CheckEquipIdConflict(self.SelectEquipId, self.CurrentPos)
    local fun = function ()
        self.TeamPrefab:CopyRealWeaponData(self.SelectEquipId, self.CurrentPos, isConflict, function ()
            -- 刷新界面（从预设重新加载数据）
            self.ChangeEquipSuccess = true
            self:UpdateView() -- 刷新整个视图，确保所有预设数据同步
            self:UpdateTeamRoleGrids()
            XUiManager.TipText("TeamPrefabWeaponUpdateSuccess")
        end)

        -- 冲突的话发全量
        if isConflict then
            self.TeamPrefab:SyncFullDataToServer(function ()
                -- 刷新界面（从预设重新加载数据）
                self.ChangeEquipSuccess = true
                self:UpdateView() -- 刷新整个视图，确保所有预设数据同步
                self:UpdateTeamRoleGrids()
                XUiManager.TipText("TeamPrefabWeaponUpdateSuccess")
            end)
        end
    end

    if isConflict then
        local conflictCharId = self.TeamPrefab:GetEntityIdByTeamPos(conflictPos)
        local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(conflictCharId)
        local content = string.gsub(CS.XTextManager.GetText("TeamPrefabWeaponReplaceTip", fullName), " ", "")
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), content, XUiManager.DialogType.Normal, function() end, function()
            fun()
        end)
    else
        fun()
    end
end

function XUiTeamPrefabWeapon:OnBtnOrderClick()
    self.IsAscendOrder = not self.IsAscendOrder
    self.ImgAscend.gameObject:SetActiveEx(self.IsAscendOrder)
    self.ImgDescend.gameObject:SetActiveEx(not self.IsAscendOrder)

    XTool.ReverseList(self.WeaponIdList)
    self:UpdateEquipList()
end

function XUiTeamPrefabWeapon:OnBtnResonanceSkill(pos)
    -- 预设武器界面禁止进入相关编辑界面
end

function XUiTeamPrefabWeapon:OnBtnOverrun()
    -- 预设武器界面禁止进入相关编辑界面
end

function XUiTeamPrefabWeapon:OnBtnOverrunClick()
    -- 预设武器界面禁止进入相关编辑界面
end

function XUiTeamPrefabWeapon:OnSortTypeChange()
    XMVCA.XEquip:SortEquipIdListByPriorType(self.WeaponIdList, self.PriorSortType)
    if self.IsAscendOrder then
        XTool.ReverseList(self.WeaponIdList)
    end
    self:UpdateEquipList()
end

function XUiTeamPrefabWeapon:InitDynamicTable()
    local XUiGridEquipTeamPrefab = require("XUi/XUiTeamPrefab/Grid/XUiGridEquipTeamPrefab")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelEquipScroll, XUiGridEquipTeamPrefab)
end

-- 替换当前使用的武器ID为预设中当前位置的武器
function XUiTeamPrefabWeapon:UpdateEquipList()
    self:MoveUsingWeaponInFirst()
    self.DynamicTable:SetDataSource(self.WeaponIdList)
    self.DynamicTable:ReloadDataASync(#self.WeaponIdList > 0 and 1 or -1)
    self:PlayAnimation("LeftQieHuan")
end

-- 将预设中当前位置的武器移到列表首位
function XUiTeamPrefabWeapon:MoveUsingWeaponInFirst()
    local usingEquipId = self:GetCurrentWeaponId()
    if not usingEquipId or usingEquipId == 0 then return end

    local otherWeaponIds = {}
    for pos, entityId in pairs(self.TeamPrefab:GetEntityIds()) do
        if pos ~= self.CurrentPos then
            local weaponData = self.TeamPrefab:GetWeaponData(pos)
            if weaponData and XTool.IsNumberValid(weaponData.EquipId) then
                table.insert(otherWeaponIds, weaponData.EquipId)
            end
        end
    end
    
    local currPosWeaponIndexBeforeSort = nil
    local otherPosWeaponIndexListBeforeSort = {}
    for index, equipId in pairs(self.WeaponIdList) do
        if equipId == usingEquipId then
            currPosWeaponIndexBeforeSort = index
        end

        if table.contains(otherWeaponIds, equipId) then
            table.insert(otherPosWeaponIndexListBeforeSort, index)
        end

        if currPosWeaponIndexBeforeSort and #otherPosWeaponIndexListBeforeSort > (XDataCenter.TeamManager.GetMaxPos() - 1) then
            break
        end
    end

    -- 将currPosWeaponIndexBeforeSort放到首位，后面的otherPosWeaponIndexListBeforeSort放到后面 todo
    -- swap方式调整顺序
    if currPosWeaponIndexBeforeSort then
        -- 1. 当前位武器 -> 第1位
        if currPosWeaponIndexBeforeSort ~= 1 then
            self.WeaponIdList[1], self.WeaponIdList[currPosWeaponIndexBeforeSort] =
                self.WeaponIdList[currPosWeaponIndexBeforeSort], self.WeaponIdList[1]
        end

        -- 2. 其他位置武器 -> 从第2位开始
        local insertPos = 2
        for _, idx in ipairs(otherPosWeaponIndexListBeforeSort) do
            -- 注意：idx 可能因为之前 swap 发生变化，这里用 while 找到当前 equipId 的最新位置
            local equipId = self.WeaponIdList[idx]
            local currentIndex
            for i = insertPos, #self.WeaponIdList do
                if self.WeaponIdList[i] == equipId then
                    currentIndex = i
                    break
                end
            end
            if currentIndex and currentIndex ~= insertPos then
                self.WeaponIdList[insertPos], self.WeaponIdList[currentIndex] =
                    self.WeaponIdList[currentIndex], self.WeaponIdList[insertPos]
            end
            insertPos = insertPos + 1
        end
    end
end

-- 获取当前位置在预设中的武器ID
function XUiTeamPrefabWeapon:GetCurrentWeaponId()
    local weaponData = self.TeamPrefab:GetWeaponData(self.CurrentPos)
    return weaponData and weaponData.EquipId or 0
end

function XUiTeamPrefabWeapon:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipId = self.WeaponIdList[index]
        grid:Refresh(equipId)

        local isSelected = equipId == self.SelectEquipId
        grid:SetSelected(isSelected)
        if isSelected then
            self.LastSelectGrid = grid
        end
        grid.Transform:Find("Effect").gameObject:SetActiveEx(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.SelectEquipId = self.WeaponIdList[index]
        self:UpdateEquipDetail()
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelected(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelected(true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

function XUiTeamPrefabWeapon:GuideGetDynamicTableIndex(id)
    for i, v in ipairs(self.WeaponIdList) do
        local equip = XMVCA.XEquip:GetEquip(v)
        if tostring(equip.TemplateId) == id then
            return i
        end
    end

    return -1
end

-- 刷新界面：从队伍预设获取数据
function XUiTeamPrefabWeapon:UpdateView()
    -- 获取当前位置角色ID（使用接口而非直接访问字段）
    local characterId = self.TeamPrefab:GetEntityIdByTeamPos(self.CurrentPos)
    if characterId == 0 then
        self.WeaponIdList = {} -- 无角色时不显示武器
    else
        self.WeaponIdList = XMVCA.XEquip:GetCanUseWeaponIds(characterId) -- 基于当前角色筛选武器
    end
    
    -- 切换角色后默认选中装备的武器
    if #self.WeaponIdList > 0 then
        self.SelectEquipId = self:GetCurrentWeaponId()
    else
        self.SelectEquipId = 0
    end

    self:OnSortTypeChange() -- 排序武器列表
    self:UpdateEquipDetail() -- 刷新详情面板
end

-- 刷新装备详情
function XUiTeamPrefabWeapon:UpdateEquipDetail()
    local templateId = XMVCA.XEquip:GetEquipTemplateId(self.SelectEquipId)
    self.TxtEquipName.text = XMVCA.XEquip:GetEquipName(templateId)
    self:UpdateEquipAttr()
    self:UpdateEquipSkillDesc()
    self:UpdateEquipResonance()
    self:UpdateOverrun()
    self:UpdateBtnState()

    -- 刷新技能和能力扩展栏状态
    local isShow = self.PaneEquipResonance.gameObject.activeSelf or self.PaneOverrun.gameObject.activeSelf
    self.PanelExtendTitle.gameObject:SetActiveEx(isShow)
    if isShow then
        self:UpdateExtendName()
    end
    if not isShow and self.IsShowExtend then
        self:ShowPanelSkill()
    end
end

-- 刷新装备属性
function XUiTeamPrefabWeapon:UpdateEquipAttr()
    local currentWeaponId = self:GetCurrentWeaponId()
    local showCurAttr = currentWeaponId ~= 0 and currentWeaponId ~= self.SelectEquipId
    local curAttrMap = showCurAttr and XMVCA.XEquip:GetEquipAttrMap(currentWeaponId) or {}
    
    -- 选中武器属性
    local attrMap = XMVCA.XEquip:GetEquipAttrMap(self.SelectEquipId)
    
    -- 以下逻辑与原代码一致，仅数据源改为curAttrMap（预设中的当前武器）和attrMap（选中武器）
    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local curAttrInfo = curAttrMap[i]
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        self["PanelAttr" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtName" .. i].text = attrInfo.Name
            self["TxtCurAttr" .. i].text = showCurAttr and curAttrInfo.Value or ""
            self["ImgArrow" .. i].gameObject:SetActiveEx(showCurAttr)
            self["TxtAttr" .. i].text = attrInfo.Value

            local color = ATTR_COLOR.EQUAL
            if showCurAttr then
                if attrInfo.Value > curAttrInfo.Value then
                    color = ATTR_COLOR.OVER
                elseif attrInfo.Value < curAttrInfo.Value then
                    color = ATTR_COLOR.BELOW
                end
            end
            self["TxtAttr" .. i].color = color
        end
    end
end

-- 刷新技能详情
function XUiTeamPrefabWeapon:UpdateEquipSkillDesc()
    local templateId = XMVCA.XEquip:GetEquipTemplateId(self.SelectEquipId)
    local weaponSkillInfo = XMVCA.XEquip:GetEquipWeaponSkillInfo(templateId)
    self.TxtSkillName.text = weaponSkillInfo.Name
    self.TxtSkillDes.text = weaponSkillInfo.Description

    local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(false)
    self.PanelNoAwarenessSkill.gameObject:SetActiveEx(false)
    self.PanelWeaponSkillDes.gameObject:SetActiveEx(not noWeaponSkill)
    self.PanelNoWeaponSkill.gameObject:SetActiveEx(noWeaponSkill)
end

-- 刷新装备共鸣
function XUiTeamPrefabWeapon:UpdateEquipResonance()
    local templateId = XMVCA.XEquip:GetEquipTemplateId(self.SelectEquipId)
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(templateId)
    self.PaneEquipResonance.gameObject:SetActiveEx(canResonance)
    if not canResonance then
        return
    end

    local isResonanceConflict = false
    local xEquip = XMVCA.XEquip:GetEquip(self.SelectEquipId)
    local curCharacterId = self.TeamPrefab:GetEntityIdByTeamPos(self.CurrentPos)
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        self:UpdateEquipResonanceSkill(pos)
        local charId = xEquip:GetResonanceBindCharacterId(pos)
        if XTool.IsNumberValid(charId) and charId ~= curCharacterId then
            isResonanceConflict = true
        end
    end
    self.PanelAdd2:ShowReddot(isResonanceConflict)
end

-- 刷新单个装备共鸣（预设优先；非本位武器回退仓库）
function XUiTeamPrefabWeapon:UpdateEquipResonanceSkill(pos)
    local uiObj = self["GridEquipResonance" .. pos]
    local effectObj = self["GridEquipResonanceEffect" .. pos]
    local button = uiObj:GetComponent("XUiButton")
    local entityId = self.TeamPrefab:GetEntityIdByTeamPos(self.CurrentPos)

    local teamWeaponData = self.TeamPrefab:GetWeaponData(self.CurrentPos)
    local isCurSelectEquipInCurrentPos = teamWeaponData and (self.SelectEquipId == teamWeaponData.EquipId)

    ------------------------------------------------------------
    -- ✅ 1. 当前武器是预设位置武器：仅展示预设共鸣数据
    ------------------------------------------------------------
    if isCurSelectEquipInCurrentPos then
        local resonanceDict = self.TeamPrefab:GetWeaponResonance(self.CurrentPos) or {}
        local presetSkillId = resonanceDict[pos] or 0

        -- 预设没有共鸣 → 不显示
        if presetSkillId == 0 then
            button:SetDisable(true)
            effectObj.gameObject:SetActiveEx(false)
            return
        end

        -- 构造预设 skillInfo
        local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
        local xEquip = XMVCA.XEquip:GetEquip(self.SelectEquipId)
        local skillType = XMVCA.XEquip:GuessResonanceType(presetSkillId, xEquip.TemplateId)
        local skillInfo = XSkillInfoObj.New(skillType, presetSkillId, entityId)

        -- ✅ 改为：用真实仓库的绑定角色ID，这样“不共鸣”标签还能正确显示
        local bindCharacterId = XMVCA.XEquip:GetResonanceBindCharacterId(self.SelectEquipId, pos)

        self:RefreshResonanceUI(uiObj, pos, skillInfo, entityId, bindCharacterId, button, effectObj)
        return
    end

    ------------------------------------------------------------
    -- ✅ 2. 非预设武器：展示仓库共鸣数据（含“不共鸣”标识）
    ------------------------------------------------------------
    local hasResonance = XMVCA.XEquip:CheckEquipPosResonanced(self.SelectEquipId, pos) ~= nil
    button:SetDisable(not hasResonance)
    effectObj.gameObject:SetActiveEx(false)
    if not hasResonance then return end

    -- 读取仓库绑定角色（让 UI 判断出不共鸣状态）
    local bindCharacterId = XMVCA.XEquip:GetResonanceBindCharacterId(self.SelectEquipId, pos)

    -- skillInfo 传 nil → UI 内部自动从仓库加载技能数据
    self:RefreshResonanceUI(uiObj, pos, nil, entityId, bindCharacterId, button, effectObj)
end

------------------------------------------------------------
-- ✅ 抽公共刷新函数，保证两种情况都正确显示
------------------------------------------------------------
function XUiTeamPrefabWeapon:RefreshResonanceUI(uiObj, pos, skillInfo, entityId, bindCharacterId, button, effectObj)
    button:SetDisable(false)
    effectObj.gameObject:SetActiveEx(false)

    self.ResonanceSkillDic = self.ResonanceSkillDic or {}
    if not self.ResonanceSkillDic[pos] then
        self.ResonanceSkillDic[pos] = {}
        for _, stateName in ipairs({"Normal", "Press"}) do
            local stateGo = uiObj:GetObject(stateName)
            self.ResonanceSkillDic[pos][stateName] = XUiGridResonanceSkill.New(
                stateGo,
                self.SelectEquipId,
                pos,
                entityId,
                function() self:OnBtnResonanceSkill(pos) end,
                nil,
                self.ForceShowBindCharacter
            )
        end
    end

    for _, stateName in ipairs({"Normal", "Press"}) do
        local grid = self.ResonanceSkillDic[pos][stateName]
        grid:SetEquipIdAndPos(self.SelectEquipId, pos)
        grid:SetCharacterId(entityId)
        grid:Refresh(skillInfo, bindCharacterId)
    end
end

-- 刷新武器超限状态（基于预设ID和实际武器数据）
function XUiTeamPrefabWeapon:UpdateOverrun()
    self.OverrunIconTips = nil
    local templateId = XMVCA.XEquip:GetEquipTemplateId(self.SelectEquipId)
    self.CanOverrun = XMVCA.XEquip:CanOverrunByTemplateId(templateId)
    self.PaneOverrun.gameObject:SetActiveEx(self.CanOverrun)
    if not self.CanOverrun then 
        return
    end

    -- 从预设获取武器ID和超频套装ID
    local presetOverrunSuitId = self.TeamPrefab:GetWeaponOverrunSuitId(self.CurrentPos)
    
    -- 从实际玩家武器获取超频等级和状态
    local realWeapon = XMVCA.XEquip:GetEquip(self.SelectEquipId)
    local realOverrunSuitId = realWeapon and realWeapon:GetOverrunChoseSuit() or 0
    
    -- 合并预设与实际数据（套装以预设为主，等级以实际为主）
    local displayOverrunSuitId = presetOverrunSuitId ~= 0 and presetOverrunSuitId or realOverrunSuitId

    -- 隐藏所有超频按钮状态
    self.BtnOverrunBlind.gameObject:SetActiveEx(false)
    self.BtnOverrunEmpty.gameObject:SetActiveEx(false)

    -- 未绑定超频套装
    local canBind = realWeapon and realWeapon:IsOverrunCanBlindSuit()
    if not canBind then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(true)
        return 
    end

    -- 已绑定超频套装
    if displayOverrunSuitId ~= 0 then
        self.BtnOverrunBlind.gameObject:SetActiveEx(true)
        self.BtnOverrunBlind:SetDisable(false)
        
        -- 设置套装图标（所有状态）
        local stateList = { "Normal", "Press" }
        local iconPath = XMVCA.XEquip:GetEquipSuitIconPath(displayOverrunSuitId)
        local uiObj = self.BtnOverrunBlind:GetComponent("UiObject")
        
        for _, stateName in ipairs(stateList) do
            local stateObj = uiObj:GetObject(stateName)
            stateObj:GetObject("RImgSuit"):SetRawImage(iconPath)
            
            -- 检查套装与角色是否匹配（从预设获取当前位置角色ID）
            local characterId = self.TeamPrefab:GetEntityIdByTeamPos(self.CurrentPos)
            local isMatch = realWeapon and realWeapon:IsOverrunBlindMatch(characterId)
            stateObj:GetObject("ImgNotMatching").gameObject:SetActiveEx(not isMatch)
        end
        
        self.OverrunBlindEffect.gameObject:SetActiveEx(false)
        return
    end

    -- 可绑定但未绑定状态
    self.BtnOverrunEmpty.gameObject:SetActiveEx(true)
end

-- 刷新按钮状态
function XUiTeamPrefabWeapon:UpdateBtnState()
    -- 培养按钮
    self.BtnStrengthen.gameObject:SetActiveEx(false)
    
    -- 穿戴/已装备状态
    local currentWeaponId = self:GetCurrentWeaponId()
    local isEquip = currentWeaponId == self.SelectEquipId
    self.BtnTakeOn.gameObject:SetActiveEx(not isEquip)
    self.ImgEquipOn.gameObject:SetActiveEx(isEquip)
end

-- 刷新扩展按钮名称
function XUiTeamPrefabWeapon:UpdateExtendName()
    local nameKey = self.CanOverrun and "EquipWeaponBtnName" or "EquipResonanceName"
    local btnName = XUiHelper.GetText(nameKey)
    self.PanelAdd2:SetName(btnName)
    self.TxtExtendTitleNormal.text = btnName
end

-- 显示技能面板
function XUiTeamPrefabWeapon:ShowPanelSkill()
    self.IsShowExtend = false
    self:PlayAnimation("AnimUnFold")
    self.PanelAddEffect.gameObject:SetActiveEx(false)
    self.PanelAdd2Effect.gameObject:SetActiveEx(true)
    self.GridEquipResonanceEffect1.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect2.gameObject:SetActiveEx(false)
    self.GridEquipResonanceEffect3.gameObject:SetActiveEx(false)
    self.OverrunBlindEffect.gameObject:SetActiveEx(false)
end

-- 显示扩展面板
function XUiTeamPrefabWeapon:ShowPanelExtend()
    self.IsShowExtend = true
    self:PlayAnimation("AnimFold")
    self.PanelAddEffect.gameObject:SetActiveEx(true)
    self.PanelAdd2Effect.gameObject:SetActiveEx(false)
end

return XUiTeamPrefabWeapon