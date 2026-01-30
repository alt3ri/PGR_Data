local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")

---@class XUiLineArithmetic2TaskGrid : XDynamicGridTask
local XUiLineArithmetic2TaskGrid = XClass(XDynamicGridTask, "XUiLineArithmetic2TaskGrid")

function XUiLineArithmetic2TaskGrid:OnBtnFinishClick()
    local taskDatas = XMVCA.XLineArithmetic2:GetTaskList()
    for i = 1, #taskDatas do
        local taskId = taskDatas[i].Id
        local config = XDataCenter.TaskManager.GetTaskTemplate(taskId)

        local weaponCount = 0
        local chipCount = 0
        local rewards = XRewardManager.GetRewardList(config.RewardId)
        for i = 1, #rewards do
            local rewardsId = self.RewardPanelList[i].TemplateId
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

    local taskIds = {}
    for i = 1, #taskDatas do
        if taskDatas[i].State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(taskIds, taskDatas[i].Id)
        end
    end
    if #taskIds == 0 then
        return
    end
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
        local horizontalNormalizedPosition = 0
        self:OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
    end)
end

return XUiLineArithmetic2TaskGrid