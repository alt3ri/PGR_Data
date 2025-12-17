local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XPartnerSort = require("XUi/XUiPartner/PartnerCommon/XPartnerSort")
local XUiTeamPrefabPartnerGridPartner = require("XUi/XUiTeamPrefab/XUiTeamPrefabPartner/Grid/XUiTeamPrefabPartnerGridPartner")
local XUiTeamPrefabPartnerGridRoleTeam = require("XUi/XUiTeamPrefab/XUiTeamPrefabPartner/Grid/XUiTeamPrefabPartnerGridRoleTeam")
local XUiGridPresetSkill = require("XUi/XUiPartner/PartnerPreset/UiPartnerSkill/XUiGridPresetSkill")

local TEAM_MEMBER_ORDER = {2, 1, 3} -- 队伍顺序（蓝，红，黄）
local DEFAULT_SELECT_INDEX = 1 -- 默认选中辅助机

--==============================
--@desc 队伍预设辅助机界面（适配XTeamPrefab）
--==============================
local XUiTeamPrefabPartner = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabPartner")

function XUiTeamPrefabPartner:OnAwake()
    self:InitUi()
    self:InitCb()
end 

---@param xTeamPrefab XTeamPrefab
---@param pos any
function XUiTeamPrefabPartner:OnStart(xTeamPrefab, pos)
    self.XTeamPrefab = xTeamPrefab  -- 核心：使用XTeamPrefab实例
    self.Pos = pos or 1  -- 初始选中位置
    
    -- 从XTeamPrefab获取核心数据
    self.TeamId = self.XTeamPrefab:GetId()  -- 队伍ID
    self.RoleList = self.XTeamPrefab:GetEntityIds()  -- 角色列表（位置->角色ID）
    self.PartnerPrefab = self.XTeamPrefab:GetPartnerData()  -- 辅助机预设数据（由XTeamPrefab管理）
    
    -- 初始化缓存与组件
    self.RoleGridList = {}
    self.ActiveSkillGrids = {}
    self.PassiveSkillGrids = {}
    
    -- 队伍名称从XTeamPrefab获取
    self.TxtName.text = self.XTeamPrefab:GetName()
    
    -- 初始化界面
    self:RefreshRoleList()
    self:RefreshPartnerList()
    
    -- 刷新技能缓存（基于XTeamPrefab数据）
    self.PartnerPrefab:InitSkillCache({TeamData = self.RoleList})
    
    -- 默认选中角色
    self:OnSelectRole(self.Pos)
end

function XUiTeamPrefabPartner:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.OnSkillChange, self)
end

function XUiTeamPrefabPartner:OnDisable()
    XDataCenter.PartnerManager.ClearAllPresetSkillCache()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.OnSkillChange, self)
end

--region 事件回调
--==============================
--@desc 选择角色回调
--@index 位置索引（1-3）
--==============================
function XUiTeamPrefabPartner:OnSelectRole(index)
    if index == self.SelectRoleIndex then return end

    -- 切换角色前检查技能缓存
    self:CheckIsClearSkillCache()
    
    self.SelectRoleIndex = index
    for i, grid in ipairs(self.RoleGridList) do
        grid:SetSelect(i == index)
    end

    local partner = self.PartnerList[self.SelectPartnerIndex]
    self:RefreshProperty(partner)
    -- self:CheckIsUpdateSkillData(partner, function()
    -- end)
end

--==============================
--@desc 选择辅助机回调
--@idx 辅助机列表索引
--==============================
function XUiTeamPrefabPartner:OnClickPartner(idx)
    if idx == self.SelectPartnerIndex then return end

    -- 切换辅助机前检查技能缓存
    self:CheckIsClearSkillCache()
    
    self.SelectPartnerIndex = idx
    local grids = self.DynamicTable:GetGrids()
    for i, grid in pairs(grids) do
        grid:SetSelect(i == idx)
    end

    local partner = self.PartnerList[idx]
    self:PlayAnimation("RightQieHuan", nil, function()
        self:RefreshProperty(partner)
    end)
end

--==============================
--@desc 动态列表事件
--==============================
function XUiTeamPrefabPartner:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PartnerList[idx], self.CarriedDict, idx)
        grid:SetSelect(idx == self.SelectPartnerIndex)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPartner(idx)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        -- 加载完成后默认选中辅助机
        local hasPartner = self:CheckHasPartner()
        local targetIndex = hasPartner 
            and self:GetEquipPartnerIndexBySelectRole() 
            or self:GetFirstNoEquipIndex()
        self:OnClickPartner(targetIndex)
    end
end

