----------------------------------------------------------------------------------------------------
-- XLaunchConst.lua
-- description: Launch更新全局模块
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local CsApplication = CS.XApplication

-- 缓存C# File静态方法，避免每次调用时的跨界成员查找
-- 统一走C# Unicode API：Windows上Lua io.open按系统ANSI代码页解释UTF-8路径，含中文路径在部分机器上会打不开
local CsIOFile = CS.System.IO.File
local CsFileExists = CsIOFile.Exists
local CsFileReadAllText = CsIOFile.ReadAllText
local CsFileWriteAllText = CsIOFile.WriteAllText
local CsFileAppendAllText = CsIOFile.AppendAllText

RES_FILE_TYPE = {
    LAUNCH_MODULE = "launch",
    MATRIX_FILE = "matrix",
    CG_FILE = "cg",
}

DOWNLOAD_SOURCE = {
    -- 默认下载源
    DEFAULT = 0,
    -- 预下载下载源
    PRELOAD = 1,
    -- 分包下载源
    SUBPACKAGE = 2
}

ResourcePathType = {
    Application = 0,
    Document = 1,
    None = 2,
}

ResourceTypeToIntDic = {
    launch = 0,
    matrix = 1
}

---@class XLaunchConst
---@field IsUpdateClose boolean? 是否关闭更新流程
---@field DebugMode boolean? 是否开启调试模式
---@field ForceUpdate boolean? 是否强制更新
---@field IsDebugLog boolean? 是否开启调试日志
XLaunchConst = {
    -- DebugMode = true,
    -- ForceUpdate = true,
    -- IsUpdateClose = true,
    IsDebugLog = true,
    XDownloadGroupId = 100,
    -- 模块信息索引
    -- XFileAssetPathIndex = 1,
    -- XFileInfoIndex = 2,

    -- 文件信息索引
    XFileInfoNameIndex = 1,
    XFileInfoSha1Index = 2,
    XFileInfoSizeIndex = 3,
    XFileInfoVersionIndex = 4,
    XFileInfoPatchVersionListIndex = 5,
    XFileInfoFlagIndex = 6,

    TaskGroupStateComplete = 5,
    TaskGroupStateCompleteError = 6,

    IsUpdateKey = "IsUpdate",
    DocAppVersionKey = "DocAppVersionKey",
    PreloadCompleteKey = "__kuro_preload_complete__",
    PreloadIndexKey = "__kuro_preload_index__",
    PreloadDlcIdsKey = "__kuro_preload_dlc_ids__",

    -- 版本内容
    -- LeastLaunchVersion = 0,
    -- LeastVersionFile = 0,
    -- LaunchIndexSha1 = "",
    -- IndexSha1 = "",
    -- LaunchIndexSize = 0,
    -- IndexSize = 0,
    -- PatchedList = "",
    -- VersionOrder = "",

    -- shader预热key name
    ShaderWarmUpKey = "ShaderWarmUp",
    ShaderWarmUpFinishKey = "ShaderWarmUpFinish",

    -- 缓存目录
    AB_Directory_Name = "Cache",
    Patch_Directory_Name = "Patch",

    -- 模块信息索引
    EVENT_SHADER_WARM_UP = "EVENT_SHADER_WARM_UP",
    EVENT_APPLICATION_QUIT = "EVENT_APPLICATION_QUIT",

    PredownloadType = {
        Download = 1,
        Merge = 2,
    }
}

