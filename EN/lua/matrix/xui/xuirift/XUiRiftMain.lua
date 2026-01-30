local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiRiftMain:XLuaUi 大秘境主界面
---@field _Control XRiftControl
local XUiRiftMain = XLuaUiManager.Register(XLuaUi, "UiRiftMain")

local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftGold3
}

function XUiRiftMain:OnAwake()
    self.RewardGridList = {}
    self:InitButton()
    self:InitComponent()
    self.BtnStory.gameObject:SetActiveEx(false) --v3.0没有剧情 隐藏剧情按钮
end

function XUiRiftMain:OnStart(param)
    self._Param = param
    self._Control:TryRequestSweepOpen()
end

function XUiRiftMain:InitButton()
    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRank)
    self:RegisterClickEvent(self.BtnStory, self.OnBtnStoryClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
end

function XUiRiftMain:OnEnable()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Rift)
    self:RefreshUiShow()
    self:SetTimer()

    if self._Param and self._Param.IsPlayScreenTween then
        self._Param.IsPlayScreenTween = false
        self:PlayAnimationWithMask("Enable")
    end
end

function XUiRiftMain:OnDisable()

end

function XUiRiftMain:OnDestroy()

end

function XUiRiftMain:RefreshUiShow()
    -- 目标(任务/权限回收)
    self:RefreshUiTask()
    -- 资源栏
    self.AssetActivityPanel:Refresh(ItemIds)
    -- 商店展示道具
    self:RefreshShopReward()
    -- 排行榜按钮
    self.IsRankUnlock, self.RankConditionDesc = self._Control:IsRankUnlock()
    self.BtnRanking:SetButtonState(self.IsRankUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    -- 商店开启时间
    local startTime = self._Control:GetActivityStartTime()
    local endTime = self._Control:GetActivityEndTime()
    local startStr = XTime.TimestampToGameDateTimeString(startTime, "MM.dd")
    local endStr = XTime.TimestampToGameDateTimeString(endTime, "MM.dd HH:mm")
    self.BtnShop:SetNameByGroup(0, string.format("%s-%s", startStr, endStr))
end

function XUiRiftMain:OnBtnBackClick()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Rift)
    self:Close()
end

function XUiRiftMain:OnBtnRank()
    if not self.IsRankUnlock then
        XUiManager.TipError(self.RankConditionDesc)
        return
    end
    XLuaUiManager.Open("UiRiftRanking")
end

function XUiRiftMain:SetTimer()
    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        local leftTime = endTimeSecond - XTime.GetServerNowTimestamp()
        local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = CS.XTextManager.GetText("ShopActivityItemCount", remainTime)
    end, nil, 0)
end

function XUiRiftMain:InitComponent()
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
end

-- 刷新任务ui
function XUiRiftMain:RefreshUiTask()
    local titleName, desc = self._Control:GetBtnShowTask()
    local isShow = titleName ~= nil
    self.PanelTask.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTaskName.text = titleName
        self.TxtTaskDesc.text = desc
        local isShowRed = self._Control:CheckTaskCanReward()
        self.BtnTask:ShowReddot(isShowRed)
    end
end

-- 刷新商店展示道具
function XUiRiftMain:RefreshShopReward()
    local config = self._Control:GetRiftShopById(1)
    for i, itemId in ipairs(config.ShowItemId) do
        local grid = self.RewardGridList[i]
        if grid == nil then
            local obj = self.GridReward
            if i > 1 then
                obj = CS.UnityEngine.GameObject.Instantiate(self.GridReward, self.GridReward.transform.parent)
            end
            grid = XUiGridCommon.New(self, obj)
            table.insert(self.RewardGridList, grid)
        end

        grid:Refresh({ TemplateId = itemId })
    end
end

function XUiRiftMain:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiRiftMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftMain:OnBtnShopClick()
    self._Control:OpenUiShop()
end

function XUiRiftMain:OnBtnStoryClick()
    XLuaUiManager.Open("UiRiftStory")
end

function XUiRiftMain:OnBtnFightClick()
    XLuaUiManager.Open("UiRiftChooseChapter", self._Control:GetChapterPanelParem())
end

return XUiRiftMain