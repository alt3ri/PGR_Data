--- 公会战行为队列相关控制器
---@class XActionQueueControl: XControl
---@field private _Model XGuildWarModel
local XActionQueueControl = XClass(XControl, 'XActionQueueControl')

function XActionQueueControl:OnInit()

end


function XActionQueueControl:OnRelease()

end

-- 检查当前播放的是否历史动作动画
function XActionQueueControl:GetIsHistoryAction()
    return self._Model.ActionQueueModel:GetIsHistoryAction()
end

return XActionQueueControl