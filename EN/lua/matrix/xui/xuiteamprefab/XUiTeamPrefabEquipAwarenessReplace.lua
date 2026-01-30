local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XTeamPrefabEquipAwarenessReplace = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabEquipAwarenessReplace")

function XTeamPrefabEquipAwarenessReplace:OnAwake()
    self.SKILL_DES_COLOR = {
        [true] = XUiHelper.Hexcolor2Color("188649"),
        [false] = XUiHelper.Hexcolor2Color("1B3750")
    }

    self.CompareEffect = self.Transform:Find("SafeAreaContentPane/Right/Effect")
    self.EquipDetail1.gameObject:SetActiveEx(false)
    self.EquipDetail2.gameObject:SetActiveEx(false)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    
    local XUiEquipPanelSuit = require("XUi/XUiEquip/XUiEquipAwarenessReplace/XUiEquipPanelSuit")
    self.UiPanelSuit = XUiEquipPanelSuit.New(self.PanelSuit, self)
    self.UiPanelSuit:Open()

    self:SetButtonCallBack()
    self:InitDynamicTable()
end

---@param teamPrefab XTeamPrefab
---@param pos number
---@param notShowStrengthenBtn bool
function XTeamPrefabEquipAwarenessReplace:OnStart(teamPrefab, pos, equipSite, notShowStrengthenBtn)
    self.TeamPrefab = teamPrefab  -- XTeamPrefab实例
    self.CurrentPos = pos  -- 队伍中的位置
    self.SelectSite = equipSite or XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE  -- 默认选中第一个意识位置
    self.SelectSuitId = XEnumConst.EQUIP.ALL_SUIT_ID
    self.NotShowStrengthenBtn = notShowStrengthenBtn == true

    -- 获取角色ID用于相关操作
    self.CharacterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)

    -- 刷新套装页签、位置选中
    self.UiPanelSuit:UpdateSuitTitle(self.SelectSuitId)
    self.PanelTogPos:SelectIndex(self.SelectSite)
end

function XTeamPrefabEquipAwarenessReplace:OnEnable()
    self.IsEnableShow = true
    self:UpdateView()
    self.UiPanelSuit:Open()
end

function XTeamPrefabEquipAwarenessReplace:OnDisable()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    self.UiPanelSuit:Close()
end

function XTeamPrefabEquipAwarenessReplace:OnDestroy()
    self.SKILL_DES_COLOR = nil
    self:ReleaseModel()
    self:ReleaseLihuiTimer()
end

-- 注册监听事件
function XTeamPrefabEquipAwarenessReplace:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_PUTON_NOTYFY,
        XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY,
        XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RECYCLE_NOTIFY
    }
end

-- 处理事件监听
function XTeamPrefabEquipAwarenessReplace:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY then
        self:UpdateView()

        local grid = self.DynamicTable:GetGridByIndex(1)
        local effect = grid.Transform:Find("Effect")
        effect.gameObject:SetActive(false)
        effect.gameObject:SetActive(true)
    elseif evt == XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY then
        self:UpdateView()
    end
end

function XTeamPrefabEquipAwarenessReplace:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)

    -- 位置按钮
    self.PosTogList = {self.Tog1, self.Tog2, self.Tog3, self.Tog4, self.Tog5, self.Tog6}
    self.PanelTogPos:Init(self.PosTogList, function(index) 
        self:OnSelectSite(index) 
    end)

    -- 装备详情操作按钮
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnStrengthen"), function() self:OnBtnStrengthenClick(self.DetailEquipId1) end)
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnPutOn"), function() self:OnBtnPutOnClick(self.DetailEquipId1) end)
    self:RegisterClickEvent(self.EquipDetail1:GetObject("BtnTakeOff"), function() self:OnBtnTakeOffClick(self.DetailEquipId1) end)
end

function XTeamPrefabEquipAwarenessReplace:OnBtnBackClick()
    self:Close()
end

function XTeamPrefabEquipAwarenessReplace:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XTeamPrefabEquipAwarenessReplace:OnBtnBgClick()
    self.UiPanelSuit:OpenSuitFilter(false)

    if self.IsDetail2Show then
        self.IsDetail2Show = false
        self:PlayAnimation("EquipDetail2Disable", function()
            self.EquipDetail2.gameObject:SetActiveEx(false)
        end)
    end
end

function XTeamPrefabEquipAwarenessReplace:OnSelectSite(site)
    self.UiPanelSuit:OpenSuitFilter(false)
    if self.SelectSite == site then
        return
    end
    self:PlayAnimation("SuitQieHuan")
    self:PlayAnimation("EquipDetail2QieHuan")

    -- 非选中 "全部" 页签，筛选无意识则不给切换
    local awarenessList
    if self.SelectSuitId ~= XEnumConst.EQUIP.ALL_SUIT_ID then
        awarenessList = self:GetAwarenessList(site, self.SelectSuitId)
        if #awarenessList == 0 then
            XUiManager.TipText("FilterAwarenessEmpty")
            self.PanelTogPos:SelectIndex(self.SelectSite)
            return
        end
    end
    
    self.SelectSite = site
    self:UpdateAwarenessList(awarenessList)
    self:UpdateEquipDetail()
