-- 检查更新 c# 调用
CheckUpdate = function(isReloaded)
    local CsApplication = CS.XApplication
    require("XLaunchUpdate/XLaunchConst")
    require("XLaunchUpdate/XLaunchUpdatePlatform")

    local XLaunchUiModule = require("XLaunchUiModule")
    CS.XLaunchManager.InitLuaUIProxy(XLaunchUiModule.NewLaunchUi)

    if not isReloaded then
        XLaunchUiModule.RegisterLaunchUi()
    end

    local info = XLaunchUpdatePlatform.GetPlatformInfo()
    -- 测试模式，初始化资源管理器
    if info.IsEditorOrStandalone and CsApplication.Mode == CS.XMode.Debug then
        CS.XResourceManager.InitBundleDebug(info.DebugFilePath)
    elseif info.IsEditorOrStandalone and CsApplication.Mode == CS.XMode.Editor then
        CS.XResourceManager.InitEditor()
    end

    -- 开启Launch模块Ui
    CS.XUiManager.Instance:Open("UiLaunch")
    CS.XRecord.Record("50000", "UiLaunchand")

    -- LuaProfiler = require('MikuLuaProfiler').LuaProfiler
    -- local luaProfiler = CS.MikuLuaProfiler.LuaProfiler
    -- luaProfiler.BeginSample("CheckUpdate")
    local updateManager = require("XLaunchUpdate/XLaunchUpdateManager")
    updateManager:CheckUpdate(isReloaded)
    -- luaProfiler.EndSample()
end
