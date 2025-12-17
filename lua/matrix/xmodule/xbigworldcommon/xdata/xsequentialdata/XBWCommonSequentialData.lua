local XBWSequentialDataBase = require("XModule/XBigWorldCommon/XData/XSequentialData/XBWSequentialDataBase")

---@class XBWCommonSequentialData : XBWSequentialDataBase
local XBWCommonSequentialData = XClass(XBWSequentialDataBase, "XBWCommonSequentialData")

function XBWCommonSequentialData:Finish()
    if not self:IsNil() then
        CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_COMMON_SEQUENTIAL_JOB_COMPLETED, self:GetId())
    end
end

return XBWCommonSequentialData
