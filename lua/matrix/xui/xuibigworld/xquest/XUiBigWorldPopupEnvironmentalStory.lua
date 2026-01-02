---@class XUiGirdBigWorldEnvironmentalStory : XUiNode
local XUiGirdBigWorldEnvironmentalStory = XClass(XUiNode, "XUiGirdBigWorldEnvironmentalStory")

function XUiGirdBigWorldEnvironmentalStory:OnStart()
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))
end

function XUiGirdBigWorldEnvironmentalStory:Refresh(id)
    self.RImgCharacter:SetRawImage(XMVCA.XBigWorldQuest:GetEnvironmentQuestRoleIcon(id))
    self.TxtName.text = XMVCA.XBigWorldQuest:GetEnvironmentQuestName(id)
    local reward = XMVCA.XBigWorldQuest:GetEnvironmentQuestShowReward(id)
    
    self:RefreshReward(reward)
    local cur, sum = XMVCA.XBigWorldQuest:GetEnvironmentProgress(id)
    self.BtnGo:SetNameByGroup(0, string.format("%s/%s", cur, sum))
    local complete = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(id)
    self.BtnReward:ShowTag(complete)
    self._SkipId = XMVCA.XBigWorldQuest:GetEnvironmentQuestSkipId(id)
end

function XUiGirdBigWorldEnvironmentalStory:RefreshReward(rewardId)
    self._GoodsParams = nil
    local rewardList
    if rewardId and rewardId > 0 then
        rewardList = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
        --local reward = rewardList[1]
        --if reward then
            --local id = reward.TemplateId or reward.Id
            --self._GoodsParams = XMVCA.XBigWorldService:GetGoodsShowParamsByTemplateId(id)
            --self.BtnReward:SetRawImage(self._GoodsParams.Icon)
        --end
    end
    self._RewardList = rewardList
    self.BtnReward.gameObject:SetActiveEx(rewardList ~= nil)
end

function XUiGirdBigWorldEnvironmentalStory:OnBtnRewardClick()
    if not self._RewardList then
        return
    end
    XMVCA.XBigWorldUI:OpenBigWorldObtain(self._RewardList, XMVCA.XBigWorldService:GetText("TipReward"), nil, true)
end

function XUiGirdBigWorldEnvironmentalStory:OnBtnGoClick()
    if not self._SkipId or self._SkipId <= 0 then
        XLog.Warning("无法跳转，跳转Id为空")
        return
    end
    XMVCA.XBigWorldSkipFunction:SkipTo(self._SkipId)
end


---@class XUiBigWorldPopupEnvironmentalStory : XBigWorldUi
local XUiBigWorldPopupEnvironmentalStory = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupEnvironmentalStory")

function XUiBigWorldPopupEnvironmentalStory:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPopupEnvironmentalStory:OnStart(id)
    self._DefaultIndex = self:CalIndexByEnvironmentId(id)
    self:InitView()
end

function XUiBigWorldPopupEnvironmentalStory:InitUi()
    self._DataList = self:SortEnvironmentIds(XMVCA.XBigWorldQuest:GetEnvironmentIds())
    self.GridStory.gameObject:SetActiveEx(false)
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListStory, XUiGirdBigWorldEnvironmentalStory)
end

function XUiBigWorldPopupEnvironmentalStory:InitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
end

function XUiBigWorldPopupEnvironmentalStory:InitView()
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(self._DefaultIndex)
end

---@param grid XUiGirdBigWorldEnvironmentalStory
function XUiBigWorldPopupEnvironmentalStory:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DataList[index])
    end
end

function XUiBigWorldPopupEnvironmentalStory:SortEnvironmentIds(ids)
    if XTool.IsTableEmpty(ids) then
        return
    end
    
    table.sort(ids, function(a, b) 
        local finishA = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(a)
        local finishB = XMVCA.XBigWorldQuest:CheckEnvironmentFinish(b)
        if finishA ~= finishB then
            return finishB
        end
        
        local pA = XMVCA.XBigWorldQuest:GetEnvironmentQuestPriority(a)
        local pB = XMVCA.XBigWorldQuest:GetEnvironmentQuestPriority(b)
        if pA ~= pB then
            return pA > pB
        end
        return a < b
    end)
    return ids
end

function XUiBigWorldPopupEnvironmentalStory:CalIndexByEnvironmentId(id)
    if not id or id <= 0 then
        return 1
    end
    for index, environmentId in pairs(self._DataList) do
        if environmentId == id then
            return index
        end
    end
    return 1
end