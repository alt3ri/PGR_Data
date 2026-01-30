local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiSkyGardenShoppingStreetMainGridStage : XUiNode
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetMainGridStage = XClass(XUiNode, "XUiSkyGardenShoppingStreetMainGridStage")

function XUiSkyGardenShoppingStreetMainGridStage:Ctor()
    self.GridStage:AddEventListener(handler(self, self.OnGridStageClick))
    self._Items = {}
    self.StarComs = {
        self.ImgOn1,
        self.ImgOn2,
        self.ImgOn3,
    }
end

function XUiSkyGardenShoppingStreetMainGridStage:OnGridStageClick()
    XMVCA.XSkyGardenShoppingStreet:StartStage(self._config.Id)
end

function XUiSkyGardenShoppingStreetMainGridStage:ResetData(rewardGetIndexs, stageId)
    self._config = self._Control:GetStageConfigsByStageId(stageId)
    self.TxtTitle.text = self._config.Name

    local rewards = {}
    local rewardGetList = self._Control:GetRewardIndexRecord(stageId)
    local starCount = rewardGetList and #rewardGetList or 0
    local insertIndex = 1
    for i = 1, #self.StarComs do
        self.StarComs[i].gameObject:SetActive(starCount >= i)
        local rewardList = XRewardManager.GetRewardList(self._config.TargetTaskRewards[i])
        if self._Control:GetRewardIndexRecordAndIndex(stageId, i) then
            table.insert(rewards, insertIndex, rewardList[1])
            insertIndex = insertIndex + 1
        else
            table.insert(rewards, #rewards + 1, rewardList[1])
        end
    end
    XTool.UpdateDynamicItemByUiCache(self._Items, rewards, self.UiBigWorldItemGrid.transform.parent, XUiGridBWItem, self)
    
    for i = 1, #self._Items do
        local PanelReceive = self._Items[i].PanelReceive
        if PanelReceive then
            PanelReceive.gameObject:SetActive(starCount >= i)
        end
    end
end

return XUiSkyGardenShoppingStreetMainGridStage
