local ToInt32 = CS.System.Convert.ToInt32
local XInputManager = CS.XInputManager
local XJoystickCursorHelper = CS.XPc.XJoystickCursorHelper
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItem")
local XUiOneKeyCustomKeyItem = require("XUi/XUiSet/ChildItem/XUiOneKeyCustomKeyItem")
local XUiNotCustomKeyItemHandle = require("XUi/XUiSet/ChildItem/XUiNotCustomKeyItemHandle")
local XUiPanelFightSet = require("XUi/XUiSet/XUiPanelFightSet")
---@class XUiPanelFightSetPc : XUiPanelFightSet
---@field Parent XUiSet
local XUiPanelFightSetPc = XClass(XUiPanelFightSet, "XUiPanelFightSetPc")

function XUiPanelFightSetPc:OnStart(secondIndex)
    self.SecondIndex = secondIndex
    XUiPanelFightSetPc.Super.OnStart(self)
    local isShowKeyboard = XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc
    self.PanelJoystick.gameObject:SetActiveEx(false)    --移到布局设置里了
    self.PanelSwitch.gameObject:SetActiveEx(not isShowKeyboard)
    if self.KeyboardText then
        self.KeyboardText.gameObject:SetActiveEx(isShowKeyboard)
    end

    local btnTouchName = isShowKeyboard and "UiSetPCBtnTabTouchName" or "UiSetBtnTabTouchName"
    self.BtnTabTouch:SetName(XUiHelper.GetText(btnTouchName))

    if not isShowKeyboard then
        local gameControllerPos = self.BtnTabGameController.transform.localPosition
        local keyboardPos = self.BtnTabKeyboard.transform.localPosition
        self.BtnTabGameController.transform.localPosition = keyboardPos
        self.BtnTabKeyboard.transform.localPosition = gameControllerPos

        --if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame then
        --    self.BtnTabKeyboard.gameObject:SetActiveEx(false)
        --end
    end

    self._IsShowFPS = XInputManager.GetFPSActive()
    self._IsShowJoystick = XInputManager.GetJoystickActive()
    self._IsShowSystemButton = false
    self._IsNoUiMode = CS.XFightUiManager.NoUiMode
    self._IsDirtyPc = false
    self:InitPc()
    
    self:SetVisiblePcToggle(isShowKeyboard)
end

function XUiPanelFightSetPc:InitDrdSort()
    if self.IsInitDrdSort then
        return
    end

    self.KeyboardDrdSort:ClearOptions()
    self.ControllerDrdSort:ClearOptions()
    local firstIndex = 1
    
    -- V4.2 relink默认选中该玩法的操作类型
    local worldType
    local fightBeginData = XMVCA.XDlcRoom:GetFightBeginData()
    if CS.XFightInterface.IsDLC and not fightBeginData:IsWorldClear() then
        worldType = XMVCA.XDlcWorld:GetWorldTypeById(fightBeginData:GetWorldData():GetId())
    end

    local CsDropdown = CS.UnityEngine.UI.Dropdown
    for index, inputMapId in ipairs(self.InputMapIdList) do
        local op = CsDropdown.OptionData()
        op.text = XSetConfigs.GetInputMapIdStr(inputMapId)
        self.KeyboardDrdSort.options:Add(op)
        self.ControllerDrdSort.options:Add(op)

        if worldType == XEnumConst.DlcWorld.WorldType.Relink and inputMapId == ToInt32(CS.XInputMapId.Relink) then
            firstIndex = index
        end
    end
    
    self.KeyboardDrdSelectIndex = firstIndex
    self.KeyboardDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index)
            return index + 1
        end
        self:OnKeyboardDrdSortClick(CSArrayIndexToLuaTableIndex(self.KeyboardDrdSort.value))
    end)
    self.KeyboardDrdSort.value = firstIndex - 1

    self.ControllerDrdSelectIndex = firstIndex
    self.ControllerDrdSort.onValueChanged:AddListener(function()
        local CSArrayIndexToLuaTableIndex = function(index)
            return index + 1
        end
        self:OnControllerDrdSortClick(CSArrayIndexToLuaTableIndex(self.ControllerDrdSort.value))
    end)
    self.ControllerDrdSort.value = firstIndex - 1
    
    self.IsInitDrdSort = true
