---@class XUiTeamRecommendMain : XLuaUi
---@field MyChoiceGrid XUiGridTRMyChoice
local XUiTeamRecommendMain = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendMain")

local StageTypeBySubTabIndex = {
    [1] = XEnumConst.FuBen.StageType.BossSingle,
    [2] = XEnumConst.FuBen.StageType.Arena,
}

local StageTypeSubTabStartIndex = 2

local FormationType = {
    Attr = 1, -- 属性
    Gen = 2, -- 效应
}

-- 本次登录内记住上次离开时的页签，不落本地存档。
local LastTabState = {
    LeftTabIndex = XEnumConst.TeamRecommend.MainTabIndex.Character,
    StageType = XEnumConst.FuBen.StageType.BossSingle,
    FormationTabIndex = 1,
}

--region ========== 生命周期 ==========

function XUiTeamRecommendMain:OnAwake()
    self:InitButton()
    self:InitTabGroup()
    self:InitDynamicTable()
    self:InitMyChoiceGrid()
end

--- 入口：OpenUi("UiTeamRecommendMain", characterId, leftTabIndex)
---@param leftTabIndex number|nil XEnumConst.TeamRecommend.MainTabIndex；不传则恢复本次登录内上次页签
function XUiTeamRecommendMain:OnStart(characterId, leftTabIndex)
    self.CharacterId = characterId
    self.TeamFormationPreloadRequestIndex = 0
    self.IsTeamFormationPreloadDone = false

    self.CurLeftTabIndex = leftTabIndex or LastTabState.LeftTabIndex
    self.CurStageType = LastTabState.StageType
    self.CurFormationTabIndex = LastTabState.FormationTabIndex
    self.CurFormationType = self.CurFormationTabIndex

    local roleName = XMVCA.XCharacter:GetCharacterFullNameStr(self.CharacterId)
    if self.TxtCharRoleName then self.TxtCharRoleName.text = roleName end
    if self.TxtTeamRoleName then self.TxtTeamRoleName.text = roleName end
    self.BtnFirstHasSnd:ShowTag(not XSaveTool.GetData(string.format("UiTeamRecommendMain_BtnFirstHasSnd_New_V4P8_%s", XPlayer.Id)))
    local leftSelectIndex = self.CurLeftTabIndex
    if self.CurLeftTabIndex == XEnumConst.TeamRecommend.MainTabIndex.Formation then
        leftSelectIndex = self.CurStageType == XEnumConst.FuBen.StageType.Arena and 4 or 3
    end
    self.PanelTabLeft:SelectIndex(leftSelectIndex)
    self:RequestAllTeamFormationList()
end

function XUiTeamRecommendMain:OnEnable()
    self:RefreshCurTab()
end

function XUiTeamRecommendMain:OnDisable()
end

function XUiTeamRecommendMain:OnDestroy()
end

--endregion ========== 生命周期 ==========

--region ========== 初始化 ==========

function XUiTeamRecommendMain:InitButton()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnGetMore.CallBack = function()
        local KujiequGuideUrlId = 18 -- UrlConfig表Id：库街区攻略
        XMVCA.XUrl:SkipByUrlId(KujiequGuideUrlId)
    end
    self:BindHelpBtn(self.BtnHelp, "OneClickCultivationRule")
end

function XUiTeamRecommendMain:InitTabGroup()
    -- 左侧Tab：1-2=主Tab(SubGroupIndex=0), 3-4=玩法StageType子按钮(SubGroupIndex=2,指向主Tab2)
    local tabBtnList = self.PanelTabLeft.TabBtnList
    if tabBtnList[2] then tabBtnList[2].SubGroupIndex = XEnumConst.TeamRecommend.MainTabIndex.Formation end
    if tabBtnList[3] then tabBtnList[3].SubGroupIndex = XEnumConst.TeamRecommend.MainTabIndex.Formation end

    self.PanelTabLeft:Init(XTool.CsList2LuaTable(tabBtnList), function(index)
        self:OnSelectLeftTab(index)
    end)

    -- 有子页签的主按钮改为定位到当前子页签，避免重复点击时被ButtonGroup折叠。
    self.BtnFirstHasSnd.ButtonGroup = nil
    self.BtnFirstHasSnd.CallBack = function()
        local subTabIndex = self.CurStageType == XEnumConst.FuBen.StageType.Arena and 4 or 3
        self.PanelTabLeft:SelectIndex(subTabIndex)
    end

    -- 右侧二级Tab（FormationType: 1=属性, 2=效应）
    local rightBtnList = self.PanelTabRight.TabBtnList
    self.PanelTabRight:Init(XTool.CsList2LuaTable(rightBtnList), function(index)
        self:OnSelectRightTab(index)
    end)
end

