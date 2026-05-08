local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

-- 四期Boss
---@class XUiGridStageTerm4:XUiGridStage
local XUiGridStageTerm4 = XClass(XUiGridStage, "XUiGridStageTerm4")

function XUiGridStageTerm4:OnBtnStageClick(selectedNodeId)
    if self.IsPathEdit then
        self.Parent:AddPath(self.StageNodeId, self)
    else
        local nodeEntity = XDataCenter.GuildWarManager.GetNode(self.StageNodeId)

        if nodeEntity then
            if nodeEntity:GetIsPlayerNode() then
                XLuaUiManager.Open("UiGuildWarTerm4Panel", nodeEntity)
            else
                XLuaUiManager.Open("UiGuildWarStageDetail", nodeEntity, false)
            end
        end
    end
end

return XUiGridStageTerm4