end

function XUiPanelFightSetPc:OnControllerDrdSortClick(index)
    if self.ControllerDrdSelectIndex == index then
        return
    end
    self.ControllerDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:OnKeyboardDrdSortClick(index)
    if self.KeyboardDrdSelectIndex == index then
        return
    end
    self.KeyboardDrdSelectIndex = index
    self:UpdatePanel()
end

function XUiPanelFightSetPc:GetInputMapId()
    if self.CurPageType == self.PageType.GameController then
        return self.InputMapIdList[self.ControllerDrdSelectIndex]
    elseif self.CurPageType == self.PageType.Keyboard then
        return self.InputMapIdList[self.KeyboardDrdSelectIndex]
    end
end

function XUiPanelFightSetPc:GetInputMapIdEnum()
    return CS.XInputMapId.__CastFrom(self:GetInputMapId())
end

function XUiPanelFightSetPc:GetDefaultIndex()
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        return self.PageType.Keyboard
    end
    return self.PageType.Touch
end

function XUiPanelFightSetPc:RefreshKeyboardPanel()
    local isShowKeyboard = XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc
    if isShowKeyboard then
        self.PanelKeyboardSet.gameObject:SetActiveEx(true)
    else
        self.Super.RefreshKeyboardPanel(self)
    end
end

function XUiPanelFightSetPc:UpdatePanel()
    if self.CurPageType == self.PageType.Touch then
        self.Parent.BtnSave.gameObject:SetActiveEx(true)
        self.Parent.BtnDefault.gameObject:SetActiveEx(false)
    elseif self.CurPageType == self.PageType.GameController then
        local enableInputJoystick = XInputManager.EnableInputJoystick
        self.Parent.BtnDefault.gameObject:SetActiveEx(enableInputJoystick)
        self.Parent.BtnSave.gameObject:SetActiveEx(enableInputJoystick)
        self.PanelGameControlOperationType.gameObject:SetActiveEx(enableInputJoystick)
        self:InitControllerPanel(false)
    elseif self.CurPageType == self.PageType.Keyboard then
        local enableInputKeyboard = XInputManager.EnableInputKeyboard
        self.Parent.BtnDefault.gameObject:SetActiveEx(enableInputKeyboard)
        self.Parent.BtnSave.gameObject:SetActiveEx(enableInputKeyboard)
        self.PanelKeyboardOperationType.gameObject:SetActiveEx(enableInputKeyboard)
        self:InitKeyboardPanel()
    end
    self:ShowSubPanel(self.CurPageType)
end

function XUiPanelFightSetPc:ResetToDefault()
    if self.CurPageType == self.PageType.Touch then
        self.DynamicJoystick = XSetConfigs.DefaultDynamicJoystick
        self.JoystickGroup:SelectIndex(self.DynamicJoystick + 1)
        
        self._IsShowJoystick = XInputManager.DEFAULT_JOYSTICK_ACTIVE == 1
        self._IsShowSystemButton = false
        self._IsNoUiMode = CS.XFightUiManager.NoUiMode
        self.TogSystemButton.isOn = self._IsShowSystemButton

    elseif self.CurPageType == self.PageType.GameController then
        self:ResetToDefaultTips(function()
            local curKeySetType = self:GetCurKeySetType()
            XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(), curKeySetType)
            XInputManager.DefaultCameraMoveSensitivitySetting(curKeySetType, CS.CameraViewType.ThirdPerson)
            XInputManager.DefaultCameraMoveSensitivitySetting(curKeySetType, CS.CameraViewType.FirstPerson)
            self.SliderCameraMoveSensitivityPc.value = self:GetCameraMoveSensitivity()
            XJoystickCursorHelper.SetDefaultSensitivity()
            self.CursorMoveSensitivity.value = self:GetCursorMoveSensitivity()
            if self.PanelBtnGroup then
                local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
                local defaultIndex = isDefault and 1 or 2
                self.PanelBtnGroup:SelectIndex(defaultIndex)
            end
            self:InitControllerPanel(true)
            if self.PanelBtnGroup then
                self:_UpdatePanelBtnGroup()
            end
        end)
    elseif self.CurPageType == self.PageType.Keyboard then
        self:ResetToDefaultTips(function()
            XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(), CS.InputDeviceType.Keyboard)
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.InputDeviceType.Keyboard, CS.CameraViewType.ThirdPerson)
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.InputDeviceType.Keyboard, CS.CameraViewType.FirstPerson)
            self:InitKeyboardPanel(true)
        end)
    end