end

function XTeamPrefabEquipAwarenessReplace:OnSelectSuit(suitId)
    self.SelectSuitId = suitId
    self.UiPanelSuit:OpenSuitFilter(false)
    self.UiPanelSuit:UpdateSuitTitle(self.SelectSuitId)
    self:UpdateAwarenessList()
    self:UpdateEquipDetail()
end

function XTeamPrefabEquipAwarenessReplace:OnBtnStrengthenClick(equipId)
    XMVCA.XEquip:OpenUiEquipDetail(equipId, nil, self.CharacterId, nil, nil, nil, true)
end

-- 穿戴装备到预设中
function XTeamPrefabEquipAwarenessReplace:OnBtnPutOnClick(equipId)
    -- 检查装备是否可以被该角色穿戴
    local xEquip = XMVCA.XEquip:GetEquip(equipId)
    if not xEquip:CheckCanCharWear(self.CharacterId) then
        XUiManager.TipText("EquipCannotWear")
        return
    end

    local isConflict, conflictPos = self.TeamPrefab:CheckEquipIdConflict(equipId, self.CurrentPos)

    local fun = function()
        -- 在预设中更新装备
        self.TeamPrefab:UpdateEquipAt(self.CurrentPos, self.SelectSite, {
            EquipId = equipId,
            ResonanceDict = {},
            WeaponOverrunSuitId = 0  -- 意识没有武器超频属性
        }, isConflict, function ()
            self:UpdateView()
            XUiManager.TipText("TeamPrefabAwarenessEquipSuccess")
        end)

        if isConflict then
            self.TeamPrefab:SyncFullDataToServer(function ()
                self:UpdateView()
                XUiManager.TipText("TeamPrefabAwarenessEquipSuccess")
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

-- 从预设中卸下装备
function XTeamPrefabEquipAwarenessReplace:OnBtnTakeOffClick()
    -- 在预设中移除装备
    self.TeamPrefab:UpdateEquipAt(self.CurrentPos, self.SelectSite, nil)
    self:UpdateView()
    XUiManager.TipText("EquipTakeOffSuccess")
end

-- 刷新界面
function XTeamPrefabEquipAwarenessReplace:UpdateView()
    self:UpdateAwarenessList()
    self:UpdateEquipDetail()
end

-- 获取意识列表（适配XTeamPrefab）
function XTeamPrefabEquipAwarenessReplace:GetAwarenessList(site, suitId)
    site = site or self.SelectSite
    suitId = suitId or self.SelectSuitId
    
    -- 获取角色可穿戴的所有意识(包含了套装筛选)
    local allAwareness = XMVCA.XEquip:GetAwarenessListForTeamPrefab(self.CharacterId, site, suitId, self.TeamPrefab, self.CurrentPos)
    
    return allAwareness
end

-- 刷新意识列表
function XTeamPrefabEquipAwarenessReplace:UpdateAwarenessList(awarenessList)
    self.AwarenessList = awarenessList or self:GetAwarenessList()

    -- 检测当前选中装备是否仍然存在
    if self.SelectEquipId then
        local isExitEquip = false
        for _, equip in ipairs(self.AwarenessList) do
            if equip.Id == self.SelectEquipId then
                isExitEquip = true
                break
            end
        end
        if not isExitEquip then
            self.SelectEquipId = nil
        end
    end

    -- 默认选中第一个装备或当前穿戴的装备
    local wearEquipId = self:GetWearingEquipId()
    if not self.SelectEquipId then
        if wearEquipId then
            -- 检查当前穿戴的装备是否在列表中
            for _, equip in ipairs(self.AwarenessList) do
                if equip.Id == wearEquipId then
                    self.SelectEquipId = wearEquipId
                    break
                end
            end
        end
        
        -- 如果没有选中，默认选第一个
        if not self.SelectEquipId and #self.AwarenessList > 0 then
            self.SelectEquipId = self.AwarenessList[1].Id
        end
    end

    self.DynamicTable:SetDataSource(self.AwarenessList)
    self.DynamicTable:ReloadDataSync(#self.AwarenessList > 0 and 1 or -1)
    local isEmpty = #self.AwarenessList == 0
    self.PanelNoEquip.gameObject:SetActiveEx(isEmpty)
end

function XTeamPrefabEquipAwarenessReplace:InitDynamicTable()
    local XUiGridEquipTeamPrefab = require("XUi/XUiTeamPrefab/Grid/XUiGridEquipTeamPrefab")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelEquipList, XUiGridEquipTeamPrefab)
end

function XTeamPrefabEquipAwarenessReplace:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equip = self.AwarenessList[index]
        local isSelect = self.SelectEquipId == equip.Id
        grid:Refresh(equip.Id, self.SelectSite)
        grid:SetSelected(isSelect)
        grid.Transform:Find("Effect").gameObject:SetActiveEx(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local grids = self.DynamicTable:GetGrids()
        for _, grid in pairs(grids) do
            grid:SetSelected(false)
        end

        self.SelectEquipId = self.AwarenessList[index].Id
        grid:SetSelected(true)
        self:UpdateEquipDetail()
    end
end

-- 获取当前穿戴的装备ID
function XTeamPrefabEquipAwarenessReplace:GetWearingEquipId()
    local awarenessData = self.TeamPrefab:GetAwarenessData(self.CurrentPos, self.SelectSite)
    return awarenessData and awarenessData.EquipId or nil
end

-- 刷新装备详情
function XTeamPrefabEquipAwarenessReplace:UpdateEquipDetail()
    -- 刷新装备详情
    local wearEquipId = self:GetWearingEquipId()
    local isCompare = false
    if self.SelectEquipId and wearEquipId and self.SelectEquipId ~= wearEquipId then
        self.DetailEquipId1 = self.SelectEquipId
        self.DetailEquipId2 = wearEquipId
        isCompare = true
    else
        self.DetailEquipId1 = self.SelectEquipId or wearEquipId
        self.DetailEquipId2 = nil
    end
    self:UpdateOneEquipDetail(1, self.DetailEquipId1, wearEquipId, isCompare)
    self:UpdateOneEquipDetail(2, self.DetailEquipId2, wearEquipId, isCompare)

    -- 刷新模型
    self:UpdateModel(self.DetailEquipId1)
end

-- 刷新一个装备详情
function XTeamPrefabEquipAwarenessReplace:UpdateOneEquipDetail(equipIndex, equipId, wearEquipId, isCompare)
    local uiObj = equipIndex == 1 and self.EquipDetail1 or self.EquipDetail2
    local isShow = equipId ~= nil

    -- 播放动画
    if equipIndex == 1 then
        uiObj.gameObject:SetActiveEx(isShow)
    else
        if isShow ~= self.IsDetail2Show then
            self.IsDetail2Show = isShow
            if isShow then
                uiObj.gameObject:SetActiveEx(true)
                self:PlayAnimation("EquipDetail2Enable")
                self.CompareEffect.gameObject:SetActive(false)
                self.CompareEffect.gameObject:SetActive(true)

            else
                self:PlayAnimation("EquipDetail2Disable", function()
                    uiObj.gameObject:SetActiveEx(false)
                end)
            end
        elseif isShow then
            self:PlayAnimation("EquipDetail2QieHuan")
            self.CompareEffect.gameObject:SetActive(false)
            self.CompareEffect.gameObject:SetActive(true)
        end
    end

    if not isShow then 
        return 
    end

    -- 刷新面板
    local equip = XMVCA.XEquip:GetEquip(equipId)
    local isWear = equipId == wearEquipId
    local icon = XMVCA.XEquip:GetEquipIconPath(equip.TemplateId, equip.Breakthrough)
    uiObj:GetObject("RImgIcon"):SetRawImage(icon)
    local name = XMVCA.XEquip:GetEquipName(equip.TemplateId)
    uiObj:GetObject("TxtName").text = name
    uiObj:GetObject("TxtLv").text = equip.Level

    -- 意识属性
    local attrMap = XMVCA.XEquip:GetEquipAttrMap(equipId)
    for i = 1, XEnumConst.EQUIP.MAX_ATTR_COUNT do
        local attrInfo = attrMap[i]
        local isShow = attrInfo ~= nil
        uiObj:GetObject("PanelAttr" .. i).gameObject:SetActiveEx(isShow)
        if isShow then
            uiObj:GetObject("TxtName" .. i).text = attrInfo.Name
            uiObj:GetObject("TxtAttr" .. i).text = attrInfo.Value
        end
    end

    -- 套装技能
    local suitId = XMVCA.XEquip:GetEquipSuitId(equip.TemplateId)
    -- 从预设中获取当前穿戴的套装激活数量
    local activeCount = 0
    local awarenessData = self.TeamPrefab:GetAllAwarenessData(self.CurrentPos)
    if awarenessData then
        for slot, data in pairs(awarenessData) do
            if data and data.EquipId then
                local equipInPrefab = XMVCA.XEquip:GetEquip(data.EquipId)
                if equipInPrefab then
                    local suitIdInPrefab = XMVCA.XEquip:GetEquipSuitId(equipInPrefab.TemplateId)
                    if suitIdInPrefab == suitId and (not isCompare or slot ~= self.SelectSite) then
                        activeCount = activeCount + 1
                    end
                end
            end
        end
    end
    
    -- 如果是比较状态且不是当前穿戴的装备，预览穿上后的效果
    if isCompare and not isWear then
        activeCount = activeCount + 1
    end

    local isOverrun = XMVCA.XEquip:IsCharacterOverrunSuit(self.CharacterId, suitId)
    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId, activeCount, isOverrun, isOverrun)
    for i = 1, XEnumConst.EQUIP.MAX_SUIT_SKILL_COUNT do
        local skillInfo = skillDesList[i]
        local isShow = skillInfo ~= nil
        local txtSkillDes = uiObj:GetObject("TxtSkillDes" .. i)
        txtSkillDes.gameObject:SetActiveEx(isShow)
        if isShow then
            local color = self.SKILL_DES_COLOR[skillInfo.IsActive]
            txtSkillDes.text = skillInfo.SkillDes
            txtSkillDes.color = color
            local txtPos = uiObj:GetObject("TxtPos" .. i)
            txtPos.color = color
        end
    end

    -- 共鸣
    local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(equip.TemplateId)
    uiObj:GetObject("PanelResonanceTitle").gameObject:SetActiveEx(canResonance)
    uiObj:GetObject("PanelResonance").gameObject:SetActiveEx(canResonance)
    if canResonance then
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local resonanceUiObj = uiObj:GetObject("ResonanceSkill" .. pos)
            self:UpdateResonanceSkill(equipIndex, resonanceUiObj, equipId, pos)
        end
    end

    -- 按钮
    -- 在比较2件装备时，当前穿戴的装备不显示穿戴/卸下按钮，显示“当前装备”
    local showCurWear = isCompare and isWear
    uiObj:GetObject("PanelCurrentEquipment").gameObject:SetActiveEx(showCurWear)
    uiObj:GetObject("BtnStrengthen").gameObject:SetActiveEx(not showCurWear and not self.NotShowStrengthenBtn)
    uiObj:GetObject("BtnTakeOff").gameObject:SetActiveEx(not showCurWear and isWear)
    uiObj:GetObject("BtnPutOn").gameObject:SetActiveEx(not showCurWear and not isWear)
end

-- 刷新单个意识共鸣
function XTeamPrefabEquipAwarenessReplace:UpdateResonanceSkill(equipIndex, resonanceUiObj, equipId, pos)
    local isEquip = XMVCA.XEquip:CheckEquipPosResonanced(equipId, pos) ~= nil
    local panelNoResnoance = resonanceUiObj:GetObject("PanelNoResnoance")
    panelNoResnoance.gameObject:SetActive(not isEquip)

    local skillGo = resonanceUiObj:GetObject("GridResnanceSkill")
    skillGo.gameObject:SetActive(isEquip)

    if isEquip then
        self.ResonanceSkillDic = self.ResonanceSkillDic or {}
        local hashCode = skillGo.transform:GetHashCode()
        local grid = self.ResonanceSkillDic[hashCode]
        if not grid then
            local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
            grid = XUiGridResonanceSkill.New(skillGo, equipId, pos, self.CharacterId, nil, nil, self.ForceShowBindCharacter)
            self.ResonanceSkillDic[hashCode] = grid
        end
        grid:SetEquipIdAndPos(equipId, pos)
        grid:Refresh()
    end
end

-- 点击意识共鸣//预设禁用培养功能
function XTeamPrefabEquipAwarenessReplace:OnBtnResonanceSkill()
end

-- 刷新模型
function XTeamPrefabEquipAwarenessReplace:UpdateModel(modelEquipId)
    if not modelEquipId then
        self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
        return
    end

    self:ReleaseModel()
    local equip = XMVCA.XEquip:GetEquip(modelEquipId)
    local resPath = XMVCA.XEquip:GetEquipLiHuiPath(equip.TemplateId, equip.Breakthrough)
    self.Loader = self.Loader or self.Transform:GetLoader()
    local texture = self.Loader:Load(resPath)
    self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
    self.ModelEquipId = modelEquipId

    local delayTime = self.IsEnableShow and 500 or 300
    self.IsEnableShow = false
    self:ReleaseLihuiTimer()
    self.FxUiLihuiChuxian01.gameObject:SetActive(false)
    self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
        self.FxUiLihuiChuxian01.gameObject:SetActive(true)
        self.LihuiTimer = nil
    end, delayTime)
end

-- 释放模型
function XTeamPrefabEquipAwarenessReplace:ReleaseModel()
end

-- 释放定时器
function XTeamPrefabEquipAwarenessReplace:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

return XTeamPrefabEquipAwarenessReplace