-- 本地正式资源模式(仅非整包 Win exe 由 C# 侧开启): 资源全量在本地 Product/File/win/release,
-- 关闭更新流程, 不连 CDN 下载资源; 包外标记文件也按包内处理(见 XModuleUpdateManager.IsInnerResource)
if CsApplication.IsLocalReleaseResource then
    XLaunchConst.IsLocalReleaseResource = true
    XLaunchConst.IsUpdateClose = true
end

-- region 创建简单元表类

-- 关联对象创建调用
local createObjFunc
createObjFunc = function(class, obj, ...)
    if class.Super then
        createObjFunc(class.Super, obj, ...)
    end

    if class.Ctor then
        class.Ctor(obj, ...)
    end
end

---创建元表类
---@param className string
---@param super table
---@return table {__index = vtbl, __newindex = vtbl} 创建的元表类
function XLaunchConst.CreateMetaTable(className, super)
    local _class = XLaunchConst["_class"]
    if not _class then
        _class = {}
        XLaunchConst["_class"] = _class
    end
    local class = {}
    class.Ctor = false
    class.Super = super
    class.New = function(...)
        local obj = {}
        obj.__cname = className
        obj.__class = class
        setmetatable(obj, { __index = _class[class] })
        createObjFunc(class, obj, ...)
        return obj
    end
    local vtbl = {}
    _class[class] = vtbl
    setmetatable(class, {
        __newindex = function(_, k, v)
            vtbl[k] = v
        end,
        __index = function(_, k)
            return vtbl[k]
        end
    })
    if super then
        vtbl.Super = super
        setmetatable(vtbl, {
            __index = function(_, k)
                local ret = _class[super][k]
                vtbl[k] = ret
                return ret
            end
        })
    end
    return class
end

-- 清空缓存
function XLaunchConst.ClearLaunchConst()
    XLaunchConst["_class"] = nil
end

-- endregion

-- 获取App升级url
function XLaunchConst.GetAppUpgradeUrl()
    return "client/patch"
end

-- 获取Apk保存路径
function XLaunchConst.GetApkSavePath()
    if not XLaunchConst.ApkSavePath then
        XLaunchConst.ApkSavePath = string.format("%s/Punishing.apk", CS.UnityEngine.Application.persistentDataPath)
    end
    return XLaunchConst.ApkSavePath
end

-- 固定OppoId = 1
function XLaunchConst.GetOppoChannelID()
    return 1
end

-- 检查是否是下载包渠道
function XLaunchConst.CheckDownloadChannel()
    local channelId = CS.XHeroSdkAgent.GetChannelId()
    return (channelId == XLaunchConst.GetOppoChannelID())
end

-- 检测是否需要更新App
function XLaunchConst.CheckAppUpdate()
    return CS.XRemoteConfig.ApplicationVersion ~= CS.XInfo.Version
end

-- 设置key value
function XLaunchConst.SetKeyValue(key, value)
    XLaunchConst[key] = value
end

-- 获取key value
function XLaunchConst.GetKeyValue(key)
    return XLaunchConst[key]
end


-- 显示错误窗口
---@param errorCode string 错误码
---@param confirmCB function 确认回调
---@param cancelCB function 取消回调
---@param cancelStr string 取消按钮文本
function XLaunchConst.ShowStartErrorDialog(errorCode, confirmCB, cancelCB, cancelStr)
    local CsTool = CS.XTool
    if CS.XInfo.IsCloudGame then
        if CS.XWLinkAgent.IsPatchOnly then
            -- 云游戏只触发热更，触发完就结束
            CS.XWLinkAgent.PatchQuit(false)
        else 
            -- 云游戏一旦出现热更错误，直接弹出提示，关闭游戏
            CS.XWLinkAgent.Exit(CsApplication.GetText(errorCode))
        end
        -- 后续加个埋点CS.XRecord.Record("50000", "UiLaunchand")
        return
    end
    confirmCB = confirmCB or CsApplication.Exit
    CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), CsApplication.GetText(errorCode), cancelCB, confirmCB, cancelStr))
end

-- 判断文件是否存在
---@param filepath string
---@return boolean, string?
function XLaunchConst.FileExists(filepath)
    -- pcall直接传函数引用，不创建闭包；失败时第二个返回值即错误信息
    local ok, exists = pcall(CsFileExists, filepath)
    if ok then return exists end
    return false, tostring(exists)
