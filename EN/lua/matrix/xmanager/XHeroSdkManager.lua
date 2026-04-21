XHeroSdkManager = XHeroSdkManager or {}

local Json = require("XCommon/Json")

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local IsSdkLogined = false
local LogoutSccess = 0
local LogoutFailed = 1
local LogoutCb = nil
local LastTimeOfCallSdkLoginUi = 0
local CallLoginUiCountDown = 2
local HeroRoleInfo = CS.XHeroRoleInfo
local HeroOrderInfo = CS.XHeroOrderInfo
local PayCallbacks = {}     -- android 充值回调
local IOSPayCallback = nil  -- iOS 充值回调
local PCPayCallback = nil -- PC 充值回调
local HasSdkLoginError = false -- sdk登陆存在错误
--local CallbackUrl = "http://haru.free.idcfengye.com/api/XPay/HeroPayResult"

local CallbackUrl = nil
local CallbackUrls = {} -- EN 充值回调

local function SplitPayCallList(list, str)
    if str == "" or str == nil then
        return
    end
    local strs = string.Split(str, '#')
    local i = 1
    for _, value in ipairs(strs) do
        list[i] = value
        i = i + 1
    end
end

local function LoadPayCallback()
    if CS.XLocalizationManager.Instance.Language == CS.XKuro.Localization.Data.Language.EN then
        SplitPayCallList(CallbackUrls, CS.XRemoteConfig.PayCallbackUrl)
    else
        CallbackUrl = CS.XRemoteConfig.PayCallbackUrl
    end
end

LoadPayCallback()

local XRecordUserInfo = CS.XRecord.XRecordUserInfo

local IsNeedShowReddot = false
local deepLinkValue = ""
local CleanPayCallbacks = function()
    PayCallbacks = {}
    IOSPayCallback = nil
    PCPayCallback = nil
end
XHeroSdkManager.UserType = {
    Vistor = 0,
    FaceBook = 1,
    Google = 2,
    GameCenter = 3,
    WeChat = 4,
    Twitter = 5,
    Line = 6,
    Apple = 7,
    Line = 8,
    Suid = 9,
    Mail = 16,
    Naver = 17,
}

function XHeroSdkManager.UpdateCallbackUrl()
    LoadPayCallback()
end

function XHeroSdkManager.SetCallbackUrl(server)
    if server.Id > #CallbackUrls then
        XLog.Error("支付服务器地址数量与服务器数量不匹配")
    end
    CallbackUrl = CallbackUrls[server.Id]
end

function XHeroSdkManager.IsNeedLogin()
    return not (CS.XHeroSdkAgent.IsLogined() and IsSdkLogined)
end

function XHeroSdkManager.HasLoginError()
    return HasSdkLoginError
end

function XHeroSdkManager.Login()
    if not XHeroSdkManager.IsNeedLogin() then
        CS.XRecord.Record("24035", "HeroSdkRepetitionLogin")
        return
    end

    local curTime = CS.UnityEngine.Time.realtimeSinceStartup
    if curTime - LastTimeOfCallSdkLoginUi < CallLoginUiCountDown then
        CS.XRecord.Record("24036", "HeroSdkShortTimeLogin")
        return
    end
    LastTimeOfCallSdkLoginUi = curTime
    
    HasSdkLoginError = false
    CS.XRecord.Record("24023", "HeroSdkLogin")
    CS.XHeroSdkAgent.Login()
end

function XHeroSdkManager.Logout(cb, isInitiative)
    -- 是否是主动登出，默认是主动登出，只有踢人不是主动
    if isInitiative == nil then
        isInitiative = true
    end
    if XHeroSdkManager.IsNeedLogin() then
        if cb then
            cb(LogoutFailed)
        end
        return
    end

    LogoutCb = cb
    
    -- 被动退出，直接走退出
    if not isInitiative then
        CS.XRecord.Record("24039", "HeroSdkKickout")
        XHeroSdkManager.OnLogoutSuccess()
        return 
    end

    CS.XRecord.Record("24029", "HeroSdkLogout")
    CS.XHeroSdkAgent.Logout()

    -- 海外暂时也没有登录回调
    if Platform == RuntimePlatform.IPhonePlayer or XOverseaManager.IsOverSeaRegion() then
        -- iOS 无回调，直接调用退出
        XHeroSdkManager.OnLogoutSuccess()
    end
end