function XUiTeamRecommendMain:InitDynamicTable()
    -- Tab1 角色列表
    local XUiGridTRCharTargetCard = require("XUi/XUiTeamRecommend/Grid/XUiGridTRCharTargetCard")
    self.CharDynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelCharInfoList, XUiGridTRCharTargetCard)
    self.CharDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnCharDynamicTableEvent(event, index, grid)
    end)
    self.CharDynamicTable:GetGrid().gameObject:SetActiveEx(false)

    -- Tab2 阵容列表
    local XUiGridTRFormation = require("XUi/XUiTeamRecommend/Grid/XUiGridTRFormation")
    self.TeamDynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelTeamList, XUiGridTRFormation)
    self.TeamDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnTeamDynamicTableEvent(event, index, grid)
    end)
    self.TeamDynamicTable:GetGrid().gameObject:SetActiveEx(false)
end

function XUiTeamRecommendMain:InitMyChoiceGrid()
    local XUiGridTRMyChoice = require("XUi/XUiTeamRecommend/Grid/XUiGridTRMyChoice")
    self.MyChoiceGrid = XUiGridTRMyChoice.New(self.GridMyChoice, self)
    self.MyChoiceGrid:Close()
end

--endregion ========== 初始化 ==========

--region ========== Tab 切换 ==========

--- 刷新当前Tab数据（OnEnable等场景，只刷数据不改变按钮选中态）
function XUiTeamRecommendMain:RefreshCurTab()
    self:RefreshTabPanel()
    if self.CurLeftTabIndex == XEnumConst.TeamRecommend.MainTabIndex.Character then
        self:RefreshCharList()
    else
        self:RefreshTeamList()
    end
end

function XUiTeamRecommendMain:RefreshTabPanel()
    local isCharTab = self.CurLeftTabIndex == XEnumConst.TeamRecommend.MainTabIndex.Character
    self.UiPanelCharInfo.gameObject:SetActiveEx(isCharTab)
    self.UiPanelTeam.gameObject:SetActiveEx(not isCharTab)
end

--- 左侧Tab回调（1-2=主Tab, 3-4=玩法StageType子按钮）
--- 框架行为：点击有子按钮的主Tab2时，框架只展开子按钮并触发第一个子按钮的回调(index=3)，不会触发主Tab自身回调(index=2)；选主Tab1时自动收起子按钮
function XUiTeamRecommendMain:OnSelectLeftTab(index)
    if index <= XEnumConst.TeamRecommend.MainTabIndex.Formation then
        -- 主Tab
        self.CurLeftTabIndex = index
        self:RefreshTabPanel()

        if index == XEnumConst.TeamRecommend.MainTabIndex.Character then
            self:RefreshCharList()
        end
        self.CharDynamicTable:SetActive(true)
        self.TeamDynamicTable:SetActive(false)
    else
        -- 子按钮（StageType: index 3→BossSingle, index 4→Arena）
        -- 点击主Tab2展开子按钮后，框架自动选中第一个子按钮，实际从这里进入阵容Tab
        self.CurLeftTabIndex = XEnumConst.TeamRecommend.MainTabIndex.Formation
        self:RefreshTabPanel()
        self.CurStageType = StageTypeBySubTabIndex[index - StageTypeSubTabStartIndex]
        self.PanelTabRight:SelectIndex(self.CurFormationTabIndex)
        self:RefreshTeamList()
        self.CharDynamicTable:SetActive(false)
        self.TeamDynamicTable:SetActive(true)
    end

    LastTabState.LeftTabIndex = self.CurLeftTabIndex
    LastTabState.StageType = self.CurStageType

    -- 进入阵容Tab（主Tab2或其StageType子按钮）即视为已读，隐藏主Tab2的新标签
    if index >= XEnumConst.TeamRecommend.MainTabIndex.Formation then
        local saveKey = string.format("UiTeamRecommendMain_BtnFirstHasSnd_New_V4P8_%s", XPlayer.Id)
        if not XSaveTool.GetData(saveKey) then XSaveTool.SaveData(saveKey, true) end
        self.BtnFirstHasSnd:ShowTag(false)
    end
end

--- 右侧二级Tab切换（FormationType: 1=属性, 2=效应）
function XUiTeamRecommendMain:OnSelectRightTab(index)
    self.CurFormationTabIndex = index
    self.CurFormationType = index -- 当前FormationType业务值和Tab下标一致，直接赋值
    LastTabState.FormationTabIndex = index
    self:RefreshTeamList()
end

--endregion ========== Tab 切换 ==========

--region ========== Tab1（按角色）刷新 ==========

function XUiTeamRecommendMain:RefreshCharList()
    local baseCharacterList = XMVCA.XTeamRecommend:GetBaseCharacterListByCharacterId(self.CharacterId)
    -- 转换为归一化数据
    self.CharDataList = {}
    for _, cfg in ipairs(baseCharacterList) do
        local recommendCharData = XMVCA.XTeamRecommend:FromCfgData(cfg)
        if recommendCharData then
            table.insert(self.CharDataList, recommendCharData)
        end
    end
    -- 查询目标名称列表（按index对齐）
    self.CharTargetNames = XMVCA.XTeamRecommend:GetCharacterTargetNames(self.CharacterId)
    self.CharDynamicTable:SetDataSource(self.CharDataList)
    self.CharDynamicTable:ReloadDataSync()
end

