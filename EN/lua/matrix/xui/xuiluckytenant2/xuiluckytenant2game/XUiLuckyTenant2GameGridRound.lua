---@class XUiLuckyTenant2GameGridRound : XUiNode
---@field _Root XLuaUi|XUiLuckyTenant2Game
---@field _Control XLuckyTenant2Control
---@field _Data table
local XUiLuckyTenant2GameGridRound = XClass(XUiNode, "XUiLuckyTenant2GameGridRound")

function XUiLuckyTenant2GameGridRound:OnStart()
    self:InitComponents()
end

function XUiLuckyTenant2GameGridRound:InitComponents()
    -- ImgBgNow 用于标识当前回合所在的 quest
    -- ImgBgComplete 用于标识已完成的 quest
    -- ImgBgNormal 用于标识普通/未开始的 quest
    -- TxtRound 显示 quest 的次序（1、2、3…），不显示回合数
    -- ImgPerfect 显示完美通关标识
    -- ImgNormal 显示普通通关标识
    -- 美术拼错了
    self.Perfect = self.Perfect or XUiHelper.TryGetComponent(self.Transform, "Image/Perfect", "RectTransform")
    self.Normal = self.Normal or XUiHelper.TryGetComponent(self.Transform, "Image/Nnormal", "RectTransform")
end

---@param data table quest数据，包含 Round、IsCurrentQuest、PerfectClear、NormalClear 字段
---@param currentRound number 当前回合数（可选，如果 data.IsCurrentQuest 已设置则不需要）
---@param questList table[] quest列表（可选，用于区间判断）
---@param index number 当前 quest 在列表中的索引（可选，用于区间判断）
function XUiLuckyTenant2GameGridRound:Update(data, currentRound, questList, index)
    self._Data = data
    if not data then
        return
    end

    -- 虚假轮次占位：仅显示 "..."
    if data.IsPlaceholder then
        if self.TxtRound then
            self.TxtRound.text = ". . ."
        end
        if self.ImgBgNow then self.ImgBgNow.gameObject:SetActiveEx(false) end
        if self.ImgBgComplete then self.ImgBgComplete.gameObject:SetActiveEx(false) end
        if self.ImgBgNormal then self.ImgBgNormal.gameObject:SetActiveEx(true) end
        if self.Perfect then self.Perfect.gameObject:SetActiveEx(false) end
        if self.Normal then self.Normal.gameObject:SetActiveEx(false) end
        return
    end

    -- 判断是否为当前回合所在的 quest（直接使用 Control 传递的值）
    local isCurrentQuest = data.IsCurrentQuest == true

    -- 只显示次序（第几个阶段），不显示 quest 的回合数；当前(浅色背景)字色 #326398，非当前(深色背景)字色 #6c92be
    if self.TxtRound then
        local order = (data.Index and data.Index > 0) and data.Index or 1
        self.TxtRound.text = XUiHelper.GetText("LuckyTenant2Round", tostring(order))
        self.TxtRound.color = isCurrentQuest and XUiHelper.Hexcolor2Color("326398") or XUiHelper.Hexcolor2Color("6c92be")
    end

    -- 判断任务是否已完成（当前回合 > quest.Round）
    local isComplete = false
    if currentRound and data.Round then
        isComplete = currentRound > data.Round
    end

    -- 显示/隐藏不同状态的背景
    -- 当前任务：显示 ImgBgNow
    if self.ImgBgNow then
        self.ImgBgNow.gameObject:SetActiveEx(isCurrentQuest)
    end
    -- 已完成：显示 ImgBgComplete
    if self.ImgBgComplete then
        self.ImgBgComplete.gameObject:SetActiveEx(isComplete and not isCurrentQuest)
    end
    -- 普通/未开始：显示 ImgBgNormal
    if self.ImgBgNormal then
        self.ImgBgNormal.gameObject:SetActiveEx(not isCurrentQuest and not isComplete)
    end

    -- 显示/隐藏通关标识（Perfect和Normal）
    local hasPerfectClear = data.PerfectClear == true
    local hasNormalClear = data.NormalClear == true

    -- 如果两者都存在，只显示Perfect
    local showPerfect = hasPerfectClear
    local showNormal = hasNormalClear and not hasPerfectClear
    if self.Perfect then
        self.Perfect.gameObject:SetActiveEx(showPerfect)
    end
    if self.Normal then
        self.Normal.gameObject:SetActiveEx(showNormal)
    end
end

return XUiLuckyTenant2GameGridRound
