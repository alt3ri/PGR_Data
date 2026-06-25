XMain = XMain or {}

XMain.IsWindowsEditor = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
local IsWindowsPlayer = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer

--远程配置是否为Debug环境
XMain.IsDebug = CS.XRemoteConfig.Debug
-- (Editor or PCWin包) and 远程配置是否为Debug环境
XMain.IsEditorDebug = (XMain.IsWindowsEditor or IsWindowsPlayer) and XMain.IsDebug
--DevBuild 构建，不包含HARU_DEBUG宏
XMain.IsDevBuild = CS.XApplication.DevBuild
--Debug构建 约等于 HARU_DEBUG。在DevBuild构建模式下不成立
XMain.IsDebugBuild = CS.XApplication.Debug
--是否为内部版本
XMain.IsInternal = CS.XApplication.IsInternal
--是否使用原生层指针读取
XMain.UseNativePtrReader = CS.XRemoteConfig.UseNativePtrReader

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
    require("XCommon/XLuaTime")
    require("XCommon/XLuaVector2")
    require("XCommon/XLuaVector3")
    require("XCommon/XMath")
    CS.XApplication.SetProgress(0.2)

    -- Network按名字排序位置, 由于依赖Rpc，所以需要放在Rpc前面，否则会有依赖问题
    require("XCommon/XNpcAttribType")
    require("XCommon/XPerformance")
    require("XCommon/XStack")
    require("XCommon/XPool")
    require("XCommon/XObjectPool")
    require("XCommon/XPrefs")
    require("XCommon/XQueue")

    -- Rpc按名字排序位置
    require("XCommon/XSaveTool")
    require("XCommon/XScheduleManager")
    require("XCommon/XSignBoardPlayer")
    require("XCommon/XString")
    require("XCommon/XTableExtension")
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
    require("XConfig/RequireConfig")
    require("XModule/XEnumConst")
    require("MVCA/XMVCA") --MVCA入口
    
    require("XGame")

    require("XBehavior/XLuaBehaviorManager")
    require("XBehavior/XLuaBehaviorAgent")
    require("XBehavior/XLuaBehaviorNode")
    
    require("XEntity/ImportXEntity")
    
    
    require("XMovieActions/XMovieActionBase")
    CS.XApplication.SetProgress(0.52)
end

XMain.Step2 = function()
    require("XManager/RequireManager")

    XMVCA:InitModule()
    XMVCA:InitAllAgencyRpc()

    CS.XApplication.SetProgress(0.54)
end

XMain.Step3 = function()
    require("XHome/XDorm/XHomeChar/XHomeBehaviorState")
    require("XHome/XDorm/XHomeChar/XHomeCharAgent")
    require("XHome/XDorm/XHomeChar/XHomeCharFSMFactory")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSM")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSMControl")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSMEmpty")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSMIdle")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSMInteract")
    require("XHome/XDorm/XHomeChar/XHomeFSM/XHomeCharFSMMood")
    require("XHome/XDorm/XHomeCharManager")
    require("XHome/XDorm/XHomeDormManager")
    require("XHome/XDorm/XHomeFurniture/XHomeFurnitureAgent")
    require("XHome/XDorm/XHomePet/XHomePetAgent")
    require("XHome/XHomeScene")
    require("XHome/XHomeSceneManager")
    require("XHome/XInfrastructure/XDeviceObject")
    require("XHome/XInfrastructure/XHomeInfrastructureManager")
    require("XHome/XInfrastructure/XRoomObject")
    require("XHome/XSceneEntityManager")
    require("XHome/XSceneResourceManager")
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

