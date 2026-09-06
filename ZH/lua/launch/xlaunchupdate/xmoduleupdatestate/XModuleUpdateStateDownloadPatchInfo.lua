----------------------------------------------------------------------------------------------------
-- XModuleUpdateStateDownloadPatchInfo.lua
-- description: 模块更新 - 下载patch info文件读取
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsFile = CS.System.IO.File

local XModuleUpdateStateBase = require("XLaunchUpdate/XModuleUpdateState/XModuleUpdateStateBase")

---@class XModuleUpdateStateDownloadPatchInfo : XModuleUpdateStateBase
local XModuleUpdateStateDownloadPatchInfo = XLaunchConst.CreateMetaTable("XModuleUpdateStateDownloadPatchInfo", XModuleUpdateStateBase)

---@override XModuleUpdateStateBase.OnEnter
function XModuleUpdateStateDownloadPatchInfo:OnEnter()
    self:_DownloadPatchInfoFiles(self.UpdateManager.PatchJsonTable)
end


-- 下载PatchInfo文件 (不校验，用二进制)
function XModuleUpdateStateDownloadPatchInfo:_DownloadPatchInfoFiles(patchJsonTable)
    if not patchJsonTable or not next(patchJsonTable) then
        self:OnFinish()
        return
    end

    local addTaskFunc = function(group)
        for oldversion, data in pairs(patchJsonTable) do
            local path = self.ModuleUpdateInfo:GetPatchInfoPath(oldversion, data.NewVersion)
            if not CsFile.Exists(path) then
                local DocumentUrl = self.ModuleUpdateInfo:GetUrlByVersion(data.NewVersion)
                local url = string.format("%s/%s/splitPatch/%s.json", DocumentUrl, data.NewVersion, oldversion)
                group:AddTask(url, path)
            end
        end
    end
    self.UpdateManager:DownloadFiles(addTaskFunc, 
        function() self:_CheckPatchInfo(patchJsonTable) end, nil, 
        nil, true)
end

-- 检查PatchInfo文件是否存在
function XModuleUpdateStateDownloadPatchInfo:_CheckPatchInfo(patchJsonTable)
    local failList = {}
    for oldversion, data in pairs(patchJsonTable) do
        if not data.IsInit then
            local path = self.ModuleUpdateInfo:GetPatchInfoPath(oldversion, data.NewVersion)
            local jsonData = XLaunchConst.LoadJsonFile(path)
            if not jsonData then
                CsFile.Delete(path)
                failList[oldversion] = data
            else
                for fileName, _ in pairs(data.Patchs) do
                    local patchInfo = jsonData[fileName]
                    if not patchInfo then
                        self.UpdateManager:AddDownloadABMap(fileName)
                    else
                        patchInfo.OldVersion = oldversion
                        patchInfo.NewVersion = data.NewVersion
                        patchInfo.FileName = fileName
                        self.UpdateManager:AddDownloadPatchMap(fileName, patchInfo)
                    end
                end
                data.IsInit = true
            end
        end
    end
    if next(failList) then
        self:_DownloadPatchInfoFiles(failList)
    else
        self:OnFinish()
    end
end

return XModuleUpdateStateDownloadPatchInfo
