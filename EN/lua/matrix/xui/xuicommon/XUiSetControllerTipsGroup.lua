-- 通用关卡词缀列表项控件
local XUiSetControllerTipsGroup = XClass(XUiNode, "XUiSetControllerTipsGroup")
local XUiSetControllerTipsGroupSet = require("XUi/XUiCommon/XUiSetControllerTipsGroupSet")

function XUiSetControllerTipsGroup:OnStart()
    self._UiButtonInfos = {}
    self._SwitchMap = {
        [1] = {
            [330] = 331,
            [331] = 330,
        },
        [2] = {
            [331] = 332,
            [332] = 331,
        },
    }
    self._PsSwitchMap = {
        [330] = 331,
        [331] = 332,
    }
end

function XUiSetControllerTipsGroup:IsSwitchKeyCode(code)
    local jtype = CS.System.Convert.ToInt32(CS.XInputManager.CurJoystickType)
    if jtype == 2 then
        code = self._PsSwitchMap[code] or code
    end
    
    local isDefault = CS.XInputManager.IsDefaultMainButton(CS.XInputManager.CurJoystickType)
    if not isDefault then
        return code
    else
        local switchCodeMap = self._SwitchMap[jtype]
        if switchCodeMap[code] then
            return switchCodeMap[code] or code
        end
        return code
    end
end

function XUiSetControllerTipsGroup:SetUIName(uiName)
    if not CS.XUiPc.XUiButtonContainerHelper.IsShowJoystickKeyCode() or string.IsNilOrEmpty(uiName) then
        -- 播放关闭动画
        self:Close()
        return
    end
    local tipsMap = XSetConfigs.GetControllerTipsMapCfg()
    local infos
    local config = tipsMap[uiName] or tipsMap[XUiManager.DefaultControlTipsName]
    -- XLog.Warning(config)
    if config.IsShow then
        -- local icons = CS.XInputManager.InputMapper:GetKeyCodeIcon(CS.XInputManager.CurJoystickType, 48)
        infos = {}
        for infoIndex, nameText in ipairs(config.KeyText) do
            local sCode = self:IsSwitchKeyCode(config.KeyCode[infoIndex])
            infos[infoIndex] = {
                Name = nameText,
                Icon = CS.XInputManager.InputMapper:GetKeyCodeIconByKeyCode(sCode),
            }
        end
    end
    -- XLog.Warning(infos)

    local hasInfo = infos and #infos > 0
    if hasInfo then
        -- 播放开启动画
        self:Open()
        XTool.UpdateDynamicItem(self._UiButtonInfos, infos, self.TipsGroup, XUiSetControllerTipsGroupSet, self)
    else
        XTool.UpdateDynamicItem(self._UiButtonInfos, nil, self.TipsGroup, XUiSetControllerTipsGroupSet, self)
        -- 播放关闭动画
        self:Close()
    end
end

return XUiSetControllerTipsGroup
