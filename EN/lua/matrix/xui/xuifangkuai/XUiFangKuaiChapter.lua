local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiFangKuaiChapter : XLuaUi 大方块关卡界面
---@field _Control XFangKuaiControl
local XUiFangKuaiChapter = XLuaUiManager.Register(XLuaUi, "UiFangKuaiChapter")

function XUiFangKuaiChapter:OnAwake()
    ---@type XUiGridFangKuaiStageGroup[]
    self._Grids = {}
    self._Timer = {}
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())
end

function XUiFangKuaiChapter:OnStart(chapterId)
    self._Chapter = self._Control:GetChapterConfig(chapterId)
    self:InitCompnent()

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiChapter:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTask()
    self:UpdateChapter(true)
    self:CheckCollectionTip()
end

function XUiFangKuaiChapter:OnDestroy()
    self:StopBubbleTimer()
    self:RemoveAnimTimer()
end

function XUiFangKuaiChapter:InitCompnent()
    self.ImgTitle:SetRawImage(self._Chapter.Icon)
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiFangKuaiChapter:RemoveAnimTimer()
    for _, timeId in pairs(self._Timer) do
        XScheduleManager.UnSchedule(timeId)
    end
end

function XUiFangKuaiChapter:UpdateChapter(isPlayAnim)
    if not self._ChapterGrids then
        ---@type XUiGridFangKuaiStageGroup[]
        self._ChapterGrids = {}
    end
    self:RemoveAnimTimer()
    local count = #self._Chapter.StageGroupIds
    for i = 1, count do
        local grid = self._ChapterGrids[i]
        if not grid then
            local root = self["Root" .. i]
            if not root then
                XLog.Error("缺失第" .. i .. "节点的Ui")
                return
            else
                local id = self._Chapter.StageGroupIds[i]
                if i == 1 then
                    self.GridChapter:SetParent(root, false)
                    self.GridChapter.localPosition = CS.UnityEngine.Vector3.zero
                    grid = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiStageGroup").New(self.GridChapter, self, id, self._Chapter.Id)
                else
                    local go = XUiHelper.Instantiate(self.GridChapter, root)
                    go.localPosition = CS.UnityEngine.Vector3.zero
                    grid = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiStageGroup").New(go, self, id, self._Chapter.Id)
                end
            end
            self._ChapterGrids[i] = grid
        end
        grid:Update()
        if isPlayAnim then
            grid.Canvas.alpha = 0
            self._Timer[i] = XScheduleManager.ScheduleOnce(function()
                grid:PlayChapterAnim()
            end, 200 * i)
        end
    end
end

function XUiFangKuaiChapter:UpdateTask()
    if self._Control:IsAllTaskFinish() then
        self.PanelItem.gameObject:SetActiveEx(false)
        self.BtnTask:ShowReddot(false)
        return
    end

    local rewards = self._Control:GetBubbleReward()
    local keepTime = self._Control:GetBubbleKeepTime()
    self.PanelItem.gameObject:SetActiveEx(true)
    XUiHelper.RefreshCustomizedList(self.PanelItem, self.Grid256New, #rewards, function(index, go)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(rewards[index])
        grid:SetName("")
    end)

    self:StopBubbleTimer()
    self._BubbleTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelItem.gameObject:SetActiveEx(false)
    end, keepTime)

    local isRed = self._Control:CheckTaskRedPoint()
    self.BtnTask:ShowReddot(isRed)
end

function XUiFangKuaiChapter:StopBubbleTimer()
    if self._BubbleTimer then
        XScheduleManager.UnSchedule(self._BubbleTimer)
        self._BubbleTimer = nil
    end
end

function XUiFangKuaiChapter:OnClickTask()
    XLuaUiManager.Open("UiFangKuaiTask")
end

function XUiFangKuaiChapter:CheckCollectionTip()
    local data = self._Control:GetCollectionRecordData()
    if data then
        if data.IsNeedShowCollection and not self._Control:IsNoStagePassed() then
            XLuaUiManager.OpenWithCloseCallback("UiObtain", handler(self, self.CheckCollectionUpgradeTip), self._Control:GetCollectionReward())
        else
            self:CheckCollectionUpgradeTip()
        end
    end
end

function XUiFangKuaiChapter:CheckCollectionUpgradeTip()
    local data = self._Control:GetCollectionRecordData()
    if data and data.InitRound and data.FinalRound and data.FinalRound > data.InitRound then
        XLuaUiManager.Open("UiFangKuaiPopupCollectionUpgrade")
    else
        self._Control:ClearCollection()
    end
end

return XUiFangKuaiChapter