--==============================
--@desc 检测是否需要清除技能缓存（基于XTeamPrefab数据）
--==============================
function XUiTeamPrefabPartner:CheckIsClearSkillCache()
    if not XTool.IsNumberValid(self.SelectPartnerIndex) then
        return
    end
    
    local lastPartner = self.PartnerList[self.SelectPartnerIndex]
    local partnerId = lastPartner:GetId()
    local changeSkill = self.PartnerPrefab:IsSkillChangeWithPrefab2Cache(partnerId)

    if changeSkill then
        XDataCenter.PartnerManager.ClearPresetSkillCache(partnerId)
        local msg = XUiHelper.GetText("PartnerTeamPrefabSkillNotSaveTips", lastPartner:GetName())
        XUiManager.TipMsg(msg)
        -- 从XTeamPrefab关联的辅助机预设中获取位置
        local isCarried = XTool.IsNumberValid(self.CarriedDict[partnerId])
        if isCarried then
            local pos = self.PartnerPrefab:GetPosByPartnerId(partnerId)
            self.PartnerPrefab:UpdateSkillData(pos, partnerId)
        end
    end
end

--==============================
--@desc 检测是否需要更新技能数据到XTeamPrefab中
--==============================
function XUiTeamPrefabPartner:CheckIsUpdateSkillData(partner, cancelCb)
    if not partner then
        return
    end
    
    local id = partner:GetId()
    local isCarried = XTool.IsNumberValid(self.CarriedDict[id])
    local isCorresponding = self:GetEquipPartnerIndexBySelectRole() == self.SelectPartnerIndex
    local changeSkill = self.PartnerPrefab:IsSkillChangeWithPrefab2Cache(id)

    if changeSkill and isCarried and isCorresponding then
        local beginCb = function()
            -- 从XTeamPrefab获取当前选中角色位置，更新技能数据
            self.PartnerPrefab:UpdateSkillData(self.SelectRoleIndex, id)
            local skillData = self.PartnerPrefab:GetSkillData(id)
            -- 提交更新到服务器（关联XTeamPrefab的TeamId）
            XDataCenter.PartnerManager.TeamPreSetPartnerRequest(
                self.TeamId, 
                self.SelectRoleIndex, 
                id, 
                skillData, 
                function()
                    self:RefreshProperty(partner)
                    XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.XTeamPrefab)
                end
            )
        end
        self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabSkillSaveTips"), beginCb)
    else
        if cancelCb then cancelCb() end
    end
end

--==============================
--@desc 技能变更回调
--==============================
function XUiTeamPrefabPartner:OnSkillChange(partner)
    if not partner then
        return
    end
    
    self:RefreshProperty(partner)
    -- self:CheckIsUpdateSkillData(partner, function()
    -- end)
end

-- 携带辅助机
function XUiTeamPrefabPartner:OnBtnTakeOnClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabEquipTips"), function()
        self:Equip()
    end)
end

-- 卸下辅助机
function XUiTeamPrefabPartner:OnBtnTakeOffClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabUnloadTips"), function()
        self:Unload()
    end)
end

-- 更换辅助机
function XUiTeamPrefabPartner:OnBtnTakeChangeClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabExchangeTips"), function()
        self:Equip()
    end)
end
--endregion

--region 初始化与刷新
function XUiTeamPrefabPartner:InitUi()
    -- 初始化动态列表（辅助机列表）
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPartnerScroll)
    self.DynamicTable:SetProxy(XUiTeamPrefabPartnerGridPartner)
    self.DynamicTable:SetDelegate(self)
    self.GridPartner.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
end

function XUiTeamPrefabPartner:InitCb()
    self:BindHelpBtn(self.BtnHelp, "PartnerPrefabHelp")
    self.BtnBack.CallBack = function() 
        self:CheckIsClearSkillCache()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        self:CheckIsClearSkillCache()
        XLuaUiManager.RunMain()
    end
    self.BtnTakeOn.CallBack = function() 
        self:OnBtnTakeOnClick()
    end
    self.BtnTakeChange.CallBack = function() 
        self:OnBtnTakeChangeClick()
    end
    self.BtnTakeOff.CallBack = function() 
        self:OnBtnTakeOffClick()
    end
end


--==============================
--@desc 刷新角色列表（从XTeamPrefab获取角色与辅助机关联关系）
--==============================
function XUiTeamPrefabPartner:RefreshRoleList()
    for i, order in ipairs(TEAM_MEMBER_ORDER) do
        local grid = self.RoleGridList[order]
        -- 从XTeamPrefab获取角色ID和对应辅助机ID
        local roleId = self.XTeamPrefab:GetEntityIdByTeamPos(order)  -- 角色ID
        local partnerId = self.PartnerPrefab:GetPartnerIdByPos(order)
        
        if not grid then
            local ui = i == 1 and self.GridTeamRole or CS.UnityEngine.Object.Instantiate(self.GridTeamRole, self.PanelTeam, false)
            ui.gameObject.name = string.format("GridTeamRole%d", order)
            grid = XUiTeamPrefabPartnerGridRoleTeam.New(ui, order, handler(self, self.OnSelectRole))
            self.RoleGridList[order] = grid
        end
        
        grid:Refresh(roleId, partnerId)
    end
