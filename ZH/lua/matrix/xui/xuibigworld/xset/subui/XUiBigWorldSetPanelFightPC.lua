local XUiBWBtnKeyItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWBtnKeyItem")
local XUiBWNotCustomKeyItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWNotCustomKeyItem")
local XUiBWNotCustomKeyItemHandle = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWNotCustomKeyItemHandle")
local XUiBWOneKeyCustomKeyItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWOneKeyCustomKeyItem")
local XUiBWCameraSensitivitySliderItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWCameraSensitivitySliderItem")
local XUiBWCursorSliderItem = require("XUi/XUiBigWorld/XSet/SubUi/XSetNode/XUiBWCursorSliderItem")

local XJoystickCursorHelper = CS.XPc.XJoystickCursorHelper
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XInputManager = CS.XInputManager
local ToInt32 = CS.System.Convert.ToInt32

---@class XUiBigWorldSetPanelFightPC : XBigWorldUI
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelFightPC = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSetPanelFightPC")
local XUiRespondBarrierType = CS.XUiComponent.XUiButton.XUiRespondBarrierType

function XUiBigWorldSetPanelFightPC:OnStart(parent)
    self:_RegisterButtonClicks()
    self.Parent = parent

    local isPc = XDataCenter.UiPcManager.IsPc()
    self.PanelSwitch.gameObject:SetActiveEx(not isPc)
    if self.KeyboardText then
        self.KeyboardText.gameObject:SetActiveEx(isPc)
    end

    self._Setting = self._Control:GetSettingBySetType(XEnumConst.BWSetting.SetType.Input)
    self._Setting:SetUiCallback(
        handler(self, self.SaveChange), 
        handler(self, self.ResetToDefault),
        handler(self, self.CheckDataIsChange),
        handler(self, self.CancelChange))
    self.ShowInputMaps = self._Setting:GetControllerMapIds()

    self.PanelKeyboardOperationType.gameObject:SetActive(false)
    self.PanelGameControlOperationType.gameObject:SetActive(false)

    XEventManager.AddEventListener(XEventId.EVENT_JOYSTICK_TYPE_CHANGED, self.OnJoystickTypeChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED, self.OnJoystickActiveChanged, self)
    
    self:ShowSetKeyTip(false)
    -- self:GetDataThenLoadSchemeName()

    self.PageType = {
        GameController = 1,         --外接手柄键位设置
        Keyboard = 2,               -- 键盘键位设置
    }
    self._CurKeySetType = false
    self.CurSelectBtn = nil
    self.CurSelectKey = nil

    local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end

    self.CurPageType = self:GetDefaultIndex() -- 在XUiPanelFightSetPc的OnShow设置
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
end

function XUiBigWorldSetPanelFightPC:OnEnable(...)
    self._Control:RefreshSpecialScreenOff(self.SafeAreaContentPane)
    self.BtnTabGroup:SelectIndex(self.CurPageType)
    self:PlayAnimation("QieHuanEnable")
end

function XUiBigWorldSetPanelFightPC:OnDisable(...)
    self:RefreshKeyboardItem(false)
    self:RefreshJoystickItem(false)
end

function XUiBigWorldSetPanelFightPC:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_JOYSTICK_TYPE_CHANGED, self.OnJoystickTypeChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_JOYSTICK_ACTIVE_CHANGED, self.OnJoystickActiveChanged, self)
end

function XUiBigWorldSetPanelFightPC:Update()
    if self.CurSelectBtn and self.CurSelectKey and XInputManager.GetCurEditKeyNum() > 0 then
        local curKeySetType = self:GetCurKeySetType()
        if curKeySetType == CS.InputDeviceType.Keyboard then
            self.TxtInput.text = XInputManager.GetCurEditKeyString() .. CS.XTextManager.GetText("SetInputFirstKey")
            self.PanelJoypadKeyIcon.gameObject:SetActiveEx(false)
        else
            self.TxtInput.text = ""
            local mainKeyIcon = XInputManager.GetCurEditKeyIcon(CS.KeyPos.MainKey, curKeySetType)
            local subKeyIcon = XInputManager.GetCurEditKeyIcon(CS.KeyPos.SubKey, curKeySetType)
            if not string.IsNilOrEmpty(mainKeyIcon) then
                self.JoypadIcon1:SetSprite(mainKeyIcon)
            end
            
            local subKeyIsNil = string.IsNilOrEmpty(subKeyIcon)
            if not subKeyIsNil then
                self.JoypadIcon2:SetSprite(subKeyIcon)
            end
            self.JoypadIcon2.gameObject:SetActiveEx(not subKeyIsNil)
            self.TxtAdd.gameObject:SetActiveEx(not subKeyIsNil)

            self.PanelJoypadKeyIcon.gameObject:SetActiveEx(true)
        end
    end
