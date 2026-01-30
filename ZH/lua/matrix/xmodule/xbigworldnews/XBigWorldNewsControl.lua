---@class XBigWorldNewsControl : XControl
---@field private _Model XBigWorldNewsModel
local XBigWorldNewsControl = XClass(XControl, "XBigWorldNewsControl")
function XBigWorldNewsControl:OnInit()
    --初始化内部变量
end

function XBigWorldNewsControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldNewsControl:RemoveAgencyEvent()

end

function XBigWorldNewsControl:OnRelease()
    self._Model:SaveAllLocalData()
end

return XBigWorldNewsControl