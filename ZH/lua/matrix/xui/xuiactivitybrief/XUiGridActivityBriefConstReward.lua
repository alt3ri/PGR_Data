--- 特殊的奖励显示，包含两个子的真奖励，点击迁移到顶部
---@class XUiGridActivityBriefConstReward
local XUiGridActivityBriefConstReward = XClass(nil, 'XUiGridActivityBriefConstReward')

local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiGridActivityBriefConstReward:Ctor(rootUi, ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self.RootUi = rootUi

    ---@type XUiGridCommon[]
    self.GridRewards = {}
    
    for i = 1, 10 do
        local rewardGo = self["GridReward" .. i]

        if rewardGo then
            self.GridRewards[i] = XUiGridCommon.New(rootUi, rewardGo)
        else
            break
        end
    end

    if self.BtnClick then
        self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
    end
end

function XUiGridActivityBriefConstReward:Refresh(itemId)
    self.ItemId = itemId

    if not XTool.IsTableEmpty(self.GridRewards) then
        for i, v in pairs(self.GridRewards) do
            v:Refresh(itemId)
        end
    end
end

function XUiGridActivityBriefConstReward:OnBtnClick()
    -- 列表都是一样的道具，调用其中一个即可
    if self.GridRewards[1] then
        self.GridRewards[1]:OnBtnClickClick()
    end
end

return XUiGridActivityBriefConstReward