end

function XUiPanelFightSetPc:ResetToDefaultTips(callFunc)
    XUiManager.DialogTip(nil, XUiHelper.GetText("DefaultKeyCodesTip"), nil, nil, callFunc)
end

function XUiPanelFightSetPc:IsSameKeySet(keySetTypes)
    if XTool.IsTableEmpty(keySetTypes) then
        return true
    end

    local curKeySetType = ToInt32(self:GetCurKeySetType())
    for _, keySetType in ipairs(keySetTypes) do
        if curKeySetType == keySetType then
            return true
        end
    end
    return false
end

function XUiPanelFightSetPc:InitControllerPanel(resetTextOnly)
    self:InitDrdSort()

    local curInputMapId = self:GetInputMapId()
    if not curInputMapId then
        return
    end

    self.CtrlKeyItemList = self.CtrlKeyItemList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, v in ipairs(list) do
        local grid = self.CtrlKeyItemList[id]
        if curInputMapId == v.InputMapId and self:IsSameKeySet(v.KeySetTypes) then
            if v.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = defaultKeyMapTable.KeyCodeType
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiNotCustomKeyItemHandle.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItemHandle, self.ControllerSetContent), self.Parent)
                else
                    grid = grid or XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.ControllerSetContent), self.Parent)
                end

                grid:SetKeySetType(self:GetCurKeySetType())
                grid:Refresh(v, handler(self, self.EditKey), resetTextOnly, curInputMapId, defaultKeyMapTable.OperationType)
            elseif v.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.ControllerSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
                txtTitle.text = v.Title
            elseif v.Type == XSetConfigs.ControllerSetItemType.Slider then
                if not grid then
                    if v.InputMapId == 1 then
                        self.GridSlider:SetParent(self.ControllerSetContent, false)
                        XUiHelper.RegisterSliderChangeEvent(self, self.SliderCameraMoveSensitivity, function(_, value)
                            if self:GetCameraMoveSensitivity() == value then
                                return
                            end
                            self:SetCameraMoveSensitivity(value)
                        end)
                        grid = grid or self.GridSlider
                    elseif v.InputMapId == 4 then
                        self.VirtualCursorPC:SetParent(self.ControllerSetContent, false)
                        XUiHelper.RegisterSliderChangeEvent(self, self.CursorMoveSensitivity, function(_, value)
                            self:SetCursorMoveSensitivity(value)
                        end)
                        grid = grid or self.VirtualCursorPC
                    end
                end
                self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
                grid = grid or self.GridSlider
            elseif v.Type == XSetConfigs.ControllerSetItemType.DoubleToggle then
                local isNotClone = not grid
                if isNotClone then
                    grid = XUiHelper.Instantiate(self.XboxBtnGroup, self.ControllerSetContent)
                end
                local gridTypeTr = grid:Find("GroupType")
                self.PanelBtnGroup = gridTypeTr:GetComponent("XUiButtonGroup")

                local button1 = gridTypeTr:Find("PanelBtn1/TogType1"):GetComponent("XUiButton")
                local button2 = gridTypeTr:Find("PanelBtn2/TogType2"):GetComponent("XUiButton")
                self.PanelBtnGroup:InitBtns({button1, button2}, handler(self, self.OnToggleSelect))

                local lastJoystickType = self:GetCurKeySetType()
                self:_UpdatePanelBtnGroup(lastJoystickType)
                local isDefaultUi = self._SelectIndex == 1

                local image1a = gridTypeTr:Find("PanelBtn1/TogType1/ImgA"):GetComponent("Image")
                local image1b = gridTypeTr:Find("PanelBtn1/TogType1/ImgB"):GetComponent("Image")
                local image2a = gridTypeTr:Find("PanelBtn2/TogType2/ImgA"):GetComponent("Image")
                local image2b = gridTypeTr:Find("PanelBtn2/TogType2/ImgB"):GetComponent("Image")
                
                local defaultKeyMapTable1 = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[isDefaultUi and 1 or 2])
                local defaultKeyMapTable2 = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[isDefaultUi and 2 or 1])
                local operationTypeInt1 = CS.XInputManager.XOperationType.__CastFrom(defaultKeyMapTable1.OperationType)
                local operationTypeInt2 = CS.XInputManager.XOperationType.__CastFrom(defaultKeyMapTable2.OperationType)
                local curInputMapIdInt1 = CS.XInputMapId.__CastFrom(defaultKeyMapTable1.InputMapId)
                local curInputMapIdInt2 = CS.XInputMapId.__CastFrom(defaultKeyMapTable2.InputMapId)
                local icons1 = XInputManager.GetKeyCodeIcon(lastJoystickType, curInputMapIdInt1, defaultKeyMapTable1.OperationKey, CS.PressKeyIndex.One, operationTypeInt1)
                if icons1 and icons1.Count ~= 0 then
                    image1a:SetSprite(icons1[0])
                    image2b:SetSprite(icons1[0])
                end
                local icons2 = XInputManager.GetKeyCodeIcon(lastJoystickType, curInputMapIdInt2, defaultKeyMapTable2.OperationKey, CS.PressKeyIndex.One, operationTypeInt2)
                if icons2 and icons2.Count ~= 0 then
                    image1b:SetSprite(icons2[0])
                    image2a:SetSprite(icons2[0])
                end
            end

            self.SliderCameraMoveSensitivity.value = self:GetCameraMoveSensitivity()
            self.CursorMoveSensitivity.value = self:GetCursorMoveSensitivity()

            self.CtrlKeyItemList[id] = grid
            
            :: CONTINUE ::
        end
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
end

