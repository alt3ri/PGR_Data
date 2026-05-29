---@type XMainLine2UiStageAreaControl
local XMainLine2UiStageAreaControl = XClassPartial("XMainLine2UiStageAreaControl")

local TableKey = {
    MainLine2StageAreaGroup = { ReadFunc = XConfigUtil.ReadType.Int, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id" },
    MainLine2StageArea = { ReadFunc = XConfigUtil.ReadType.Int, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Id" },
}

function XMainLine2UiStageAreaControl:_InitConfigs()
    self:InitConfigByTabKey("Fuben/MainLine2", TableKey)
end

---@return XTableMainLine2StageAreaGroup
function XMainLine2UiStageAreaControl:GetTableMainLine2StageAreaGroupCfgById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MainLine2StageAreaGroup, id, notips)
end

---@return XTableMainLine2StageArea
function XMainLine2UiStageAreaControl:GetTableMainLine2StageAreaCfgById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MainLine2StageArea, id, notips)
end

return XMainLine2UiStageAreaControl