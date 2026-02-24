local XUiPanelLuosaitaSection = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Panel/XUiPanelLuosaitaSection")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local ipairs = ipairs

---@class XUiMainLineLuosaitaMain : XLuaUi
---@field _Control XMainLineLuosaitaControl
---@field _UiPanelSectionDic table<number, XUiPanelLuosaitaSection>
---@field _UiPanelTalk XUiPanelLuosaitaTalk
---@field _UiPanelFight XUiPanelLuosaitaFight
---@field _UiPanelPositionDetail XUiPanelMainLineLuosaitaPositionDetail
local XUiMainLineLuosaitaMain = XLuaUiManager.Register(XLuaUi, "UiMainLineLuosaitaMain")

function XUiMainLineLuosaitaMain:OnAwake()
    self.Arrow.gameObject:SetActiveEx(false)
    self.PanelFight.gameObject:SetActiveEx(false)
    self.PanelPositionDetail.gameObject:SetActiveEx(false)
    self.BtnReview:ShowReddot(false)
    self:InitDropDown()
    self:InitPanelTalk()
    self:RegisterUiEvents()
end

function XUiMainLineLuosaitaMain:OnStart()
    -- 进入玩法才播放动效
    if not self.ResumeData then
        self:PlayAnimation("AnimEnableStar")
    end
    
    self._MainId = XEnumConst.MAINLINE2.SPECIAL_MAINID.LUOSAITA
    self._UiPanelSectionDic = {}
    
    -- 打开最新的阶段
    local sectionId = self._Control:GetEnterSectionId()
    self:SwitchPanelSection(sectionId)
end

function XUiMainLineLuosaitaMain:OnEnable()
    self:Refresh()
end

function XUiMainLineLuosaitaMain:OnResume(data)
    self.ResumeData = data
end

function XUiMainLineLuosaitaMain:OnReleaseInst()
    local data = {}
    local panelSection = self:GetCurPanelSection()
    data["SectionId"] = self:GetCurSectionId()
    data["Pos"] = panelSection:GetAreaScaleDragPosition()
    data["ActivatedAnimDic"] = panelSection:GetActivatedAnimDic()
    return data
end

-- 获取阶段的恢复位置
function XUiMainLineLuosaitaMain:GetResumePos(sectionId)
    if self.ResumeData and self.ResumeData.SectionId == sectionId and not self.ResumeData.IsPosUse then
        self.ResumeData.IsPosUse = true
        return self.ResumeData.Pos
    end
end

-- 获取阶段恢复时的动画激活记录
function XUiMainLineLuosaitaMain:GetResumeActivatedAnimDic(sectionId)
    if self.ResumeData and self.ResumeData.SectionId == sectionId then
        return self.ResumeData.ActivatedAnimDic
    end
end

function XUiMainLineLuosaitaMain:OnGetEvents()
    return {  
        XEventId.EVENT_UI_ENABLE, 
        XEventId.EVENT_UI_DISABLE,
    }
end

function XUiMainLineLuosaitaMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_MAINLINE_LUOSAITA_ATTACK_PREVIEW,
        XEventId.EVENT_MAINLINE_LUOSAITA_ATTACK,
    }
end

function XUiMainLineLuosaitaMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_UI_ENABLE or evt == XEventId.EVENT_UI_DISABLE then
        local isTopUi = XLuaUiManager.GetTopUiName() == self.Name
        self:SetAreaDragEnable(isTopUi)
    elseif evt == XEventId.EVENT_MAINLINE_LUOSAITA_ATTACK_PREVIEW then
        local armyNodeName = args[1]
        local enemyNodeName = args[2]
        local panelSection = self:GetCurPanelSection()
        panelSection:GuideAttackPreview(armyNodeName, enemyNodeName)
    elseif evt == XEventId.EVENT_MAINLINE_LUOSAITA_ATTACK then
        local armyNodeName = args[1]
        local enemyNodeName = args[2]
        local panelSection = self:GetCurPanelSection()
        panelSection:GuideAttack(armyNodeName, enemyNodeName)
    end
end

function XUiMainLineLuosaitaMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnCurDropdown, self.OnBtnCurDropdownClick)
    self:RegisterClickEvent(self.BtnCloseDropdown, self.CloseDropdown)
    self:RegisterClickEvent(self.BtnReview, self.OnBtnReviewClick)
    self:RegisterClickEvent(self.BtnMission, self.OnBtnMissionClick)
    self:RegisterClickEvent(self.BtnAchievement, self.OnBtnAchievementClick)
