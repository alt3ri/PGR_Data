local XUiPanelDlcRelinkChooseBossDetail = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkChooseBossDetail")
local XUiGridDlcRelinkChooseBoss = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkChooseBoss")
---@class XUiDlcRelinkChooseBoss : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelDrag XUiComponent.XGesture.XUiGestureFixedAreaScaleDrag
local XUiDlcRelinkChooseBoss = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkChooseBoss")

function XUiDlcRelinkChooseBoss:OnAwake()
    self.GridBoss.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    ---@type table<number, XUiGridDlcRelinkChooseBoss>
    self.BossGridList = {}

    -- 进入选择Boss界面时，设置玩家状态为准备中
    XMVCA.XDlcRoom:ReqSetShowState(XEnumConst.DlcRoom.PlayerShowState.Preparing)
end

function XUiDlcRelinkChooseBoss:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)

    self:InitChapterGrid()
    self.ChapterId = self._Control:GetCurrentSelectChapterId()
    self.LevelId = self._Control:GetCurrentSelectLevelId()

    self.WheelSensitivity = self.PanelDrag.WheelSensitivity

    self.BtnTraining.gameObject:SetActiveEx(XTool.IsNumberValid(self._Control:GetTrainingLevelId()))
    self.BtnTeaching.gameObject:SetActiveEx(XTool.IsNumberValid(self._Control:GetTeachingLevelId()))
end

function XUiDlcRelinkChooseBoss:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshChapterGrid()
    self:RefreshPanelDetail(true)
    self:RefreshRedPoint()
end

function XUiDlcRelinkChooseBoss:OnDisable()
    self.Super.OnDisable(self)
end

function XUiDlcRelinkChooseBoss:OnDestroy()
    XMVCA.XDlcRoom:ReqSetShowState(XEnumConst.DlcRoom.PlayerShowState.Normal)
end

function XUiDlcRelinkChooseBoss:InitChapterGrid()
    self.BossGridList = {}
    local chapterIds = self._Control:GetActivityChapterIds()
    if XTool.IsTableEmpty(chapterIds) then
        XLog.Error("XUiDlcRelinkChooseBoss:InitChapterGrid error: chapterIds is empty")
        return
    end

    for index, chapterId in ipairs(chapterIds) do
        local panelBoss = self["PanelBoss" .. index]
        if panelBoss then
            local go = XUiHelper.Instantiate(self.GridBoss, panelBoss)
            ---@type XUiGridDlcRelinkChooseBoss
            local grid = XUiGridDlcRelinkChooseBoss.New(go, self, chapterId)
            self.BossGridList[chapterId] = grid
            grid:Open()
        else
            XLog.Error(string.format("XUiDlcRelinkChooseBoss:InitChapterGrid error: not find PanelBoss%s", index))
        end
    end
end

function XUiDlcRelinkChooseBoss:RefreshChapterGrid()
    for chapterId, grid in pairs(self.BossGridList) do
        if grid then
            grid:Refresh()
            grid:SetSelect(self.ChapterId == chapterId)
        end
    end
end

function XUiDlcRelinkChooseBoss:RefreshPanelDetail(isEnable)
    if not self.PanelDetailUi then
        ---@type XUiPanelDlcRelinkChooseBossDetail
        self.PanelDetailUi = XUiPanelDlcRelinkChooseBossDetail.New(self.PanelDetail, self)
    end

    if XTool.IsNumberValid(self.ChapterId) and XTool.IsNumberValid(self.LevelId) then
        self.PanelDetailUi:Open()
        self.PanelDetailUi:Refresh(self.ChapterId, self.LevelId)
        -- 禁用滚轮缩放
        self.PanelDrag.WheelSensitivity = 0
        self.PanelDrag.IsIgnoreStartedOverGui = true
        -- 设置拖动面板位置
        local grid = self.BossGridList[self.ChapterId]
        if grid and grid.Transform then
            self.PanelDrag:WorldPositionAnchorToScenePercentage(grid.Transform.position.x, grid.Transform.position.y, 0.25, 0.5, 0.1)
        end
    else
        self.PanelDetailUi:Close()
        -- 恢复滚轮缩放
        self.PanelDrag.WheelSensitivity = self.WheelSensitivity
        self.PanelDrag.IsIgnoreStartedOverGui = false
        -- 如果没有选择章节，则将拖动面板位置设置到最后解锁的章节
        if isEnable then
            local lastChapterId = self._Control:GetLastUnlockedChapterId()
            if XTool.IsNumberValid(lastChapterId) then
                local grid = self.BossGridList[lastChapterId]
                if grid and grid.Transform then
                    self.PanelDrag:WorldPositionAnchorToScenePercentage(grid.Transform.position.x, grid.Transform.position.y, 0.5, 0.5, 0.1)
                end
            end
        end
    end
