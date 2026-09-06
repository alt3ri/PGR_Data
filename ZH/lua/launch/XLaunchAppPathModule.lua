local UnityApplication = CS.UnityEngine.Application
local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform

local CsApplication = CS.XApplication
-- local CsLog = CS.XLog
local CsInfo = CS.XInfo

-- 应用路径模块
local XLaunchAppPathModule = {}

local RuntimePlatform = {
    ANDROID = 1,
    IOS = 2,
    EDITOR = 3,
    STANDALONE = 4,
}

local CurRuntimePlatform
local IsEditorOrStandalone
local PLATFORM

-- platform
local DocumentUrl
local ConfigUrl
local ApplicationFilePath

-- editor/standalone
local ProductPath
local DebugFilePath

-- common
local AppUpgradeUrl
local DocumentFilePath

-- Local Function
local function Init()
    AppUpgradeUrl = "client/patch"
    DocumentFilePath = UnityApplication.persistentDataPath .. "/document"
    local platformPath

    if UnityApplication.platform == UnityRuntimePlatform.Android then
        -- 安卓平台
        CurRuntimePlatform = RuntimePlatform.ANDROID
        PLATFORM = "android"
        platformPath = PLATFORM
        ApplicationFilePath = UnityApplication.streamingAssetsPath .. "/resource"
    elseif UnityApplication.platform == UnityRuntimePlatform.IPhonePlayer then
        -- iOS平台
        CurRuntimePlatform = RuntimePlatform.IOS
        PLATFORM = "ios"
        platformPath = PLATFORM
        ApplicationFilePath = UnityApplication.streamingAssetsPath .. "/resource"
    else
        -- win平台
        PLATFORM = "win"
        if UnityApplication.platform == UnityRuntimePlatform.WindowsEditor or
                UnityApplication.platform == UnityRuntimePlatform.OSXEditor or
                UnityApplication.platform == UnityRuntimePlatform.LinuxEditor then
            -- 编辑器平台
            CurRuntimePlatform = RuntimePlatform.EDITOR
            PLATFORM = CS.XLaunchManager.PLATFORM   --编辑器平台，随平台选择而变化
            platformPath = "editor"
            ProductPath = UnityApplication.dataPath .. "/../../../Product"
            DebugFilePath = ProductPath .. "/File/win/debug"
            ApplicationFilePath = ProductPath .. "/File/" .. PLATFORM .. "/release"
        elseif UnityApplication.platform == UnityRuntimePlatform.WindowsPlayer or
                UnityApplication.platform == UnityRuntimePlatform.OSXPlayer or
                UnityApplication.platform == UnityRuntimePlatform.LinuxPlayer then
            -- 电脑系统平台
            CurRuntimePlatform = RuntimePlatform.STANDALONE
            platformPath = "standalone"
            ProductPath = UnityApplication.dataPath .. "/../../../../.."
            DebugFilePath = ProductPath .. "/File/win/debug"
            ApplicationFilePath = CsApplication.Debug and ProductPath .. "/File/" .. PLATFORM .. "/release" or UnityApplication.streamingAssetsPath .. "/resource"
            if not CsApplication.Debug then 
                -- Release包 资源目录跟安装目录相同
                DocumentFilePath = UnityApplication.streamingAssetsPath .. "/document"
            end
        end
    end
    
    local LaunchStringIsNilOrEmpty = function (str)
        return str == nil or #str == 0
    end

    local cdnKey = CsInfo.CDNKey
    if LaunchStringIsNilOrEmpty(cdnKey) then
        DocumentUrl = string.format("client/patch/%s/%s/%s", CsInfo.Identifier, CsInfo.Version, platformPath)
        ConfigUrl = string.format("client/config/%s/%s/%s", CsInfo.Identifier, CsInfo.Version, platformPath)
    else
        DocumentUrl = string.format("client/patch/%s/%s/%s/%s", cdnKey, CsInfo.Identifier, CsInfo.Version, platformPath)
        ConfigUrl = string.format("client/config/%s/%s/%s/%s", cdnKey, CsInfo.Identifier, CsInfo.Version, platformPath)
    end
    IsEditorOrStandalone = CurRuntimePlatform == RuntimePlatform.EDITOR or CurRuntimePlatform == RuntimePlatform.STANDALONE
end

-- local function PrintPath()
--     CsLog.Error("Check files. PLATFORM = " .. PLATFORM)
--     CsLog.Error("Check files. DocumentUrl = " .. DocumentUrl)
--     CsLog.Error("Check files. ConfigUrl = " .. ConfigUrl)
--     CsLog.Error("Check files. ApplicationFilePath = " .. ApplicationFilePath)
--     CsLog.Error("Check files. ProductPath = " .. ProductPath)
--     CsLog.Error("Check files. DebugFilePath = " .. DebugFilePath)
-- end

Init()
--PrintPath()

function XLaunchAppPathModule.IsEditorOrStandalone()
    return IsEditorOrStandalone
end

function XLaunchAppPathModule.IsAndroid()
    return CurRuntimePlatform == RuntimePlatform.ANDROID
end

function XLaunchAppPathModule.IsIos()
    return CurRuntimePlatform == RuntimePlatform.IOS;
end

function XLaunchAppPathModule.GetApplicationFilePath()
    return ApplicationFilePath
end

function XLaunchAppPathModule.GetDocumentFilePath()
    return DocumentFilePath
end

function XLaunchAppPathModule.GetDebugFilePath()
    return DebugFilePath
end

function XLaunchAppPathModule.GetDocumentUrl()
    return DocumentUrl
end

function XLaunchAppPathModule.GetConfigUrl()
    return ConfigUrl
end

function XLaunchAppPathModule.GetAppUpgradeUrl()
    return AppUpgradeUrl
end

return XLaunchAppPathModule