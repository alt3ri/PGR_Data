local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelGachaLiv4P5Reward : XUiNode
---@field Parent XUiGachaLiv4P5Log
local XUiPanelGachaLiv4P5Reward = XClass(XUiNode, "XUiPanelGachaLiv4P5Reward")

function XUiPanelGachaLiv4P5Reward:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end

    self._GachaConfig = gachaConfig
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(gachaConfig.Id)
    -- 生成奖励格子
    for i, group in pairs(rewardRareLevelList) do
        local parent = self["PanelItem" .. i]
        for _, v in pairs(group) do
            local go = CS.UnityEngine.Object.Instantiate(self.GridItem, parent)
            go.gameObject:SetActiveEx(true)
            ---@type XUiGridCommon
            local item = XUiGridCommon.New(self.Parent, go)
            local fashionId = XGachaConfigs.GetClientConfigNumber("WeaponFashionId", self._GachaConfig.CourseRewardId, true)
            item:SetCustomWeaopnFashionId(fashionId, XUiHelper.GetText("GachaBiankaFashionDesc"))
            item:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                XLuaUiManager.Open("UiGachaLifu405Tip", data, hideSkipBtn, rootUiName, lackNum)
            end)

            local tmpData = {}
            tmpData.TemplateId = v.Cfg.TemplateId
            tmpData.Count = v.Cfg.Count

            local curCount
            if v.Cfg.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end
end

return XUiPanelGachaLiv4P5Reward