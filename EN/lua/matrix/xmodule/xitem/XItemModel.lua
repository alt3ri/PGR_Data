---@class XItemModel : XModel
---@field _AccumulatedExpendItem XAccumulateExpendItem
local XItemConfigModel = require("XModule/XItem/XItemConfigModel")
local XItemModel = XClass(XItemConfigModel, "XItemModel")
function XItemModel:OnInit()
    self:_InitTableKey()

end

-- 退出清理内部数据
function XItemModel:ClearPrivate()
end

-- 重登清理数据
function XItemModel:ResetAll()

end

--endregion
return XItemModel
