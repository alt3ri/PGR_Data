XDeeplinkManager = XDeeplinkManager or {}

local this = XDeeplinkManager

function this.InvokeDeeplink()
    local deeplinkEnabled =  CS.XRemoteConfig.DeeplinkEnabled
    if XOverseaManager.IsOverSeaRegion() then
        deeplinkEnabled = CS.XRemoteConfig.AFDeepLinkEnabled
    end
    if deeplinkEnabled == false then
        return false
    end
    
    local isMainUi = XLuaUiManager.IsUiShow("UiMain")
    if not isMainUi then
        return false
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end

 
    return this.GetDeeplinkValue()
end
function this.GetDeeplinkValue()
    if XOverseaManager.IsOverSeaRegion() then
        local deepLinkValue = XHeroSdkManager.GetDeepLinkValue()
        XHeroSdkManager.ClearDeepLinkValue() -- 不论如何，拿到就清空

        CS.XLog.Debug(deepLinkValue)
        local NewGuidePass = CS.XGame.ClientConfig:GetInt("DeepLinkCondition")
        if not string.IsNilOrEmpty(deepLinkValue) and XConditionManager.CheckCondition(NewGuidePass) then
            local skipId = tonumber(deepLinkValue)
            if skipId and XFunctionManager.IsAFDeepLinkCanSkipByShowTips(skipId) then
                XFunctionManager.SkipInterface(skipId)
                return true
            end
        end
        return false
    end
    local deepMgr = CS.XDeeplinkManager;
    if deepMgr.HasDeeplink == false then
        return false
    end
    XFunctionManager.SkipInterface(deepMgr.DeeplinkValue)
    deepMgr.Reset()
    return true
end

function this.InvokeOverSeaDeeplink()
    if CS.XRemoteConfig.AFDeepLinkEnabled == false then
        return false
    end

    local isMainUi = XLuaUiManager.IsUiShow("UiMain")
    if not isMainUi then
        return false
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end
    local afdeeplink = CS.XHeroSdkAgent.GetDeepLinkValue()
    CS.XLog.Debug("afdeeplink")
    CS.XLog.Debug(afdeeplink)
    local NewGuidePass = CS.XGame.ClientConfig:GetInt("DeepLinkCondition")
    if CS.XRemoteConfig.AFDeepLinkEnabled and not string.IsNilOrEmpty(afdeeplink) and XConditionManager.CheckCondition(NewGuidePass) then
        local endValuePos = afdeeplink:find("?af_qr=true", 1) or 0
        if endValuePos-1 > 1 then
            afdeeplink = afdeeplink:sub(1,endValuePos-1)
        end
        local afdeepInfo = string.Split(afdeeplink, "_")
        CS.XHeroSdkAgent.ResetAFDeepLinkValue()
        if afdeepInfo[1] == "i" then
            local skipId = tonumber(afdeepInfo[2])
            if XFunctionManager.IsAFDeepLinkCanSkipByShowTips(skipId) then
                XFunctionManager.SkipInterface(skipId)
                return true
            end
        end
    elseif not XConditionManager.CheckCondition(NewGuidePass) then
        CS.XHeroSdkAgent.ResetAFDeepLinkValue()
    end
    return false
end

function this.TryInvokeDeeplink()
    if CS.XRemoteConfig.DeeplinkEnabled == false then
        return
    end

    if not XLoginManager.IsLogin() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    if not CS.XFight.IsOutFight then
        return
    end

    if XHomeDormManager.InDormScene() then
        return
    end

    if XDataCenter.FunctionEventManager.IsPlaying() then
        return
    end

    local deepMgr = CS.XDeeplinkManager;
    if deepMgr.HasDeeplink == false then
        return
    end
    XFunctionManager.SkipInterface(deepMgr.DeeplinkValue)
    deepMgr.Reset()
end