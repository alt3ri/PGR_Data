---@class XBigWorldServiceAgency : XAgency Dlc公共服务
---@field private _Model XBigWorldServiceModel
local XBigWorldServiceAgency = XClass(XAgency, "XBigWorldServiceAgency")

---@type XBigWorldCondition
local XBigWorldCondition

local stringFormat = string.format

function XBigWorldServiceAgency:OnInit()
    self.DlcEventId = require("XModule/XBigWorldService/Common/XBigWorldEventId")

    self.ShopBuyGoodsCountLimit = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")

    self.RewardDisplayType = {
        Normal = 0,
        Expensive = 1,
        Special = 2,
    }
    self.RewardDisplayDataType = {
        Template = 1,
        RewardGoods = 2,
        Reward = 3,
    }

    self._RewardTypesWithoutCount = false
end

function XBigWorldServiceAgency:InitRpc()
    self:AddRpc("NotifyDlcQuestItemUpdate", handler(self, self.NotifyDlcQuestItemUpdate))
    self:AddRpc("NotifyDlcQuestItemObtainDisplay", handler(self, self.NotifyDlcQuestItemObtainDisplay))
end

function XBigWorldServiceAgency:InitEvent()

end

function XBigWorldServiceAgency:OnRelease()
    if XBigWorldCondition then
        XBigWorldCondition:OnRelease()
    end
end

function XBigWorldServiceAgency:GetDlcConditionTemplate(conditionId, noTips)
    return self._Model:GetDlcConditionTemplate(conditionId, noTips)
end

function XBigWorldServiceAgency:GetDlcConditionDesc(conditionId, noTips)
    local t = self._Model:GetDlcConditionTemplate(conditionId, noTips)
    return t and t.Desc or ""
end

function XBigWorldServiceAgency:_InitXBigWorldCondition()
    if XBigWorldCondition then return end
    XBigWorldCondition = require("XModule/XBigWorldService/Common/XBigWorldCondition").New()
end

function XBigWorldServiceAgency:RegisterConditionFunc(conditionType, func)
    self:_InitXBigWorldCondition()
    XBigWorldCondition:RegisterConditionFunc(conditionType, func)
end

function XBigWorldServiceAgency:UnRegisterConditionFunc(conditionType)
    self:_InitXBigWorldCondition()
    XBigWorldCondition:UnRegisterConditionFunc(conditionType)
end

function XBigWorldServiceAgency:CheckCondition(conditionId, ...)
    local template = self:GetDlcConditionTemplate(conditionId, true)
    -- 非Dlc内部
    if not template then
        return XConditionManager.CheckCondition(conditionId, ...)
    end
    self:_InitXBigWorldCondition()
    return XBigWorldCondition:CheckCondition(template, ...)
end

function XBigWorldServiceAgency:GetBigWorldTaskTemplate(taskId, noTip)
    return self._Model:GetBigWorldTaskTemplate(taskId, noTip)
end

function XBigWorldServiceAgency:GetBigWorldTaskTemplates()
    return self._Model:GetBigWorldTaskTemplates()
end

function XBigWorldServiceAgency:GetDlcRewardGoodsTemplate(rewardSubId, noTip)
    return self._Model:GetDlcRewardGoodsTemplate(rewardSubId, noTip)
end

function XBigWorldServiceAgency:GetRewardGoodDetailsTemplate(id, noTip)
    return self._Model:GetRewardGoodDetailsTemplate(id, noTip)
end

function XBigWorldServiceAgency:GetRewardGoodsDisplayType(id, noTip)
    local template = self:GetRewardGoodDetailsTemplate(id, noTip)

    return template and template.DisplayType or self.RewardDisplayType.Normal
end

function XBigWorldServiceAgency:GetRewardGoodsDisplayDataType(id, noTip)
    local template = self:GetRewardGoodDetailsTemplate(id, noTip)

    return template and template.DataType or self.RewardDisplayDataType.Template
end

function XBigWorldServiceAgency:GetDlcRewardTemplate(rewardId, noTip)
    return self._Model:GetDlcRewardTemplate(rewardId, noTip)
end

function XBigWorldServiceAgency:GetDlcRewardSubIds(rewardId, noTip)
    local template = self:GetDlcRewardTemplate(rewardId, noTip)
    return template and template.SubIds
end

function XBigWorldServiceAgency:GetText(key, ...)
    local t = self._Model:GetTextTemplate(key)
    if not t then
        XLog.Error("BigWorldText 不存在Key: " .. key)
        return ""
    end

    return stringFormat(t.Value, ...)
