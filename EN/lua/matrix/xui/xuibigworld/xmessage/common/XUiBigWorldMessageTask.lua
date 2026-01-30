---@class XUiBigWorldMessageTask : XUiNode
---@field ImgIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field ImgGo UnityEngine.UI.Image
---@field ImgComplete UnityEngine.UI.Image
---@field BtnTask XUiComponent.XUiButton
local XUiBigWorldMessageTask = XClass(XUiNode, "XUiBigWorldMessageTask")

-- region 生命周期

function XUiBigWorldMessageTask:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageTask:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageTask:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessageTask:OnDestroy()

end

function XUiBigWorldMessageTask:OnTaskSkip()
    if self._QuestId then
        local questData = XMVCA.XBigWorldQuest:GetQuestData(self._QuestId)

        if questData and not questData:IsFinish() then
            XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest(1, self._QuestId)
        end
    end
end

-- endregion

function XUiBigWorldMessageTask:Refresh(questId)
    ---@type XBigWorldQuest
    local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)

    if questData then
        self._QuestId = questId
        self.TxtTitle.text = XMVCA.XBigWorldQuest:GetQuestText(questId)
        self.ImgIcon:SetSprite(XMVCA.XBigWorldQuest:GetQuestIcon(questId))
        self:_RefreshTaskState(questData)
        self:_RefreshTaskColor(questId)
    else
        self._QuestId = false
        self:Close()
    end
end

function XUiBigWorldMessageTask:PlayEnableAnimation()
    self:PlayAnimation("PanelTaskEnable")
end

function XUiBigWorldMessageTask:RefreshState(questId)
    if self:IsNodeShow() then
        if self._QuestId and self._QuestId == questId then
            local questData = XMVCA.XBigWorldQuest:GetQuestData(questId)

            self:_RefreshTaskState(questData)
        end
    end
end

-- region 私有方法

function XUiBigWorldMessageTask:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterCommonClickEvent(self, self.BtnTask, self.OnTaskSkip)
end

function XUiBigWorldMessageTask:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageTask:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageTask:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageTask:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageTask:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMessageTask:_RefreshTaskColor(questId)
    local color = XMVCA.XBigWorldQuest:GetQuestTypeMessageColorWithQuestId(questId)

    if not string.IsNilOrEmpty(color) then
        color = XUiHelper.Hexcolor2Color(color)
        self.BtnTask:SetImgRGB(color)
    end
end

---@param questData XBigWorldQuest
function XUiBigWorldMessageTask:_RefreshTaskState(questData)
    if questData then
        self.ImgGo.gameObject:SetActiveEx(not questData:IsFinish())
        self.ImgComplete.gameObject:SetActiveEx(questData:IsFinish())
    end
end

-- endregion

return XUiBigWorldMessageTask
