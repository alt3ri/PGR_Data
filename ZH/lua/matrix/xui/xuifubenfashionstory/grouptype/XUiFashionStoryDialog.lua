-- 复用预制：Assets/Product/Ui/Prefab/UiArchiveStoryDialog.prefab（同时被 XUiArchiveStoryDialog 使用，改 prefab 需同步两边）
local XUiFashionStoryDialog = XLuaUiManager.Register(XLuaUi, "UiFashionStoryDialog")

local CSTextManagerGetText = CS.XTextManager.GetText

--region 生命周期
function XUiFashionStoryDialog:OnAwake()
    self:Init()
end

function XUiFashionStoryDialog:OnStart(stageId)
    self.StageId = stageId
    self:RefreshData()
end
--endregion

--region 初始化
function XUiFashionStoryDialog:Init()
    self.BtnEnterStoryBefore.gameObject:SetActiveEx(true)
    self.BtnEnterStoryAfter.gameObject:SetActiveEx(false)
    self.BtnEnterStoryBefore:SetName(CSTextManagerGetText("PlayStory"))

    self.BtnMask:AddEventListener(Handler(self, self.OnBtnMaskClick))
    self.BtnEnterStoryBefore:AddEventListener(Handler(self, self.OnPlayClick))
end
--endregion

--region 数据更新
function XUiFashionStoryDialog:RefreshData()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(XMVCA.XFashionStory:GetStoryStageDetailIcon(self.StageId))
end
--endregion

--region 事件处理
function XUiFashionStoryDialog:OnBtnMaskClick()
    self:Close()
end

function XUiFashionStoryDialog:OnPlayClick()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(self.StageId, function()
            --XMVCA.XFashionStory:RefreshStagePassedBySettleData({ StageId = self.StageId })
            XDataCenter.MovieManager.PlayMovie(beginStoryId, function()

            end)
        end)
    end
end
--endregion

return XUiFashionStoryDialog