function XUiTeamRecommendMain:OnCharDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local recommendCharData = self.CharDataList and self.CharDataList[index]
        local targetName = self.CharTargetNames and self.CharTargetNames[index]
        local isShowSixStarWeaponTag = true
        grid:Refresh(recommendCharData, targetName, isShowSixStarWeaponTag)
    end
end

--endregion ========== Tab1（按角色）刷新 ==========

--region ========== Tab2（按阵容）刷新 ==========

function XUiTeamRecommendMain:RefreshTeamList()
    local gridList = XMVCA.XTeamRecommend:BuildFormationGridList(self.CurStageType, self.CurFormationType, self.CharacterId)
    self:ApplyTeamDataList(gridList)
end

function XUiTeamRecommendMain:OnTeamDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local formationGridData = self.TeamDataList and self.TeamDataList[index]
        grid:Refresh(formationGridData, self.CharacterId)
    end
end

--endregion ========== Tab2（按阵容）刷新 ==========

--region ========== 目标协议 ==========

function XUiTeamRecommendMain:ApplyTeamDataList(gridList)
    self.TeamDataList = gridList
    self.TeamDynamicTable:SetDataSource(gridList)
    self.TeamDynamicTable:ReloadDataSync()
    self:RefreshMyChoiceGrid()
end

function XUiTeamRecommendMain:RequestAllTeamFormationList()
    if self.IsTeamFormationPreloadDone then
        return
    end

    local teamCfgIds = self:GetAllVisibleTeamCfgIds()
    if #teamCfgIds <= 0 then
        return
    end
    if XMVCA.XTeamRecommend:AreServerFormationDatasRequested(self.CharacterId, teamCfgIds) then
        self.IsTeamFormationPreloadDone = true
        return
    end

    self.IsTeamFormationPreloadDone = true
    self.TeamFormationPreloadRequestIndex = self.TeamFormationPreloadRequestIndex + 1
    local requestIndex = self.TeamFormationPreloadRequestIndex

    XMVCA.XTeamRecommend:TeamRecommendFormationRequest(self.CharacterId, teamCfgIds, function(success)
        if requestIndex ~= self.TeamFormationPreloadRequestIndex then
            return
        end

        if not success or XTool.UObjIsNil(self.GameObject) then
            return
        end

        self:RefreshTeamList()
    end)
end

function XUiTeamRecommendMain:GetAllVisibleTeamCfgIds()
    local result = {}
    local teamCfgIdMap = {}

    for _, stageType in ipairs(StageTypeBySubTabIndex) do
        for _, formationType in pairs(FormationType) do
            local gridList = XMVCA.XTeamRecommend:BuildFormationGridList(stageType, formationType, self.CharacterId)
            for _, gridData in ipairs(gridList or {}) do
                local formationCfg = gridData and gridData.Formation
                local teamCfgId = formationCfg and formationCfg.Id
                if XTool.IsNumberValid(teamCfgId) and not teamCfgIdMap[teamCfgId] then
                    teamCfgIdMap[teamCfgId] = true
                    table.insert(result, teamCfgId)
                end
            end
        end
    end

    table.sort(result)
    return result
end

function XUiTeamRecommendMain:RefreshMyChoiceGrid()
    local formationGridData = XMVCA.XTeamRecommend:BuildFormationTargetGridData(self.CharacterId)
    if formationGridData then
        self.MyChoiceGrid:Refresh(formationGridData)
    else
        self.MyChoiceGrid:Close()
    end
end

function XUiTeamRecommendMain:OnTeamRecommendCharSetTarget(recommendCharData)
    local baseCfgId = recommendCharData and recommendCharData.BaseCfgId
    local characterId = recommendCharData and recommendCharData.CharacterId
    if not XTool.IsNumberValid(baseCfgId) or not XTool.IsNumberValid(characterId) then XLog.Error("[XUiTeamRecommendMain] BaseCfgId or CharacterId is invalid") return end

    XMVCA.XTeamRecommend:TeamRecommendSetTargetRequest(characterId, baseCfgId, function()
        if self:IsReturnToRoleTargetDetail() then
            self:Close()
        else
            XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", characterId)
        end
    end)
end

-- 为了避免跳转嵌套严重，当Main界面上一个界面是RoleTargetDetail时，直接关闭Main界面天然复用
function XUiTeamRecommendMain:IsReturnToRoleTargetDetail()
    local mainUiName = "UiTeamRecommendMain"
    local roleTargetDetailUiName = "UiTeamRecommendRoleTargetDetail"
    local uiList = CS.XUiManager.Instance:GetAllList()
    local mainIndex = -1
    for i = uiList.Count - 1, 0, -1 do
        local uiData = uiList[i].UiData
        if uiData.UiType == CS.XUiType.Normal and uiData.UiName == mainUiName and uiList[i].IsEnable then
            mainIndex = i
            break
        end
    end
    if mainIndex < 0 then
        return false
    end
    for i = mainIndex - 1, 0, -1 do
        local uiData = uiList[i].UiData
        if uiData.UiType == CS.XUiType.Normal then
            return uiData.UiName == roleTargetDetailUiName
        end
    end
    return false
end

--endregion ========== 目标协议 ==========

return XUiTeamRecommendMain