function XHeroSdkManager.OnLoginSuccess(uid, username, token, loginChannel)
    if IsSdkLogined and XUserManager.UserId ~= uid then
        XLog.Error("重复的登陆成功回调 user_id1:" .. tostring(XUserManager.UserId) .. ", user_id2:" .. tostring(uid))
        HasSdkLoginError = true
    end
    IsSdkLogined = true
    LastTimeOfCallSdkLoginUi = 0

    XLog.Debug("uid:" .. tostring(uid) .. ", username:" .. tostring(username) .. ", token:" .. tostring(token))
    XUserManager.SetUserId(uid)
    if XOverseaManager.IsENRegion() then
        XServerManager.SelectServerAndSort()
    end
    XUserManager.SetUserName(username)
    XUserManager.SetToken(token)
    XUserManager.SetLoginChannel(loginChannel)

    local info = XRecordUserInfo()
    info.UserId = XUserManager.GetUniqueUserId()
    info.UserName = username
    CS.XRecord.Login(info)
    CS.XRecord.Record("24024", "HeroSdkLoginSuccess")

    CleanPayCallbacks()
    
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_SDK_LOGIN_SUCCESS)
    --CheckPoint: APPEVENT_SDK_INITIALIZE
    XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.SDK_Initialize)
end

function XHeroSdkManager.OnLoginFailed(msg)
    XLog.Error("Hero sdk login failed. " .. msg)
    IsSdkLogined = false
    CS.XRecord.Record("24032", "HeroSdkLoginFailed")
    local errorTxt = CS.XTextManager.GetText("HeroSdkLoginFailed")
    -- KuroSDK提供的，如果登录失败返回这个，则是SDK未初始化完，换个提醒
    if string.match(msg, "failed for init not accomplished") then 
        errorTxt = CS.XTextManager.GetText("HeroSdkNotInit")
    end
    LastTimeOfCallSdkLoginUi = 0
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), errorTxt, XUiManager.DialogType.OnlySure, nil, function()
        XHeroSdkManager.Login()
    end)
end

function XHeroSdkManager.OnLoginCancel()
    IsSdkLogined = false
    LastTimeOfCallSdkLoginUi = 0
    -- CS.XRecord.Record("24032", "HeroSdkLoginFailed")
end

function XHeroSdkManager.OnSwitchAccountSuccess(uid, username, token)
    -- 先设置UserId
    XUserManager.OnSwitchAccountSuccess(uid, username, token)

    -- 再进行埋点
    local info = XRecordUserInfo()
    info.UserId = XUserManager.GetUniqueUserId()
    info.UserName = username
    CS.XRecord.Login(info)
    CS.XRecord.Record("24025", "HeroSdkSwitchAccountSuccess")

    CleanPayCallbacks()
end

function XHeroSdkManager.OnSwitchAccountFailed(msg)
    CS.XRecord.Record("24026", "HeroSdkSwitchAccountFailed")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, nil)
end

function XHeroSdkManager.OnSwitchAccountCancel()
    --TODO
end

function XHeroSdkManager.OnLogoutSuccess()
    IsSdkLogined = false
    CS.XRecord.Record("24027", "HeroSdkLogoutSuccess")
    CS.XRecord.Logout()
    CleanPayCallbacks()
    XUserManager.SignOut()

    if LogoutCb then
        LogoutCb(LogoutSccess)
        LogoutCb = nil
    end
end

function XHeroSdkManager.OnLogoutFailed(msg)
    IsSdkLogined = true
    CS.XRecord.Record("24028", "HeroSdkLogoutFailed")
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), msg, XUiManager.DialogType.OnlySure, nil, nil)

    if LogoutCb then
        LogoutCb(LogoutFailed)
        LogoutCb = nil
    end
end

-- 是否是主动登出的，跟SDK被动登出的做区分
function XHeroSdkManager.IsLogout()
end

function XHeroSdkManager.OnSdkKickOff(msg)
    XLog.Debug("XHeroSdkManager.OnSdkKickOff()  msg = " .. msg)
    XDataCenter.AntiAddictionManager.Kick(msg)
end

local GetRoleInfo = function()
    local roleInfo = HeroRoleInfo()
    roleInfo.Id = XPlayer.Id
    if XUserManager.IsKuroSdk() then 
        -- 库洛母包需要有正确的区服ID，下面那个else获取的是服务器列表索引值，其实是错的
        roleInfo.ServerId = XUserManager.ServerId
    else 
        roleInfo.ServerId = XServerManager.Id
    end
    roleInfo.ServerName = XServerManager.ServerName
    roleInfo.Name = XPlayer.Name
    roleInfo.Level = XPlayer.Level
    roleInfo.CreateTime = XPlayer.CreateTime
    roleInfo.PaidGem = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PaidGem)
    roleInfo.Coin = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Coin)
    roleInfo.SumPay = 0
    roleInfo.VipLevel = 0
    roleInfo.PartyName = nil

    return roleInfo
end

