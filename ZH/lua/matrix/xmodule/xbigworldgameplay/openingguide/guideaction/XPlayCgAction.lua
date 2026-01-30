
local XGuideAction = require("XModule/XBigWorldGamePlay/OpeningGuide/GuideAction/XGuideAction")

---@class XPlayCgAction : XGuideAction
local XPlayCgAction = XClass(XGuideAction, "XPlayCgAction")

function XPlayCgAction:Begin()
    local videoId = self._Template.VideoConfigId
    local callBack = function() 
        self:Finish()
    end
    local needAuto = self._Template.ActionParams[1] == 1
    local needSkip = self._Template.ActionParams[2] == 1
    XLuaVideoManager.PlayUiVideo(videoId, callBack, needAuto, needSkip)
end

return XPlayCgAction