end

function XUiBigWorldSetPanelFightPC:OnJoystickTypeChanged()
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
    self:OnPatternGroupClick()
end

function XUiBigWorldSetPanelFightPC:OnJoystickActiveChanged()
    self:RefreshJoystickPanel()
    self:OnBtnCloseInputClick()
end

--region 按键回调

function XUiBigWorldSetPanelFightPC:OnTabClick(index)
    if self.CurPageType ~= index then
        self:PlayAnimation("QieHuan")
    end
    self.CurPageType = index
    self:UpdateKeySetType()
    self:UpdatePanel()
end

function XUiBigWorldSetPanelFightPC:OnPatternGroupClick(index)
    self:UpdateKeySetType()
    if self.BtnTabGroup.CurSelectId ~= self.PageType.GameController then return end
    self:InitControllerPanel()
end

function XUiBigWorldSetPanelFightPC:OnBtnCloseInputClick()
    XInputManager.EndEdit()
    self:ShowSetKeyTip(false)
end

function XUiBigWorldSetPanelFightPC:OnTogEnableJoystickClick(value)
    if value ~= nil then
        self:SetEnableInputJoystick(value == 1)
    else
        self:SetEnableInputJoystick(self.TogEnableJoystick:GetToggleState() == XUiButtonState.Select)
    end

    if XInputManager.EnableInputJoystick and not XDataCenter.UiPcManager.IsPc() then
        self:SetEnableInputKeyboard(false)
    end

    self:InitControllerPanel()
    self:RefreshJoystickPanel()
end

function XUiBigWorldSetPanelFightPC:OnTogEnableKeyboardClick(value)
    if value ~= nil then
        self:SetEnableInputKeyboard(value == 1)
    else
        self:SetEnableInputKeyboard(self.TogEnableKeyboard:GetToggleState())
    end

    if XInputManager.EnableInputKeyboard and not XDataCenter.UiPcManager.IsPc() then
        self:SetEnableInputJoystick(false)
    end

    self:InitKeyboardPanel()
    self:RefreshKeyboardPanel()
end

function XUiBigWorldSetPanelFightPC:OnToggleSelect(index)
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

function XUiBigWorldSetPanelFightPC:_RegisterButtonClicks()
    self.BtnTabGroup:Init({ self.BtnTabGameController, self.BtnTabKeyboard }, function(index)
        self:OnTabClick(index)
    end)
    self.PatternGroup:Init({ self.BtnXbox, self.BtnPS4 }, function(index)
        self:OnPatternGroupClick(index)
    end)

    self.TogEnableJoystick:AddEventListener(handler(self, self.OnTogEnableJoystickClick))
    self.TogEnableKeyboard:AddEventListener(handler(self, self.OnTogEnableKeyboardClick))
    self.BtnCloseInput:AddEventListener(handler(self, self.OnBtnCloseInputClick))
    self.BtnCloseInput:SetBarrierType(XUiRespondBarrierType.Mouse2)
end

--endregion

--region 界面设置

function XUiBigWorldSetPanelFightPC:GetDefaultIndex()
    return self.PageType.Keyboard
end

function XUiBigWorldSetPanelFightPC:GetCurKeySetType()
    return self._CurKeySetType or CS.InputDeviceType.Xbox --默认会显示xbox
end

function XUiBigWorldSetPanelFightPC:IsShowInputMapId(inputMapId)
    return self.ShowInputMaps[inputMapId]
end

function XUiBigWorldSetPanelFightPC:GetInputMapId()
    return ToInt32(CS.XInputMapId.Fight) -- CS.XInputMapId.SkyGarden
end

function XUiBigWorldSetPanelFightPC:GetCursorMoveSensitivity()
    return XJoystickCursorHelper.CursorMoveSensitivity
end

