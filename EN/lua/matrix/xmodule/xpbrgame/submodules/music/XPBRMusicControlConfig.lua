--- 负责业务层Bgm相关的子控制器
---@type XPBRMusicControl
local XPBRMusicControl = XClassPartial("XPBRMusicControl")

local TableKey = {
    PBRBgmList = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id'}
}

function XPBRMusicControl:InitConfigs()
    self:InitConfigByTabKey("Pbr", TableKey)
end

---@return XTablePBRBgmList
function XPBRMusicControl:GetTablePBRBgmCfgById(bgmId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PBRBgmList, bgmId, notips)
end

---@return table<number, XTablePBRBgmList>
function XPBRMusicControl:GetTablePBRBgmCfgs()
    return self:GetAllConfigByTabKey(TableKey.PBRBgmList)
end

return XPBRMusicControl