end

function XUiMainLineLuosaitaMain:OnBtnBackClick()
    self:Close()
end

function XUiMainLineLuosaitaMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiMainLineLuosaitaMain:OnBtnReviewClick()
    XLuaUiManager.Open("UiMainLineLuosaitaPopupReview", self._CurSectionId)
    
    self._Control:SetDocumentReviewRed(false)
    self:RefreshBtnReview()
end

function XUiMainLineLuosaitaMain:OnBtnMissionClick()
    XLuaUiManager.Open("UiMainLine2Task", self._MainId)
end

function XUiMainLineLuosaitaMain:OnBtnAchievementClick()
    XMVCA.XMainLine2:OnBtnAchievementClick(self._MainId, function()
        self:RefreshAchievement()
    end)
end

function XUiMainLineLuosaitaMain:Refresh()
    self:RefreshDropDown()
    self:RefreshAchievement()
    self:RefreshTask()
    self:RefreshBtnReview()
    -- XUiPanelLuosaitaSection 在OnEnable刷新
end

function XUiMainLineLuosaitaMain:OnBtnCurDropdownClick()
    if self._OpenDropDown then
        self:CloseDropdown()
    else
        self:OpenDropdown()
    end
end

function XUiMainLineLuosaitaMain:OnDropDownItemClick(data, index)
    self._OpenDropDown = not self._OpenDropDown
    local curIndex = self:GetCurSectionId()
    local unLock = curIndex ~= index
    if not unLock then
        self.ModuleList.gameObject:SetActive(self._OpenDropDown)
        return
    end
    self._CurSectionId = index
    self:EnterNewSection()
end

-- 刷新章节成就
function XUiMainLineLuosaitaMain:RefreshAchievement()
    local curCnt, maxCnt = XMVCA.XMainLine2:GetMainAchievementProgress(self._MainId)
    local progressFormat = self._Control:GetConfig():GetConfigString("ProgressText", 1)
    self.TxtAchievementProgress.text = string.format(progressFormat, curCnt, maxCnt)

    local isUnlock = curCnt >= maxCnt
    local isGet = XMVCA.XMainLine2:IsAchievementGet(self._MainId)
    local isRed = isUnlock and not isGet
    self.BtnAchievement:ShowReddot(isRed)
    self.ImgAchievementComplete.gameObject:SetActiveEx(isGet)

    local icon = XMVCA.XMainLine2:GetMainAchievementIcon(self._MainId)
    local iconLock = XMVCA.XMainLine2:GetAchievementChapterIconLock(self._MainId)
    self.RImgAchievement.gameObject:SetActiveEx(not isUnlock)
    self.RImgAchievementUnlock.gameObject:SetActiveEx(isUnlock)
    self.RImgAchievement:SetRawImage(iconLock)
    self.RImgAchievementUnlock:SetRawImage(icon)
end

-- 刷新任务信息
function XUiMainLineLuosaitaMain:RefreshTask()
    local curCnt = 0
    local totalCnt = 0
    self.TaskGroupId = self.TaskGroupId or XMVCA.XMainLine2:GetMainTaskGroupId(self._MainId)
    local tasks = XDataCenter.TaskManager.GetStoryTaskListByGroupId(self.TaskGroupId)
    for _, v in pairs(tasks) do
        if v.State == XDataCenter.TaskManager.TaskState.Finish then
            curCnt = curCnt + 1
        end
        totalCnt = totalCnt + 1
    end
    local progressFormat = self._Control:GetConfig():GetConfigString("ProgressText", 1)
    local progress = string.format(progressFormat, curCnt, totalCnt)
    self.BtnMission:SetName(progress)

    -- 蓝点
    local isRed = XMVCA.XMainLine2:IsMainRedTaskReward(self._MainId)
    self.BtnMission:ShowReddot(isRed)
    
    -- 完成状态
    if self.ImgMissionComplete then
        local isFinish = curCnt >= totalCnt
        self.ImgMissionComplete.gameObject:SetActiveEx(isFinish)
    end
end

-- 刷新文件回顾按钮
function XUiMainLineLuosaitaMain:RefreshBtnReview()
    local isRed = self._Control:GetDocumentReviewRed()
    self.BtnReview:ShowReddot(isRed)
end

