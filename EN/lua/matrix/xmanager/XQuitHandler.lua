local ExitingGame = false

XQuitHandler = XQuitHandler or {}

local function IsOnBtnClick()
    if XLuaUiManager.IsUiShow("UiLoading") or
            XLuaUiManager.IsUiShow("UiAssignInfo") or -- loading 界面 边界公约
            XDataCenter.GuideManager.CheckIsInGuide() or
            XLuaUiManager.IsUiShow("UiBlackScreen") or 
            XLuaUiManager.IsUiShow("UiRogueSimLoading") then
        return false
    end
    return true
end

XQuitHandler.OnEscBtnClick = function()
    if XLuaUiManager.IsUiShow("UiGuide") then
        -- 新手引导当做系统界面处理
        -- XQuitHandler.ExitGame()
        return
    end
    -- 剧情
    if XLuaUiManager.IsUiShow("UiMovie") then
        return
    end
    -- cg
    if XLuaUiManager.IsUiShow("UiVideoPlayer") then
        return
    end
    if not IsOnBtnClick() then
        return
    end
    if XLuaUiManager.IsUiShow("UiGoldenMinerBattle") then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_EXIT_CLICK)
        return
    end
    -- 它自己
    if XLuaUiManager.IsUiShow("UiDialogExitGame") then
        return
    end

    if XDataCenter.UiPcManager.IsEditingKey() then
        return
    end

    if CS.XUiManagerExtension.Masked then
        return
    end

    if not XLuaUiManager.IsUiShow("UiMain") and not XLuaUiManager.IsUiShow("UiLogin") then
        return
    end
    if not CS.XUiManagerExtension.IsUIEnabled("UiMain") and not CS.XUiManagerExtension.IsUIEnabled("UiLogin") then
        return
    end
    --退出游戏
    XQuitHandler.ExitGame()
end

XQuitHandler.ExitGame = function()

    if ExitingGame then
        return
    end
    ExitingGame = true

    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("GameExitMsg")
    local confirmCb = function()
        if XDataCenter.UiPcManager.IsCloudGame() then
            -- 云游戏退出直接弹出提示，关闭游戏
            CS.XWLinkAgent.Exit(CS.XTextManager.GetText("GameExitMsg"))
            return
        end
        CS.XDriver.Exit()
    end
    -- 会关闭公告, 尝试不发此事件
    -- CsXGameEventManager.Instance:Notify(XEventId.EVENT_UIDIALOG_VIEW_ENABLE)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiDialogExitGame", title, content, XUiManager.DialogType.Normal, nil, confirmCb)
end

XQuitHandler.SetExitingGame = function(value)
    ExitingGame = value
end

XQuitHandler.GetExitingGame = function()
    return ExitingGame
end