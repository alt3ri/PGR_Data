local XUiPlotExhibitionUtil = require("XUi/XUiPlotExhibition/XUiPlotExhibitionUtil")

---@class XUiMainLine2DetailBattle:XLuaUi
---@field private _Control XMainLine2Control
local XUiMainLine2DetailBattle = XLuaUiManager.Register(XLuaUi, "UiMainLine2DetailBattle")

function XUiMainLine2DetailBattle:OnAwake()
    self.BtnMode.gameObject:SetActiveEx(false)
    self.ImgVtTag.gameObject:SetActiveEx(false)

    self.AchievementUiObjs = { self.GridAchievement }
    self.CharacterUiObjs = { self.GridCharacter }
    self.GridPoints = { self.GridPoint }
    self:RegisterUiEvents()
    XUiPlotExhibitionUtil.Init(self, "SafeAreaContentPane/UiPlotExhibitionPanelMode/BtnToggle")
end

function XUiMainLine2DetailBattle:OnStart(stageIds, chapterId, mainId, closeCb)
    self.StageIds = stageIds
    self.ChapterId = chapterId
    self.MainId = mainId
    self.CloseCb = closeCb

    self.UnlockStageIds = self:GetUnlockStageIds(stageIds)
    self.StageIndex = 1
    self.StageId = stageIds[self.StageIndex]
    self:InitStageIcons()
end

function XUiMainLine2DetailBattle:OnEnable()
    self:Refresh()
end

function XUiMainLine2DetailBattle:OnRelease()
    self.AchievementUiObjs = nil
    self.CharacterUiObjs = nil
    self.GridPoints = nil
end

function XUiMainLine2DetailBattle:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnAchievement, self.OnBtnAchievementClick)
end

function XUiMainLine2DetailBattle:OnBtnCloseClick()
    local cb = self.CloseCb
    self:Close()
    
    if cb then
        cb()
    end
end

