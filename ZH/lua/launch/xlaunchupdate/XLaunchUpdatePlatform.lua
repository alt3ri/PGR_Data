----------------------------------------------------------------------------------------------------
-- XLaunchUpdatePlatform.lua
-- description: 平台路径相关信息
-- Created by liang qian
-- --------------------------------------------------------------------------------------------------

local UnityApplication = CS.UnityEngine.Application
local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform
local CsApplication = CS.XApplication
local CsInfo = CS.XInfo

-- region 通用路径

-- 检查字符串是否为空
local LaunchStringIsNilOrEmpty = function (str)
    return str == nil or #str == 0
end

-- 获取StreamingAssets目录下的资源路径
local GetStreamingAssetsResourcePath = function ()
    return UnityApplication.streamingAssetsPath .. "/resource"
end

-- 获取win平台release目录
local GetFileReleasePath = function (productPath, platformName)
    return string.format("%s/File/%s/release", productPath, platformName)
end

-- 获取win平台debug目录
local GetFileDebugPath = function (productPath)
    return productPath .. "/File/win/debug"
end

-- endregion

-- region editor

-- 编辑器信息积累
---@class XLaunchUpdatePlatformEditor
---@field DocumentUrl string 远端更新版本地址
---@field ConfigUrl string 远端配置地址
---@field DocumentFilePath string 本地持久化目录
---@field DownloadFilePath string 下载目录
---@field PreloadFilePath string 预加载目录
---@field ApplicationFilePath string 包内资源路径
---@field DebugFilePath string 调试文件路径
---@field IsEditorOrStandalone boolean 是否是编辑器或Standalone
local XLaunchUpdatePlatformEditor = XLaunchConst.CreateMetaTable("XLaunchUpdatePlatformEditor")

-- 构造函数
function XLaunchUpdatePlatformEditor:Ctor()
    -- 下载apk信息
    self.DocumentFilePath = UnityApplication.persistentDataPath .. "/document"
    self.DownloadFilePath = UnityApplication.persistentDataPath .. "/download"
    self.PreloadFilePath = UnityApplication.persistentDataPath .. "/preload"

    -- 路径配置
    self:InitPath()
    self:InitUrl()
end

-- url路径（无差异）
function XLaunchUpdatePlatformEditor:InitUrl()
    local platformPath = self:_GetPlatformPath()
    local cdnKey = CsInfo.CDNKey
    local identifier = tostring(CsInfo.Identifier)
    local version = CsInfo.Version
    if LaunchStringIsNilOrEmpty(cdnKey) then
        self.DocumentUrl = string.format("client/patch/%s/%s/%s", identifier, version, platformPath)
        self.ConfigUrl = string.format("client/config/%s/%s/%s", identifier, version, platformPath)
    else
        self.DocumentUrl = string.format("client/patch/%s/%s/%s/%s", cdnKey, identifier, version, platformPath)
        self.ConfigUrl = string.format("client/config/%s/%s/%s/%s", cdnKey, identifier, version, platformPath)
    end
    self.DocumentUrlWithoutKey =  "client/patch/%s/%s/%s/" .. platformPath
    -- self.DocumentUrlWithoutKey =  "client/patch/%s/" .. identifier .. "/%s/" .. platformPath
end

-- 路径差异
function XLaunchUpdatePlatformEditor:InitPath()
    local platformName = CS.XLaunchManager.PLATFORM                           -- 编辑器平台，随平台选择而变化
    local ProductPath = UnityApplication.dataPath .. "/../../../Product"
    self.ApplicationFilePath = GetFileReleasePath(ProductPath, platformName)
    self.DebugFilePath = GetFileDebugPath(ProductPath)
    self.IsEditorOrStandalone = true
end

-- 平台差异
function XLaunchUpdatePlatformEditor:_GetPlatformPath()
    return "editor"
end

-- endregion

-- region standalone

---@class XLaunchUpdatePlatformStandalone : XLaunchUpdatePlatformEditor
local XLaunchUpdatePlatformStandalone = XLaunchConst.CreateMetaTable("XLaunchUpdatePlatformStandalone", XLaunchUpdatePlatformEditor)

-- 路径差异
function XLaunchUpdatePlatformStandalone:InitPath()
    local ProductPath = UnityApplication.dataPath .. "/../../../../.."
    local applicationFilePath
    if CsApplication.Debug then
        applicationFilePath = GetFileReleasePath(ProductPath, "win")
    else
        applicationFilePath = GetStreamingAssetsResourcePath()
        
        -- Release包 资源目录跟安装目录相同
        self.DocumentFilePath = UnityApplication.streamingAssetsPath .. "/document"
        self.DownloadFilePath = UnityApplication.streamingAssetsPath .. "/download"
        self.PreloadFilePath = UnityApplication.streamingAssetsPath .. "/preload"
    end
    
    self.ApplicationFilePath = applicationFilePath
    self.DebugFilePath = GetFileDebugPath(ProductPath)
    self.IsEditorOrStandalone = true
end

-- 平台差异
function XLaunchUpdatePlatformStandalone:_GetPlatformPath()
    return "standalone"
end

-- endregion

-- region android

---@class XLaunchUpdatePlatformAndroid : XLaunchUpdatePlatformEditor
local XLaunchUpdatePlatformAndroid = XLaunchConst.CreateMetaTable("XLaunchUpdatePlatformAndroid", XLaunchUpdatePlatformEditor)

-- 路径差异
function XLaunchUpdatePlatformAndroid:InitPath()
    self.ApplicationFilePath = GetStreamingAssetsResourcePath()
    self.IsEditorOrStandalone = false
end

-- 平台差异
function XLaunchUpdatePlatformAndroid:_GetPlatformPath()
    return "android"
end

-- endregion

-- region ios

---@class XLaunchUpdatePlatformIos : XLaunchUpdatePlatformAndroid
local XLaunchUpdatePlatformIos = XLaunchConst.CreateMetaTable("XLaunchUpdatePlatformIos", XLaunchUpdatePlatformAndroid)

-- 平台差异
function XLaunchUpdatePlatformIos._GetPlatformPath()
    return "ios"
end

-- endregion

-- region 获取平台信息

local PlatformToInfo = {
    [UnityRuntimePlatform.Android] = XLaunchUpdatePlatformAndroid,
    [UnityRuntimePlatform.IPhonePlayer] = XLaunchUpdatePlatformIos,
    [UnityRuntimePlatform.WindowsEditor] = XLaunchUpdatePlatformEditor,
    [UnityRuntimePlatform.OSXEditor] = XLaunchUpdatePlatformEditor,
    [UnityRuntimePlatform.LinuxEditor] = XLaunchUpdatePlatformEditor,
    [UnityRuntimePlatform.WindowsPlayer] = XLaunchUpdatePlatformStandalone,
    [UnityRuntimePlatform.OSXPlayer] = XLaunchUpdatePlatformStandalone,
    [UnityRuntimePlatform.LinuxPlayer] = XLaunchUpdatePlatformStandalone,
}

---@class XLaunchUpdatePlatform
XLaunchUpdatePlatform = {}

-- 获取平台信息
---@return XLaunchUpdatePlatformEditor
XLaunchUpdatePlatform.GetPlatformInfo = function(platform)
    local curplatform = platform or UnityApplication.platform
    local platformClass = PlatformToInfo[curplatform]
    if platformClass then
        return platformClass.New()
    else
        return XLaunchUpdatePlatformEditor.New()
    end
end

-- endregion
