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
    self._GridTasks = {
        XUiBountyChallengeChapterDetailTask.New(self.GridTask1, self),
        XUiBountyChallengeChapterDetailTask.New(self.GridTask2, self),
    }

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
    self.TxtDetail1.text = data.Description

    -- 限定角色
    if #data.Characters > 0 then
        self.ListCharacter.gameObject:SetActive(true)
        XTool.UpdateDynamicItem(self._GridCharacters, data.Characters, self.GridCharacter, XUiBountyChallengeChapterDetailCharacter, self)
    else
        for i = 1, #self._GridCharacters do
            self._GridCharacters[i]:Close()
        end
        self.ListCharacter.gameObject:SetActive(false)
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
    -- 因为ui设计上，确保要有3格，不够的，用空格填充，所以这里需要把taskList扩充到至少3格
    for i = #data.TaskList + 1, 2 do
        table.insert(data.TaskList, false)
    end
    XTool.UpdateDynamicItem(self._GridTasks, data.TaskList, self.GridTask, XUiBountyChallengeChapterDetailTask, self)

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