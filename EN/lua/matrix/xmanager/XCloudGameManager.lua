XCloudGameManagerCreator = function()

    ---@class XCloudGameManager
    local XCloudGameManager = {}

    -- 实现一些云游戏特有的业务接口

    -- 虚拟键盘 打开虚拟键盘，msg为输入框文本
    function XCloudGameManager.ActiveVirtualKeyBoard(msg)
        CS.XWLinkAgent.ActiveVirtualKeyBoard(msg)
    end

    -- 虚拟键盘 设置文本输入回调
    function XCloudGameManager.SetKeyBoardTextChangeAction(action)
        CS.XWLinkAgent.SetKeyBoardTextChangeAction(action)
    end

    -- 虚拟键盘 设置虚拟键盘关闭回调
    function XCloudGameManager.SetKeyBoardCloseAction(action)
        CS.XWLinkAgent.SetKeyBoardCloseAction(action)
    end

    -- 粘贴剪切板内容到微端
    function XCloudGameManager.ClipBoardCopy(msg)
        CS.XWLinkAgent.ClipBoardCopy(msg)
    end

    -- 通知云游戏可以显示画面
    function XCloudGameManager.HotPatchEnterGame()
        CS.XWLinkAgent.HotPatchEnterGame()
    end

    -- 退出云游戏，用于代替登出
    function XCloudGameManager.Exit(msg)
        CS.XWLinkAgent.Exit(msg)
    end

    -- 云游戏下，需要监听textInputField，弹出虚拟键盘
    function XCloudGameManager.StartListTextInput()
        if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame then
            local uiRoot = CS.XUiManager.Instance:GetUiRoot()
            XUiHelper.TryAddComponent(uiRoot.gameObject, typeof(CS.XUiPc.XCloudGameTextInputListener))
        end
    end

    -- 云游戏默认拖拽移动相机
    function XCloudGameManager.OpenControlCameraByDragLocalCache()
        if XDataCenter.UiPcManager.GetUiPcMode() ~= XDataCenter.UiPcManager.XUiPcMode.CloudGame then
            return
        end
        CS.XInputKeyboard.ControlCameraByDragLocalCache = true
    end

    XCloudGameManager.StartListTextInput()
    return XCloudGameManager
end
