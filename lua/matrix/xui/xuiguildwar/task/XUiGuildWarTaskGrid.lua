local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGuildWarTaskGrid: XDynamicGridTask
local XUiGuildWarTaskGrid = XClass(XDynamicGridTask, "XUiGuildWarTaskGrid")

function XUiGuildWarTaskGrid:ResetData(data)
    if data.TaskType ~= XGuildWarConfig.SubTaskType.Real then
        if not data then
            self.GameObject:SetActiveEx(false)
            return
        end
        self.GameObject:SetActiveEx(true)
        self.ImgComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
        self.Data = data

        local config = XGuildWarConfig.GetCfgByIdKey(
            XGuildWarConfig.TableKey.Task,
            self.Data.GuildWarTaskId
        )
        self.tableData = config
        self.TxtTaskName.text = config.Name
        self.TxtTaskDescribe.text = config.Desc
        self.TxtSubTypeTip.text = ""
        --self.RootUi:SetUiSprite(self.RImgTaskType, config.Icon)
        self.RImgTaskType:SetRawImage(config.Icon)
        self:UpdateProgress(self.Data)
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        -- reset reward panel
        for i = 1, #self.RewardPanelList do
            self.RewardPanelList[i]:Refresh()
        end

        if not rewards then
            return
        end

        for i = 1, #rewards do

            local panel = self.RewardPanelList[i]
            if not panel then
                if #self.RewardPanelList == 0 then
                    panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
                else
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                    ui.transform:SetParent(self.GridCommon.parent, false)
                    panel = XUiGridCommon.New(self.RootUi, ui)
                end
                table.insert(self.RewardPanelList, panel)
            end
            panel:Refresh(rewards[i])

        end
        if self.PanelAnimationGroup then
            self.PanelAnimationGroup.alpha = 1
        end
    else
        XUiGuildWarTaskGrid.Super.ResetData(self, data)
    end
    
    -- 设置一键领取
    self:SetReceiveAll()
end
--=================
--临时任务不走一般奖励领取逻辑，重写基类的领取按钮方法
--=================
function XUiGuildWarTaskGrid:OnBtnSkipClick()
    if not self.Data then return end
    if self.Data.TaskType == XGuildWarConfig.SubTaskType.Real then
        XUiGuildWarTaskGrid.Super.OnBtnSkipClick(self)
    end
end
--=================
--刷新任务进度
--=================
function XUiGuildWarTaskGrid:UpdateProgress(data)
    if data.TaskType ~= XGuildWarConfig.SubTaskType.Real then
        self.Data = data
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        self.TxtTaskNumQian.gameObject:SetActive(false)
        self.BtnFinish.gameObject:SetActive(false)
        if self.BtnReceiveHave then
            self.BtnReceiveHave.gameObject:SetActive(false)
        end
        local isFinish = (data.State == XDataCenter.TaskManager.TaskState.Finish)
        if isFinish then
            self.BtnSkip.gameObject:SetActive(false)
        --判断该轮是否在当期所在公会里玩的工会战
        elseif not XDataCenter.GuildWarManager.CheckIsInGuildByRound(self.Data.RoundId) then
            self.BtnSkip.gameObject:SetActive(true)
            self.BtnSkip:SetNameByGroup(1, XUiHelper.GetText("GuildWarTaskExpireName"))
            self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
        elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
            self.BtnSkip.gameObject:SetActive(true)
            self.BtnSkip:SetNameByGroup(1, XUiHelper.GetText("GuildWarTaskDisableName"))
            self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
        end
    else
        self.BtnSkip:SetNameByGroup(1, XUiHelper.GetText("GuildWarTaskDisableName"))
        XUiGuildWarTaskGrid.Super.UpdateProgress(self, data)
    end
end

---@overload 重写一键领取的方法
function XUiGuildWarTaskGrid:OnBtnAllReceiveClick()
    local weaponCount = 0
    local chipCount = 0

    if XTool.IsTableEmpty(self.AllAchieveTaskDatas) then
        return
    end
    
    for key, taskId in pairs(self.AllAchieveTaskDatas) do --装备上限判断
        local tableData = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        local rewards = XRewardManager.GetRewardList(tableData.RewardId)
        for i = 1, #rewards do
            local rewardsId = rewards[i].TemplateId
            if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
                weaponCount = weaponCount + 1
            elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
                chipCount = chipCount + 1
            end
        end
        if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
                chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
            return
        end
    end

    --批量领取任务奖励
    if self.Data.ReceiveCb then
        self.Data.ReceiveCb()
    else
        local taskIds = self.AllAchieveTaskDatas
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
            local horizontalNormalizedPosition = 0
            self:OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
        end)
    end
end

function XUiGuildWarTaskGrid:SetAllReceiveTaskIds(ids)
    self.AllAchieveTaskDatas = ids
end

return XUiGuildWarTaskGrid