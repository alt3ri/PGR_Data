XUiPcManagerCreator = function()
    ---@class XUiPcManager
    local XUiPcManager = {

        ---@field Default number@ 默认移动端
        ---@field Pc number@ PC
        ---@field CloudGame number@ 云游戏
        ---@class XUiPcMode@方便lua跳转
        ---@type XUiPcMode
        XUiPcMode = CS.XUiPc.XUiPcMode,

        Channel = {
            Oppo = 1,
            Vivo = 2,
            Huawei = 11,
            Android = 18,
            Pc = 19,
            JiuYou = 20,
            XiaoMi = 23,
            X4399 = 24,
            YingYongBao = 35,
            Bilibili = 46,
            IOS = 56,
            Mumu = 94,
            HeiSha = 147,
            DouYin = 243,
        }
    }
    
    local FullScreenMode = CS.UnityEngine.FullScreenMode
    local PlayerPrefs = CS.UnityEngine.PlayerPrefs

    local EditingKey
    local ExitingGame

    local CsXGameEventManager = CS.XGameEventManager
    local CSEventId = CS.XEventId

    function XUiPcManager.OnUiEnable()
        -- todo 删除
    end

    function XUiPcManager.OnUiDisableAbandoned()
        -- todo 删除 (但是写注释删除的人一直没删除)
    end

    --local function IsInputFieldFocused()
    --    local EventSystem = CS.UnityEngine.EventSystems.EventSystem
    --    if EventSystem then
    --        local isFocused = EventSystem.current.isFocused
    --        if isFocused then
    --            local currentSelectedGameObject = EventSystem.current.currentSelectedGameObject
    --            if not XTool.UObjIsNil(currentSelectedGameObject) then
    --                if currentSelectedGameObject:GetComponent(typeof(CS.UnityEngine.UI.InputField)) then
    --                    return true
    --                end
    --            end
    --        end
    --    end
    --    return false
    --end

    --- 关闭界面
    function XUiPcManager.OnUiDisable()
        XDataCenter.BackManager.OnUiDisable()
    end

    XUiPcManager.Init = function()
        EditingKey = false
        ExitingGame = false
        CS.XUiManagerExtension.SetBlackList("UiNoticeTips") -- 跑马灯
    end

    XUiPcManager.OnEscBtnClick = function()
        XQuitHandler.OnEscBtnClick()
    end

    XUiPcManager.IsOverSea = function()
        return false
    end

    --region !!!这些接口与ui模式分离, 供狗哥专用, 业务层请使用GetUiPcMode自行判断
    XUiPcManager.IsPc = function()
        return CS.XUiPc.XUiPcManager.IsPcMode()
    end

    XUiPcManager.IsCloudGame = function()
        return CS.XInfo.IsCloudGame
    end

    XUiPcManager.IsPcServer = function()
        return CS.XUiPc.XUiPcManager.IsPcModeServer()
    end
    --endregion !!!这些接口与ui模式分离, 供狗哥专用, 业务层请使用GetUiPcMode自行判断
    
    XUiPcManager.GetUiPcMode = function()
        return CS.XUiPc.XUiPcManager.GetUiPcMode()
    end

    -- 设备分辨率,非游戏分辨率
    XUiPcManager.GetDeviceScreenResolution = function()
        local vector = CS.XWin32Api.GetResolutionSize();
        return vector.x, vector.y;
    end

    XUiPcManager.GetTabUiPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local width, height = XUiPcManager.GetDeviceScreenResolution()
        local result = {}
        for i, size in pairs(config) do
            if size.y <= (height - 10)
                    and size.x <= width
            then
                result[#result + 1] = size
            end
        end
        return result
    end

    XUiPcManager.GetOriginPcResolution = function()
        local config = XUiPcConfig.GetTabUiPcResolution()
        local result = {}
        for i, size in pairs(config) do
            result[#result + 1] = size
        end
        return result
    end

    XUiPcManager.SetEditingKeyState = function(editing)
        CS.XJoystickLSHelper.ForceResponse = not editing
        XUiPcManager.EditingKey = editing
        CS.XCommonGenericEventManager.NotifyInt(CSEventId.EVENT_EDITING_KEYSET, editing and 1 or 0)
    end

    XUiPcManager.IsEditingKey = function()
        return XUiPcManager.EditingKey
    end

    XUiPcManager.RefreshJoystickActive = function()
        XEventManager.DispatchEvent(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED)
    end

    XUiPcManager.RefreshJoystickType = function()
        XEventManager.DispatchEvent(XEventId.EVENT_JOYSTICK_TYPE_CHANGED)
    end

    XUiPcManager.FullScreenableCheck = function()
        if XUiPcManager.IsCloudGame() then
            -- 云游戏分辨率不随表格，随手机设备
            local width = CS.XWLinkAgent.ScreenWidth
            local height = CS.XWLinkAgent.ScreenHeight
            CS.XLog.Debug("CloudGame Fix Screen Resolution", width, height)
            CS.XSettingHelper.ForceWindow = true;
            XUiPcManager.SetResolution(width, height, FullScreenMode.Windowed);
            -- XUiPcManager.SetResolution(width, height, FullScreenMode.FullScreenWindow);
            -- XUiPcManager.SaveResolution(width, height)
             return
        end
        local width, height = XUiPcManager.GetDeviceScreenResolution(); -- 获取设备分辨率
        local resolutions = XUiPcManager.GetOriginPcResolution();       -- 获取配置表最大分辨率
        local lastResolution = XUiPcManager.GetLastResolution();        -- 获取上一次设备分辨率
        local lastScreen = XUiPcManager.GetLastScreen();                -- 获取上一次使用的屏幕分辨率 
        local unityScreen = XUiPcManager.GetUnityScreen();              -- 获取Unity写入的设备分辨率
		local minResolution = resolutions[1]
        local length = #resolutions
        local maxResolution = resolutions[length]
        local lessHeightResolution = XUiPcManager.GetLessHeightResolution(resolutions, height)
        local noFrame = XUiPcManager.GetLastNoFrame();
        local lastFullScreen = XUiPcManager.GetLastFullScreen();
        local windowedMode = FullScreenMode.Windowed;
        local fullScreenMode = not noFrame and FullScreenMode.ExclusiveFullScreen or FullScreenMode.FullScreenWindow;
        local mode = lastFullScreen and fullScreenMode or windowedMode;
        CS.XLog.Debug(string.format("获取设备分辨率，width：%s，height：%s；配置，maxResolution：(%s,%s)，minResolution：(%s,%s)；lastResolution：%s，lastScreen：%s；unity写入的设备分辨率，%s * %s", 
                width, height, maxResolution.x, maxResolution.y, minResolution.x, minResolution.y, lastResolution, lastScreen, unityScreen.width, unityScreen.height))
        if width > maxResolution.x or height > maxResolution.y then
            CS.XLog.Debug("不能使用全屏")
            -- compare 
            -- 当获取的屏幕尺寸超过配置表最大值时
            -- 这货不能用全屏, 给他禁掉
            CS.XSettingHelper.ForceWindow = true;
            -- 同时立即设置为窗口模式
            CS.UnityEngine.Screen.fullScreen = false;
            local fitWidth;
            local fitHeight;
            if (lastScreen.width ~= 0 and lastScreen.height ~= 0) and lastScreen.width <= lessHeightResolution.x and lastScreen.height <= lessHeightResolution.y then
                fitWidth = lastScreen.width;
                fitHeight = lastScreen.height;
            else
                fitWidth = lessHeightResolution.x;
                fitHeight = lessHeightResolution.y;
            end
            CS.XLog.Debug(string.format("fitResolution:%s x %s", fitWidth, fitHeight))
            XUiPcManager.SetResolution(fitWidth, fitHeight, windowedMode)
        elseif width < lastResolution.width or height < lastResolution.height then
            if (lastScreen.width > minResolution.x and lastScreen.height > minResolution.y) and (width < lastScreen.width or height < lastScreen.height) then
                -- 当前设备分辨率小于上一次使用的屏幕分辨率, 使其全屏
                CS.XLog.Debug(string.format("新设备比旧设备分辨率小, 直接使用当前分辨率并全屏，width：%s，height：%s", width, height))
                XUiPcManager.SetResolution(width, height, fullScreenMode);
            else
                -- 当前设备分辨率大于上一次使用的屏幕分辨率, 直接使用上一次的作为当前窗口分辨率设置
                CS.XLog.Debug("新设备比旧设备分辨率小, 但是大于上一次窗口分辨率设置, 使用上一次的窗口化分辨率，mode：%s", mode)
                XUiPcManager.SetResolution(lastScreen.width, lastScreen.height, mode)
            end
            CS.XSettingHelper.ForceWindow = false;
        elseif height == unityScreen.height and not lastFullScreen then
            -- 理应不会出现高 如 1450 或 1430 的 分辨率
            -- 当前设备分辨率 等于 上一次使用的屏幕分辨率, 且非全屏, 则改为小一级的
            CS.XLog.Debug(string.format("设备分辨率高度与配置分辨率高度一致, 使用小一级窗口化分辨率, width: %s, heigth: %s", lessHeightResolution.x, lessHeightResolution.y))
            XUiPcManager.SetResolution(lessHeightResolution.x, lessHeightResolution.y, windowedMode)
        else
            if unityScreen.width < minResolution.x or unityScreen.height < minResolution.y then
                -- unity读取的尺寸很可能导致条幅屏, 判断是否有正确的缓存值
				if lastScreen.width > minResolution.x and lastScreen.height > minResolution.y then
				    -- 如果有正确的缓存值
					CS.XLog.Debug("设置过正确的缓存值, 使用这个")
					XUiPcManager.SetResolution(lastScreen.width, lastScreen.height, mode)
				else
				    -- 没有正确的缓存值, 使用全屏
				    CS.XLog.Debug("未被设置过, 使用全屏")
                    XUiPcManager.SetResolution(width, height, mode)
				end
            else
                CS.XLog.Debug("不需要任何变化")
            end
            CS.XSettingHelper.ForceWindow = false;
        end
        -- 记录设备分辨率
        XUiPcManager.SaveResolution(width, height)
    end

    XUiPcManager.GetLessHeightResolution = function(resolutions, height)
        -- 反向遍历, 求得一个小于目标值的分辨率
        -- local taskbarHeight = CS.XWin32Api.GetTaskbarSize().x
        local taskbarHeight = 40
        CS.XLog.Debug(string.format("任务栏高度%d", taskbarHeight))
        for i = #resolutions, 1, -1 do
            local resolution = resolutions[i]
            if resolution.y < height - taskbarHeight then
                return resolution
            end
        end
        return resolutions[1]
    end

    XUiPcManager.LastResolution = nil
    -- 获取上一次设备分辨率
    XUiPcManager.GetLastResolution = function()
        if not XUiPcManager.LastResolution then
            local prefs = PlayerPrefs.GetString("LastResolution", nil);
            if not prefs or prefs == "" then
                XUiPcManager.LastResolution = CS.UnityEngine.Screen.currentResolution
            else
                local empty = CS.XUnityEx.ResolutionEmpty
                local arr = string.Split(prefs, ",")
                empty.width = arr[1]
                empty.height = arr[2]
                XUiPcManager.LastResolution = empty
            end
        end
        return XUiPcManager.LastResolution
    end

    XUiPcManager.LastScreen = nil
    -- 获取上一次使用的屏幕分辨率 
    XUiPcManager.GetLastScreen = function()
        if not XUiPcManager.LastScreen then
            local prefs = PlayerPrefs.GetString("LastScreen", nil)
            if not prefs or prefs == "" then
                XUiPcManager.LastScreen = CS.XUnityEx.ResolutionEmpty
            else
                local empty = CS.XUnityEx.ResolutionEmpty
                local arr = string.Split(prefs, ",")
                empty.width = arr[1]
                empty.height = arr[2]
                XUiPcManager.LastScreen = empty
            end
        end
        return XUiPcManager.LastScreen
    end

    -- 获取Unity写入的设备分辨率
    XUiPcManager.GetUnityScreen = function()
        local Screen = CS.UnityEngine.Screen
        local result = {
            width = Screen.width,
            height = Screen.height
        }
        return result;
    end

    XUiPcManager.LastFullScreen = false
    -- 获取上一次是否全屏
    XUiPcManager.GetLastFullScreen = function()
        if not XUiPcManager.LastFullScreen then
            local prefs = PlayerPrefs.GetInt("LastFullScreen", -1)
            if prefs == -1 then
                XUiPcManager.LastFullScreen = CS.UnityEngine.Screen.fullScreen
            else
                XUiPcManager.LastFullScreen = prefs == 1
            end
        end
        return XUiPcManager.LastFullScreen
    end

    XUiPcManager.LastFullScreenMode = nil
    -- 获取上一次全屏模式, 有独占全屏, 全屏无边框, 窗口模式
    XUiPcManager.GetLastFullScreenMode = function()
        if not XUiPcManager.LastFullScreenMode then
            local prefs = PlayerPrefs.GetInt("LastFullScreenMode", -1);
            if prefs < 0 or prefs > 3 then
                XUiPcManager.LastFullScreenMode = CS.UnityEngine.Screen.fullScreenMode;
            else
                XUiPcManager.LastFullScreenMode = FullScreenMode.__CastFrom(prefs)
            end
        end
        return XUiPcManager.LastFullScreenMode
    end

    XUiPcManager.LastNoFrame = false
    XUiPcManager.GotLastNoFrame = false
    -- 获取上一次是否无边框
    XUiPcManager.GetLastNoFrame = function()
        if not XUiPcManager.GotLastNoFrame then
            XUiPcManager.GotLastNoFrame = true
            local prefs = CS.UnityEngine.PlayerPrefs.GetInt("LastNoFrame", -1)
            if prefs == -1 then
                XUiPcManager.LastNoFrame = true
            else
                XUiPcManager.LastNoFrame = prefs == 1
            end
        end
        return XUiPcManager.LastNoFrame
    end

    -- 保存无边框记录
    XUiPcManager.SetNoFrame = function(value)
        XUiPcManager.LastNoFrame = value
        CS.UnityEngine.PlayerPrefs.SetInt("LastNoFrame", value and 1 or 0)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    ---@param width number
    ---@param height number
    ---@param fullScreenMode FullScreenMode 
    XUiPcManager.SetResolution = function(width, height, fullScreenMode)
        CS.XSettingHelper.SetResolution(width, height, fullScreenMode)
        XUiPcManager.SaveScreen(width, height)
        XUiPcManager.SaveFullScreen(fullScreenMode == FullScreenMode.FullScreenWindow or fullScreenMode == FullScreenMode.ExclusiveFullScreen)
        XUiPcManager.SaveFullScreenMode(fullScreenMode)
        if XDataCenter.UiPcManager.IsPcServer() then
            XLog.Error(string.format("设置窗口大小调试日志 SetResolution，width：%s，height：%s，fullScreenMode：%s", width, height, fullScreenMode))
        end
    end

    -- 保存设备分辨率
    XUiPcManager.SaveResolution = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty
        empty.width = width;
        empty.height = height
        XUiPcManager.LastResolution = empty
        PlayerPrefs.SetString("LastResolution", width .. "," .. height);
        PlayerPrefs.Save();
    end

    -- 保存窗体分辨率
    XUiPcManager.SaveScreen = function(width, height)
        local empty = CS.XUnityEx.ResolutionEmpty
        empty.width = width
        empty.height = height
        XUiPcManager.LastScreen = empty
        PlayerPrefs.SetString("LastScreen", width .. "," .. height)
        PlayerPrefs.Save()
    end

    -- 保存全屏(bool)
    XUiPcManager.SaveFullScreen = function(fullScreen)
        XUiPcManager.LastFullScreen = fullScreen
        PlayerPrefs.SetInt("LastFullScreen", fullScreen and 1 or 0)
        PlayerPrefs.Save()
    end

    -- 保存全屏Mode(FullScreenMode)
    XUiPcManager.SaveFullScreenMode = function(fullScreenMode)
        XUiPcManager.LastFullScreenMode = fullScreenMode;
        PlayerPrefs.SetInt("LastFullScreenMode", fullScreenMode);
        PlayerPrefs.Save()
    end

    XUiPcManager.AddCustomUI = function(root)
        CS.XUiManagerExtension.AddCustomUI(root)
    end

    XUiPcManager.RemoveCustomUI = function(root)
        CS.XUiManagerExtension.RemoveCustomUI(root)
    end

    XUiPcManager.Init()
    return XUiPcManager
end