--region 下拉列表
-- 初始化下拉列表
function XUiMainLineLuosaitaMain:InitDropDown()
    self._OpenDropDown = false
    self.DropdownList.gameObject:SetActiveEx(false)
    
    ---@type XTableMainLineLuosaitaSection[]
    self._DropDownDates = self._Control:GetConfig():GetConfigSections()

    local XUiGridLuosaitaDropDown = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaDropDown")
    self._DropDownDynamic = XUiHelper.DynamicTableNormal(self, self.DropdownList, XUiGridLuosaitaDropDown)
    self._DropDownDynamic:SetDataSource(self._DropDownDates)
    self._DropDownDynamic:ReloadDataSync()
end

-- 刷新下拉列表
function XUiMainLineLuosaitaMain:RefreshDropDown()
    local sectionIndex = self:GetCurSectionIndex()
    local name = self._DropDownDates[sectionIndex].Name
    local viewModel = XMVCA.XMainLine2:GetMain(XEnumConst.MAINLINE2.SPECIAL_MAINID.LUOSAITA)
    self.TxtSection.text = viewModel:GetExtralName()
    self.TxtSectionName.text = viewModel:GetName()
    self.BtnCurDropdown:SetNameByGroup(0, name)
end

-- 获取当前阶段的SectionId
function XUiMainLineLuosaitaMain:GetCurSectionId()
    return self._CurSectionId
end

-- 获取当前阶段的下标
function XUiMainLineLuosaitaMain:GetCurSectionIndex()
    for i, data in ipairs(self._DropDownDates) do
        if data.Id == self._CurSectionId then
            return i
        end
    end
    return 1
end