function XHeroSdkManager.EnterGame()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.EnterGame(GetRoleInfo())
end

function XHeroSdkManager.CreateNewRole()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.CreateNewRole(GetRoleInfo())
end

function XHeroSdkManager.RoleLevelUp()
    if not XUserManager.IsUseSdk() then
        return
    end
    CS.XHeroSdkAgent.RoleLevelUp(GetRoleInfo())
end

local GetOrderInfo = function(cpOrderId, goodsId, extraParams,productKey)
    local orderInfo = HeroOrderInfo()
    orderInfo.CpOrderId = cpOrderId
    orderInfo.GoodsId = goodsId

    if extraParams and _G.next(extraParams) then
        orderInfo.ExtraParams = Json.encode(extraParams)
    end
    local template = XPayConfigs.GetPayTemplate(productKey)

    if XUserManager.IsKuroSdk() and template then
        -- orderInfo.Price = tostring(template.Amount)
        orderInfo.Price = tostring(template.ShowAmount)
        orderInfo.GoodsName = template.Name
        orderInfo.GoodsDesc = template.Desc
        orderInfo.Currency = template.Currency
    end
    -- if productInfo.GoodsName and #productInfo.GoodsName > 0 then
    --     orderInfo.GoodsName = productInfo.GoodsName
    -- end
    -- if productInfo.GoodsDesc and #productInfo.GoodsDesc > 0 then
    --     orderInfo.GoodsDesc = productInfo.GoodsDesc
    -- end
    -- if productInfo.Amount and productInfo.Amount > 0 then
    --     orderInfo.Amount = productInfo.Amount
    -- end
    -- if productInfo.Price and productInfo.Price > 0 then
    --     orderInfo.Price = productInfo.Price
    -- end
    -- if productInfo.Count and productInfo.Count > 0 then
    --     orderInfo.Count = productInfo.Count
    -- end
    if CallbackUrl then
        orderInfo.CallbackUrl = CallbackUrl
    end

    return orderInfo
end

-- 新的统一支付接口
function XHeroSdkManager.NewPay(productKey, cpOrderId, goodsId, cb)
    PayCallbacks[cpOrderId] = {
            cb = cb,
            info = {
                ProductKey = productKey,
                CpOrderId = cpOrderId,
                GoodsId = goodsId,
                PlayerId = XPlayer.Id
            }
        }
    local order = GetOrderInfo(cpOrderId, goodsId,nil,productKey)
    CS.XHeroSdkAgent.Pay(order, GetRoleInfo())
    XDataCenter.AntiAddictionManager.BeginPayAction()
end

