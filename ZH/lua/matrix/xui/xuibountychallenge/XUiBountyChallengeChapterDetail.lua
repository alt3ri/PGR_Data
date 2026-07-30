local XUiBountyChallengeChapterDetailCharacter = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailCharacter")
local XUiBountyChallengeChapterDetailTask = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailTask")
local XUiBountyChallengeChapterDetailDifficulty = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailDifficulty")

---@class XUiBountyChallengeChapterDetail : XLuaUi
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetail = XLuaUiManager.Register(XLuaUi, "UiBountyChallengeChapterDetail")

function XUiBountyChallengeChapterDetail:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(nil, "BountyChallengeHelp")
    self.BtnDetail:AddEventListener(handler(self, self._OnClickDetail))
    self.BtnTongBlack:AddEventListener(handler(self, self._OnClickFight))
    self.BtnLianyu:AddEventListener(handler(self, self._OnClickFight))
    self.BtnTask:AddEventListener(handler(self, self._OnClickTask))
    self.BtnCloseTask:AddEventListener(handler(self, self._OnClickCloseTask))

    ---@type XUiBountyChallengeChapterDetailCharacter[]
    self._GridCharacters = {}

    ---@type XUiBountyChallengeChapterDetailTask[]
    self._GridTasks = {}

    ---@type XUiBountyChallengeChapterDetailDifficulty[]
    self._GridDifficulty = {}
    
    self.RImgBossList = {
        self.RImgBoss_A,
        self.RImgBoss_B,
        self.RImgBoss_C,
        self.RImgBoss_D,
    }

    self.PanelList:Init({}, function(index)
    end)
end

---@param data XUiBountyChallengeMainGridData
function XUiBountyChallengeChapterDetail:OnStart(data)
    self._Control:SetSelectedBoss(data.BossId, 1)
    --self._Control:SetDifficultyLevel(data.DifficultyLevel)
end

function XUiBountyChallengeChapterDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_BOUNTYCHALLENGE_CLOSE_TASK, self._OnClickCloseTask, self)
    
    local level = self._Control:SetDefaultDifficultyLevel()
    --self._Control:AutoFinishTask(function()
    --    self:Update()
    --end)
    self:SetLine(level)
    self:Update()
end

function XUiBountyChallengeChapterDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BOUNTYCHALLENGE_CLOSE_TASK, self._OnClickCloseTask, self)
    
    if not self.PanelTaskBg.gameObject.activeInHierarchy then
        for i = 1, #self._GridTasks do
            self._GridTasks[i]:Close()
        end
        self._GridTasks = {}
    end
end

function XUiBountyChallengeChapterDetail:Update()
    local data = self._Control:GetUiChapterDetail()
    self._Data = data
    self.TxtName.text = data.Name

    if self.TxtTitle then
        self.TxtTitle.gameObject:SetActiveEx(not self._Data.IsRobot)
    end

    if self.TxtTitleDifficulty4 then
        self.TxtTitleDifficulty4.gameObject:SetActiveEx(self._Data.IsRobot)
    end

    -- 限定角色
    if #data.Characters > 0 then
        if self.PanelMember then
            self.PanelMember.gameObject:SetActiveEx(true)
        end
        self.ListCharacter.gameObject:SetActiveEx(true)
        XTool.UpdateDynamicItem(self._GridCharacters, data.Characters, self.GridCharacter, XUiBountyChallengeChapterDetailCharacter, self)
    else
        for i = 1, #self._GridCharacters do
            self._GridCharacters[i]:Close()
        end
        self.ListCharacter.gameObject:SetActiveEx(false)

        if self.PanelMember then
            self.PanelMember.gameObject:SetActiveEx(false)
        end
    end

    -- 难度
    XTool.UpdateDynamicItem(self._GridDifficulty, data.Difficulties, self.DifficultyGrid, XUiBountyChallengeChapterDetailDifficulty, self)

    -- 兼容, 改成了XUiButtonGroup
    if self.PanelList.AddButton then
        for i = 1, #self._GridDifficulty do
            local grid = self._GridDifficulty[i]
            local button = grid.Transform:GetComponent("XUiButton")
            if button then
                if not grid.IsAdd2ButtonGroup then
                    grid.IsAdd2ButtonGroup = true
                    self.PanelList:AddButton(button, function(index)
                        -- do nothing
                        -- 为什么要这么做？ 因为XUiButton有bug，在按钮之外的区域，松手，就会改变选中状态，并且不触发onClick，
                        -- 加入了XUiButtonGroup，就可以拦截这个问题
                        -- 这个问题争取在3.8修复
                    end)
                end
            end
        end
    end

    -- 任务
    if self.PanelTaskBg.gameObject.activeInHierarchy then
        XTool.UpdateDynamicItem(self._GridTasks, data.TaskList, self.GridTask, XUiBountyChallengeChapterDetailTask, self)

        self:_PlayGridTaskEnableAnim()
    end
    
    self:UpdateButton()

    local bossIndex = self._Control:GetBossIndexInTable(data.BossId)
    for i, rimgBoss in ipairs(self.RImgBossList) do
        if rimgBoss then
            rimgBoss.gameObject:SetActiveEx(i == bossIndex)
        end
    end

    self:UpdateDifficultyUI()
