---@class XUiPanelBWNewsQuest : XUiNode
---@field Parent XUiBigWorldPopupNews
---@field _GridRewards XUiGridBWItem[]
---@field UiBigWorldCommonBtnBigConfirm XUiComponent.XUiButton
local XUiPanelBWNewsQuest = XClass(XUiNode, "XUiPanelBWNewsQuest")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiPanelBWNewsQuest:OnStart()
    self._GridRewards = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self.UiBigWorldCommonBtnBigConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    if self.BtnTeach then
        self.BtnTeach:AddEventListener(handler(self.Parent, self.Parent.OnBtnTeachClick))
    end
    self.LockTips = self.LockTips or self.Transform:Find("PanelContent/LockTips")
end

function XUiPanelBWNewsQuest:Refresh(newsId)
    self._NewsId = newsId
    self:Open()
    self.TxtTitle.text = XMVCA.XBigWorldNews:GetNewsTitle(newsId)
    self.TxtDetail.text = XMVCA.XBigWorldNews:GetNewsContent(newsId)
    self.RImgPoster:SetRawImage(XMVCA.XBigWorldNews:GetNewsBgPic(newsId))
    self._FirstNotPassConditionIndex = XMVCA.XBigWorldNews:GetNewsFirstLockCondition(newsId)
    self:RefreshReward(XMVCA.XBigWorldNews:GetNewsShowReward(newsId))
    self.Parent:RefreshTeach(self.BtnTeach)
    self:RefreshButton()
end

function XUiPanelBWNewsQuest:RefreshReward(rewardId)
    if not rewardId or rewardId <= 0 then
        for _, grid in pairs(self._GridRewards) do
            grid:Close()
        end
        return
    end
    local rewards = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
    XTool.UpdateDynamicItem(self._GridRewards, rewards, self.GridCommon, XUiGridBWItem, self)
end

function XUiPanelBWNewsQuest:RefreshButton()
    local isPassed = self._FirstNotPassConditionIndex <= 0
    if isPassed then
        self.LockTips.gameObject:SetActiveEx(false)
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("SkipTo"))
    else
        self.LockTips.gameObject:SetActiveEx(true)
        local preConditions = XMVCA.XBigWorldNews:GetNewsPreConditions(self._NewsId)
        self.UiBigWorldCommonBtnBigConfirm:ShowTag(XMVCA.XBigWorldNews:CheckQuestNewsHasNew(self._NewsId))
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("SkipToFinshPreCondition"))
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(1, XMVCA.XBigWorldService:GetDlcConditionDesc(preConditions[self._FirstNotPassConditionIndex]))
    end
    local finish = self.Parent:CheckFinish(self._NewsId)
    self.UiBigWorldCommonBtnBigConfirm:SetDisable(finish, not finish)
end

function XUiPanelBWNewsQuest:OnBtnConfirmClick()
    local isPassed = self._FirstNotPassConditionIndex <= 0
    local skipId
    if isPassed then
        skipId = XMVCA.XBigWorldNews:GetNewsSkipId(self._NewsId)
    else
        local preSkipIds = XMVCA.XBigWorldNews:GetNewsPreSkipIds(self._NewsId)
        skipId = preSkipIds[self._FirstNotPassConditionIndex]
    end
    XMVCA.XBigWorldNews:MarkQuestNewsPreConditionTag(self._NewsId, self._FirstNotPassConditionIndex)
    XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
end

return XUiPanelBWNewsQuest