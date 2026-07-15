local XUiGridFashionStoryTrialStage = XClass(nil, "XUiGridFashionStoryTrialStage")

local XUiButtonState = {
    Normal = 0,
    Disable = 3
}

function XUiGridFashionStoryTrialStage:Ctor(root, ui)
    self.Root = root
    XTool.InitUiObjectByUi(self, ui)
    self.GridFitting:AddEventListener(Handler(self, self.OnClickEvent))
end

function XUiGridFashionStoryTrialStage:RefreshData(id)
    self.Id = id
    self._LastLockText = nil
    --设置基本信息
    self.GridFitting:SetNameByGroup(0, XDataCenter.FubenManager.GetStageName(self.Id))
    self.GridFitting:SetRawImage(XMVCA.XFashionStory:GetEntryTrialFace(self.Id))
    local imgName = XMVCA.XFashionStory:GetEntryTrialImgName(self.Id)
    self.TitleNameNormal:SetRawImage(imgName)
    self.TitleNamePress:SetRawImage(imgName)
    self.RImgIconMask:SetRawImage(XMVCA.XFashionStory:GetEntryTrialLockIcon(self.Id))

    --判断是否解锁
    local isOpen, unOpenReason = XMVCA.XFashionStory:CheckTrialStageIsOpenByTimeId(self.Id)
    self.IsOpen = isOpen
    self.UnOpenReason = unOpenReason
    if self.IsOpen then
        self.GridFitting:SetButtonState(XUiButtonState.Normal)
    else
        self.GridFitting:SetButtonState(XUiButtonState.Disable)
        if unOpenReason == XMVCA.XFashionStory.TrialStageUnOpenReason.OutOfTime then
            local timeId = XMVCA.XFashionStory:GetTrialStageTimeId(self.Id)
            self:_SetLockText(XMVCA.XFashionStory:GetTimeLockText(timeId))
        end
    end
end

-- 父界面倒计时 tick 时调用：状态翻转走完整 RefreshData，未翻转只刷锁定倒计时文本
function XUiGridFashionStoryTrialStage:RefreshLockCountDown()
    if not self.TxtLock or self.IsOpen then return end
    if self.UnOpenReason ~= XMVCA.XFashionStory.TrialStageUnOpenReason.OutOfTime then return end
    local isOpen = XMVCA.XFashionStory:CheckTrialStageIsOpenByTimeId(self.Id)
    if isOpen then
        self:RefreshData(self.Id)
        return
    end
    local timeId = XMVCA.XFashionStory:GetTrialStageTimeId(self.Id)
    self:_SetLockText(XMVCA.XFashionStory:GetTimeLockText(timeId))
end

function XUiGridFashionStoryTrialStage:_SetLockText(text)
    if self._LastLockText == text then return end
    self._LastLockText = text
    self.TxtLock.text = text
    -- 刷新布局，避免锁定提示文本被锁定图标遮挡
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TxtLock.transform.parent)
end

function XUiGridFashionStoryTrialStage:OnClickEvent()
    if self.Id then
        if self.IsOpen then
            -- 原入口（历史参考，已统一走 Experiment 试验关流程）
            -- self.Root:OpenOneChildUi("UiFashionStoryStageTrialDetailNew", self.Id, handler(self.Root, self.Root.Close))

            -- v4.6 改为试验关跳转
            local trialLevel = XDataCenter.FubenExperimentManager.GetTrialLevelByStageId(self.Id)
            if trialLevel then
                XLuaUiManager.Open("UiPaintingExperiencePassV4P2", trialLevel.Id)
            else
                XLog.Error(string.format("[XUiGridFashionStoryTrialStage] 未找到 StageId=%s 对应的 TrialLevel，请检查 ExperimentLevel.tab 中的 SingStageId 配置", tostring(self.Id)))
                XUiManager.TipText("CommonNotOpen")
            end
        else
            XUiManager.TipMsg(self.TxtLock.text)
        end
    end
end

return XUiGridFashionStoryTrialStage