end

--==============================
--@desc 刷新辅助机列表（从XTeamPrefab获取已携带状态）
--==============================
function XUiTeamPrefabPartner:RefreshPartnerList()
    self.DynamicTable:Clear()
    self.PartnerList = XDataCenter.PartnerManager.GetPartnerOverviewDataList()
    -- 从XTeamPrefab关联的辅助机预设中获取已携带字典
    self.CarriedDict = self.PartnerPrefab:GetCarriedDict()
    XPartnerSort.PresetSort(self.PartnerList, self.CarriedDict)
    self.DynamicTable:SetDataSource(self.PartnerList)
    self.DynamicTable:ReloadDataASync(1)
    self:PlayAnimation("LeftQieHuan")
end

--==============================
--@desc 刷新辅助机属性面板
--==============================
function XUiTeamPrefabPartner:RefreshProperty(partner)
    if not partner then
        return
    end
    local partnerId = partner:GetId()
    
    -- 基础信息（从辅助机实体获取）
    self.RImgPartnerIcon:SetRawImage(partner:GetIcon())
    self.RawImageQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(partner:GetQuality()))
    self.TxtPartnerName.text = partner:GetName()
    self.TxtPartnerLevel.text = partner:GetLevel()
    self.TxtSelectAbil.text = partner:GetAbility()

    -- 按钮状态（基于XTeamPrefab中的携带状态）
    local hasPartner = self:CheckHasPartner()
    self.BtnTakeOn.gameObject:SetActiveEx(not hasPartner)
    local isCorresponding = self:GetEquipPartnerIndexBySelectRole() == self.SelectPartnerIndex
    self.BtnTakeOff.gameObject:SetActiveEx(hasPartner and isCorresponding)
    self.BtnTakeChange.gameObject:SetActiveEx(hasPartner and not isCorresponding)
    
    -- 刷新技能列表
    self:RefreshSkillList(partner, partnerId)
    
    -- 辅助机类型显示（异界装备特殊处理）
    local partnerType = partner:GetPartnerType()
    if partnerType == XPartnerConfigs.PartnerType.Link then
        if self.TxtNameType and self.TxtNameTypeLink then
            self.TxtNameType.gameObject:SetActiveEx(false)
            self.TxtNameTypeLink.gameObject:SetActiveEx(true)
        end
    else
        if self.TxtNameType and self.TxtNameTypeLink then
            self.TxtNameType.gameObject:SetActiveEx(true)
            self.TxtNameTypeLink.gameObject:SetActiveEx(false)
        end
    end
end

--==============================
--@desc 刷新技能列表（从实际辅助机数据获取）
--==============================
function XUiTeamPrefabPartner:RefreshSkillList(partner, partnerId)
    -- 主动技能（从实际辅助机数据获取）
    local activeSkills = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.MainSkill)
    -- 被动技能（从实际辅助机数据获取）
    local passiveSkills = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.PassiveSkill)
    
    local skillCount = partner:GetQualitySkillColumnCount()
    
    -- 刷新主动技能
    for idx = 1, XPartnerConfigs.MainSkillCount do
        local grid = self.ActiveSkillGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkills, false)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridPresetSkill.New(ui)
            grid.GameObject.name = string.format("ActiveSkill%d", idx)
            self.ActiveSkillGrids[idx] = grid
        end
        grid:Refresh(activeSkills[idx], partner, false, XPartnerConfigs.SkillType.MainSkill, idx + 1, self.PartnerPrefab)
    end

    -- 刷新被动技能
    for idx = 1, XPartnerConfigs.PassiveSkillCount do
        local grid = self.PassiveSkillGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkills, false)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridPresetSkill.New(ui)
            grid.GameObject.name = string.format("PassiveSkill%d", idx)
            self.PassiveSkillGrids[idx] = grid
        end
        grid:Refresh(passiveSkills[idx], partner, skillCount < idx, XPartnerConfigs.SkillType.PassiveSkill, idx + 1, self.PartnerPrefab)
    end
end
--endregion

--region 工具方法
--==============================
--@desc 检查当前角色是否携带辅助机（从XTeamPrefab获取）
--==============================
function XUiTeamPrefabPartner:CheckHasPartner()
    local partnerId = self.PartnerPrefab:GetPartnerIdByPos(self.SelectRoleIndex)
    return XTool.IsNumberValid(partnerId)
end 

