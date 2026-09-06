----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateListPredownloadNormal.lua
-- description: 模块更新 - 预下载获取处理列表
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateListPredownloadNormal : XModuleUpdateStateBase
local XModuleUpdateStateListPredownloadNormal = XLaunchConst.CreateMetaTable("XModuleUpdateStateListPredownloadNormal", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateListPredownloadNormal:OnEnter()
    -- preindex和remoteindex对比，获取操作列表
    self:CollectInfo(self.UpdateManager.LocalIndexTable, self.UpdateManager.PreIndexTable, self.UpdateManager:GetTargetIndexMap())
    self:OnFinish()
end

-- 收集热更数据
function XModuleUpdateStateListPredownloadNormal:CollectInfo(localIndexTable, preIndexTable, newIndexTable)
    local oldAssetMap = localIndexTable
    local preAssetMap = preIndexTable

    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
    local XFileInfoPatchVersionListIndex = XLaunchConst.XFileInfoPatchVersionListIndex
    for fileName, newInfo in pairs(newIndexTable) do
        local newSha1 = newInfo[XFileInfoSha1Index]
        local newVersion = newInfo[XFileInfoVersionIndex]
        -- 不是包内才需要下载
        if not self.UpdateManager:IsInnerResource(fileName, newSha1) then
            -- 预下载是否存在
            local preInfo = preAssetMap[fileName]
            if preInfo then
                local isNeedUse = preInfo[XFileInfoSha1Index] == newSha1
                -- 判断是否需要更新（预下载和最新版本一致就用预下载）
                if isNeedUse then
                    -- 旧获取去判断能否patch
                    local oldPreInfo = oldAssetMap[fileName]
                    if oldPreInfo then
                        local oldVersion = oldPreInfo[XFileInfoVersionIndex]
                        -- preindex资源如果可以找到当前到patch的版本，就使用patch
                        local patchVersionList = preInfo[XFileInfoPatchVersionListIndex]
                        local isAbUpdate = true
                        for _, patchVersion in pairs(patchVersionList) do
                            if patchVersion == oldVersion then
                                isAbUpdate = false
                                break
                            end
                        end
                        if isAbUpdate then
                            self.UpdateManager:AddDownloadABMap(fileName)
                        else
                            self.UpdateManager:AddPatchInfo(fileName, oldVersion, newVersion)
                        end
                    else
                        self.UpdateManager:AddDownloadABMap(fileName)
                    end
                end
            end
        end
    end
end


return XModuleUpdateStateListPredownloadNormal
