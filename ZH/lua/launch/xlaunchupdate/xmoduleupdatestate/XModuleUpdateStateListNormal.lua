----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateListNormal.lua
-- description: 模块更新 - 生成更新列表
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateListNormal : XModuleUpdateStateBase
local XModuleUpdateStateListNormal = XLaunchConst.CreateMetaTable("XModuleUpdateStateListNormal", XModuleUpdateStateBase)

function XModuleUpdateStateListNormal:IsEnter()
    return self.ModuleUpdateInfo:HasUpdated()
end

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateListNormal:OnEnter()
    -- 是不是Doc更新模块
    self._isMatrixMode = self.ModuleUpdateInfo:IsMatrixUpdate()
    self._isPredownload = self.ModuleUpdateInfo:IsPredownloadStatus()

    if self._isPredownload then
        self:CollectInfo(self.UpdateManager.LocalIndexTable, self.UpdateManager.PreIndexTable)
    else
        self:CollectInfo(self.UpdateManager.LocalIndexTable, self.UpdateManager:GetTargetIndexMap())
    end

    self:OnFinish()
end

-- 收集热更数据
function XModuleUpdateStateListNormal:CollectInfo(localIndexTable, newIndexTable)
    local oldAssetMap = localIndexTable
    local XFileInfoSha1Index = XLaunchConst.XFileInfoSha1Index
    local XFileInfoVersionIndex = XLaunchConst.XFileInfoVersionIndex
    local XFileInfoPatchVersionListIndex = XLaunchConst.XFileInfoPatchVersionListIndex
    local XFileInfoFlagIndex = XLaunchConst.XFileInfoFlagIndex
    for fileName, newInfo in pairs(newIndexTable) do
        local newSha1 = newInfo[XFileInfoSha1Index]
        local newVersion = newInfo[XFileInfoVersionIndex]
        -- 不是包内才需要下载
        if self.ModuleUpdateInfo:IsNeedDownloadVersion(newVersion) and 
            not self.UpdateManager:IsInnerResource(fileName, newSha1) then
            local oldInfo = oldAssetMap[fileName]
            if oldInfo == nil then
                self.UpdateManager:AddDownloadABMap(fileName)
            else
                -- 之前是包内，后面是包外的情况需要补充下载
                local preInPackage = oldInfo[XFileInfoFlagIndex] == 0 and newInfo[XFileInfoFlagIndex] == 1
                -- 判断是否需要更新，之前只判断sha1发现没差异，但是之前是包内，后面是包外，则需要下载（补充）
                local isNeedDownload = oldInfo[XFileInfoSha1Index] ~= newSha1 or preInPackage
                if isNeedDownload then
                    if self._isMatrixMode then
                        local curVersion = oldInfo[XFileInfoVersionIndex]
                        local patchVersionList = newInfo[XFileInfoPatchVersionListIndex]
                        local isAbUpdate = true
                        for _, patchVersion in pairs(patchVersionList) do
                            if patchVersion == curVersion then
                                isAbUpdate = false
                                break
                            end
                        end
                        if isAbUpdate then
                            self.UpdateManager:AddDownloadABMap(fileName)
                        else
                            self.UpdateManager:AddPatchInfo(fileName, curVersion, newVersion)
                        end
                    else
                        self.UpdateManager:AddDownloadABMap(fileName)
                    end
                end
            end
        end
    end
end

return XModuleUpdateStateListNormal
