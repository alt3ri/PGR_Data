
local XUiTeamPrefabMain = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabMain")

function XUiTeamPrefabMain:OnAwake()
    self.CurSelectGrid = nil -- 保存当前选中的 Grid
    self.CurSelectIndex = 1
    self.CurDragCardIndex = nil
    self.CurDragCopyGo = nil
    ---@type XUiPanelCharacterCard[]
    self.CharacterCardList = {}
    -- Tag 筛选状态
    self.FilterTags = {}
    self.IsFiltering = false
    self.DisplayList = {}

    self:InitDyanamicTable()
    self:InitCharacterCard()
    self:InitButton()
    self:InitTagDetailPool()
    XSaveTool.SaveData("HasNeverOpenTeamPrefabV4P0"..XPlayer.Id, 1)
end

function XUiTeamPrefabMain:InitDyanamicTable()
    local XUiDYTGridTeamPrefab = require("XUi/XUiTeamPrefab/XUiTeamPrefabMain/Grid/XUiDYTGridTeamPrefab")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.TeamPefabList, XUiDYTGridTeamPrefab)
end

function XUiTeamPrefabMain:InitCharacterCard()
    local XUiPanelCharacterCard = require("XUi/XUiTeamPrefab/XUiTeamPrefabMain/Grid/XUiPanelCharacterCard")
    local memberCount = self.TeamList.childCount
    for i = 1, memberCount do
        local cardTrans = self["CharacterCard"..i]
        local XPanelCard = XUiPanelCharacterCard.New(cardTrans, self, i)
        self.CharacterCardList[i] = XPanelCard
        cardTrans:AddBeginDragListener(function() self:OnCharacterCardBeginDrag(i) end)
        cardTrans:AddDragListener(function() self:OnCharacterCardDrag(i) end)
        cardTrans:AddEndDragListener(function() self:OnCharacterCardEndDrag(i) end)
    end
end

local TempV2 = Vector2(0, 0)
function XUiTeamPrefabMain:OnCharacterCardBeginDrag(index)
    if self.CurDragCopyGo then
        return
    end

    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    local charId = curTeamPrefabEntity:GetEntityIdByTeamPos(index)
    if not XTool.IsNumberValid(charId) then
        return
    end

    if self.DragMask then
        self.DragMask.gameObject:SetActiveEx(true)
    end

    local xCard = self.CharacterCardList[index]
    -- 跟随鼠标的Panel
    xCard.SA_ImgStaticBack.gameObject:SetActiveEx(false)
    xCard.SA_ImgSelect.gameObject:SetActiveEx(false)
    xCard.SA_ImgShadow.gameObject:SetActiveEx(true)
    xCard.SA_ImgColourSelect.gameObject:SetActiveEx(true)
    xCard.SA_PanelWithOutDragControl.gameObject:SetActiveEx(true)
    xCard.SA_ImgSelectGray.gameObject:SetActiveEx(true)
    self.CurDragCardIndex = index
    self.CurDragCopyGo = XUiHelper.Instantiate(xCard.GameObject)
    self.CurDragCopyGo.transform:SetParent(xCard.Transform.parent.parent.parent)
    self.CurDragCopyGo.transform.localScale = Vector3.one
    self.CurDragCopyGo.transform:SetAsLastSibling()
    -- 被拖但在原地不动的Panel
    xCard.SA_ImgStaticBack.gameObject:SetActiveEx(true)
    xCard.SA_ImgShadow.gameObject:SetActiveEx(false)
    xCard.SA_ImgColourSelect.gameObject:SetActiveEx(false)
    xCard.SA_PanelWithOutDragControl.gameObject:SetActiveEx(false)
    xCard.SA_ImgSelectGray.gameObject:SetActiveEx(false)
end

function XUiTeamPrefabMain:OnCharacterCardDrag(index)
    if not self.CurDragCopyGo then
        return
    end
    self.Camera = self.Camera or self.Transform:GetComponent("Canvas").worldCamera
    local pos = XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
    self.CurDragCopyGo.transform.localPosition = pos

    -- 转换成屏幕坐标检测 hover
    local screenPoint = self.Camera:WorldToScreenPoint(self.CurDragCopyGo.transform.position)
    TempV2.x = screenPoint.x
    TempV2.y = screenPoint.y
    local screenPointV2 = TempV2

    local hoverIndex = self:GetHoverCardIndex(screenPointV2)
    for posInCards, xCard in ipairs(self.CharacterCardList) do
        xCard.SA_ImgSelect.gameObject:SetActiveEx(hoverIndex == posInCards and hoverIndex ~= index)
    end