--==============================
--@desc 获取第一个未装备的辅助机索引
--==============================
function XUiTeamPrefabPartner:GetFirstNoEquipIndex()
    local partnerCount = #self.PartnerList
    if partnerCount <= 0 then
        return 0
    end
    
    -- 从XTeamPrefab的辅助机预设中获取已携带数量
    local carryCount = self.PartnerPrefab:GetCarriedCount()
    return partnerCount > carryCount and carryCount + 1 or DEFAULT_SELECT_INDEX
end

--==============================
--@desc 根据选中角色获取已装备的辅助机索引
--==============================
function XUiTeamPrefabPartner:GetEquipPartnerIndexBySelectRole()
    local partnerCount = #self.PartnerList
    if partnerCount <= 0 then
        return 0
    end

    -- 从XTeamPrefab获取当前角色携带的辅助机ID
    local partnerId = self.PartnerPrefab:GetPartnerIdByPos(self.SelectRoleIndex)
    if not XTool.IsNumberValid(partnerId) then return 0 end
    
    -- 查找辅助机在列表中的索引
    local maxIndex = #self.RoleList
    for i, partner in ipairs(self.PartnerList) do
        if i > maxIndex then return DEFAULT_SELECT_INDEX end
        if partner:GetId() == partnerId then
            return i
        end
    end
    
    return DEFAULT_SELECT_INDEX
end

--==============================
--@desc 装备/替换辅助机（更新到XTeamPrefab）
--==============================
function XUiTeamPrefabPartner:Equip()
    local partner = self.PartnerList[self.SelectPartnerIndex]
    local partnerId = partner:GetId()
    
    local equipFunc = function()
        -- 通过XTeamPrefab的辅助机预设装备辅助机
        self.PartnerPrefab:Equip(self.SelectRoleIndex, partnerId)
        local skillData = self.PartnerPrefab:GetSkillData(partnerId)
        -- 提交到服务器，关联XTeamPrefab的TeamId
        XDataCenter.PartnerManager.TeamPreSetPartnerRequest(
            self.TeamId, 
            self.SelectRoleIndex, 
            partnerId, 
            skillData, 
            function()
                self.SelectPartnerIndex = 0
                self:RefreshPartnerList()
                self:RefreshRoleList()
                -- 分发事件携带XTeamPrefab实例
                XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.XTeamPrefab)
            end
        )
    end
    
    local unloadThenEquipFunc = function()
        -- 从原位置卸下（通过XTeamPrefab的辅助机预设）
        local pos = self.PartnerPrefab:GetPosByPartnerId(partnerId)
        self.PartnerPrefab:Unload(pos, true)
        XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self.TeamId, pos, 0, {}, function()
            equipFunc()
        end)
    end
    
    -- 检查当前角色和辅助机的携带状态（基于XTeamPrefab）
    local isRoleEquipPartner = self:CheckHasPartner()
    local isPartnerEquipped = self.PartnerPrefab:GetIsCarry(partnerId)
    
    if isRoleEquipPartner then
        if isPartnerEquipped then
            -- 当前角色携带辅助机，选中辅助机已被其他角色携带：先卸自身，再卸原携带者，再装备
            self.PartnerPrefab:Unload(self.SelectRoleIndex)
            unloadThenEquipFunc()
        else
            -- 当前角色携带辅助机，选中辅助机未被携带：先卸自身，再装备
            self.PartnerPrefab:Unload(self.SelectRoleIndex)
            equipFunc()
        end
    else
        if isPartnerEquipped then
            -- 当前角色未携带，选中辅助机已被携带：先卸原携带者，再装备
            unloadThenEquipFunc()
        else
            -- 直接装备
            equipFunc()
        end
    end
end 

--==============================
--@desc 卸下辅助机（从XTeamPrefab移除）
--==============================
function XUiTeamPrefabPartner:Unload()
    if not XTool.IsNumberValid(self.SelectRoleIndex) then return end
    
    -- 通过XTeamPrefab的辅助机预设卸下
    self.PartnerPrefab:Unload(self.SelectRoleIndex)
    XDataCenter.PartnerManager.TeamPreSetPartnerRequest(
        self.TeamId, 
        self.SelectRoleIndex, 
        0, 
        {}, 
        function()
            self.SelectPartnerIndex = 0
            self:RefreshPartnerList()
            self:RefreshRoleList()
            XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.XTeamPrefab)
        end
    )
end

--==============================
--@desc 显示提示弹窗
--==============================
function XUiTeamPrefabPartner:OpenPopupTip(title, beginCb, endCb)
    title = title or ""
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XLuaUiManager.Open("UiPartnerPopupTip", title, function()
        if endCb then endCb() end
        XLuaUiManager.SetMask(false)
    end)
end
--endregion

return XUiTeamPrefabPartner
