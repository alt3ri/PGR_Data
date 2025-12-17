require("XEntity/XFuben/XExFubenActivityManager")
---@type XExFubenActivityManager
local XExFubenActivityManager = XClassPartial('XExFubenActivityManager')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XExFubenActivityManager
end

-- 获取进度提示
function XExFubenActivityManager:ExGetProgressTip(teachId)
    local managerName = self.ExConfig.ManagerName
    if string.IsNilOrEmpty(managerName) then return "" end
    local manager = XDataCenter[managerName]
    if manager == nil then return "" end
    local func = manager["GetProgressTips"]
    if func == nil then return "" end
    return func(teachId) or ""
end

return XExFubenActivityManager