---@param grid XUiGridLuosaitaDropDown
function XUiMainLineLuosaitaMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DropDownDates[index]
        grid:Refresh(data, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sectionId = self._DropDownDates[index].Id
        local unLock = self._Control:IsSectionUnlock(sectionId)
        if unLock then
            self:CloseDropdown()
            self:SwitchPanelSection(sectionId, true)
        else
            local tips = self._Control:GetConfig():GetConfigString("SectionLock", 1)
            XUiManager.TipMsg(tips)
        end
    end
end

function XUiMainLineLuosaitaMain:OpenDropdown()
    self._OpenDropDown = true
    self.BtnCloseDropdown.gameObject:SetActiveEx(true)
    self.DropdownList.gameObject:SetActiveEx(true)
    self.ImgArrowDownNormal.gameObject:SetActiveEx(false)
    self.ImgArrowUpNormal.gameObject:SetActiveEx(true)
    self.ImgArrowDownPress.gameObject:SetActiveEx(false)
    self.ImgArrowUpPress.gameObject:SetActiveEx(true)

    self._DropDownDynamic:SetDataSource(self._DropDownDates)
    self._DropDownDynamic:ReloadDataSync()

    -- 禁用面板拖拽
    self:SetAreaDragEnable(false)
end

function XUiMainLineLuosaitaMain:CloseDropdown()
    self._OpenDropDown = false
    self.BtnCloseDropdown.gameObject:SetActiveEx(false)
    self.DropdownList.gameObject:SetActiveEx(false)
    self.ImgArrowDownNormal.gameObject:SetActiveEx(true)
    self.ImgArrowUpNormal.gameObject:SetActiveEx(false)
    self.ImgArrowDownPress.gameObject:SetActiveEx(true)
    self.ImgArrowUpPress.gameObject:SetActiveEx(false)

    -- 动态滑动列表
    local grids = self._DropDownDynamic:GetGrids()
    for _, grid in pairs(grids) do
        grid:Close()
    end

    -- 启用面板拖拽
    self:SetAreaDragEnable(true)
end
--endregion

--region XUiPanelLuosaitaSection 阶段面板
-- 切换阶段面板
function XUiMainLineLuosaitaMain:SwitchPanelSection(sectionId, isAnim)
    if self._CurSectionId == sectionId then return end

    -- 先请求数据再刷新UI
    XMVCA.XMainLineLuosaita:RequestMainLineLuosaitaEnter(sectionId, function()
        if isAnim then
            self:PlayAnimation("AnimSectionList")
        end
        
        self:OnSwitchPanelSection(sectionId)
    end)
end

function XUiMainLineLuosaitaMain:OnSwitchPanelSection(sectionId)
    self._CurSectionId = sectionId
    
    -- 关闭其他面板
    for id, panelSection in pairs(self._UiPanelSectionDic) do
        if id ~= sectionId then
            panelSection:Close()
        end
    end

    -- 创建阶段面板
    local panel = self._UiPanelSectionDic[sectionId]
    if not panel then
        local linkGo = CSInstantiate(self.SectionLink, self.SectionLink.transform.parent)
        local path = self._Control:GetConfig():GetSectionMapPrefabPath(sectionId)
        local prefab = linkGo:LoadPrefab(path)
        panel = XUiPanelLuosaitaSection.New(prefab, self, sectionId)
        self._UiPanelSectionDic[sectionId] = panel
    end

    -- 打开阶段面板
    panel:Open()

    -- 刷新下拉列表
    self:RefreshDropDown()
    
    -- 触发引导
    XDataCenter.GuideManager.CheckGuideOpen()
end

-- 获取当前阶段面板
---@return XUiPanelLuosaitaSection
function XUiMainLineLuosaitaMain:GetCurPanelSection()
    return self._UiPanelSectionDic[self._CurSectionId]
end

-- 设置拖拽组件是否启用
function XUiMainLineLuosaitaMain:SetAreaDragEnable(isEnable)
    local panel = self:GetCurPanelSection()
    if panel then
        panel:SetAreaDragEnable(isEnable)
    end
end

-- 检测下一阶段是否解锁，自动切换下一阶段
function XUiMainLineLuosaitaMain:CheckSwitchNextSection()
    local sectionId = self._Control:GetEnterSectionId()
    self:SwitchPanelSection(sectionId, true)
end
--endregion


--region XUiPanelMainLineLuosaitaPositionDetail 点位详情面板
-- 打开点位的详情信息
---@param posId number
function XUiMainLineLuosaitaMain:OpenPanelPositionDetail(posId)
    if not self.UiPanelBuy then
        local XUiPanelMainLineLuosaitaPositionDetail = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Panel/XUiPanelMainLineLuosaitaPositionDetail")
        self._UiPanelPositionDetail = XUiPanelMainLineLuosaitaPositionDetail.New(self.PanelPositionDetail, self)
    end
    self._UiPanelPositionDetail:Open()
    self._UiPanelPositionDetail:Refresh(posId)
end

-- 关闭点位的详情信息
function XUiMainLineLuosaitaMain:ClosePanelPositionDetail()
    if self._UiPanelPositionDetail then
        self._UiPanelPositionDetail:Close()
    end
end

function XUiMainLineLuosaitaMain:IsPanelPositionDetailShow()
    return self._UiPanelPositionDetail and self._UiPanelPositionDetail:IsNodeShow()
end
--endregion

--region XUiPanelLuosaitaTalk 讲话面板
-- 初始化讲话面板
function XUiMainLineLuosaitaMain:InitPanelTalk()
    local XUiPanelLuosaitaTalk = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Panel/XUiPanelLuosaitaTalk")
    self._UiPanelTalk = XUiPanelLuosaitaTalk.New(self.PanelTalk, self)
    self._UiPanelTalk:Open()
end

-- 设置讲话文本
function XUiMainLineLuosaitaMain:SetTalk(talkType, context)
    self._UiPanelTalk:Refresh(talkType, context)
end

-- 设置讲话文本
function XUiMainLineLuosaitaMain:SetTalkByClientConfigKey(talkType, key)
    local context = self._Control:GetConfig():GetConfigString(key, 1)
    self._UiPanelTalk:Refresh(talkType, context)
end

-- 清除讲话内容
function XUiMainLineLuosaitaMain:ClearTalk()
    self._UiPanelTalk:ClearTalk()
end
--endregion

--region XUiPanelLuosaitaFight 战斗面板
-- 设置战斗面板
function XUiMainLineLuosaitaMain:SetFight(allyData, enemyData)
    if not self._UiPanelFight then
        local XUiPanelLuosaitaFight = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Panel/XUiPanelLuosaitaFight")
        self._UiPanelFight = XUiPanelLuosaitaFight.New(self.PanelFight, self)
    end
    self._UiPanelFight:Open()
    self._UiPanelFight:Refresh(allyData, enemyData)
end

-- 关闭战斗面板
function XUiMainLineLuosaitaMain:ClosePanelFight()
    if self._UiPanelFight then
        self._UiPanelFight:Close()
    end
end

function XUiMainLineLuosaitaMain:IsPanelFightShow()
    return self._UiPanelFight and self._UiPanelFight:IsNodeShow()
end
--endregion

return XUiMainLineLuosaitaMain