end

function XUiTeamPrefabMain:OnCharacterCardEndDrag(index)
    if not self.CurDragCopyGo then
        return
    end

    if self.DragMask then
        self.DragMask.gameObject:SetActiveEx(false)
    end

    local curDragCard = self.CharacterCardList[self.CurDragCardIndex]
    local screenPoint = self.Camera:WorldToScreenPoint(self.CurDragCopyGo.transform.position)
    TempV2.x = screenPoint.x
    TempV2.y = screenPoint.y
    local screenPointV2 = TempV2

    local hoverIndex = self:GetHoverCardIndex(screenPointV2)
    if hoverIndex and hoverIndex ~= index then
        local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
        curTeamPrefabEntity:SwapPosData(index, hoverIndex)
        local targetCard = self.CharacterCardList[hoverIndex]
        targetCard.FxSelectFormation.gameObject:SetActiveEx(true)
        targetCard:PlayAnimation("SelectFormationEnable", function ()
            targetCard.FxSelectFormation.gameObject:SetActiveEx(false)
        end)
    end

    -- 所有的Panel取消选中状态
    for posInCards, xCard in ipairs(self.CharacterCardList) do
        xCard.SA_ImgSelect.gameObject:SetActiveEx(false)
    end

    -- 在原地的Panel还原回默认状态
    curDragCard.SA_ImgStaticBack.gameObject:SetActiveEx(false)
    curDragCard.SA_ImgSelect.gameObject:SetActiveEx(false)
    curDragCard.SA_ImgShadow.gameObject:SetActiveEx(false)
    curDragCard.SA_ImgColourSelect.gameObject:SetActiveEx(true)
    curDragCard.SA_PanelWithOutDragControl.gameObject:SetActiveEx(true)
    curDragCard.SA_ImgSelectGray.gameObject:SetActiveEx(false)
    
    self:OnlyRefreshDynamicGridData()
    self:RefreshRightInfo()
    XUiHelper.Destroy(self.CurDragCopyGo)
    self.CurDragCopyGo = nil
    self.CurDragCardIndex = nil
end

-- 返回光标落在哪个 card 上，若没有返回 nil
function XUiTeamPrefabMain:GetHoverCardIndex(screenPointV2)
    for posInCards, xCard in ipairs(self.CharacterCardList) do
        local isInside = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(xCard.Transform, screenPointV2, self.Camera)
        if isInside then
            return posInCards
        end
    end
    return nil
end

function XUiTeamPrefabMain:InitButton()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnAdd.CallBack = function() self:OnBtnAddClick() end
    self.BtnCover.CallBack = function() self:OnBtnCoverClick() end
    self.BtnDelete.CallBack = function() self:OnBtnDeleteClick() end
    self.BtnName.CallBack = function() self:OnBtnNameClick() end
    self.BtnTopUp.CallBack = function() self:OnBtnTopUpClick() end
    self.BtnUse.CallBack = function() self:OnBtnUseClick() end
    self.BtnGeneralSkillSet.CallBack = function() self:OnBtnGeneralSkillSetClick() end
    self.BtnLeaderSet.CallBack = function() self:OnBtnLeaderSetClick() end
    self.BtnAnimationSet.CallBack = function() self:OnBtnAnimationSetClick() end
    self.BtnSkipToTeamRecommendation.CallBack = function() self:OnBtnSkipToTeamRecommendationClick() end
    self.BtnFilter.CallBack = function() self:OnBtnFilterClick() end
    self.BtnTag.CallBack = function() self:OnBtnTagClick() end
    self.BtnFilter2.CallBack = function() self:OnBtnFilterClick() end
end

function XUiTeamPrefabMain:InitTagDetailPool()
    self.TagDetailPool = {}
    for i = 1, 2 do
        local go = XUiHelper.Instantiate(self.BtnTagDetail.gameObject)
        go.transform:SetParent(self.BtnTagDetail.transform.parent, false)
        go:SetActiveEx(false)

        local uiObj = go:GetComponent("UiObject")
        local item = {
            Go = go,
            NormalImgBgMode  = uiObj:GetObject("NormalImgBgMode"),
            PressImgBgMode   = uiObj:GetObject("PressImgBgMode"),
            NormalUiImgIcon  = uiObj:GetObject("NormalUiImgIcon"),
            PressUiImgIcon   = uiObj:GetObject("PressUiImgIcon"),
            BtnSelf          = uiObj:GetObject("BtnSelf"),
        }

        local btnSelf = item.BtnSelf:GetComponent("XUiButton")
        btnSelf.CallBack = handler(self, self.OnBtnTagClick)

        self.TagDetailPool[i] = item
    end

    -- 模板永久隐藏
    self.BtnTagDetail.gameObject:SetActiveEx(false)