-- 新的统一支付回调
function XHeroSdkManager.OnPaySuccess(sdkOrderId, cpOrderId, extraParams)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.info.sdkOrderId = sdkOrderId
        cbInfo.cb(nil, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayFailed(cpOrderId, msg)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(msg, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayCancel(cpOrderId)
    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end
-- 新的统一支付回调End


function XHeroSdkManager.Pay(productKey, cpOrderId, goodsId, cb)
    -- local extraParams = {
    --     PlayerId = XPlayer.Id,
    --     ProductKey = productKey,
    --     CpOrderId = cpOrderId,
    --     ProductId = productInfo.ProductId
    -- }
    if Platform == RuntimePlatform.Android then
        PayCallbacks[cpOrderId] = {
            cb = cb,
            info = {
                ProductKey = productKey,
                CpOrderId = cpOrderId,
                GoodsId = goodsId,
                PlayerId = XPlayer.Id
            }
        }
    end

    local order = GetOrderInfo(cpOrderId, goodsId,nil,productKey)
    CS.XHeroSdkAgent.Pay(order, GetRoleInfo())
    XDataCenter.AntiAddictionManager.BeginPayAction()
end

function XHeroSdkManager.OnPayAndSuccess(sdkOrderId, cpOrderId)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.info.sdkOrderId = sdkOrderId
        cbInfo.cb(nil, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayAndFailed(cpOrderId, msg)
    local cbInfo = PayCallbacks[cpOrderId]
    if cbInfo and cbInfo.cb then
        cbInfo.cb(msg, cbInfo.info)
    end

    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayAndCancel(cpOrderId)
    PayCallbacks[cpOrderId] = nil
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayIOSSuccess(orderId)
    if IOSPayCallback then
        IOSPayCallback(nil, orderId)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayIOSFailed(msg)
    if IOSPayCallback then
        IOSPayCallback(msg)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.RegisterIOSCallback(cb)
    IOSPayCallback = cb
end

function XHeroSdkManager.OnPayPCSuccess(orderId)
    if PCPayCallback then
        PCPayCallback(nil, orderId)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.OnPayPCFail(msg)
    if PCPayCallback then
        PCPayCallback(msg)
    end
    XDataCenter.AntiAddictionManager.EndPayAction()
end

function XHeroSdkManager.RegisterPCCallback(cb)
    PCPayCallback = cb
end

function XHeroSdkManager.IsPayEnable()
    if XDataCenter.UiPcManager.IsPc() then
        return CS.XHeroSdkAgent.IsPCPayEnable == true and CS.XRemoteConfig.IsPCPayEnable == true
    end
    return true
end

-- 客服接口
function XHeroSdkManager.Feedback(from, isLogin)
    -- 加上返回是为了兼容是否有接入SDK
    if CS.XHeroSdkAgent.Feedback then 
        CS.XHeroSdkAgent.Feedback(from, isLogin, GetRoleInfo())
        return true
    end
    return false
end

-- 客服回调，用于触发红点刷新
function XHeroSdkManager.FeedbackCallback()
    IsNeedShowReddot = true
    XEventManager.DispatchEvent(XEventId.EVENT_FEEDBACK_REFRESH)
end

-- 检测客服红点
function XHeroSdkManager.CheckShowReddot()
    return IsNeedShowReddot
end

-- 清理客服红点
function XHeroSdkManager.ClearReddot()
    IsNeedShowReddot = false
end

-- 分享是否开放
function XHeroSdkManager.SharePlatformIsEnable(platform)
    return CS.XHeroSdkAgent.SharePlatformIsEnable(platform)
end

-- 分享
function XHeroSdkManager.Share(platform, path, callback, title, text, topics)
    CS.XHeroSdkAgent.Share(platform, path, callback, title, text, topics)
end

-- 内嵌浏览器打开，url：网址，title：标题，transparent：bool是否隐藏标题，默认false不隐藏，isLandscape：是否横屏，默认true横屏
function XHeroSdkManager.OpenWebview(url, title, transparent, isLandscape, cb)
    transparent = transparent or false
    isLandscape = isLandscape == nil and true or isLandscape
    if isLandscape == false and XUserManager.Platform == XUserManager.PLATFORM.IOS then 
        -- iOS SDK的问题，用他们竖屏Webview的时候，要先将我们游戏给旋转过来，
        CS.XResolutionManager.SetIsLandscape(false) 
        XScheduleManager.ScheduleNextFrame(function()
            local isSuccess = CS.XHeroSdkAgent.OpenWebView(url, title, transparent, false)

            if isSuccess then
                if cb then
                    cb()
                end
            end
        end)
    else 
        local isSuccess = CS.XHeroSdkAgent.OpenWebView(url, title, transparent, isLandscape)

        if isSuccess then
            if cb then
                cb()
            end
        end
    end 

end

function XHeroSdkManager.OnWebviewClose()
    XEventManager.DispatchEvent(XEventId.EVENT_WEBVIEW_CLOSE)
end

-- 外部浏览器打开
function XHeroSdkManager.OpenURL(url)
    CS.XHeroSdkAgent.OpenUrl(url)
end

function XHeroSdkManager.GetAccessToken()
    if XUserManager.IsKuroSdk() then 
        return CS.XHeroSdkAgent.GetAccessToken()    
    end
    return ""
end
function XHeroSdkManager.SetUserType(userType)
    XUserManager.SetUserType(userType)
end
function XHeroSdkManager.OnBindTaskFinished()
    local taskConfig = XTaskConfig.GetTaskCondition(2120001)
    if taskConfig == nil then
        return
    end
    local taskParam = taskConfig.Params[2]
    XNetwork.Call("DoClientTaskEventRequest", {ClientTaskType = taskParam}, function(reply)
        if reply.Code ~= XCode.Success then
            return
        end
        XLog.Debug("引继码任务完成")
    end)
end

function XHeroSdkManager.ClearDeepLinkValue()
    deepLinkValue = nil
end
function XHeroSdkManager.GetDeepLinkValue()
    if not deepLinkValue or deepLinkValue == "" then
        deepLinkValue = CS.XHeroSdkAgent.GetDeepLinkValue()
    end
    if deepLinkValue and deepLinkValue ~= "" then
        XLog.Debug("DeepLinkValue:"..tostring(deepLinkValue))
        return deepLinkValue
    end
end

function XHeroSdkManager.GetCurPkgId()
    if XUserManager.IsUseSdk() then
        if XUserManager.Platform == XUserManager.PLATFORM.IOS then
            return 'A1348'
        else
            return CS.XHeroSdkAgent.GetPkgId()
        end
    end
    
    return ''
end

function XHeroSdkManager.OnKRPluginCallback(responseData)
    XPgsAchievementManager.OnKRPluginCallback(responseData)
end