end

-- 写入文件所有内容
---@param filepath string
---@param content string
---@param mode string? 默认为 "w"，覆盖写入；"a" 为追加
---@return string? err 成功返回nil，失败返回错误信息
function XLaunchConst.WriteAllText(filepath, content, mode)
    local csWrite = (mode == "a") and CsFileAppendAllText or CsFileWriteAllText
    local ok, err = pcall(csWrite, filepath, content)
    if ok then return end
    return tostring(err)
end

-- 读取文件所有内容，返回完整字符串
---@param filepath string
---@return string?, string?
function XLaunchConst.ReadAllText(filepath)
    local ok, result = pcall(CsFileReadAllText, filepath)
    if ok then
        -- -- 与旧Lua io文本模式读取保持一致：\r\n统一为\n（下载缓存等按"\n"逐行Split依赖此行为）
        -- if result and result:find("\r", 1, true) then
        --     result = result:gsub("\r\n", "\n")
        -- end
        return result
    end
    return nil, tostring(result)
end

--- 加载Json文件
---@param file string
---@return table?
function XLaunchConst.LoadJsonFile(file)
    local patchInfo
    xpcall(function()
        local luaJson = require("XLaunchCommon/XLaunchJson")
        local content, err = XLaunchConst.ReadAllText(file)
        if not content then
            CS.XLog.Error(string.format("[XLaunchConst] LoadJsonFile read failed, file:%s, err:%s", tostring(file), tostring(err)))
            return
        end
        patchInfo = luaJson.decode(content)
    end, function(err)
        CS.XLog.Error(string.format("[XLaunchConst] LoadJsonFile error, file:%s, err:%s", tostring(file), tostring(err)))
    end)
    return patchInfo
end

-- 判断字符串是否为nil或者为空
---@param str string?
---@return boolean
function XLaunchConst.IsNilOrEmpty(str)
    return str == nil or #str == 0
end

-- 判断字符串 str 是否以 prefix 开头
---@param str string
---@param prefix string
---@return boolean
function XLaunchConst.StartsWith(str, prefix)
    -- ^ 是正则锚点，代表字符串开头
    return str:find(prefix, 1, true) == 1
end

-- 分割字符串 str，使用 separator 分割，返回一个数组
---@param str string?
---@param separator string? 默认为 "|"
---@param removeEmpty boolean? 默认为 false
---@return table
function XLaunchConst.Split(str, separator, removeEmpty)
    if XLaunchConst.IsNilOrEmpty(str) then
        return {}
    end

    if not separator then
        separator = "|"
    end

    local tableInsert = table.insert
    local result = {}
    local startPos = 1
    while true do
        local endPos = str:find(separator, startPos)
        if endPos == nil then
            break
        end

        local elem = str:sub(startPos, endPos - 1)
        if not removeEmpty or not XLaunchConst.IsNilOrEmpty(elem) then
            tableInsert(result, elem)
        end
        
        startPos = endPos + #separator
    end

    tableInsert(result, str:sub(startPos))
    return result
end

-- 获取文件名
---@param path string
---@return string
function XLaunchConst.GetFileName(path)
    -- 匹配最后一个 / 或 \ 后面的所有内容
    return path:match("[^/\\]+$")
end

-- 获取文件大小和单位
---@param size number
---@return string, string
function XLaunchConst.GetSizeAndUnit(size)
    local unit = "KB"
    local num = size / 1024
    if (num > 100) then
        unit = "MB"
        num = num / 1024
    end
    return unit, num
end

-- 获取文件大小
---@param path string
---@return number
function XLaunchConst.GetSizeText(size)
    local unit, num = XLaunchConst.GetSizeAndUnit(size)
    return string.format("%0.2f%s", num, unit)
end

