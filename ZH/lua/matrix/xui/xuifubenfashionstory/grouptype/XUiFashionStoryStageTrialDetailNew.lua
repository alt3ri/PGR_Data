-- DEPRECATED: 旧版夏活试玩关详情 UI，现已统一接入 Experiment 试验关流程（UiPaintingExperiencePassV4P2）
-- 当前已无活跃调用入口，保留代码与 prefab 仅作历史参考与未来可能的复用
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiFashionStoryStageTrialDetailNew = XLuaUiManager.Register(XLuaUi, "UiFashionStoryStageTrialDetailNew")

--region 生命周期
function XUiFashionStoryStageTrialDetailNew:OnAwake()
    self.RewardList = {}
    self:AddListener()
end

function XUiFashionStoryStageTrialDetailNew:OnStart(trialStageId, closeParentCb, CloseTrialDetailCb)
    self.StageId = trialStageId
    self.CloseParentCb = closeParentCb
    self.CloseTrialDetailCb = CloseTrialDetailCb

    self:Refresh()
end

function XUiFashionStoryStageTrialDetailNew:OnEnable(trialStageId, closeParentCb, CloseTrialDetailCb)
    if trialStageId then self.StageId = trialStageId end
    if closeParentCb then self.CloseParentCb = closeParentCb end
    if CloseTrialDetailCb then self.CloseTrialDetailCb = CloseTrialDetailCb end

    self:Refresh()
end
--endregion

--region 初始化
function XUiFashionStoryStageTrialDetailNew:AddListener()
    self.BtnBack:AddEventListener(Handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(Handler(self, self.OnBtnMainUiClick))
    self.BtnEnter:AddEventListener(Handler(self, self.OnBtnEnterClick))

    self.BtnSkip1 = self.BtnSkip1 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelInformation/PanelSkip/BtnSkip1", "XUiButton")
    self.BtnSkip1:AddEventListener(Handler(self, self.OnBtnSkip1Click))
end
--endregion

--region 事件处理
function XUiFashionStoryStageTrialDetailNew:OnBtnBackClick()
    if self.CloseTrialDetailCb then
        self.CloseTrialDetailCb()
    end

    self:Close()
    self.ParentUi:PlayAnimation("AnimEnable")
end

function XUiFashionStoryStageTrialDetailNew:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFashionStoryStageTrialDetailNew:OnBtnSkip1Click()
    -- 3.6需求, 跳转商店
    XFunctionManager.SkipInterface(XMVCA.XFashionStory:GetFashionStorySkipId(XMVCA.XFashionStory:GetCurrentActivityId(), XMVCA.XFashionStory.FashionStorySkip.SkipToStore))
end

function XUiFashionStoryStageTrialDetailNew:OnBtnEnterClick()
    local leftTimeStamp = XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId())
    if leftTimeStamp <= 0 then
        XUiManager.TipText("FashionStoryActivityEnd")
        self.CloseParentCb()
        return
    end

    local isInTime = XMVCA.XFashionStory:IsTrialStageInTime(self.StageId)
    if isInTime then
        XMVCA.XFuben:OpenUiBattleRoleRoom(self.StageId)
    else
        XUiManager.TipText("FashionStoryTrialStageEnd")
    end
end
--endregion

--region 数据更新
function XUiFashionStoryStageTrialDetailNew:Refresh()
    -- 图标
    self.RImgNandu:SetRawImage(XMVCA.XFashionStory:GetTrialDetailHeadIcon(self.StageId))

    -- 名称
    self.TxtTitle.text = XFubenConfigs.GetStageName(self.StageId)

    -- 推荐等级
    self.TxtRecommendLevel.text = XMVCA.XFashionStory:GetTrialDetailRecommendLevel(self.StageId)

    -- 背景
    self.ImgFullScreen.gameObject:SetActiveEx(true)
    self.PanelSpine.gameObject:SetActiveEx(false)
    local spine = XMVCA.XFashionStory:GetTrialDetailSpine(self.StageId)
    if spine then
        self.PanelSpine.gameObject:SetActiveEx(true)
        self.PanelSpine.gameObject:LoadSpinePrefab(spine)
    else
        self.ImgFullScreen:SetRawImage(XMVCA.XFashionStory:GetTrialDetailBg(self.StageId))
    end

    -- 描述
    self.TxtDes.text = XUiHelper.ConvertLineBreakSymbol(XMVCA.XFashionStory:GetTrialDetailDesc(self.StageId))

    -- 奖励
    local rewardId = XFubenConfigs.GetFirstRewardShow(self.StageId)
    local rewardCount = 0

    if rewardId > 0 then
        local rewardsList = XRewardManager.GetRewardList(rewardId)
        if not rewardsList then
            return
        end
        rewardCount = #rewardsList

        local isPass = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
        for i = 1, rewardCount do
            local reward = self.RewardList[i]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
                reward = XUiGridCommon.New(self, obj)
                table.insert(self.RewardList, reward)
            end
            local temp = { ShowReceived = isPass }
            reward:Refresh(rewardsList[i], temp)
        end
    end

    -- 隐藏多余的奖励格子
    local gridCommonCount = #self.RewardList
    if gridCommonCount > rewardCount then
        for j = rewardCount + 1, gridCommonCount do
            self.RewardList[j]:Refresh()
        end
    end
end
--endregion

return XUiFashionStoryStageTrialDetailNew
