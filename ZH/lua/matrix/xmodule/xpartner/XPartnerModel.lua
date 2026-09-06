---@class XPartnerModel : XModelBase
local XPartnerModel = XClass(XModelBase, "XPartnerModel")
function XPartnerModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._OneKeyCultureModel = self:AddSubModel(require("XModule/XPartner/Model/OneKeyCulture/XPartnerOneKeyCultureModel"))
end

function XPartnerModel:ClearPrivate()
end

function XPartnerModel:ResetAll()
end

---region ----------public start----------

---@return XPartnerOneKeyCultureModel
function XPartnerModel:GetOneKeyCultureModel()
    return self._OneKeyCultureModel
end

--endregion ----------public end----------

--region ----------private start----------


--endregion ----------private end----------


return XPartnerModel