function XUiBigWorldSetPanelFightPC:SetCursorMoveSensitivity(value)
    XJoystickCursorHelper.PreSetCursorMoveSensitivity(value)
end

function XUiBigWorldSetPanelFightPC:GetCameraMoveSensitivity(viewType)
    viewType = viewType or CS.CameraViewType.ThirdPerson
    local value = XInputManager.GetCameraMoveSensitivity(self:GetCurKeySetType(), viewType)
    return math.max(0, value - 1)
end

function XUiBigWorldSetPanelFightPC:SetCameraMoveSensitivity(value, viewType)
    value = value + 1
    viewType = viewType or CS.CameraViewType.ThirdPerson
    XInputManager.SetCameraMoveSensitivity(self:GetCurKeySetType(), value, viewType)
end

function XUiBigWorldSetPanelFightPC:ShowSetKeyTip(show)
    XDataCenter.UiPcManager.SetEditingKeyState(show)
    self.PanelSetKeyTip.gameObject:SetActiveEx(show)
end

function XUiBigWorldSetPanelFightPC:SetEnableInputJoystick(value)
    XInputManager.SetEnableInputJoystick(value)
    self.TogEnableJoystick:SetButtonState(XInputManager.EnableInputJoystick and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiBigWorldSetPanelFightPC:SetEnableInputKeyboard(value)
    XInputManager.SetEnableInputKeyboard(value)
    self.TogEnableKeyboard:SetButtonState(XInputManager.EnableInputKeyboard and XUiButtonState.Select or XUiButtonState.Normal)
end


function XUiBigWorldSetPanelFightPC:RefreshGridList(curKeySetType, blockTip)
    if not curKeySetType then return end

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

    if blockTip then return end
    XUiManager.TipSuccess(XUiHelper.GetText("SetJoyStickSuccess"))
end

function XUiBigWorldSetPanelFightPC:CheckDataIsChange()
    if self._CurKeySetTypeInt and self._CurKeySetTypeInt ~= XInputManager.GetJoystickType() then
        return true
    end
    
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        if defaultIndex ~= self._SelectIndex then
            return true
        end
    end
    return XInputManager.IsKeyMappingChange() or XInputManager.IsCameraMoveSensitivitiesChange()
end

function XUiBigWorldSetPanelFightPC:SaveChange()
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        if defaultIndex ~= self._SelectIndex and CS.XInputManager.SetDefaultMainButton(self._lastJoystickType, not isDefault) then
            self:RefreshGridList(self:GetCurKeySetType())
        end
    end
    if self._CurKeySetTypeInt then
        XInputManager.SetJoystickType(self._CurKeySetTypeInt)
    end
    XInputManager.SaveChange()
end

function XUiBigWorldSetPanelFightPC:CancelChange()
    if self.PanelBtnGroup then
        local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
        local defaultIndex = isDefault and 1 or 2
        self.PanelBtnGroup:SelectIndex(defaultIndex)
    end
    self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
    self._CurKeySetTypeInt = XInputManager.GetJoystickType()
    XInputManager.RevertKeyMappings()
end

function XUiBigWorldSetPanelFightPC:ResetToDefaultTips(callFunc)
    local dialogData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    dialogData:InitInfo(nil, XUiHelper.GetText("DefaultKeyCodesTip"))
    dialogData:InitSureClick(nil, callFunc, true):InitToggleActive(false)
    XMVCA.XBigWorldUI:OpenConfirmPopup(dialogData)
end

function XUiBigWorldSetPanelFightPC:GetInputMapIdEnum(inputMapId)
    return CS.XInputMapId.__CastFrom(inputMapId)
end

function XUiBigWorldSetPanelFightPC:ResetToDefault()
    if self.CurPageType == self.PageType.GameController then
        self:ResetToDefaultTips(function()
            local curKeySetType = self:GetCurKeySetType()
            for inputMapId, _ in pairs(self.ShowInputMaps) do
                XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(inputMapId), curKeySetType)
            end
            XInputManager.DefaultCameraMoveSensitivitySetting(curKeySetType, CS.CameraViewType.ThirdPerson)
            XInputManager.DefaultCameraMoveSensitivitySetting(curKeySetType, CS.CameraViewType.FirstPerson)
            XJoystickCursorHelper.SetDefaultSensitivity()
            if self.PanelBtnGroup then
                local isDefault = CS.XInputManager.IsDefaultMainButton(self._lastJoystickType)
                local defaultIndex = isDefault and 1 or 2
                self.PanelBtnGroup:SelectIndex(defaultIndex)
            end
            self.PatternGroup:SelectIndex(XInputManager.GetJoystickType())
            self:InitControllerPanel(true)
        end)
    elseif self.CurPageType == self.PageType.Keyboard then
        self:ResetToDefaultTips(function()
            for inputMapId, _ in pairs(self.ShowInputMaps) do
                XInputManager.InputMapper:DefaultKeysSetting(self:GetInputMapIdEnum(inputMapId), CS.InputDeviceType.Keyboard)
            end
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.InputDeviceType.Keyboard, CS.CameraViewType.ThirdPerson)
            XInputManager.DefaultCameraMoveSensitivitySetting(CS.InputDeviceType.Keyboard, CS.CameraViewType.FirstPerson)
            self:InitKeyboardPanel(true)
        end)
    end