end

function XUiTeamPrefabMain:OnBtnAddClick()
    local curListLength = #self.DynamicTable.DataSource
    local limitCount = CS.XGame.Config:GetInt("MaxTeamPrefab")
    if curListLength >= limitCount then
        XUiManager.TipText("TeamPrefabMaxCountReached")
        return
    end
    -- 新队伍预设
    local targetShowIndex = curListLength + 1
    XDataCenter.TeamManager.TeamPrefabAddRequestV4P0(function() 
        self.CurSelectIndex = targetShowIndex
        self:RefreshTeamPrefabListDynamicTable(targetShowIndex)
    end)
end

function XUiTeamPrefabMain:OnBtnDeleteClick()
    local totalCount = #XDataCenter.TeamManager.GetTeamPrefabList()
    if totalCount <= 1 then
        XUiManager.TipText("TeamPrefabCannotDeleteLast")
        return
    end

    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    local deleteXTeamId = curTeamPrefabEntity:GetId()
    local displayCount = #self.DisplayList
    local targetShowIndex = self.CurSelectIndex >= displayCount and math.max(displayCount - 1, 1) or self.CurSelectIndex
    local title = CS.XTextManager.GetText("TipTitle")
    XLuaUiManager.Open("UiDialog", title, XUiHelper.GetText("TeamPrefabDeleteConfirm", curTeamPrefabEntity:GetName()), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.TeamManager.TeamPrefabDelRequest(deleteXTeamId, function() 
            self.CurSelectIndex = targetShowIndex
            self:RefreshTeamPrefabListDynamicTable(targetShowIndex)
            XUiManager.TipText("TeamPrefabDeleteSuccess")
        end)
    end)
end

-- 将当前真实队伍的数据更新到当前选中的预设队伍
function XUiTeamPrefabMain:OnBtnCoverClick()
    if self.ForbiddenRealTeamOperate then
        XUiManager.TipText("RoomTeamPrefabNotSupport")
        return
    end

    if not self.XRealTeam then
        XUiManager.TipText("RoomTeamPrefabNotSupport")
        return
    end

    if self.XRealTeam:GetIsEmpty() then
        XUiManager.TipText("TeamPrefabCannotCoverEmptyTeam")
        return
    end
    
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    XLuaUiManager.Open("UiTeamPrefabPopupCover", self.XRealTeam, curTeamPrefabEntity, function ()
        self:RefreshTeamPrefabListDynamicTable(self.CurSelectIndex)
        XUiManager.TipText("TeamPrefabCoverSuccess")
    end)
end

