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

    -- 云游戏，添加陀螺仪数据监听回调 参数默认*100转整型，使用时需要自己/100
    -- 注意：Remove 依赖委托相等性，Add/Remove 必须传入同一个函数对象（先用 handler 创建好并缓存复用）
    -- 监听者从无到有时自动开启云端数据推送，清空后自动关闭，无需业务手动开关
    -- public class DeviceMotionAttitude
    -- {
    --     public int pitch;// 俯仰角：设备前后倾斜的角度，范围 -π/2 到 π/2。向前倾斜为正，向后倾斜为负
    --     public int roll;// 横滚角：设备左右倾斜的角度，范围 -π 到 π。向右倾斜为正，向左倾斜为负
    --     public int yaw;// 偏航角：设备水平旋转的角度，范围 -π 到 π。逆时针旋转为正，顺时针旋转为负
    -- }
    function XCloudGameManager.AddMotionListener(action)
        -- Action<DeviceMotionAttitude>
        CS.XWLinkAgent.AddMotionListener(action)
    end

    -- 云游戏，移除陀螺仪数据监听回调，必须传入与 Add 时同一个函数对象
    function XCloudGameManager.RemoveMotionListener(action)
        CS.XWLinkAgent.RemoveMotionListener(action)
    end

    XCloudGameManager.StartListTextInput()
    return XCloudGameManager
end