function XUiPanelFightSetPc:_UpdatePanelBtnGroup(lastJoystickType)
    local defaultIndex
    if lastJoystickType then
        if lastJoystickType ~= self._lastJoystickType then
            self._lastJoystickType = lastJoystickType
            local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
            defaultIndex = isDefault and 1 or 2
        else
            defaultIndex = self._SelectIndex
        end
    else
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType or self:GetCurKeySetType())
        defaultIndex = isDefault and 1 or 2
    end
    self._isSwichGroupInit = true
    self.PanelBtnGroup:SelectIndex(defaultIndex)
    self._isSwichGroupInit = false
end

function XUiPanelFightSetPc:InitKeyboardPanel(resetTextOnly)
    self:InitDrdSort()
    local curInputMapId = self:GetInputMapId()

    if not curInputMapId then
        return
    end

    self._KeyboardGridList = self._KeyboardGridList or {}
    local list = XSetConfigs.GetControllerMapCfg()

    for id, item in ipairs(list) do
        local grid = self._KeyboardGridList[id]
        if curInputMapId == item.InputMapId and self:IsSameKeySet(item.KeySetTypes) then
            if item.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(item.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = CS.XInputManager.GetKeyCodeTypeByInt(defaultKeyMapTable.OperationKey, curInputMapId, defaultKeyMapTable.OperationType)
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiNotCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItem, self.KeyboardSetContent), self.Parent)
                elseif keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.SingleKey or
                        keyCodeType == XSetConfigs.KeyCodeType.Default
                then
                    grid = grid or XUiOneKeyCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.OneKeyCustomKeyItem, self.KeyboardSetContent), self.Parent)
                    -- elseif keyCodeType == XSetConfigs.KeyCodeType.Default then
                    --     grid = XUiBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.KeyboardSetContent), self.Parent)
                end

                grid:SetKeySetType(CS.InputDeviceType.Keyboard)
                grid:Refresh(item, handler(self, self.EditKey), resetTextOnly, curInputMapId, defaultKeyMapTable.OperationType)
            elseif item.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.KeyboardSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent("Text")
                txtTitle.text = item.Title
            elseif item.Type == XSetConfigs.ControllerSetItemType.Slider then
                local isNotClone = not grid
                if not grid then
                    grid = XUiHelper.Instantiate(self.GridSliderPC, self.KeyboardSetContent)
                end
                local slider = XUiHelper.TryGetComponent(grid.transform, "SliderCameraMoveSensitivityPc", typeof(CS.UnityEngine.UI.Slider))
                if isNotClone then
                    XUiHelper.RegisterSliderChangeEvent(self, slider, function(_, value)
                        if value == self:GetCameraMoveSensitivity() then
                            return
                        end
                        self:SetCameraMoveSensitivity(value)
                    end)
                end
                slider.value = self:GetCameraMoveSensitivity()
            end

            self._KeyboardGridList[id] = grid
        end
        
        :: CONTINUE ::
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiPanelFightSetPc:SetGridActive(grid, enable)
    if not grid then
        return
    end

    if grid.GameObject then
        if enable then
            grid:Open()
        else
            grid:Close()
        end
    elseif grid.gameObject then
        grid.gameObject:SetActiveEx(enable)
    end