end

function XUiBigWorldSetPanelFightPC:EditKey(keyCode, targetItem, pressKeyIndex)
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
                local dialogData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
                dialogData:InitInfo(nil, XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("SetKeyConflict", textKeyConflict, textKeyCurrent)))
                dialogData:InitSureClick(nil, function()
                    CS.XInputManager.InputMapper:SwapConflictKey(curKeySetType, pressKeyIndex, inputMapId)
                    self:RefreshGridList(curKeySetType)
                end, true):InitToggleActive(false)
                dialogData:InitCancelAndCloseClick(nil, function()
                    CS.XInputManager.InputMapper:ClearConflictKey()
                end, true)
                XMVCA.XBigWorldUI:OpenConfirmPopup(dialogData)
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

function XUiBigWorldSetPanelFightPC:_UpdatePanelBtnGroup(lastJoystickType)
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

function XUiBigWorldSetPanelFightPC:InitControllerPanel(resetTextOnly)
    self.CtrlKeyItemList = self.CtrlKeyItemList or {}
    local list = self._Setting:GetControllerMapCfg()

    for id, v in ipairs(list) do
        local grid = self.CtrlKeyItemList[id]
        if self:IsShowInputMapId(v.InputMapId) and self:IsSameKeySet(v.KeySetTypes) then
            if v.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = defaultKeyMapTable.KeyCodeType
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiBWNotCustomKeyItemHandle.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItemHandle, self.ControllerSetContent), self)
                else
                    grid = grid or XUiBWBtnKeyItem.New(CSUnityEngineObjectInstantiate(self.BtnKeyItem, self.ControllerSetContent), self)
                end

                grid:SetKeySetType(self:GetCurKeySetType())
                grid:Refresh(v, handler(self, self.EditKey), resetTextOnly, v.InputMapId, defaultKeyMapTable.OperationType)
            elseif v.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.ControllerSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
                txtTitle.text = v.Title
            elseif v.Type == XSetConfigs.ControllerSetItemType.Slider then
                if not grid then
                    if v.InputMapId == 1 or v.InputMapId == 11 then
                        local ui = CSUnityEngineObjectInstantiate(self.GridSlider, self.ControllerSetContent)
                        grid = XUiBWCameraSensitivitySliderItem.New(ui, self, v)
                    elseif v.InputMapId == 4 then
                        local ui = CSUnityEngineObjectInstantiate(self.VirtualCursorPC, self.ControllerSetContent)
                        grid = XUiBWCursorSliderItem.New(ui, self, v)
                    end
                end
                grid:Update(v)
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

                local image1a = gridTypeTr:Find("PanelBtn1/TogType1/ImgA"):GetComponent(typeof(CS.UnityEngine.UI.Image))
                local image1b = gridTypeTr:Find("PanelBtn1/TogType1/ImgB"):GetComponent(typeof(CS.UnityEngine.UI.Image))
                local image2a = gridTypeTr:Find("PanelBtn2/TogType2/ImgA"):GetComponent(typeof(CS.UnityEngine.UI.Image))
                local image2b = gridTypeTr:Find("PanelBtn2/TogType2/ImgB"):GetComponent(typeof(CS.UnityEngine.UI.Image))
                
                local defaultKeyMapTable1 = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[isDefaultUi and 1 or 2])
                local defaultKeyMapTable2 = XSetConfigs.GetDefaultKeyMapTable(v.DefaultKeyMapIds[isDefaultUi and 2 or 1])
                local operationTypeInt1 = XInputManager.XOperationType.__CastFrom(defaultKeyMapTable1.OperationType)
                local operationTypeInt2 = XInputManager.XOperationType.__CastFrom(defaultKeyMapTable2.OperationType)
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

            self.CtrlKeyItemList[id] = grid
            
            :: CONTINUE ::
        end
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
end

