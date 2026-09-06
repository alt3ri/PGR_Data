----------------------------------------------------------------------------------------------------
-- XLaunchLocalZipUnzip.lua
-- description: Debug包解压document目录本地压缩包, 使用XHaruUnzip多线程解压
--   支持两种包形态(可混放):
--     1. 普通zip: 文件名含source, 每个zip一个任务, 单个解压完成即删源文件
--     2. 嵌套pack: 文件名含source_pack, 单个大zip内以Stored方式存放多个子zip,
--        经AddNestedTasks为每个子zip建任务, 保留多线程并发, 全部成功后才删大zip
-- Created by zhangguodong
-- --------------------------------------------------------------------------------------------------

local CsApplication = CS.XApplication
local CsRemoteConfig = CS.XRemoteConfig
local CsLog = CS.XLog
local CsTool = CS.XTool
local CsDirectory = CS.System.IO.Directory
local CsFileTool = CS.XFileTool
local CsGameEventManager = CS.XGameEventManager.Instance

-- XUnzipManagerState: 0 Idle, 1 Unzipping, 2 AllComplete, 3 CompleteWithError
local STATE_ALL_COMPLETE = 2
local STATE_COMPLETE_WITH_ERROR = 3

---@class XLaunchLocalZipUnzip
local XLaunchLocalZipUnzip = {}

-- 收集document目录顶层待解压的zip, 文件名需包含source
local function CollectZipFiles(documentPath)
    local zipList = {}
    local files = CsDirectory.GetFiles(documentPath, "*.zip", CS.System.IO.SearchOption.TopDirectoryOnly)
    for i = 0, files.Length - 1 do
        local file = files[i]
        if string.find(file, "source") then
            table.insert(zipList, file)
        else
            CsLog.Debug(string.format("[Unzip] name not Contains 'source', skip zipFile: %s", tostring(file)))
        end
    end
    return zipList
end

-- 是否为嵌套pack: 文件名含source_pack, 与打包端XBuilderBaseResZip.cs的命名约定对应
local function IsNestedPackZip(zipPath)
    return string.find(zipPath, "source_pack") ~= nil
end

-- 多线程解压zipList中的所有zip到documentPath, 全部结束后回调finishCb
local function StartUnzip(zipList, documentPath, finishCb)
    local XLaunchDlcManager = require("XLaunchDlcManager")
    -- 普通zip: 纯文件名 -> 完整路径, 单个解压完成后按名删除源文件
    local zipPathMap = {}
    -- 嵌套pack完整路径列表, 整体AllComplete后才删除(失败时保留, 下次启动可重新解压)
    local nestedPackList = {}
    local unzipManager = CS.XHaruUnzip.XUnzipManager()
    unzipManager.OnTotalProgress = function(progress)
        CsApplication.SetProgress(progress)
    end
    unzipManager.OnZipFinished = function(zipName)
        -- 嵌套任务名为"外层名!子zip名", 不在zipPathMap里, 天然跳过删除
        local zipPath = zipPathMap[zipName]
        CsLog.Debug(string.format("[Unzip] Completed file:%s", tostring(zipPath or zipName)))
        if zipPath then
            CsFileTool.DeleteFile(zipPath)
        end
    end
    unzipManager.OnZipFailed = function(zipName, errorInfo)
        -- 失败的zip不删除, 下次启动可重新解压
        CsLog.Error(string.format("[Unzip] Failed file:%s, error:%s", tostring(zipName), tostring(errorInfo)))
    end
    unzipManager.OnStateChanged = function(state)
        if state == STATE_ALL_COMPLETE or state == STATE_COMPLETE_WITH_ERROR then
            if state == STATE_ALL_COMPLETE then
                for _, packPath in ipairs(nestedPackList) do
                    CsLog.Debug(string.format("[Unzip] Delete nested pack:%s", tostring(packPath)))
                    CsFileTool.DeleteFile(packPath)
                end
            end
            XLaunchDlcManager.SetAllLaunchDownloadRecord()
            CsApplication.SetProgress(1)
            CsLog.Debug(string.format("[Unzip] Finished. state:%s", tostring(state)))
            finishCb()
        end
    end
    unzipManager.OnFileUnzipped = function(taskName, filePath)
        XLaunchDlcManager.WriteDownloadCache(filePath)
    end

    local taskCount = 0
    for _, zipPath in ipairs(zipList) do
        if IsNestedPackZip(zipPath) then
            local addCount = unzipManager:AddNestedTasks(zipPath, documentPath)
            if addCount > 0 then
                taskCount = taskCount + addCount
                table.insert(nestedPackList, zipPath)
            else
                CsLog.Error(string.format("[Unzip] AddNestedTasks failed, skip pack:%s", tostring(zipPath)))
            end
        else
            zipPathMap[CsFileTool.GetFileName(zipPath)] = zipPath
            unzipManager:AddTask(zipPath, documentPath)
            taskCount = taskCount + 1
        end
    end

    if taskCount == 0 then
        CsLog.Error("[Unzip] no valid unzip task, skip")
        finishCb()
        return
    end

    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, taskCount, false, CsApplication.GetText("Unzip") .. "(%d/%d)") -- 解压资源
    CsApplication.SetProgress(0)
    unzipManager:Start()
end

-- 入口: Debug包检查document目录本地zip并解压, 流程结束后回调finishCb
function XLaunchLocalZipUnzip.Run(finishCb)
    if not CsRemoteConfig.Debug then
        finishCb()
        return
    end

    local documentPath = CS.UnityEngine.Application.persistentDataPath .. "/document"
    if not CsDirectory.Exists(documentPath) then
        finishCb()
        return
    end

    local zipList = CollectZipFiles(documentPath)
    CsLog.Debug(string.format("[Unzip] DocumentPath:%s, zip count:%s", tostring(documentPath), tostring(#zipList)))
    if #zipList == 0 then
        finishCb()
        return
    end

    local nameList = {}
    for _, zipPath in ipairs(zipList) do
        table.insert(nameList, CsFileTool.GetFileNameWithoutExtension(zipPath))
    end
    local text = string.format("检查到%d个本地压缩文件:%s, 是否进行解压?", #zipList, table.concat(nameList, ", "))
    local cancelCB = function()
        finishCb()
    end
    local confirmCB = function()
        StartUnzip(zipList, documentPath, finishCb)
    end
    CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), text, cancelCB, confirmCB))
end

return XLaunchLocalZipUnzip