end

function XUiPanelFightSetPc:SetEnableInputKeyboard(value)
    XInputManager.SetEnableInputKeyboard(value)
end

function XUiPanelFightSetPc:RefreshGridList(curKeySetType, blockTip)
    if not curKeySetType then
        return
    end

    local gridList
    if curKeySetType == CS.InputDeviceType.Xbox or curKeySetType == CS.InputDeviceType.Ps then
        gridList = self.CtrlKeyItemList
    elseif curKeySetType == CS.InputDeviceType.Keyboard then
        gridList = self._KeyboardGridList
    end
    if gridList then
        for _, v in pairs(gridList) do
            if v.SetKeySetType then
                v:SetKeySetType(self:GetCurKeySetType())
            end
            if v.Refresh then
                v:Refresh(nil, nil, true)
            end
        end
    end

    if blockTip then
        return
    end

    XUiManager.TipSuccess(XUiHelper.GetText("SetJoyStickSuccess"))
end

function XUiPanelFightSetPc:EditKey(keyCode, targetItem, pressKeyIndex)
    if not pressKeyIndex then
        pressKeyIndex = XSetConfigs.PressKeyIndex.One
    end
    
    local operationType = targetItem:GetCurOperationType()
    local inputMapId = targetItem:GetCurInputMapId()

    XInputManager.EndEdit()
    self.PanelJoypadKeyIcon.gameObject:SetActiveEx(false)
    local cb = function(isConflict)
        self.CurSelectBtn = nil
        self.CurSelectKey = nil
        targetItem:Refresh()
        self:ShowSetKeyTip(false)
        if isConflict then
            local curKeySetType = self:GetCurKeySetType()
            local keyCurrent = CS.XInputManager.GetConflictKey1()
            local keyConflict = CS.XInputManager.GetConflictKey2()
            local textKeyCurrent = XSetConfigs.GetControllerKeyText(keyCurrent)
            local textKeyConflict = XSetConfigs.GetControllerKeyText(keyConflict)
            if textKeyCurrent and textKeyConflict then
                XUiManager.DialogTip(
                        nil,
                        XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("SetKeyConflict", textKeyConflict, textKeyCurrent)),
                        XUiManager.DialogType.Normal,
                        function()
                            CS.XInputManager.InputMapper:ClearConflictKey()
                        end,
                        function()
                            CS.XInputManager.InputMapper:SwapConflictKey(curKeySetType, pressKeyIndex, inputMapId)
                            self:RefreshGridList(curKeySetType)
                        end
                )
            end
        end
    end

    self.TxtInput.text = CS.XTextManager.GetText("SetInputStart")
    self.TxtFunction.text = targetItem.Data.Title

    XInputManager.StartEditKey(self:GetCurKeySetType(), keyCode, pressKeyIndex, cb, inputMapId, operationType, targetItem:GetDataId())
    self:ShowSetKeyTip(true)
    self.CurSelectBtn = targetItem
    self.CurSelectKey = keyCode
