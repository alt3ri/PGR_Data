---@class XUiGridMainWheelchairEntranceEx: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridMainWheelchairEntranceEx = XClass(XUiNode, 'XUiGridMainWheelchairEntranceEx')
local XUiGridBubbleShow = require('XUi/XUiWheelchairManual/UiExWheelchairManualMainEntrance/XUiGridBubbleShow')

---@param rootUi XLuaUi
function XUiGridMainWheelchairEntranceEx:OnStart(rootUi)
    self.RootUi = rootUi
    self.CommonTaskRewardLeft = self.Transform:LoadPrefabEx(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('ExmainEntranceBubbleResPath'))
    
    if self.CommonTaskRewardLeft then
        self.CommonTaskRewardLeft.transform:SetAsFirstSibling()
        self.CommonTaskRewardLeft.gameObject:SetActiveEx(false)
        self.BubbleShow = XUiGridBubbleShow.New(self.CommonTaskRewardLeft, self, self.RootUi)
    end
end

function XUiGridMainWheelchairEntranceEx:OnEnable()
    self:RefreshBubbleShow()
end

function XUiGridMainWheelchairEntranceEx:RefreshBubbleShow()
    local cfgs = self._Control:GetWheelchairManualCoreRewardPreviewCfgs()

    local showList = nil
    
    if cfgs then
        showList = {}
        
        for i, v in pairs(cfgs) do
            if XTool.IsNumberValidEx(v.RewardId) then
                if not self._Control:CheckManualRewardIsGet(v.RewardId) then
                    local rewardId = self._Control:GetBPRewardIdById(v.RewardId)
                    local reward = XRewardManager.GetRewardInListNoCount(rewardId)

                    if reward then
                        table.insert(showList, reward)
                    end
                end
            elseif XTool.IsNumberValidEx(v.PlanId) then
                if not self._Control:CheckPlanIsGetReward(v.PlanId) then
                    local rewardId = self._Control:GetManualPlanRewardId(v.PlanId)

                    if XTool.IsNumberValidEx(rewardId) then
                        local reward = XRewardManager.GetRewardInListNoCount(rewardId)

                        if reward then
                            table.insert(showList, reward)
                        end
                    end
                end    
            end    
                
        end
    end
    
    local hasRewardShow = not XTool.IsTableEmpty(showList)

    if self.BubbleShow then
        if hasRewardShow then
            self.BubbleShow:Open()
        else
            self.BubbleShow:Close()
        end

        if hasRewardShow then
            self.BubbleShow:RefreshBubbleShow(showList)
        end
    end
    
end


return XUiGridMainWheelchairEntranceEx