end

function XUiBountyChallengeChapterDetail:UpdateButton()
    local taskCount = #self._Data.TaskList
    local finishCount = 0
    local reddotCount = 0
    for k,v in pairs(self._Data.TaskList) do
        if v.IsClear or v.IsCanFinish then
            finishCount = finishCount + 1
            if v.IsCanFinish then
                reddotCount = reddotCount + 1
            end
        end
    end
    self.ImgJindu.fillAmount = finishCount/taskCount
    self.TxtFinish.text = finishCount
    self.TxtAll.text ="/" .. taskCount
    self.BtnTask:ShowReddot(reddotCount > 0)
    self.IconComplete.gameObject:SetActiveEx(finishCount == taskCount)
    self.IconNormal.gameObject:SetActiveEx(finishCount ~= taskCount)
end

function XUiBountyChallengeChapterDetail:_OnClickDetail()
    XLuaUiManager.Open("UiBountyChallengePopupBossDetail")
end

function XUiBountyChallengeChapterDetail:_OnClickFight()
    self._Control:OpenRoom()
end

function XUiBountyChallengeChapterDetail:_OnClickTask()
    self.PanelTaskBg.gameObject:SetActiveEx(true)
    XTool.UpdateDynamicItem(self._GridTasks, self._Data.TaskList, self.GridTask, XUiBountyChallengeChapterDetailTask, self)
    self:_PlayGridTaskEnableAnim()
end

function XUiBountyChallengeChapterDetail:_OnClickCloseTask()
    self.PanelTaskBg.gameObject:SetActiveEx(false)
end

function XUiBountyChallengeChapterDetail:SetLine(index)
    index = index - 1
    local panelLine = self.PanelLine
    if panelLine then
        for i = 0, panelLine.childCount - 1 do
            local child = panelLine:GetChild(i)
            child.gameObject:SetActive(i == index)
        end
    end
end

function XUiBountyChallengeChapterDetail:UpdateDifficultyUI()
    local currentLevel = self._Control._DifficultyLevel
    local maxLevel = self._Control:GetBossMaxDifficultyLevel(self._Control._SelectedBossId)
    local isLianyuDifficulty = (currentLevel == maxLevel)

    self.PanelLianyu.gameObject:SetActiveEx(isLianyuDifficulty)
    self.BtnLianyu.gameObject:SetActiveEx(isLianyuDifficulty)
    self.BtnTongBlack.gameObject:SetActiveEx(not isLianyuDifficulty)
end

function XUiBountyChallengeChapterDetail:_PlayGridTaskEnableAnim()
    -- 任务序列动画
    if not self._HadPlayTaskUiAnim then
        -- 当任务没有折叠到子面板时，开启，这样不会反复播放
        -- self._HadPlayTaskUiAnim = true
        if not XTool.IsTableEmpty(self._GridTasks) then
            for i, v in ipairs(self._GridTasks) do
                v:PlayStartAnimation(i)
            end
        end
    end
end

return XUiBountyChallengeChapterDetail