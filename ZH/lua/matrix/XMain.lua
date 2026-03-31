XMain = XMain or {}

XMain.IsWindowsEditor = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
local IsWindowsPlayer = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer

XMain.IsDebug = CS.XRemoteConfig.Debug
XMain.IsEditorDebug = (XMain.IsWindowsEditor or IsWindowsPlayer) and XMain.IsDebug
--是否为内部版本
XMain.IsInternal = CS.XApplication.IsInternal

local lockGMeta = {
    __newindex = function(t, k)
        XLog.Error("can't assign " .. k .. " in _G")
    end,
    __index = function(t, k)
        XLog.Error("can't index " .. k .. " in _G, which is nil")
    end
}

function LuaLockG()
    setmetatable(_G, lockGMeta)
end

local import = CS.XLuaEngine.Import

local function ImportXCommonDir()
    -- 默认基础模块
    require("XCommon/Fix")
    require("XCommon/Json")
    CS.XApplication.SetProgress(0.1)
    
    -- 配置表依赖
    local USE_BYTES = 1
    if CS.XTableManager.UseBytes ~= USE_BYTES or CS.XTableManager.UseExternTable then
        require("XCommon/XTable")
    else
        XTable = {}
    end

    require("XCommon/XAnalyticsEvent")
    require("XCommon/XBindTools")
    require("XCommon/XBTree")
    require("XCommon/XBTreeNode")
    require("XCommon/XCameraHelper")
    require("XCommon/XClass")
    require("XCommon/XCode")
    require("XCommon/XCountDown")
    require("XCommon/XDlcNpcAttribType")
    require("XCommon/XDynamicList")
    require("XCommon/XEntityHelper")
    require("XCommon/XEventId")
    require("XCommon/XFightNetwork")
    require("XCommon/XFightUtil")
    require("XCommon/XGlobalFunc")
    require("XCommon/XGlobalVar")
    require("XCommon/XLog")
    require("XCommon/XLuaBehaviour")
    require("XCommon/XLuaVector2")
    require("XCommon/XLuaVector3")
    require("XCommon/XMath")
    CS.XApplication.SetProgress(0.2)

    -- Network按名字排序位置, 由于依赖Rpc，所以需要放在Rpc前面，否则会有依赖问题
    require("XCommon/XNpcAttribType")
    require("XCommon/XObjectPool")
    require("XCommon/XPerformance")
    require("XCommon/XPool")
    require("XCommon/XPrefs")
    require("XCommon/XQueue")

    -- Rpc按名字排序位置
    require("XCommon/XSaveTool")
    require("XCommon/XScheduleManager")
    require("XCommon/XSignBoardPlayer")
    require("XCommon/XStack")
    require("XCommon/XString")

    -- XTable名字排序位置，只给配置引用，放到最前面
    require("XCommon/XTime")
    require("XCommon/XTool")
    require("XCommon/XUiGravity")
    require("XCommon/XUiHelper")
    CS.XApplication.SetProgress(0.3)

    --------------------------------------------------------------------------------
    -- 依赖需要
    require("XCommon/XRpcExceptionCode")
    require("XCommon/XRpc")
    -- 网络依赖Rpc
    require("XCommon/XNetwork")
    require("XCommon/XNetworkCallCd")
    CS.XApplication.SetProgress(0.4)
end

XMain.Step1 = function()
    --打点
    CS.XRecord.Record("23000", "LuaXMainStart")

    if XMain.IsEditorDebug then
        require("XDebug/LuaProfilerTool")
        require("XHotReload")
        require("XDebug/WeakRefCollector")
    end

    ImportXCommonDir()
    require("Binary/ReaderPool")
    require("Binary/CryptoReaderPool")
    import("XConfig")
    require("XModule/XEnumConst")
    require("MVCA/XMVCA") --MVCA入口
    require("XGame")

    require("XEntity/ImportXEntity")
    
    import("XBehavior")
    --import("XGuide")
    require("XMovieActions/XMovieActionBase")
    CS.XApplication.SetProgress(0.52)
end

XMain.Step2 = function()
    require("XManager/XUi/XLuaUiManager")
    import("XManager")

    XMVCA:InitModule()
    XMVCA:InitAllAgencyRpc()

    import("XNotify")
    CS.XApplication.SetProgress(0.54)
end

XMain.Step3 = function()
    import("XHome")
    import("XScene")
    require("XUi/XUiCommon/XUiCommonEnum")
    CS.XApplication.SetProgress(0.68)
end

XMain.Step4 = function()
    LuaLockG()
    --打点
    CS.XRecord.Record("23008", "LuaXMainStartFinish")
end

-- 待c#移除
XMain.Step5 = function()

end

XMain.Step6 = function()
end

XMain.Step7 = function()
end

XMain.Step8 = function()
end

XMain.Step9 = function()
end
