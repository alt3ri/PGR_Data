local XUiGridFashionStoryGroup = XClass(nil, "XUiGridFashionStoryGroup")

local XUiButtonState = {
    Normal = 0,
    Disable = 3
}

function XUiGridFashionStoryGroup:Ctor(root, ui)
    self.Root = root
    XTool.InitUiObjectByUi(self, ui)

    --注册点击事件打开关卡组界面
    self.PanelSummer:AddEventListener(Handler(self, self.OnClickEvent))
end

function XUiGridFashionStoryGroup:Refresh(groupId)
    self.GroupId = groupId
    --读取配置表显示信息
    self.PanelSummer:SetNameByGroup(0, XMVCA.XFashionStory:GetSingleLineName(self.GroupId))
    self.PanelSummer:SetRawImage(XMVCA.XFashionStory:GetSingleLineAsGroupStoryIcon(self.GroupId))
    self.PanelSummer:SetSprite(XMVCA.XFashionStory:GetStoryDecorateIcon(self.GroupId))
    --判断是否解锁
    self.IsOpen, self.LockReason = XMVCA.XFashionStory:CheckGroupIsCanOpen(self.GroupId)
    if self.IsOpen then
        self.PanelSummer:SetButtonState(XUiButtonState.Normal)
        --读取当进度数据显示信息
        local stagesCount = XMVCA.XFashionStory:GetSingleLineStagesCount(self.GroupId)
        local passedCount = XMVCA.XFashionStory:GetGroupStagesPassCount(XMVCA.XFashionStory:GetSingleLineStages(self.GroupId))

        self.PanelSummer:SetNameByGroup(1, tostring(passedCount) .. "/" .. tostring(stagesCount))
        -- XUiBtton组件不支持多个rawimage的多状态设置，暂时通过设置子物体的RawImage来实现
        local isFinish = passedCount >= stagesCount
        self.ImgFinish1.gameObject:SetActiveEx(isFinish)
        self.ImgFinish2.gameObject:SetActiveEx(isFinish)
    else
        self.PanelSummer:SetButtonState(XUiButtonState.Disable)
        self:RefreshLockTip()
    end
    --红点
    XRedPointManager.CheckOnceByButton(self.PanelSummer, { XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK }, self.GroupId)
end

function XUiGridFashionStoryGroup:OnClickEvent()
    XMVCA.XFashionStory:EnterPaintingGroupPanel(self.GroupId, self.IsOpen, self.LockReason)
end

function XUiGridFashionStoryGroup:RefreshLockTip()
    if not self.TxtLock then return end
    if self.LockReason == XMVCA.XFashionStory.GroupUnOpenReason.OutOfTime then
        local timeId = XMVCA.XFashionStory:GetSingleLineTimeId(self.GroupId)
        self.TxtLock.text = XMVCA.XFashionStory:GetTimeLockText(timeId)
    elseif self.LockReason == XMVCA.XFashionStory.GroupUnOpenReason.PreGroupUnPass then
        local preGroupId = XMVCA.XFashionStory:GetPreSingleLineId(self.GroupId)
        self.TxtLock.text = XUiHelper.GetText("FashionStoryGroupPassTip", XMVCA.XFashionStory:GetSingleLineName(preGroupId))
    end
    -- 刷新布局，避免锁定提示文本被锁定图标遮挡
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TxtLock.transform.parent)
end

return XUiGridFashionStoryGroup