function XUiTeamPrefabMain:OnBtnUseClick()
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    if curTeamPrefabEntity:GetIsEmpty() then
        XUiManager.TipText("TeamPrefabNoMembers")
        return
    end

    -- 武器存在性冲突检测（最优先）
    local function CheckWeaponExistConflictAndConfirm()
        local isWeaponExistConflict = false
        for pos, v in ipairs(self.CharacterCardList) do
            if v:GetIsWeaponExsitConflict() then
                isWeaponExistConflict = true
                break
            end
        end
        
        if isWeaponExistConflict then
            XUiManager.TipMsg(CS.XTextManager.GetText("TeamPrefabWeaponNotExistConflict"))
            return false
        end

        return true
    end

    -- 最终执行应用
    local function ApplyTeamPrefab()
        XDataCenter.TeamManager.TeamPrefabApplyRequest(curTeamPrefabEntity:GetId(), function ()
            if self.XRealTeam then
                curTeamPrefabEntity:CoverToRealTeamData(self.XRealTeam)
            else
                -- 有些旧界面数据如多队伍战斗依赖这个EVENT_TEAM_PREFAB_SELECT
                local teamData = {}
                teamData.CaptainPos = curTeamPrefabEntity:GetCaptainPos()
                teamData.FirstFightPos = curTeamPrefabEntity:GetFirstFightPos()
                teamData.EnterCgIndex = curTeamPrefabEntity:GetEnterCgIndex()
                teamData.SettleCgIndex = curTeamPrefabEntity:GetSettleCgIndex()
                teamData.SelectedGeneralSkill = curTeamPrefabEntity:GetCurGeneralSkill()
                teamData.TeamData = XTool.Clone(curTeamPrefabEntity:GetEntityIds())
                XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_SELECT, teamData)
            end
            self:Close()
        end)
    end

    -- 辅助机冲突检测
    local function CheckPartnerConflictAndConfirm()
        local entityIds = curTeamPrefabEntity:GetEntityIds()
        local teamPrefabPartnerData = curTeamPrefabEntity:GetPartnerData()
        local partnerConflict = false
        for pos, charId in ipairs(entityIds) do
            local partnerId = teamPrefabPartnerData:GetPartnerIdByPos(pos)
            if XTool.IsNumberValid(partnerId) then
                local realPartner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
                local isCarring = realPartner:GetIsCarry() and realPartner:GetCharacterId() ~= charId
                if isCarring or teamPrefabPartnerData:IsSkillChangeWithPrefab2Group(partnerId) then
                    partnerConflict = true
                    break
                end
            end
        end

        if partnerConflict then
            XLuaUiManager.Open("UiPartnerPresetPopup", self.XRealTeam, curTeamPrefabEntity, false, function ()
                ApplyTeamPrefab()
            end)
        else
            ApplyTeamPrefab()
        end
    end

    -- 欲穿戴武器意识当前有真正的角色正在穿戴的冲突检测
    local function CheckEquipConflictAndConfirm()
        local maxPos = XDataCenter.TeamManager.GetMaxPos()
        local isEquipConflict = false
        for pos = 1, maxPos do
            local curPosCharId = curTeamPrefabEntity:GetEntityIdByTeamPos(pos)
            local weapon = curTeamPrefabEntity:GetWeaponData(pos)
            if weapon and weapon.EquipId then
                local xEquip = XMVCA.XEquip:GetEquip(weapon.EquipId)
                if XTool.IsNumberValid(xEquip.CharacterId) and xEquip.CharacterId ~= curPosCharId then
                    isEquipConflict = true
                    break
                end
            end
            local awarenessList = curTeamPrefabEntity:GetAllAwarenessData(pos)
            if awarenessList then
                for _, v in pairs(awarenessList) do
                    if v.EquipId then
                        local xEquip = XMVCA.XEquip:GetEquip(v.EquipId)
                        if XTool.IsNumberValid(xEquip.CharacterId) and xEquip.CharacterId ~= curPosCharId then
                            isEquipConflict = true
                            break
                        end
                    end
                end
            end
            if isEquipConflict then break end
        end

        if isEquipConflict then
            XLuaUiManager.Open("UiDialog", XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("TeamPrefabEquipmentInUse"),
                XUiManager.DialogType.Normal, nil, function ()
                    CheckPartnerConflictAndConfirm()
                end)
        else
            CheckPartnerConflictAndConfirm()
        end
    end

    -- 武器共鸣与谐振冲突检测（②共鸣数量 ③谐振 ④共鸣技能绑定）
    local function CheckResonanceAndOverrunConflictAndConfirm()
        local isResonanceOrOverrunConflict = false
        local conflictPosList = {}
        for pos, v in ipairs(self.CharacterCardList) do
            if v:GetIsWeaponResonanceCountConflict() or v:GetIsWeaponOverrunConflict() or v:GetIsWeaponResonanceSkillNeedConfirm() then
                isResonanceOrOverrunConflict = true
                table.insert(conflictPosList, pos)
            end
        end
        
        if isResonanceOrOverrunConflict then
            XLuaUiManager.Open("UiDialog", XUiHelper.GetText("TipTitle"),
            XUiHelper.GetText("TeamPrefabEquipConflictConfirm"),
            XUiManager.DialogType.Normal, nil, function ()
                if not XTool.IsTableEmpty(conflictPosList) then
                    -- 点击确认，用实际装备数据覆盖预设中的共鸣与谐振数据
                    -- 每个冲突位都要单独发一次 TeamPrefabUpdateEquipRequest，串行执行避免并发覆盖
                    local function SyncNextConflictPos(conflictIndex)
                        if conflictIndex > #conflictPosList then
                            CheckEquipConflictAndConfirm()
                            return
                        end
                        local pos = conflictPosList[conflictIndex]
                        local charId = curTeamPrefabEntity:GetEntityIdByTeamPos(pos)
                        local curCharUsingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(charId)
                        curTeamPrefabEntity:CopyRealWeaponData(curCharUsingWeaponId, pos, false, function()
                            SyncNextConflictPos(conflictIndex + 1)
                        end)
                    end
                    SyncNextConflictPos(1)
                else
                    CheckEquipConflictAndConfirm()
                end
            end)
        else
            -- 无弹窗时，静默修复共鸣数量与谐振数据
            for pos, v in ipairs(self.CharacterCardList) do
                local charId = curTeamPrefabEntity:GetEntityIdByTeamPos(pos)
                if XTool.IsNumberValid(charId) then
                    if v:GetIsWeaponResonanceCountConflict() then
                        local weaponId = curTeamPrefabEntity:GetWeaponData(pos).EquipId
                        local xEquip = XMVCA.XEquip:GetEquip(weaponId)
                        local resDic = xEquip:GetResonanceInfoDic()
                        curTeamPrefabEntity:CopyRealWeaponResonance(XTool.Clone(resDic), pos)
                    end
    
                    if v:GetIsWeaponOverrunConflict() then
                        local weaponId = curTeamPrefabEntity:GetWeaponData(pos).EquipId
                        local xEquip = XMVCA.XEquip:GetEquip(weaponId)
                        curTeamPrefabEntity:CopyRealWeaponWeaponOverrunSuitId(xEquip:GetOverrunChoseSuit(), pos)
                    end
                end
            end

            CheckEquipConflictAndConfirm()
        end
    end

    -- 优先执行武器存在性冲突检测
    if not CheckWeaponExistConflictAndConfirm() then
        return
    end
    
    -- 继续原有的检测流程
    CheckResonanceAndOverrunConflictAndConfirm()