end

function XBigWorldServiceAgency:GetTextDialogTemplate(id)
    local t = self._Model:GetTextDialogTemplate(id)
    return t
end

function XBigWorldServiceAgency:GetNarrativeTitle(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return template and template.Title or ""
end

function XBigWorldServiceAgency:GetNarrativeType(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return template and template.Type or ""
end

function XBigWorldServiceAgency:GetNarrativeSignature(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return template and template.Signature or ""
end

function XBigWorldServiceAgency:GetNarrativeAssetUrl(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return template and template.AssetUrl or ""
end

function XBigWorldServiceAgency:GetNarrativeAlignment(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    return CS.UnityEngine.TextAnchor.__CastFrom(template and template.Alignment or 0)
end

function XBigWorldServiceAgency:GetNarrativeContent(id)
    local template = self._Model:GetNarrativeTextTemplate(id)
    local content
    if not string.IsNilOrEmpty(template.Content) then
        content = template and XUiHelper.ReplaceTextNewLine(template.Content) or ""
        -- 当策划使用 Alt+Enter 换行的时候，文本的首尾会有一个“，所以这里要去除
        if string.StartsWith(content, "\"") and string.EndsWith(content, "\"") then
            content = string.Utf8Sub(content, 2, string.Utf8Len(content) - 2)
        end
    else
        content = ""
    end

    return content
end

function XBigWorldServiceAgency:DebugCheckNarrativeExist(id)
    return self._Model:DebugCheckNarrativeExist(id)
end

function XBigWorldServiceAgency:TipText(key, ...)
    local text = self:GetText(key, ...)
    XUiManager.TipMsg(text)
end

-- region Item

---@return XItem
function XBigWorldServiceAgency:GetItemById(itemId)
    return self._Model:GetItem(itemId)
end

---@return XItem[]
function XBigWorldServiceAgency:GetItemsByItemType(itemType, isIncludeZero)
    return self._Model:GetItemsByType(itemType, isIncludeZero)
end

---@return XItem[]
function XBigWorldServiceAgency:GetItemsByItemTypes(itemTypes, isIncludeZero)
    return self._Model:GetItemsByTypes(itemTypes, isIncludeZero)
end

function XBigWorldServiceAgency:GetItemTemplateObject(itemId)
    if self:IsDlcItem(itemId) then
        return self._Model:GetItemTemplateObject(itemId)
    end

    return nil
end

---@return XTableItem
function XBigWorldServiceAgency:GetItemTemplate(itemId, isNoTip)
    if self:IsDlcItem(itemId) then
        return self._Model:GetItemTemplate(itemId, isNoTip)
    end

    return XDataCenter.ItemManager.GetItemTemplate(itemId)
end

function XBigWorldServiceAgency:GetItemDescription(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Description or ""
end

function XBigWorldServiceAgency:GetItemWorldDesc(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.WorldDesc or ""
end

function XBigWorldServiceAgency:GetItemName(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Name or ""
end

function XBigWorldServiceAgency:GetItemQuality(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Quality or 0
end

function XBigWorldServiceAgency:GetItemIcon(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.Icon or ""
end

function XBigWorldServiceAgency:GetItemBigIcon(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.BigIcon or ""
end

function XBigWorldServiceAgency:GetItemSkipIdParams(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.SkipIdParams
end

function XBigWorldServiceAgency:GetItemType(itemId)
    local template = self:GetItemTemplate(itemId)

    return template and template.ItemType
end

function XBigWorldServiceAgency:GetItemRecycleLeftTime(id)
    local leftTime = 0

    local item = self:GetItemById(id)

    if not item then
        return leftTime
    end

    local startTime = nil

    if item.Template.TimelinessType == XDataCenter.ItemManager.TimelinessType.FromConfig then
        startTime = XTime.ParseToTimestamp(item.Template.StartTime)
    elseif item.Template.TimelinessType == XDataCenter.ItemManager.TimelinessType.AfterGet then
        startTime = item.CreateTime
    end

    if startTime then
        local endTime = startTime + item.Template.Duration

        leftTime = endTime - XTime.GetServerNowTimestamp()
    end

    return leftTime
end

function XBigWorldServiceAgency:UseItem(id, recycleTime, count, callback, rewardIds)
    XDataCenter.ItemManager.Use(id, recycleTime, count, callback, rewardIds)
end

function XBigWorldServiceAgency:CheckItemAutoUseGift(itemList)
    if not XTool.IsTableEmpty(itemList) then
        -- 收集所有礼包的结果，一次弹出来
        local allReward = {}
        local rewardAmount = 0

        for _, data in pairs(itemList) do
            local id = data.Id

            if XDataCenter.ItemManager.IsAutoGift(id) then
                local leftTime = self:GetItemRecycleLeftTime(id)
                local count = data.Count or 0

                if count > 0 then
                    rewardAmount = rewardAmount + 1
                    self:UseItem(id, leftTime, count, function(rewardGoodList)
                        for i = 1, #rewardGoodList do
                            allReward[#allReward + 1] = rewardGoodList[i]
                        end
                        rewardAmount = rewardAmount - 1
                        if rewardAmount == 0 then
                            XMVCA.XBigWorldUI:OpenBigWorldObtain(allReward)
                        end
                    end)
                end
            end
        end
    end
end

function XBigWorldServiceAgency:IsDlcItem(itemId)
    return itemId >= 950000 and itemId <= 999999
end

function XBigWorldServiceAgency:GetItemsShowParams(data)
    if not data then
        return nil
    end

    local params = {}
    if type(data) == "number" then
        params.TemplateId = data
    else
        local templeteId = (data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id

        params.TemplateId = templeteId

        if self:CheckRewardTypeWithoutCountById(templeteId) then
            params.Count = nil
        else
            params.Count = data.Count
        end

        params.IsUseBigIcon = data.UseBigIcon or false
        params.IsAllowSkip = data.IsSkip and true or false
    end

    return params
end

function XBigWorldServiceAgency:GetItemGoodsShowParams(itemId)
    return {
        RewardType = XRewardManager.XRewardType.Item,
        TemplateId = itemId,
        Name = self:GetItemName(itemId),
        Quality = self:GetItemQuality(itemId),
        Icon = self:GetItemIcon(itemId),
        BigIcon = self:GetItemBigIcon(itemId),
        WorldDesc = self:GetItemWorldDesc(itemId),
        Description = self:GetItemDescription(itemId),
    }
end

function XBigWorldServiceAgency:GetItemCount(itemId)
    local item = self:GetItemById(itemId)

    return item and item.Count or 0
end

function XBigWorldServiceAgency:OnCheckRecoveryItemsCount()
    local itemIds = self._Model:GetRecoveryItemIds()

    if not XTool.IsTableEmpty(itemIds) then
        for _, itemId in pairs(itemIds) do
            local item = self._Model:GetRecoveryItem(itemId)

            if item then
                item:CheckCount()
            end
        end
    end
end

function XBigWorldServiceAgency:OnInitItemData(itemData)
    if self:IsDlcItem(itemData.Id) then
        local item = self:GetItemById(itemData.Id)

        if item then
            item:RefreshItem(itemData)
        end
    end
end

function XBigWorldServiceAgency:OnNotifyItemData(itemData)
    self:OnInitItemData(itemData)
end

function XBigWorldServiceAgency:OnNotifyItemRecycle(itemId)
    if self:IsDlcItem(itemId) then
        self._Model:RecycleItem(itemId)
    end
end

-- endregion

-- region Task

---@return XTaskData
function XBigWorldServiceAgency:GetTaskDataByTaskId(taskId)
    return XDataCenter.TaskManager.GetTaskDataById(taskId)
end

---@return XTaskData[]
function XBigWorldServiceAgency:GetTimeLimitTaskListByGroupId(taskGroupId, isSort, isIgnoreTimeId, taskDatas)
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId, isSort, isIgnoreTimeId, taskDatas)
end

function XBigWorldServiceAgency:GetTaskStateByTaskId(taskId)
    local taskData = self:GetTaskDataByTaskId(taskId)

    if taskData then
        return taskData.State
    end

    return XDataCenter.TaskManager.TaskState.InActive
end

function XBigWorldServiceAgency:GetTaskDescriptionByTaskId(taskId)
    local template = self:GetBigWorldTaskTemplate(taskId)

    return template and template.Desc or ""
end

function XBigWorldServiceAgency:GetTaskRewardIdByTaskId(taskId)
    local template = self:GetBigWorldTaskTemplate(taskId)

    return template and template.RewardId or 0
end

function XBigWorldServiceAgency:GetTaskResultByTaskId(taskId)
    local template = self:GetBigWorldTaskTemplate(taskId)

    return template and template.Result or 0
end

function XBigWorldServiceAgency:GetTaskPriorityByTaskId(taskId)
    local template = self:GetBigWorldTaskTemplate(taskId)

    return template and template.Priority or 0
end

function XBigWorldServiceAgency:CheckTaskInActive(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.InActive
end

function XBigWorldServiceAgency:CheckTaskStandby(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Standby
end

function XBigWorldServiceAgency:CheckTaskActive(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Active
end

function XBigWorldServiceAgency:CheckTaskAccepted(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Accepted
end

function XBigWorldServiceAgency:CheckTaskAchieved(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Achieved
end

function XBigWorldServiceAgency:CheckTaskFinish(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Finish
end

function XBigWorldServiceAgency:CheckTaskInvalid(taskId)
    return self:GetTaskStateByTaskId(taskId) == XDataCenter.TaskManager.TaskState.Invalid
end

function XBigWorldServiceAgency:FinishTask(taskId, callback)
    XDataCenter.TaskManager.FinishTask(taskId, callback)
end

function XBigWorldServiceAgency:FinishMultiTasks(taskIds, callback, notTip, isLoopReceive)
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, callback, notTip, isLoopReceive)
end

-- endregion

-- region QuestItem

function XBigWorldServiceAgency:InitQuestItemMap(map)
    self._Model:InitQuestItemMap(map)
end

function XBigWorldServiceAgency:GetQuestItemMap()
    return self._Model:GetQuestItemMap()
end

function XBigWorldServiceAgency:GetQuestItemCount(itemId)
    return self._Model:GetQuestItemCount(itemId)
end

function XBigWorldServiceAgency:IsQuestItemExist(itemId)
    return self._Model:IsQuestItemExist(itemId)
end

function XBigWorldServiceAgency:GetQuestItemParams(templateId)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("显示的道具数据TemplateId为空！")
        return
    end
    return {
        RewardType = XRewardManager.XRewardType.QuestItem,
        TemplateId = templateId,
        Name = XMVCA.XBigWorldQuest:GetQuestItemName(templateId),
        Icon = XMVCA.XBigWorldQuest:GetQuestItemIcon(templateId),
        Quality = XMVCA.XBigWorldQuest:GetQuestItemQuality(templateId),
        Priority = XMVCA.XBigWorldQuest:GetQuestItemPriority(templateId),
        WorldDesc = XMVCA.XBigWorldQuest:GetQuestItemWorldDescription(templateId),
        Description = XMVCA.XBigWorldQuest:GetQuestItemDescription(templateId),
    }
end

function XBigWorldServiceAgency:NotifyDlcQuestItemUpdate(data)
    self._Model:UpdateQuestItemMap(data.DlcQuestItemChangeDict)
end

function XBigWorldServiceAgency:NotifyDlcQuestItemObtainDisplay(data)
    if not data then
        XLog.Error("协议:NotifyDlcQuestItemObtainDisplay 推送内容为空！")
        return
    end
    local dict = data.DlcQuestItemChangeDict
    if XTool.IsTableEmpty(dict) then
        return
    end
    local rewardData = {}
    for id, item in pairs(dict) do
        rewardData[#rewardData + 1] = {
            Id = id,
            TemplateId = id,
            Count = item.Count,
        }
    end
    XMVCA.XBigWorldUI:OpenBigWorldObtain(rewardData, nil, nil, nil, true)
end

-- endregion

-- region Reward

function XBigWorldServiceAgency:GetRewardDataList(reward, isSort)
    if not reward then
        return {}
    end

    local typeOfData = type(reward)

    if typeOfData == "number" then
        if XMVCA.XBigWorldQuest:IsQuestItem(reward) then
            return { reward }
        end

        local rewardDatas = XRewardManager.GetRewardList(reward)

        if isSort then
            rewardDatas = XRewardManager.SortRewardGoodsList(rewardDatas)
        end

        return rewardDatas
    elseif typeOfData == "table" then
        if isSort then
            return XRewardManager.SortRewardGoodsList(reward)
        end

        return reward
    end

    XLog.Error("奖励数据有误，请检查数据: ", reward)

    return {}
end

function XBigWorldServiceAgency:CheckExpensiveReward(id, dataType)
    if not XTool.IsNumberValid(id) then
        return false
    end

    local displayType = self:GetRewardGoodsDisplayType(id, true)
    local displayDataType = self:GetRewardGoodsDisplayDataType(id, true)
    
    dataType = dataType or self.RewardDisplayDataType.Template

    return displayType == self.RewardDisplayType.Expensive and displayDataType == dataType
end

function XBigWorldServiceAgency:CheckSpecialReward(id, dataType)
    if not XTool.IsNumberValid(id) then
        return false
    end

    local displayType = self:GetRewardGoodsDisplayType(id, true)
    local displayDataType = self:GetRewardGoodsDisplayDataType(id, true)

    dataType = dataType or self.RewardDisplayDataType.Template

    return displayType == self.RewardDisplayType.Special and displayDataType == dataType
end

function XBigWorldServiceAgency:CheckRewardTypeWithoutCount(rewardType)
    if not self._RewardTypesWithoutCount then
        local values = XMVCA.XBigWorldCommon:GetCommonValues("RewardTypesWithoutCount")

        self._RewardTypesWithoutCount = {}
        if not XTool.IsTableEmpty(values) then
            for _, value in pairs(values) do
                self._RewardTypesWithoutCount[tonumber(value)] = true
            end
        end
    end

    return self._RewardTypesWithoutCount[rewardType] or false
end

function XBigWorldServiceAgency:CheckRewardTypeWithoutCountById(templateId)
    local rewardType = XArrangeConfigs.GetType(templateId)

    return self:CheckRewardTypeWithoutCount(rewardType)
end

function XBigWorldServiceAgency:CheckRewardCharacter(rewardType, templateId)
    return XRewardManager.IsRewardCharacter(rewardType, templateId)
end

function XBigWorldServiceAgency:CheckRewardEquip(rewardType, templateId)
    return XRewardManager.IsRewardEquip(rewardType, templateId)
end

-- endregion

-- region Partner

function XBigWorldServiceAgency:GetPartnerCountByTemplateId(templateId)
    return XDataCenter.PartnerManager.GetPartnerCountByTemplateId(templateId)
end

-- endregion

-- region Shop

function XBigWorldServiceAgency:GetShopGoodsBuyPriorityDescript(goodsId)
    return XShopConfigs.GetGoodsBuyPriorityDesc(goodsId)
end

function XBigWorldServiceAgency:GetShopBuyLimitLabel(clockId)
    return XShopConfigs.GetBuyLimitLabel(clockId)
end

function XBigWorldServiceAgency:GetShopLeftTime(endTime)
    return XShopManager.GetLeftTime(endTime)
end

function XBigWorldServiceAgency:GetShopLeftBuyTimes(shopId)
    return XShopManager.GetShopLeftBuyTimes(shopId)
end

function XBigWorldServiceAgency:GetShopGoodsList(shopId, notDebugError, ignoreSort)
    return XShopManager.GetShopGoodsList(shopId, notDebugError, ignoreSort)
end

function XBigWorldServiceAgency:RequestShopInfo(shopId, callback, noTip)
    XShopManager.GetShopInfo(shopId, callback, noTip)
end

function XBigWorldServiceAgency:RequestShopBuy(shopId, goodsId, count, callback, errorCallback, isActivityOpen)
    XShopManager.BuyShop(shopId, goodsId, count, callback, errorCallback, isActivityOpen)
end

-- endregion

-- region Goods

function XBigWorldServiceAgency:GetGoodsShowParamsByTemplateId(templateId)
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
end

function XBigWorldServiceAgency:GetGoodsIconByTemplateId(templateId)
    return XGoodsCommonManager.GetGoodsIcon(templateId)
end

function XBigWorldServiceAgency:GetGoodsNameByTemplateId(templateId)
    return XGoodsCommonManager.GetGoodsName(templateId)
end

function XBigWorldServiceAgency:GetGoodsCurrentCountByTemplateId(templateId)
    return XGoodsCommonManager.GetGoodsCurrentCount(templateId)
end

function XBigWorldServiceAgency:GetQualityIcon(quality)
    local key = self._Model:GetQualityPathKey(quality)

    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetString(key)
end

-- endregion

-- region Time

function XBigWorldServiceAgency:CheckInTimeByTimeId(timeId, defaultValue)
    return XFunctionManager.CheckInTimeByTimeId(timeId, defaultValue)
end

function XBigWorldServiceAgency:GetEndTimeByTimeId(timeId)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XBigWorldServiceAgency:GetStartTimeByTimeId(timeId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

-- endregion

return XBigWorldServiceAgency
