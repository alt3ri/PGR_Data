--- 序章动态漫特定详情页
---@class XUiMainLineExhibitionPopupComic: XLuaUi
local XUiMainLineExhibitionPopupComic = XLuaUiManager.Register(XLuaUi, 'UiMainLineExhibitionPopupComic')

function XUiMainLineExhibitionPopupComic:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnPlay:AddEventListener(handler(self, self.OnBtnPlayClickEvent))
    self.BtnReview:AddEventListener(handler(self, self.OnBtnReviewClickEvent))
end

function XUiMainLineExhibitionPopupComic:OnStart(stageCfg)
    self.StageCfg = stageCfg
    
    self:RefreshStageBaseInfoShow()
    self:RefreshStageAssociateCharacterShow()
end

function XUiMainLineExhibitionPopupComic:OnEnable()
    self:RefreshReviewEntrance()
end

function XUiMainLineExhibitionPopupComic:RefreshStageBaseInfoShow()
    if not self.StageCfg then
        return
    end
    
    self.TxtName.text = XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('NewbiePreChapterExStageNameFormat', 1), self.StageCfg.Name)
    self.TxtDesc.text = self.StageCfg.Description

    if self.StageCfg.Icon then
        self.RImgCG:SetRawImage(self.StageCfg.Icon)
    end
end

function XUiMainLineExhibitionPopupComic:RefreshStageAssociateCharacterShow()
    local characterIds = XMVCA.XMainLine2:GetClientConfigNumberArray('NewbiePreChapterCGLinkCharacterIds')
    
    XUiHelper.RefreshCustomizedList(self.GridHead.transform.parent, self.GridHead, characterIds and #characterIds or 0, function(index, go)
        ---@type XUiComponent.XUiButton
        local uiButton = go:GetComponent(typeof(CS.XUiComponent.XUiButton))

        if uiButton then
            uiButton:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterIds[index]))
        end
    end)
end

function XUiMainLineExhibitionPopupComic:RefreshReviewEntrance()
    local conditionId = XMVCA.XMainLine2:GetClientNewbieMainLineLockCondition()
    
    local isShow = not XTool.IsNumberValidEx(conditionId) or not XConditionManager.CheckCondition(conditionId)

    self.BtnReview.gameObject:SetActiveEx(isShow)
end

function XUiMainLineExhibitionPopupComic:OnBtnPlayClickEvent()
    local stageId = self.StageCfg.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
    self:Close()
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
                if self.RootUi then
                    self.RootUi:RefreshForChangeDiff()
                end
            end)
        end)
    end
end

function XUiMainLineExhibitionPopupComic:OnBtnReviewClickEvent()
    -- 关闭章节界面，相当于“返回”到外面
    self:Close()
    XLuaUiManager.RemoveTopOne('UiFubenMainLineChapter')
    -- 重新打开主线前设置为旧样式
    XMVCA.XMainLine2:SetOpenExhibition(false)
    XLuaUiManager.OpenSingleUi('UiNewFuben', table.unpack(XMVCA.XMainLine2:GetClientConfigNumberArray('NewbiePreChapterSkipParams')))
end


return XUiMainLineExhibitionPopupComic