end

function XUiTeamPrefabMain:OnBtnNameClick()
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    XLuaUiManager.Open("UiTeamPrefabPopupRename", function (newName)
        curTeamPrefabEntity:UpdateTeamName(newName, function ()
            self:OnlyRefreshDynamicGridData()
            self:RefreshRightInfo()
        end)
    end)
end

function XUiTeamPrefabMain:OnBtnTopUpClick()
    if self.CurSelectIndex == 1 then
        XUiManager.TipText("TeamPrefabPositionFirst")
        return
    end

    local teamId = self:GetCurTeamPrefabEntity():GetId()
    local targetShowIndex = self.CurSelectIndex - 1
    XDataCenter.TeamManager.TeamPrefabMoveForwardRequest(teamId, function ()
        self.CurSelectIndex = targetShowIndex
        self:RefreshTeamPrefabListDynamicTable(targetShowIndex)
        XUiManager.PopupLeftTip(XUiHelper.GetText("TeamPrefabAdjustSuccess"))
    end)
end

function XUiTeamPrefabMain:OnBtnGeneralSkillSetClick()
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    local oldGeneralSkillId = curTeamPrefabEntity:GetCurGeneralSkill()
    if not XTool.IsNumberValid(oldGeneralSkillId) then
        XUiManager.TipText("TeamPrefabNoActivableEffect")
        return
    end

    XLuaUiManager.OpenWithCloseCallback('UiBattleRoomGeneralSkillSelect', function()
        local newGeneralSkillId = curTeamPrefabEntity:GetCurGeneralSkill()
        if oldGeneralSkillId ~= newGeneralSkillId then
            XUiManager.PopupLeftTip(XUiHelper.GetText("TeamPrefabEffectSwitchSuccess"))
        end

        self:RefreshRightInfo()
    end, nil, curTeamPrefabEntity)
end

function XUiTeamPrefabMain:OnBtnLeaderSetClick()
    local characterViewModelDic = {}
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    local entitys = curTeamPrefabEntity:GetEntityIds()
    for pos, entityId in ipairs(entitys) do
        if XTool.IsNumberValid(entityId) then
            local xCharacter = XMVCA.XCharacter:GetCharacter(entityId)
            local characterViewModel = xCharacter:GetCharacterViewModel()
            characterViewModelDic[pos] = characterViewModel
        end
    end

    XLuaUiManager.Open("UiBattleRoleRoomCaptain", characterViewModelDic, curTeamPrefabEntity:GetCaptainPos(), function(newCaptainPos)
        if newCaptainPos == curTeamPrefabEntity:GetCaptainPos() then
            return
        end

        curTeamPrefabEntity:UpdateCaptainPos(newCaptainPos)
        self:OnlyRefreshDynamicGridData()
        self:RefreshRightInfo()
        XUiManager.PopupLeftTip(XUiHelper.GetText("TeamPrefabCaptainSkillSetSuccess"))
    end)