function XUiMainLine2DetailBattle:OnBtnEnterClick()
    local stageId = self.StageId
    local isNeedSetGender = self:IsNeedSetGender()
    local gender = self._Control:GetPlayerGender()
    self:Close()

    -- 需要设置指挥官
    if isNeedSetGender then
        XLuaUiManager.Open("UiMainLine2PopupChooseGender", stageId)
        return
    end

    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    
    local speedStageId = XMVCA.XPlotExhibition:GetSpeedrunStageId(stageId)
    local team
    if speedStageId then
        team = XDataCenter.TeamManager.GetXTeamSpeedrun(stageId)
    else
        team = XDataCenter.TeamManager.GetXTeamByStageIdEx(stageId)
    end
    
    local isCfgExit, lineupCfg = XMVCA.XFuben:GetConfigStageLineupType(stageId)
    local isExitType = (isCfgExit and #lineupCfg.Type > 0)
    if #stageCfg.RobotId > 0 and not isExitType and not speedStageId then
        -- 关卡配置机器人
        local entityIds = {0, 0, 0}
        for i, robotId in pairs(stageCfg.RobotId) do
            entityIds[i] = robotId
        end
        -- 指挥官机器人
        local isReplacePlayer = isCfgExit and lineupCfg.PlayerReplaceOrders > 0
        if isReplacePlayer then
            local isMan = gender == XEnumConst.PLAYER.GENDER_TYPE.MAN
            local playerRobotId = isMan and lineupCfg.PlayerSexRobotMan or lineupCfg.PlayerSexRobotWoman
            entityIds[lineupCfg.PlayerReplaceOrders] = playerRobotId
        end
        
        team:UpdateEntityIds(entityIds)
        team:AutoSelectGeneralSkill(XMVCA.XFuben:GetGeneralSkillIds(stageId))
        XMVCA.XFuben:EnterFightByStageId(stageId, team:GetId())
    else
        local proxy = require("XUi/XUiMainLine2/XUiMainLine2BattleRoleRoom")
        XMVCA.XFuben:OpenUiBattleRoleRoom(stageId, team, proxy)
    end
end

function XUiMainLine2DetailBattle:OnBtnLeftClick()
    local index = self.StageIndex - 1
    if index < 1 then 
        index = #self.UnlockStageIds
    end
    self:OnStageChange(index)
end

function XUiMainLine2DetailBattle:OnBtnRightClick()
    local index = self.StageIndex + 1
    if index > #self.UnlockStageIds then 
        index = 1
    end
    self:OnStageChange(index)
end

function XUiMainLine2DetailBattle:OnBtnAchievementClick()
    XLuaUiManager.Open("UiMainLine2DetailAchievement", self.StageId)
end

-- 初始化关卡图
function XUiMainLine2DetailBattle:InitStageIcons()
    local isMult = #self.UnlockStageIds > 1
    self.PanelPoint.gameObject:SetActiveEx(isMult)
    self.BtnLeft.gameObject:SetActiveEx(isMult)
    self.BtnRight.gameObject:SetActiveEx(isMult)
    if isMult then
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i, stageId in ipairs(self.UnlockStageIds) do
            local point = self.GridPoints[i]
            if not point then
                local go = CSInstantiate(self.GridPoint.gameObject, self.PanelPoint.transform)
                point = go:GetComponent("UiObject")
                self.GridPoints[i] = point
            end
        end
    end
end

function XUiMainLine2DetailBattle:Refresh()
    self:RefreshInfo()
    self:RefreshProgress()
    self:RefreshAchievements()
    self:RefreshCharacters()
    self:RefreshPoints()
    self:RefreshBtnEnter()
    XUiPlotExhibitionUtil.UpdateSpeedrunBtnToggle(self, self.StageId)
end

function XUiMainLine2DetailBattle:RefreshInfo()
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    local title = self._Control:GetMainTitle(self.MainId)
    local specialorder = self._Control:GetStageSpecialorder(self.StageId)
    self.RImgIcon:SetRawImage(stageCfg.StoryIcon)
    self.TxtName.text = string.format("%s-%s%s %s", title, stageCfg.OrderId, specialorder or "", stageCfg.Name)
    self.TxtName2.text = string.format("%s%s %s", stageCfg.OrderId, specialorder or "", stageCfg.Name)
    self.TxtDesc.text = stageCfg.Description
    self.TxtTarget.text = stageCfg.StarDesc[1]
end

-- 刷新进度
function XUiMainLine2DetailBattle:RefreshProgress()
    local reachCnt, allCnt = self._Control:GetStageProgress(self.StageId)
    if allCnt <= 0 or reachCnt == allCnt then
        self.TxtTargetProgress.text = ""
    else
        self.TxtTargetProgress.text = math.floor(reachCnt / allCnt * 100) .. "%"
    end

    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local isPass = agency:IsStagePass(self.StageId)
    self.ClearTag.gameObject:SetActiveEx(isPass)
end

-- 刷新成就列表
function XUiMainLine2DetailBattle:RefreshAchievements()
    local achieveInfos = self._Control:GetStagesAchievementInfos(self.StageId, false, false)
    local isPanelShow = false
    for _, uiObj in ipairs(self.AchievementUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    for i, info in ipairs(achieveInfos) do
        local uiObj = self.AchievementUiObjs[i]
        if not uiObj then
            local go = CS.UnityEngine.Object.Instantiate(self.GridAchievement.gameObject, self.GridAchievement.transform.parent)
            uiObj = go:GetComponent("UiObject")
            self.AchievementUiObjs[i] = uiObj
        end
        uiObj.gameObject:SetActiveEx(true)

        -- 隐藏显示
        local isHide = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE and not info.IsUnLock
        if isHide then
            uiObj.gameObject:SetActiveEx(false)
            goto CONTINUE
        end

        isPanelShow = true
        -- 解锁状态
        uiObj:GetObject("PanelOn").gameObject:SetActiveEx(info.IsUnLock)
        uiObj:GetObject("PanelOff").gameObject:SetActiveEx(not info.IsUnLock)

        -- 图标
        local isNormal = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.NORMAL
        local isSpecial = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.SPECIAL
        local isHide = info.Type == XEnumConst.MAINLINE2.ACHIEVEMENT_TYPE.HIDE
        
        uiObj:GetObject("RImgNormalOn").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgNormalOff").gameObject:SetActiveEx(isNormal)
        uiObj:GetObject("RImgSpecialOn").gameObject:SetActiveEx(isSpecial)
        uiObj:GetObject("RImgSpecialOff").gameObject:SetActiveEx(isSpecial)

        local rImgRealHideOn = uiObj:GetObject("RImgRealHideOn")
        local rImgRealHideOff = uiObj:GetObject("RImgRealHideOff")

        if rImgRealHideOn then
            rImgRealHideOn.gameObject:SetActiveEx(isHide)
        end

        if rImgRealHideOff then
            rImgRealHideOff.gameObject:SetActiveEx(isHide)
        end
        
        -- 描述
        uiObj:GetObject("TxtDescOn").text = info.Name
        uiObj:GetObject("TxtDescOff").text = info.Name

        ::CONTINUE::
    end
    -- 无配置成就 / 配置隐藏成就但是隐藏成就完成没显示出来，都不显示整个成就面板
    self.PanelAchievement.gameObject:SetActiveEx(isPanelShow)
end

-- 刷新出站成员
function XUiMainLine2DetailBattle:RefreshCharacters()
    for _, uiObj in pairs(self.CharacterUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    -- 刷新机器人
    local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(self.StageId)
    if #stageCfg.RobotId > 0 then
        for i, robotId in ipairs(stageCfg.RobotId) do
            local uiObj = self.CharacterUiObjs[i]
            if not uiObj then
                local go = CS.UnityEngine.Object.Instantiate(self.GridCharacter.gameObject, self.CharacterList.transform)
                uiObj = go:GetComponent("UiObject")
                self.CharacterUiObjs[i] = uiObj
            end
            if not XTool.IsNumberValid(XRobotManager.GetRebuildNpcId(robotId)) then
                local icon = XRobotManager.GetRobotSmallHeadIcon(robotId)
                uiObj:GetObject("RImgCharater"):SetRawImage(icon)
                uiObj:GetObject("FirstTag").gameObject:SetActiveEx(i == 1)
                uiObj:GetObject("BtnChange").gameObject:SetActiveEx(false)
                uiObj.gameObject:SetActiveEx(true)
            end
        end
    end

    -- 刷新怪物
    local monsterHeads = self._Control:GetStageMonsterHeads(self.StageId)
    if #monsterHeads > 0 then
        local replaceOrders = self._Control:GetStageMonsterReplaceOrders(self.StageId)
        for i, head in ipairs(monsterHeads) do
            local order = replaceOrders[i]
            self:RefreshCharacter(order, head, false)
        end
    end
    
    -- 替换指挥官
    local isCfgExit, lineupCfg = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)
    local isReplacePlayer = isCfgExit and lineupCfg.PlayerReplaceOrders > 0
    self.TxtCharacterTips.gameObject:SetActiveEx(isReplacePlayer)
    if isReplacePlayer then
        local gender = self._Control:GetPlayerGender()
        local isMan = gender == XEnumConst.PLAYER.GENDER_TYPE.MAN
        local robotId = isMan and lineupCfg.PlayerSexRobotMan or lineupCfg.PlayerSexRobotWoman
        local order = lineupCfg.PlayerReplaceOrders
        local rebuildNpcId = XRobotManager.GetRebuildNpcId(robotId)
        local head = XRobotManager.GetRobotRebuildNpcBigHeadIcon(rebuildNpcId)
        self:RefreshCharacter(order, head, true)
    end
end

-- 刷新单个角色UI
function XUiMainLine2DetailBattle:RefreshCharacter(order, headIcon, isShowBtnChange)
    local uiObj = self.CharacterUiObjs[order]
    if not uiObj then
        local go = CS.UnityEngine.Object.Instantiate(self.GridCharacter.gameObject, self.CharacterList.transform)
        uiObj = go:GetComponent("UiObject")
        self.CharacterUiObjs[order] = uiObj
    end
    uiObj:GetObject("RImgCharater"):SetRawImage(headIcon)
    uiObj:GetObject("FirstTag").gameObject:SetActiveEx(order == 1)
    local btnChange = uiObj:GetObject("BtnChange")
    btnChange.gameObject:SetActiveEx(isShowBtnChange)
    if isShowBtnChange then
        btnChange.CallBack = function()
            self:OnCharacterBtnChangeClick(order)
        end
    end
    uiObj.gameObject:SetActiveEx(true)
end

-- 点击角色的切换按钮
function XUiMainLine2DetailBattle:OnCharacterBtnChangeClick(index)
    local stageId = self.StageId
    self:Close()
    XLuaUiManager.Open("UiMainLine2PopupChooseGender", stageId)
end

-- 刷新关卡图标选中点
function XUiMainLine2DetailBattle:RefreshPoints()
    for i, point in ipairs(self.GridPoints) do
        local isSelect = i == self.StageIndex
        point:GetObject("ImgOn").gameObject:SetActiveEx(isSelect)
        point:GetObject("ImgOff").gameObject:SetActiveEx(not isSelect)
    end
end

-- 刷新进入按钮
function XUiMainLine2DetailBattle:RefreshBtnEnter()
    local isNoPass = false
    for _, stageId in pairs(self.StageIds) do
        isNoPass = isNoPass or not self._Control:IsStagePass(stageId)
    end
    if isNoPass then
        local effectPath = self._Control:GetSpecialEffect(self.MainId)
        if effectPath and effectPath ~= "" then
            self.BtnEnterEffect:LoadPrefab(effectPath)
            self.BtnEnterEffect.gameObject:SetActiveEx(true)
        end
    end

    local isExit, cfg = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)
    local isExitType = (isExit and #cfg.Type > 0)
    local isTextReady = isExitType or self:IsNeedSetGender()
    if isTextReady then
        self.BtnEnter:SetNameByGroup(0, XUiHelper.GetText('MainLine2BattleReadyTips'))
    else
        self.BtnEnter:SetNameByGroup(0, XUiHelper.GetText('MainLine2BattleStartTips'))
    end
end

-- 是否需要设置指挥官性别
function XUiMainLine2DetailBattle:IsNeedSetGender()
    local isExit, cfg = XMVCA.XFuben:GetConfigStageLineupType(self.StageId)
    if isExit and cfg.PlayerReplaceOrders > 0 then
        local isSet = self._Control:IsSetPlayerGender()
        return not isSet -- 未设置
    end
    return false
end

-- 切换关卡Id
function XUiMainLine2DetailBattle:OnStageChange(index)
    self.StageIndex = index
    self.StageId = self.UnlockStageIds[self.StageIndex]
    self:Refresh()
end

-- 获取解锁的关卡Id列表
function XUiMainLine2DetailBattle:GetUnlockStageIds(stageIds)
    local result = {}
    for _, stageId in ipairs(stageIds) do
        local isUnlock = self._Control:IsStageUnlock(stageId)
        if isUnlock then
            table.insert(result, stageId)
        end
    end
    return result
end

return XUiMainLine2DetailBattle