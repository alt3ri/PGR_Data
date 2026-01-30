local super = require("XUi/XUiActivityBrief/XActivityBrieButton")
---@type XActivityBrieButton
local XActivityBrieButton = XClassPartial('XActivityBrieButton')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XActivityBrieButton
end

function XActivityBrieButton:ShowBtnCom(isOpen, isWaitLockAnim)
    --海外合并版本特殊处理，特殊的活动没到时间直接隐藏按钮
    local needHideGroupId
    local ids = CS.XGame.ClientConfig:GetString("GroupActIds")
    if ids then
        needHideGroupId = string.Split(ids, "-")
    end
    local needHide = false
    for k, v in pairs(needHideGroupId) do
        if self.activityGroupId == tonumber(v) then
            needHide = true
            break
        end
    end
    if needHide and not isOpen then
        self.BtnCom.gameObject:SetActiveEx(false)
    else
        self.BtnCom.gameObject:SetActiveEx(true)
        self.BtnCom:SetDisable(not isOpen or isOpen and isWaitLockAnim)
    end
end

return XActivityBrieButton

