----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateListCahceFiles.lua
-- description: 模块更新 - 初始化本地Index状态
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

local CsFile = CS.System.IO.File

---@class XModuleUpdateStateListCahceFiles : XModuleUpdateStateBase
local XModuleUpdateStateListCahceFiles = XLaunchConst.CreateMetaTable("XModuleUpdateStateListCahceFiles", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateListCahceFiles:OnEnter()
    self:CollectInfo(self.UpdateManager:GetTargetIndexMap())
    self:OnFinish()
end

-- 收集热更数据
function XModuleUpdateStateListCahceFiles:CollectInfo(newIndexTable)
    local deleteCache = {}
    local checkList = {}
    local cache = self.UpdateManager.TempDeleteCache

    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    for fileName, newInfo in pairs(newIndexTable) do
        local newSha1 = newInfo[XFileInfoSha1Index]
        -- 不是包内才需要下载
        if not self.UpdateManager:IsInnerResource(fileName, newSha1) then
            local hasCache = cache[fileName]
            if hasCache then
                checkList[fileName] = newInfo
                cache[fileName] = nil
            end
        end
    end
    for fileName, _ in pairs(cache) do
        deleteCache[fileName] = true
    end
    self.UpdateManager:SetUpdateCheckTable(checkList)
    self.UpdateManager.TempDeleteCache = deleteCache
end

return XModuleUpdateStateListCahceFiles
