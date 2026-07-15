local XUiGridFashionStoryStage = XClass(nil, "XUiGridFashionStoryStage")

local XUiButtonState = {
    Normal = 0,
    Disable = 3
}

function XUiGridFashionStoryStage:Ctor(root, ui)
    self.Root = root
    XTool.InitUiObjectByUi(self, ui)
    self.Button:AddEventListener(Handler(self, self.OnClickEvent))
end

function XUiGridFashionStoryStage:RefreshData(stageId)
    self.Id = stageId
    self.Button:SetRawImage(XMVCA.XFashionStory:GetStoryStageFace(self.Id))
    --设置关卡名称
    self.Button:SetNameByGroup(0, XDataCenter.FubenManager.GetStageName(self.Id))

    self.IsOpen, self.UnLockReason = XMVCA.XFashionStory:CheckFashionStoryStageIsOpen(self.Id)
    if self.IsOpen then
        self.Button:SetButtonState(XUiButtonState.Normal)
        -- XUiBtton组件不支持多个rawimage的多状态设置，暂时通过设置子物体的RawImage来实现
        local isFinish = XDataCenter.FubenManager.CheckStageIsPass(self.Id)
        self.ImgFinish1.gameObject:SetActiveEx(isFinish)
        self.ImgFinish2.gameObject:SetActiveEx(isFinish)
    else
        self.Button:SetButtonState(XUiButtonState.Disable)
    end
end

function XUiGridFashionStoryStage:OnClickEvent()
    if self.Id then
        if self.IsOpen then
            XLuaUiManager.Open("UiFashionStoryDialog", self.Id)
        else
            local content
            if self.UnLockReason == XMVCA.XFashionStory.TrialStageUnOpenReason.PreStageUnPass then
                content = XUiHelper.GetText("FashionStoryTrialPreStagePassTip", XDataCenter.FubenManager.GetStageName(XMVCA.XFashionStory:GetPreStageId(self.Id)))
            elseif self.UnLockReason == XMVCA.XFashionStory.TrialStageUnOpenReason.OutOfTime then
                content = XUiHelper.GetText("FashionStoryTrialOutTime", XUiHelper.GetTimeYearMonthDay(XMVCA.XFashionStory:GetStageTimeId(self.Id)))
            end
            XUiManager.TipMsg(content)
        end
    end
end

return XUiGridFashionStoryStage
