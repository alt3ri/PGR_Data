XUserManager = XUserManager or {}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

XUserManager.CHANNEL = {
    HARU = 1,
    HERO = 2,
    KURO_SDK = 5
}

XUserManager.PLATFORM = {
    Win = 0,
    Android = 1,
    IOS = 2
}

XUserManager.UserId = nil
XUserManager.UserName = nil
XUserManager.Token = nil
XUserManager.ReconnectedToken = nil
XUserManager.Channel = nil
XUserManager.Platform = nil
-- 登录渠道，PC端用
XUserManager.LoginChannel = nil
XUserManager.ServerId = nil

local InitPlatform = function()
    if Platform == RuntimePlatform.Android then
        XUserManager.Platform = XUserManager.PLATFORM.Android
    elseif Platform == RuntimePlatform.IPhonePlayer then
        XUserManager.Platform = XUserManager.PLATFORM.IOS
    else
        XUserManager.Platform = XUserManager.PLATFORM.Win
    end
end

function XUserManager.IsUseSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.HERO or XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK
end

function XUserManager.IsKuroSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK
end

function XUserManager.IsHeroSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.HERO
end

function XUserManager.Init()
    XUserManager.Channel = CS.XRemoteConfig.Channel
    if not XUserManager.IsUseSdk() then
        XUserManager.UserId = CS.UnityEngine.PlayerPrefs.GetString(XPrefs.UserId)
        XUserManager.UserName = CS.UnityEngine.PlayerPrefs.GetString(XPrefs.UserName)
        XUserManager.Token = CS.UnityEngine.PlayerPrefs.GetString(XPrefs.Token)
    end
    InitPlatform()
end

function XUserManager.IsNeedLogin()
    if XUserManager.IsUseSdk() then
        return XHeroSdkManager.IsNeedLogin()
    else
        return XHaruUserManager.IsNeedLogin()
    end
end

function XUserManager.HasLoginError()
    if XUserManager.IsUseSdk() then
        return XHeroSdkManager.HasLoginError()
    else
        return false
    end
end

function XUserManager.ShowLogin()
    if XUserManager.IsUseSdk() then
        XHeroSdkManager.Login()
    else
        XHaruUserManager.Login()
    end
end

function XUserManager.Logout(cb, isInitiative)
    -- 是否是主动登出，默认是主动登出，只有踢人不是主动
    if isInitiative == nil then
        isInitiative = true
    end
    if XUserManager.IsUseSdk() then
        XHeroSdkManager.Logout(cb, isInitiative)
    else
        XHaruUserManager.Logout(cb)
    end
end

function XUserManager.ClearLoginData()
    if XUserManager.IsUseSdk() then
        XHeroSdkManager.Logout()
    else
        XUserManager.SignOut()
    end
end

function XUserManager.SetUserId(userId)
    XLog.Debug("userId:" .. tostring(userId))
    XUserManager.UserId = userId
    if not XUserManager.IsUseSdk() then
        CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserId, XUserManager.UserId)
        CS.UnityEngine.PlayerPrefs.Save()
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERID_CHANGE, userId)
end

function XUserManager.SetUserName(userName)
    XUserManager.UserName = userName

    if not XUserManager.IsUseSdk() then
        CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserName, XUserManager.UserName)
        CS.UnityEngine.PlayerPrefs.Save()
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERNAME_CHANGE, userName)
end

function XUserManager.SetToken(token)
    XUserManager.Token = token
    if not XUserManager.IsUseSdk() then
        CS.UnityEngine.PlayerPrefs.SetString(XPrefs.Token, XUserManager.Token)
        CS.UnityEngine.PlayerPrefs.Save()
    end
end

function XUserManager.SetLoginChannel(channel)
    XUserManager.LoginChannel = channel
    -- 海外合版本改动 所有登录都会传这个，所以要用平台区分
    if XDataCenter.UiPcManager.IsPc() then 
        CS.XLog.Debug(string.format("XUserManager.SetLoginChannel: type: %s , value: %s", type(XUserManager.LoginChannel), tostring(XUserManager.LoginChannel)))
        --pc版的要在获取到登录渠道后才设置选择服务器
        XServerManager.SelectChannelServer()
    end
end

function XUserManager.SetUserType(userType)
    XUserManager.UserType = userType
end

local DoRunLogin = function()
    XEventManager.DispatchEvent(XEventId.EVENT_LOGIN_UI_OPEN)
    CsXUiManager.Instance:SetRevertAndReleaseLock(true)
    XFightUtil.ClearFight()
    if XDataCenter.MovieManager then
        XDataCenter.MovieManager.StopMovie(true)
    end
    CS.Movie.XMovieManager.Instance:Clear()
    CsXUiManager.Instance:Clear()
    XMVCA.XBigWorldGamePlay:OnExitFight()
    XHomeSceneManager.LeaveScene()

    XDataCenter.InitRepeat()
    XMVCA:Init()

    XLoginManager.BackToUiLogin()
end

function XUserManager.SignOut()
    XLoginManager.Disconnect()

    XUserManager.SetUserId(nil)
    XUserManager.SetUserName(nil)
    XUserManager.SetToken(nil)

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)

    DoRunLogin()
end

function XUserManager.OnSwitchAccountSuccess(uid, username, token)
    XLoginManager.Disconnect()

    XUserManager.SetUserId(uid)
    XUserManager.SetUserName(username)
    XUserManager.SetToken(token)

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)
    
    DoRunLogin()
end

function XUserManager.GetLoginType()
    return XUserManager.LoginType[XUserManager.Channel]
end

-- 对应服务端Server文件Define.cs中Channel规则
function XUserManager.GetUniqueUserId()
    local prefix = ""
    if XUserManager.Channel == XUserManager.CHANNEL.HARU then   --dev（母包和win包）、
        prefix = "dev"
    elseif XUserManager.Channel == XUserManager.CHANNEL.HERO then
        local channelId = CS.XHeroSdkAgent.GetChannelId()
        if channelId == XDataCenter.UiPcManager.Channel.Android or channelId == XDataCenter.UiPcManager.Channel.IOS then          --Hero（国服官服渠道18、56）
            prefix = "Hero"
        else                                                --国内其他安卓渠道使用英雄提供的渠道Id
            prefix = tostring(channelId)
        end
    end
    return string.format("%s#%s", prefix, XUserManager.UserId)
end

XRpc.LoginResponse = function(response)
    if response.Token then
        XUserManager.ReconnectedToken = response.Token
        if not XUserManager.IsUseSdk() then
            CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserId, XUserManager.UserId)
            CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserName, XUserManager.UserName)
            -- CS.UnityEngine.PlayerPrefs.SetString(XPrefs.Token, XUserManager.Token)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end
end