-- 显示下载提示
function XLaunchConst.ShowDownloadTips(updateSize, cb)
    local sizeTxt = XLaunchConst.GetSizeText(updateSize)
    local tmpStr = ""
    if CS.XUiPc.XUiPcManager.IsPcMode() then
        local totalTxt = CsApplication.GetText("PCUpdateTips")
        tmpStr = string.format(totalTxt, sizeTxt)
    else
        local envTxt = ""
        local totalTxt = CsApplication.GetText("UpdateTips")
        if CS.UnityEngine.NetworkApplication.internetReachability == CS.UnityEngine.NetworkReachability.ReachableViaCarrierDataNetwork then
            envTxt = CsApplication.GetText("CarrierTxt")
        else
            envTxt = CsApplication.GetText("WifiTxt")
        end
        tmpStr = string.format(totalTxt, sizeTxt, envTxt)
    end
    CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_DIALOG, tmpStr, CsApplication.Exit, cb)
end

function XLaunchConst.CheckNeedSize(needSize, defaultExtraSize)
    local available = CS.XAppPlatBridge.GetAvailableDiskSize()
    if not needSize or needSize <= 0 then
        return true, available
    end
    -- 如果空间不足的话，直接弹出空间不足提示 追加多15Mb检测，避免缓存移动文件，会额外占用
    local checkSize = needSize + (defaultExtraSize or 15) * 1024 * 1024
    return available >= checkSize, available
end

function XLaunchConst.CheckDiskSize(needSize, enoughCb, notEnoughCb, defaultExtraSize)
    local enough, available = XLaunchConst.CheckNeedSize(needSize, defaultExtraSize)
    if not enough then
        local sizeTxt1 = XLaunchConst.GetSizeText(needSize)
        local sizeTxt2 = XLaunchConst.GetSizeText(available)
        CS.XTool.WaitCoroutine(
            CsApplication.CoDialog(
                CsApplication.GetText("Tip"),
                string.format(CsApplication.GetText("FileManagerDownloadDiskFull"), sizeTxt1, sizeTxt2), 
                notEnoughCb or CsApplication.Exit,
                notEnoughCb or CsApplication.Exit
            )
        )
    else
        enoughCb()
    end
end

-- 下载前提示
function XLaunchConst.BeforeDownloadTips(updateSize, cb)
    XLaunchConst.CheckDiskSize(updateSize, function() XLaunchConst.ShowDownloadTips(updateSize, cb) end)
end

function XLaunchConst.StartDownloadFile(addDownloadFileCallback, finishCallback, failCallback)
    if not addDownloadFileCallback then
        finishCallback(false)
        return
    end
    XLaunchConst.XDownloadGroupId = XLaunchConst.XDownloadGroupId + 1
    CS.XHaruDownloader.XDownloadConst.DownloadUrlLog = true
    local downloadManager = CS.XHaruDownloader.XDownloadManager()
    downloadManager:Init()
    local downloadGroup = CS.XHaruDownloader.XDownloadTaskGroup(XLaunchConst.XDownloadGroupId)
    downloadGroup.NotifyStateChanged = function(id, state)
        if state == XLaunchConst.TaskGroupStateComplete then
            downloadManager:Stop()
            if finishCallback then
                CS.XHaruDownloader.XDownloadConst.DownloadUrlLog = false
                finishCallback(true)
            end
        elseif state == XLaunchConst.TaskGroupStateCompleteError then
            if failCallback then
                failCallback()
            else
                XLaunchConst.ShowStartErrorDialog("FileManagerInitFileTableDownloadError", nil, function()
                    downloadManager:ResetAllFailedTask()
                end, CsApplication.GetText("Retry")) -- 重试
            end
        end
    end
    addDownloadFileCallback(downloadGroup)
    downloadManager:RegisterTaskGroup(downloadGroup)
    downloadManager:StartAll()
end

function ApplicationQuit()
    CS.XGameEventManager.Instance:Notify(XLaunchConst.EVENT_APPLICATION_QUIT)
end

function ApplicationPause(pause)
end
