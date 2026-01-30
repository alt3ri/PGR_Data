local super = require("XUi/XUiNewChar/WeiLa/XUiPanelFubenWeiLaStage")
---@type XUiPanelFubenWeiLaStage
local XUiPanelFubenWeiLaStage = XClassPartial('XUiPanelFubenWeiLaStage')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XUiPanelFubenWeiLaStage
end

function XUiPanelFubenWeiLaStage:GetTeachingAndChallenge()
    local UIFUBENKOROTUTORIA_TEACHING_DETAIL
    local UIFUBENKOROTUTORIA_CHALLENGE_DETAIL
    if self.Cfg.TeachingDetailUiName then
        UIFUBENKOROTUTORIA_TEACHING_DETAIL = self.Cfg.TeachingDetailUiName
    end
    if self.Cfg.ChallengeDetailUiName then
        UIFUBENKOROTUTORIA_CHALLENGE_DETAIL = self.Cfg.ChallengeDetailUiName
    end
    return UIFUBENKOROTUTORIA_TEACHING_DETAIL, UIFUBENKOROTUTORIA_CHALLENGE_DETAIL
end

return XUiPanelFubenWeiLaStage