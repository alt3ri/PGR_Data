-- XLuaUiRunMainUtil.lua
-- 用于管理返回主界面的相关工具函数
local XUiRunMainUtil = {}
local needClearUiName = {"UiFubenMainLineChapter", "UiFubenMainLineChapterFw", "UiFubenMainLineChapterDP", "UiPrequel",
                         "UiTheatre5PVEClueBoard", "XUiSoloReformChapterDetail"}
-- 清理需要清理的UI数据
function XUiRunMainUtil.ClearNeedClearUi()
    for _, uiName in pairs(needClearUiName) do
        XLuaUiManager.RemoveUiData(uiName)
    end
end

-- 创建RunMain函数
function XUiRunMainUtil.CreateRunMainFunction()
    if XMVCA.XBigWorldGamePlay:IsInGame() then
        XMVCA.XBigWorldUI:RunMain()
    else
        CsXUiManager.Instance:RunMain()
    end
end

-- 处理房间数据存在的情况
function XUiRunMainUtil.HandleRoomExists(notDialogTip, runMainFunc)
    if notDialogTip then
        XDataCenter.RoomManager.Quit(runMainFunc)
        return
    end

    -- 如果在房间中，需要先弹确认框
    local title = CsXTextManagerGetText("TipTitle")
    local cancelMatchMsg
    local stageId = XDataCenter.RoomManager.RoomData.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceQuitRoom")

    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.RoomManager.Quit(runMainFunc)
    end)
end

-- 处理正在匹配的情况
function XUiRunMainUtil.HandleMatching(notDialogTip, runMainFunc)
    if notDialogTip then
        XDataCenter.RoomManager.CancelMatch(runMainFunc)
        return
    end

    local title = CsXTextManagerGetText("TipTitle")
    local cancelMatchMsg = CsXTextManagerGetText("OnlineInstanceCancelMatch")
    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.RoomManager.CancelMatch(runMainFunc)
    end)
end

-- 处理Dlc房间管理器在房间中的情况
function XUiRunMainUtil.HandleDlcRoomManagerInRoom(runMainFunc)
    XDataCenter.DlcRoomManager.DialogTipQuitRoom(runMainFunc)
end

-- 处理XDlcRoom在房间中的情况
function XUiRunMainUtil.HandleXDlcRoomInRoom(notDialogTip, runMainFunc)
    if notDialogTip then
        XMVCA.XDlcRoom:Quit(runMainFunc)
    else
        XMVCA.XDlcRoom:DialogTipQuit(runMainFunc)
    end
end

-- 处理XDlcRoom正在匹配的情况
function XUiRunMainUtil.HandleXDlcRoomMatching(notDialogTip, runMainFunc)
    if notDialogTip then
        XMVCA.XDlcRoom:CancelMatch(runMainFunc)
    else
        XMVCA.XDlcRoom:DialogTipCancelMatch(runMainFunc)
    end
end

-- 处理正常情况下的返回主界面
function XUiRunMainUtil.HandleNormalRunMain(runMainFunc)
    if XLoginManager.IsFirstOpenMainUi() then
        CS.XCustomUi.Instance:GetData()
    end
    runMainFunc()
end

-- 处理返回主界面的完整逻辑
function XUiRunMainUtil.HandleRunMain(notDialogTip)
    -- 清理需要清理的UI
    XUiRunMainUtil.ClearNeedClearUi()
    -- 创建RunMain函数
    local runMainFunc = XUiRunMainUtil.CreateRunMainFunction
    -- 处理各种情况
    if XDataCenter.RoomManager.RoomData then
        XUiRunMainUtil.HandleRoomExists(notDialogTip, runMainFunc)
    elseif XDataCenter.RoomManager.Matching then
        XUiRunMainUtil.HandleMatching(notDialogTip, runMainFunc)
    elseif XDataCenter.DlcRoomManager.IsInRoom() then
        XUiRunMainUtil.HandleDlcRoomManagerInRoom(runMainFunc)
    elseif XMVCA.XDlcRoom:IsInRoom() then
        XUiRunMainUtil.HandleXDlcRoomInRoom(notDialogTip, runMainFunc)
    elseif XMVCA.XDlcRoom:IsMatching() then
        XUiRunMainUtil.HandleXDlcRoomMatching(notDialogTip, runMainFunc)
    else
        XUiRunMainUtil.HandleNormalRunMain(runMainFunc)
    end
end

return XUiRunMainUtil
