local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

--- 7期boss
---@class XUiGridStageBoss7: XUiGridStage
local XUiGridStageBoss7 = XClass(XUiGridStage, 'XUiGridStageBoss7')

function XUiGridStageBoss7:OnBtnStageClick()
    if self.IsPathEdit then
        self.Base:AddPath(self.StageNodeId, self)
    else
        local nodeEntity = XDataCenter.GuildWarManager.GetNode(self.StageNodeId)

        if nodeEntity then
            if nodeEntity:GetIsPlayerNode() then
                XLuaUiManager.Open("UiGuildWarBoss7Panel", nodeEntity)
            else
                XLuaUiManager.Open("UiGuildWarStageDetail", nodeEntity, false)
            end
        end
    end
end

return XUiGridStageBoss7