function XUiBigWorldSetPanelFightPC:InitKeyboardPanel(resetTextOnly)
    self._KeyboardGridList = self._KeyboardGridList or {}
    local list = self._Setting:GetControllerMapCfg()

    for id, item in ipairs(list) do
        local grid = self._KeyboardGridList[id]
        if self:IsShowInputMapId(item.InputMapId) and self:IsSameKeySet(item.KeySetTypes) then
            if item.Type == XSetConfigs.ControllerSetItemType.SetButton then
                local defaultKeyMapTable = XSetConfigs.GetDefaultKeyMapTable(item.DefaultKeyMapIds[1])
                if not defaultKeyMapTable then
                    goto CONTINUE
                end
                
                local keyCodeType = XInputManager.GetKeyCodeTypeByInt(defaultKeyMapTable.OperationKey, item.InputMapId, defaultKeyMapTable.OperationType)
                if keyCodeType == XSetConfigs.KeyCodeType.NotCustom or keyCodeType == XSetConfigs.KeyCodeType.NotCustomIgnoreCheck then
                    grid = grid or XUiBWNotCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.NotCustomKeyItem, self.KeyboardSetContent), self)
                elseif keyCodeType == XSetConfigs.KeyCodeType.OneKeyCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.KeyMouseCustom or
                        keyCodeType == XSetConfigs.KeyCodeType.SingleKey or
                        keyCodeType == XSetConfigs.KeyCodeType.Default
                then
                    grid = grid or XUiBWOneKeyCustomKeyItem.New(CSUnityEngineObjectInstantiate(self.OneKeyCustomKeyItem, self.KeyboardSetContent), self)
                end

                grid:SetKeySetType(CS.InputDeviceType.Keyboard)
                grid:Refresh(item, handler(self, self.EditKey), resetTextOnly, item.InputMapId, defaultKeyMapTable.OperationType)
            elseif item.Type == XSetConfigs.ControllerSetItemType.Section then
                grid = grid or CSUnityEngineObjectInstantiate(self.TxtSection, self.KeyboardSetContent)
                local txtTitle = grid:Find("TxtTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
                txtTitle.text = item.Title
            elseif item.Type == XSetConfigs.ControllerSetItemType.Slider then
                if not grid then
                    local ui = XUiHelper.Instantiate(self.GridSliderPC, self.KeyboardSetContent)
                    grid = XUiBWCameraSensitivitySliderItem.New(ui, self, item)
                end
                grid:Update(item)
            end

            self._KeyboardGridList[id] = grid
        end
        
        :: CONTINUE ::
    end
    self.BtnKeyItem.gameObject:SetActiveEx(false)
    self.KeyboardPanelInit = true
end

function XUiBigWorldSetPanelFightPC:ShowBtnDefault(enable)
    self.Parent.BtnDefault.gameObject:SetActive(enable)
end

function XUiBigWorldSetPanelFightPC:ShowBtnSave(enable)
    self.Parent.BtnSave.gameObject:SetActive(enable)
end

function XUiBigWorldSetPanelFightPC:RefreshJoystickPanel()
    self:UpdatePanelGrid()

    local enable = XInputManager.EnableInputJoystick
    self.TogEnableJoystick:SetButtonState(XInputManager.EnableInputJoystick and XUiButtonState.Select or XUiButtonState.Normal)
    self:ShowBtnSave(enable)
    self:ShowBtnDefault(enable)
    
    local isPc = XDataCenter.UiPcManager.IsPc()
    if enable then
        if not isPc then
            self:SetEnableInputKeyboard(false)
        end
    else
        if isPc then  -- pc时,手柄被禁用了则要立即开启键盘
            self:SetEnableInputKeyboard(true)
        end
    end
    self.PanelJoystickSet.gameObject:SetActiveEx(enable)
    self.TipDisableJoyStick.gameObject:SetActiveEx(not enable)
    
    self:RefreshJoystickItem(self.CurPageType == self.PageType.GameController and self.TogEnableJoystick:GetToggleState())
end

function XUiBigWorldSetPanelFightPC:RefreshKeyboardPanel()
    self:UpdatePanelGrid()

    local enable = XInputManager.EnableInputKeyboard
    self.TogEnableKeyboard:SetButtonState(enable and XUiButtonState.Select or XUiButtonState.Normal)
    self:ShowBtnSave(enable)
    self:ShowBtnDefault(enable)

    local isPc = XDataCenter.UiPcManager.IsPc()
    if enable then
        if not isPc then
            self:SetEnableInputJoystick(false)
        end
    -- else
    --     if isPc then  -- pc时,键盘被禁用了则要立即开启手柄 maybe
    --         self:SetEnableInputJoystick(true)
    --     end
    end
    self.PanelKeyboardSet.gameObject:SetActiveEx(enable)
    self.TipDisableKeyboard.gameObject:SetActiveEx(not enable)

    self:RefreshKeyboardItem(self.CurPageType == self.PageType.Keyboard and self.TogEnableKeyboard:GetToggleState())
end

function XUiBigWorldSetPanelFightPC:UpdatePanelGrid()
    local isKeyboard = self.CurPageType == self.PageType.Keyboard
    self.PanelKeyboard.gameObject:SetActiveEx(isKeyboard)

    local isGameController = self.CurPageType == self.PageType.GameController
    self.PanelGameController.gameObject:SetActiveEx(isGameController)
end

function XUiBigWorldSetPanelFightPC:UpdatePanel()
    if self.CurPageType == self.PageType.GameController then
        local enableInputJoystick = XInputManager.EnableInputJoystick
        self:ShowBtnSave(enableInputJoystick)
        self:ShowBtnDefault(enableInputJoystick)
        self:InitControllerPanel()
        self:RefreshJoystickPanel()
    elseif self.CurPageType == self.PageType.Keyboard then
        local enableInputKeyboard = XInputManager.EnableInputKeyboard
        self:ShowBtnSave(enableInputKeyboard)
        self:ShowBtnDefault(enableInputKeyboard)
        self:InitKeyboardPanel()
        self:RefreshKeyboardPanel()
    end
end

function XUiBigWorldSetPanelFightPC:UpdateKeySetType()
    if self.BtnTabGroup.CurSelectId == self.PageType.Keyboard then
        self._CurKeySetType = CS.InputDeviceType.Keyboard
        self._CurKeySetTypeInt = nil
        return
    end
    if self.BtnTabGroup.CurSelectId == self.PageType.GameController then
        if self.PatternGroup.CurSelectId == 1 then
            self._CurKeySetType = CS.InputDeviceType.Xbox
            self._CurKeySetTypeInt = 1
            return
        end
        if self.PatternGroup.CurSelectId == 2 then
            self._CurKeySetType = CS.InputDeviceType.Ps
            self._CurKeySetTypeInt = 2
            return
        end
    end
end

function XUiBigWorldSetPanelFightPC:IsSameKeySet(keySetTypes)
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

function XUiBigWorldSetPanelFightPC:SetGridActive(grid, enable)
    if not grid then return end

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

function XUiBigWorldSetPanelFightPC:RefreshKeyboardItem(enable)
    if self._KeyboardGridList then
        for i, grid in pairs(self._KeyboardGridList) do
            local list = self._Setting:GetControllerMapCfg()
            local item = list[i]
            local isActive = self:IsShowInputMapId(item.InputMapId) and self:IsSameKeySet(item.KeySetTypes)
            self:SetGridActive(grid, enable and isActive)
        end
    end
end

function XUiBigWorldSetPanelFightPC:RefreshJoystickItem(enable)
    if self.CtrlKeyItemList then
        for i, grid in pairs(self.CtrlKeyItemList) do
            local list = self._Setting:GetControllerMapCfg()
            local item = list[i]
            local isActive = self:IsShowInputMapId(item.InputMapId) and self:IsSameKeySet(item.KeySetTypes)
            self:SetGridActive(grid, enable and isActive)
        end
    end
end

--endregion

return XUiBigWorldSetPanelFightPC
