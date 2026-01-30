local XUiBountyChallengeChapterDetailCharacter = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailCharacter")
local XUiBountyChallengeChapterDetailTask = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailTask")
local XUiBountyChallengeChapterDetailDifficulty = require("XUi/XUiBountyChallenge/XUiBountyChallengeChapterDetailDifficulty")

---@class XUiBountyChallengeChapterDetail : XLuaUi
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetail = XLuaUiManager.Register(XLuaUi, "UiBountyChallengeChapterDetail")

function XUiBountyChallengeChapterDetail:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(nil, "BountyChallengeHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self._OnClickDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self._OnClickFight)

    ---@type XUiBountyChallengeChapterDetailCharacter[]
    self._GridCharacters = {}

    ---@type XUiBountyChallengeChapterDetailTask[]
    self._GridTasks = {}

    ---@type XUiBountyChallengeChapterDetailDifficulty[]
    self._GridDifficulty = {}

    self.RImgBoss = self.RImgBoss or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/RImgBoss", "RawImage")

    self.PanelList:Init({}, function(index)
    end)
end

---@param data XUiBountyChallengeMainGridData
function XUiBountyChallengeChapterDetail:OnStart(data)
    self._Control:SetSelectedBoss(data.BossId, 1)
    --self._Control:SetDifficultyLevel(data.DifficultyLevel)
end

function XUiBountyChallengeChapterDetail:OnEnable()
    local level = self._Control:SetDefaultDifficultyLevel()
    --self._Control:AutoFinishTask(function()
    --    self:Update()
    --end)
    self:SetLine(level)
    self:Update()
end

function XUiBountyChallengeChapterDetail:OnDisable()

end

function XUiBountyChallengeChapterDetail:Update()
    local data = self._Control:GetUiChapterDetail()
    self._Data = data
    self.TxtName.text = data.Name
    --self.TxtDetail1.text = data.Description

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
    XTool.UpdateDynamicItem(self._GridTasks, data.TaskList, self.GridTask, XUiBountyChallengeChapterDetailTask, self)
    
    -- 任务序列动画
    if not self._HadPlayTaskUiAnim then
        self._HadPlayTaskUiAnim = true
        if not XTool.IsTableEmpty(self._GridTasks) then
            for i, v in ipairs(self._GridTasks) do
                v:PlayStartAnimation(i)
            end
        end
    end

    if self.RImgBoss then
        self.RImgBoss:SetRawImage(data.Icon)
    end
end

function XUiBountyChallengeChapterDetail:_OnClickDetail()
    XLuaUiManager.Open("UiBountyChallengePopupBossDetail")
end

function XUiBountyChallengeChapterDetail:_OnClickFight()
    self._Control:OpenRoom()
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

return XUiBountyChallengeChapterDetail