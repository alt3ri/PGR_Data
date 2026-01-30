---@class XShopModel : XModel
---@field _AccumulatedExpendShop XAccumulateExpendShop
local XShopConfigModel = require("XModule/XShop/XShopConfigModel")
local XShopModel = XClass(XShopConfigModel, "XShopModel")
function XShopModel:OnInit()
    self:_InitTableKey()
    local XAccumulateExpendShop = require("XModule/XShop/XEntity/XAccumulateExpendShop")
    self._AccumulatedExpendShop = XAccumulateExpendShop.New(self)
end

-- 退出清理内部数据
function XShopModel:ClearPrivate()
end

-- 重登清理数据
function XShopModel:ResetAll()

end

--region 累消商店相关
function XShopModel:GetAccumulateExpendShop()
    return self._AccumulatedExpendShop
end

function XShopModel:SetAccumulateExpendShopData(notifyData)
    self._AccumulatedExpendShop:RefreshData(notifyData)
end

--endregion
return XShopModel