end

function XUiDlcRelinkChooseBoss:RefreshTime()
    for _, grid in pairs(self.BossGridList) do
        if grid then
            grid:RefreshTime()
        end
    end
end

function XUiDlcRelinkChooseBoss:RefreshRedPoint()
    for _, grid in pairs(self.BossGridList) do
        if grid then
            grid:RefreshRedPoint()
        end
    end
end

function XUiDlcRelinkChooseBoss:OnBtnChapterGridClick(chapterId)
    if not XTool.IsNumberValid(chapterId) or self.ChapterId == chapterId then
        return
    end

    if not self._Control:CheckChapterUnlock(chapterId) then
        self._Control:OpenCommonTipMsg(self._Control:GetChapterUnlockDesc(chapterId))
        return
    end

    local lastChapterGrid = self.BossGridList[self.ChapterId]
    if lastChapterGrid then
        lastChapterGrid:SetSelect(false)
    end

    self.ChapterId = chapterId
    self.LevelId = self._Control:GetDefaultSelectLevelId(self.ChapterId)

    local chapterGrid = self.BossGridList[chapterId]
    if chapterGrid then
        chapterGrid:SetSelect(true)
    end

    self:RefreshPanelDetail()
end

function XUiDlcRelinkChooseBoss:OnPanelDetailClose()
    if not XTool.IsNumberValid(self.ChapterId) then
        return
    end

    local chapterGrid = self.BossGridList[self.ChapterId]
    if chapterGrid then
        chapterGrid:SetSelect(false)
    end

    self.ChapterId = 0
    self.LevelId = 0
    self:RefreshPanelDetail()
end

function XUiDlcRelinkChooseBoss:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnTeaching:AddEventListener(handler(self, self.OnBtnTeachingClick))
    self.BtnTraining:AddEventListener(handler(self, self.OnBtnTrainingClick))
    self.BtnBubbleClose:AddEventListener(handler(self, self.OnPanelDetailClose))
end

function XUiDlcRelinkChooseBoss:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkChooseBoss:SelectSpecialLevel(levelId)
    if XMVCA.XDlcRoom:IsMatching() then
        self._Control:OpenCommonTipCode(XCode.MatchPlayerIsMatching)
        return
    end

    local isNeedQuit = false
    if XMVCA.XDlcRoom:IsInRoom() then
        --房间内有其他玩家时，无法选择训练关\教学关
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        if team and team:GetMemberAmount() > 1 then
            self._Control:OpenCommonTipText("SelectTrainingTip")
            return
        end
        --房间为空时，自动退出房间回到单人
        isNeedQuit = true
    end

    local chapterId = self._Control:GetLevelChapterId(levelId)
    self._Control:SetCurrentSelectLevelData(chapterId, levelId)

    if isNeedQuit then
        XMVCA.XDlcRoom:Quit(handler(self, self.Close))
    else
        self:Close()
    end
end

function XUiDlcRelinkChooseBoss:OnBtnTeachingClick()
    self:SelectSpecialLevel(self._Control:GetTeachingLevelId())
end

function XUiDlcRelinkChooseBoss:OnBtnTrainingClick()
    self:SelectSpecialLevel(self._Control:GetTrainingLevelId())
end

return XUiDlcRelinkChooseBoss