end

function XUiTeamPrefabMain:OnBtnAnimationSetClick()
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    XLuaUiManager.OpenWithCloseCallback("UiPopupAnimationSet",function ()
        self:RefreshRightInfo()
    end, curTeamPrefabEntity)
end

function XUiTeamPrefabMain:OnBtnSkipToTeamRecommendationClick()
    local skipId = 189068  -- 跳转到外链的队伍推荐，写死
    XFunctionManager.SkipInterface(skipId)
end

function XUiTeamPrefabMain:OnBtnTagClick()
    local entity = self:GetCurTeamPrefabEntity()
    if not entity then return end

    XLuaUiManager.Open("UiTeamPrefabPopupTagSelector", "set", entity:GetTagsSet(), function(tagsSet, tagsArray)
        entity:SyncTagsToServer(tagsArray, function()
            self:RefreshPanelTag()
            if self.IsFiltering then
                self:RefreshFilteredList()
            end
        end)
    end)
end

function XUiTeamPrefabMain:OnBtnFilterClick()
    XLuaUiManager.Open("UiTeamPrefabPopupTagSelector", "filter", self.FilterTags, function(tagsSet)
        self.FilterTags = tagsSet
        local hasFilter = not XTool.IsTableEmpty(tagsSet)
        self.IsFiltering = hasFilter

        self:RefreshFilterState()
        self.CurSelectIndex = 1
        self:RefreshTeamPrefabListDynamicTable(1)
    end)
end

---@param xRealTeam XTeam
function XUiTeamPrefabMain:OnStart(xRealTeam, forceHideUseBtn, forceHideCoverBtn)
    self.XRealTeam = xRealTeam
    local XTeam = require("XEntity/XTeam/XTeam")
    -- 不是xTeam或不是继承自xTeam的都不能操作这些队伍
    if not xRealTeam or (xRealTeam.__cname ~= "XTeam" and xRealTeam.Super == nil) or (xRealTeam.__cname ~= "XTeam" and not CheckClassSuper(xRealTeam, XTeam)) then
        self.ForbiddenRealTeamOperate = true
    end

    if xRealTeam and xRealTeam:CheckHasRobotId() then
        self.ForbiddenRealTeamOperate = true
    end

    self.BtnUse.gameObject:SetActiveEx(not forceHideUseBtn)
    self.BtnCover.gameObject:SetActiveEx(not forceHideCoverBtn)
    self.PanelTagEmpty.gameObject:SetActiveEx(false)
end

function XUiTeamPrefabMain:OnEnable()
    self:RefreshTeamPrefabListDynamicTable(self.CurSelectIndex)
end

function XUiTeamPrefabMain:RefreshTeamPrefabListDynamicTable(index)
    self:RebuildDisplayList()
    self.DynamicTable:SetDataSource(self.DisplayList)
    self.DynamicTable:ReloadDataSync(index)
    self:RefreshFilterEmptyState()
end

function XUiTeamPrefabMain:OnlyRefreshDynamicGridData()
    local grids = self.DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        local data = self.DynamicTable.DataSource[index]
        grid:Refresh(data)
    end
end

function XUiTeamPrefabMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable.DataSource[index]
        grid:Refresh(data)
        if self.CurSelectIndex == index then
            if self.CurSelectGrid and self.CurSelectGrid ~= grid then
                self.CurSelectGrid:SetSelect(false)
            end

            grid:SetSelect(true)
            self.CurSelectGrid = grid

            self:OnSelectCallBack()
        else
            grid:SetSelect(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSelectGrid and self.CurSelectGrid ~= grid then
            self.CurSelectGrid:SetSelect(false)
        end
        self:PlayAnimation("QieHuan")
        grid:SetSelect(true)
        self.CurSelectGrid = grid
        self.CurSelectIndex = index  -- 更新当前选中的索引

        self:OnSelectCallBack()
    end
end

--- 获取当前选中的预设实体（兼容筛选态）
---@return XTeamPrefab
function XUiTeamPrefabMain:GetCurTeamPrefabEntity()
    return self.DisplayList and self.DisplayList[self.CurSelectIndex]
end

function XUiTeamPrefabMain:OnSelectCallBack()
    self:RefreshRightInfo()
    self:RefreshPanelTag()
end

function XUiTeamPrefabMain:RefreshRightInfo()
    -- 角色卡片
    local curTeamPrefabEntity = self:GetCurTeamPrefabEntity()
    if not curTeamPrefabEntity then return end
    
    local memberCount = #curTeamPrefabEntity.EntitiyIds
    for i = 1, memberCount do
        local xPanelCard = self.CharacterCardList[i]
        xPanelCard:Refresh(curTeamPrefabEntity, i)
    end

    -- 队伍名
    self.BtnName:SetNameByGroup(0, curTeamPrefabEntity:GetName())
    self.TxtNum.text = #self.DynamicTable.DataSource .."/".. CS.XGame.Config:GetInt("MaxTeamPrefab")

    -- 下部分按钮信息
    -- 效应
    local hasGeneralSkill = curTeamPrefabEntity:CheckHasGeneralSkills()
    local generalSkillId = curTeamPrefabEntity:GetCurGeneralSkill()
    local isNoChoose = curTeamPrefabEntity:GetCurGeneralSkillISelectNone() -- 新增判断

    if hasGeneralSkill and XTool.IsNumberValid(generalSkillId) then
        -- 显示有效应图标
        local genralSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]
        self.BtnGeneralSkillSet:SetRawImage(genralSkillConfig.IconBlue)
        self.BtnGeneralSkillSet:SetNameByGroup(1, genralSkillConfig.Name)
    end

    if isNoChoose then
        -- 显示 PanelNoChoose，其他隐藏
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelNone").gameObject:SetActiveEx(false)
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelHave").gameObject:SetActiveEx(false)
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelNotChosen").gameObject:SetActiveEx(true)

        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelNone").gameObject:SetActiveEx(false)
        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelHave").gameObject:SetActiveEx(false)
        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelNotChosen").gameObject:SetActiveEx(true)
    else
        -- 原有逻辑
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelNone").gameObject:SetActiveEx(not hasGeneralSkill)
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelHave").gameObject:SetActiveEx(hasGeneralSkill)
        self.BtnGeneralSkillSetObj:GetObject("Normal"):GetObject("PanelNotChosen").gameObject:SetActiveEx(false)

        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelNone").gameObject:SetActiveEx(not hasGeneralSkill)
        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelHave").gameObject:SetActiveEx(hasGeneralSkill)
        self.BtnGeneralSkillSetObj:GetObject("Press"):GetObject("PanelNotChosen").gameObject:SetActiveEx(false)
    end

    -- 队长
    local isCharIdValid = nil
    local captainPosEntityId = curTeamPrefabEntity:GetCaptainPosEntityId()
    isCharIdValid = XTool.IsNumberValid(captainPosEntityId)
    if isCharIdValid then
        self.BtnLeaderSet:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(captainPosEntityId))
        self.BtnLeaderSet:SetNameByGroup(1, XMVCA.XCharacter:GetCharacterFullNameStr(captainPosEntityId))
    end
    self.BtnLeaderSetObj:GetObject("Normal"):GetObject("PanelNone").gameObject:SetActiveEx(not isCharIdValid)
    self.BtnLeaderSetObj:GetObject("Normal"):GetObject("PanelHave").gameObject:SetActiveEx(isCharIdValid)
    self.BtnLeaderSetObj:GetObject("Press"):GetObject("PanelNone").gameObject:SetActiveEx(not isCharIdValid)
    self.BtnLeaderSetObj:GetObject("Press"):GetObject("PanelHave").gameObject:SetActiveEx(isCharIdValid)

    -- 动画
    local enterCharId = curTeamPrefabEntity:GetEntityIdByTeamPos(curTeamPrefabEntity:GetEnterCgIndex())
    isCharIdValid = XTool.IsNumberValid(enterCharId)
    if isCharIdValid then
        self.EntranceRImgHead1:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(enterCharId))
        self.EntranceRImgHead2:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(enterCharId))
    end
    self.BtnAnimationSet:ShowTag(not isCharIdValid)
    self.PanelAnimEntrance1.gameObject:SetActiveEx(isCharIdValid)
    self.PanelAnimEntrance2.gameObject:SetActiveEx(isCharIdValid)
    
    local exitCharId = curTeamPrefabEntity:GetEntityIdByTeamPos(curTeamPrefabEntity:GetSettleCgIndex())
    isCharIdValid = XTool.IsNumberValid(exitCharId)
    if isCharIdValid then
        self.ExitRImgHead1:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(exitCharId))
        self.ExitRImgHead2:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(exitCharId))
    end
    self.BtnAnimationSet:ShowReddot(not isCharIdValid)
    self.PanelAnimExit1.gameObject:SetActiveEx(isCharIdValid)
    self.PanelAnimExit2.gameObject:SetActiveEx(isCharIdValid)

    -- 上移按钮
    self.BtnTopUp:SetDisable(self.CurSelectIndex == 1)
    self.BtnAdd:SetNameByGroup(0, #(XDataCenter.TeamManager.GetTeamPrefabList()) .."/" .. CS.XGame.Config:GetInt("MaxTeamPrefab"))
end

function XUiTeamPrefabMain:RefreshPanelTag()
    local entity = self:GetCurTeamPrefabEntity()
    if not entity then return end

    local tagsList = entity:GetTagsList()
    local tagCount = #tagsList
    local hasTags = tagCount > 0

    self.BtnTag.gameObject:SetActiveEx(not hasTags)

    for i = 1, 2 do
        local item = self.TagDetailPool[i]
        if i <= tagCount then
            item.Go:SetActiveEx(true)
            self:UpdateTagDetail(item, tagsList[i])
        else
            item.Go:SetActiveEx(false)
        end
    end
end

function XUiTeamPrefabMain:UpdateTagDetail(item, tagId)
    local cfg = XTeamConfig.GetTeamPrefabTagCfgById(tagId)
    if not cfg then return end

    local isMode = (cfg.TagType == XEnumConst.TeamPrefab.TagTypeGameplay)

    -- 玩法标签显示紫色底，属性标签隐藏紫色底
    item.NormalImgBgMode.gameObject:SetActiveEx(isMode)
    item.PressImgBgMode.gameObject:SetActiveEx(isMode)

    -- 图标
    if not string.IsNilOrEmpty(cfg.Icon) then
        item.NormalUiImgIcon.gameObject:SetActiveEx(true)
        item.PressUiImgIcon.gameObject:SetActiveEx(true)
        item.NormalUiImgIcon:GetComponent("RawImage"):SetRawImage(cfg.Icon)
        item.PressUiImgIcon:GetComponent("RawImage"):SetRawImage(cfg.Icon)
    else
        item.NormalUiImgIcon.gameObject:SetActiveEx(false)
        item.PressUiImgIcon.gameObject:SetActiveEx(false)
    end

    -- 文本
    local btn = item.Go:GetComponent("XUiButton")
    btn:SetNameByGroup(0, cfg.Text)
end

--- 构建显示列表（全量或过滤）
function XUiTeamPrefabMain:RebuildDisplayList()
    local fullList = XDataCenter.TeamManager.GetTeamPrefabList()
    if not self.IsFiltering or XTool.IsTableEmpty(self.FilterTags) then
        self.DisplayList = fullList
        return
    end

    self.DisplayList = {}
    for _, xTeamPrefab in ipairs(fullList) do
        if xTeamPrefab:MatchFilter(self.FilterTags) then
            table.insert(self.DisplayList, xTeamPrefab)
        end
    end
end

--- 筛选后空态处理
function XUiTeamPrefabMain:RefreshFilterEmptyState()
    local isEmpty = self.IsFiltering and #self.DisplayList == 0
    self.PanelTagEmpty.gameObject:SetActiveEx(isEmpty)
    self.TeamPefabList.gameObject:SetActiveEx(not isEmpty)
    self.PanelRight.gameObject:SetActiveEx(not isEmpty)
end

--- 刷新筛选态的 UI 状态（按钮显隐、BtnFilter 状态）
function XUiTeamPrefabMain:RefreshFilterState()
    self.BtnFilter:SetButtonState(self.IsFiltering and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnAdd.gameObject:SetActiveEx(not self.IsFiltering)
    self.BtnTopUp.gameObject:SetActiveEx(not self.IsFiltering)
end

--- 筛选态下标签变更后刷新列表，尝试保留当前选中实体
function XUiTeamPrefabMain:RefreshFilteredList()
    local curEntity = self:GetCurTeamPrefabEntity()

    self:RebuildDisplayList()
    self.DynamicTable:SetDataSource(self.DisplayList)

    -- 尝试在新列表中找到原选中实体
    local newIndex = 1
    if curEntity then
        for i, entity in ipairs(self.DisplayList) do
            if entity:GetId() == curEntity:GetId() then
                newIndex = i
                break
            end
        end
    end

    if #self.DisplayList > 0 then
        self.CurSelectIndex = newIndex
        self.DynamicTable:ReloadDataSync(newIndex)
    else
        self.DynamicTable:ReloadDataSync()
    end

    self:RefreshFilterEmptyState()
end