end

function XUiPanelFightSetPc:CheckDataIsChange()
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        if defaultIndex ~= self._SelectIndex then
            return true
        end
    end

    local changed = self.Super.CheckDataIsChange(self)
    changed = XJoystickCursorHelper.IsCursorSensitivityChanged() or changed
    changed = self._IsDirtyPc or changed
    return changed
end

function XUiPanelFightSetPc:SaveChange()
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        if defaultIndex ~= self._SelectIndex and CS.XInputManager.SetDefaultMainButton(self._lastJoystickType, not isDefault) then
            self:RefreshGridList(self:GetCurKeySetType())
        end
    end
    self.Super.SaveChange(self);
    XJoystickCursorHelper.SaveSensitivityChange();

    self._IsDirtyPc = false
    CS.XFightUiManager.NoUiMode = self._IsNoUiMode
    self:LoadSchemeName()
end

function XUiPanelFightSetPc:CancelChange()
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        self.PanelBtnGroup:SelectIndex(defaultIndex)
    end

    self.Super.CancelChange(self);
    XJoystickCursorHelper.RevertSensitivity();
end

function XUiPanelFightSetPc:SetCursorMoveSensitivity(value)
    XJoystickCursorHelper.PreSetCursorMoveSensitivity(value)
end

function XUiPanelFightSetPc:GetCursorMoveSensitivity()
    return XJoystickCursorHelper.CursorMoveSensitivity
end

function XUiPanelFightSetPc:InitPc()
    self.TogSystemButton.isOn = self._IsShowSystemButton
    self.TogSystemButton.onValueChanged:AddListener(handler(self, self.OnTogSystemButtonChanged))
end

function XUiPanelFightSetPc:OnTogFPSValueChanged(value)
    if self._IsShowFPS ~= value then
        self._IsShowFPS = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogJoystickValueChanged(value)
    if self._IsShowJoystick ~= value then
        self._IsShowJoystick = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogSystemButtonChanged(value)
    if self._IsShowSystemButton ~= value then
        self._IsShowSystemButton = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnTogClearUIButtonChanged(value)
    if self._IsNoUiMode ~= value then
        self._IsNoUiMode = value
        self._IsDirtyPc = true
    end
end

function XUiPanelFightSetPc:OnToggleSelect(index)
    if index == self._SelectIndex then return end
    self._SelectIndex = index
    if self._isSwichGroupInit then return end
    -- self._IsDirtyPc = true

    -- local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
    -- if CS.XInputManager.SetDefaultMainButton(self._lastJoystickType, not isDefault) then
    --     local curKeySetType = self:GetCurKeySetType()
    --     self:RefreshGridList(curKeySetType)
    -- end
end

function XUiPanelFightSetPc:IsPageTypeTouch()
    return self.CurPageType == self.PageType.Touch
end

function XUiPanelFightSetPc:HidePanel()
    XUiPanelFightSet.HidePanel(self)
    if self._KeyboardGridList then
        for _, grid in pairs(self._KeyboardGridList) do
            if grid and grid.Close then
                grid:Close()
            end
        end
    end
end

return XUiPanelFightSetPc