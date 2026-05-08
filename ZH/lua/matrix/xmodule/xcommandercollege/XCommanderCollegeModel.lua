local TableKey = {
    BigWorldOpenFunctionMain = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
}

---@class XCommanderCollegeModel : XModel
local XCommanderCollegeModel = XClass(XModel, "XCommanderCollegeModel")
function XCommanderCollegeModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    
    --config相关
    self:_InitConfig()
end

function XCommanderCollegeModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCommanderCollegeModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------

function XCommanderCollegeModel:_InitConfig()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/SkipFunction", TableKey)
end

function XCommanderCollegeModel:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.BigWorldOpenFunctionMain)
    return cfgs[functionKey]
end

----------config end----------


return XCommanderCollegeModel