---@class XUiSkyGardenDormPhotoWall : XBigWorldUi
---@field _Control XSkyGardenDormControl
---@field _PanelWall XUiPanelSGWall
---@field _PanelNumber XUiPanelSGNumber
local XUiSkyGardenDormPhotoWall = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormPhotoWall")

local SgDormAreaType = XMVCA.XSkyGardenDorm.XSgDormAreaType
local XDormEventId = XMVCA.XSkyGardenDorm.XEventId

function XUiSkyGardenDormPhotoWall:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormPhotoWall:OnStart(areaType)
    self._AreaType = areaType
    self:InitView()

    self._Control:Subscribe(XDormEventId.REFRESH_HANDBOOK_NEW_MARK, self.RefreshCodeNewMark, self)
    self._Control:Subscribe(XDormEventId.EVENT_DORM_FURNITURE_REFRESH, self.RefreshCodeNewMark, self)
    self._Control:Subscribe(XDormEventId.EVENT_DORM_LAYOUT_REFRESH, self.OnRefreshLayout, self)
    self._Control:Subscribe(XDormEventId.EVENT_DORM_APPLY_NEW_LAYOUT, self.OnApplyNewLayout, self)
end

function XUiSkyGardenDormPhotoWall:OnDestroy()
    self._Control:Unsubscribe(XDormEventId.REFRESH_HANDBOOK_NEW_MARK, self.RefreshCodeNewMark, self)
    self._Control:Unsubscribe(XDormEventId.EVENT_DORM_FURNITURE_REFRESH, self.RefreshCodeNewMark, self)
    self._Control:Unsubscribe(XDormEventId.EVENT_DORM_LAYOUT_REFRESH, self.OnRefreshLayout, self)
    self._Control:Unsubscribe(XDormEventId.EVENT_DORM_APPLY_NEW_LAYOUT, self.OnApplyNewLayout, self)
    
    local name = self._AreaType == SgDormAreaType.Wall and "UiSkyGardenDormCameraPhotoWall" or "UiSkyGardenDormCameraFrame"
    XMVCA.XBigWorldGamePlay:DeactivateVCamera(name, false)
    
    self._Control:ClearContainerDataList(self._AreaType)

    local manager = XMVCA.XSkyGardenDorm:GetManager()
    if manager then
        manager:DisposeDynamicContainer()
        manager:DisposeStaticContainer()
    end

    XMVCA.XBigWorldGamePlay:SetCameraProjection(false)
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(true)
end

function XUiSkyGardenDormPhotoWall:OnEnable()
    self:PlayAnimation("Enable")
    self:UpdateView()
    self:RegisterPCEvent()
end

function XUiSkyGardenDormPhotoWall:OnDisable()
    self:UnregisterPCEvent()
end

function XUiSkyGardenDormPhotoWall:InitUi()
    self._IsHide = false
    self._RotateSpeed = self._Control:GetHandleRotateSpeed()
end

function XUiSkyGardenDormPhotoWall:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    
    self.BtnDelete:AddEventListener(handler(self, self.OnBtnDeleteClick))
    
    self.BtnReset:AddEventListener(handler(self, self.OnBtnResetClick))
    
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    
    self.BtnHideClose:AddEventListener(handler(self, self.OnBtnHideClick))
    
    self.BtnHideOpen:AddEventListener(handler(self, self.OnBtnHideClick))
    
    self.BtnPresuppose:AddEventListener(handler(self, self.OnBtnPresupposeClick))
    
    self.BtnCodex:AddEventListener(handler(self, self.OnBtnCodeClick))
    
    self._OnPressPCKeyHandler = function(inputDeviceType, key, operationType) 
        self:OnPressPCKeyHandle(inputDeviceType, key, operationType)
    end
    local PCKey = {
        HandleRT = 311,
        HandleLT = 312,
    }
    self._PressCb = {
        [PCKey.HandleRT] = handler(self, self.OnHandleRTPress),
        [PCKey.HandleLT] = handler(self, self.OnHandleLTPress)
    }
end

function XUiSkyGardenDormPhotoWall:InitView()
    local isPhotoWall = self._AreaType == SgDormAreaType.Wall
    local ui = isPhotoWall and self.PanelHomePhoto or self.PanelHomeFrame
    self.PanelHomePhoto.gameObject:SetActiveEx(isPhotoWall)
    self.PanelHomeFrame.gameObject:SetActiveEx(not isPhotoWall)
    self._PanelNumber = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGNumber").New(self.PanelGridNumber, self, self._AreaType)
    local panelWall
    if isPhotoWall then
        panelWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGPhotoWall").New(ui, self, self._AreaType)
    else
        panelWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGGiftWall").New(ui, self, self._AreaType)
    end
    self._PanelWall = panelWall
    
    self:OnRefreshLayout()
    self._PanelWall:InitFurniture()
end

function XUiSkyGardenDormPhotoWall:UpdateView()
    self._PanelNumber:Refresh()
    self._PanelWall:Refresh()
    self:RefreshCodeNewMark()
end

function XUiSkyGardenDormPhotoWall:OnBtnBackClick()
    local currentData = self:GetContainerData(self._AreaType)
    local serverData = self._Control:GetContainerFurnitureData(self._AreaType)
    if currentData:Equal(serverData) then
        return self:Close()
    end
    local txt = self._Control:GetFurnitureChangedText()
    
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    data:InitInfo(nil, txt)
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    data:InitToggleActive(false):InitSureClick(nil, function() 
        self._Control:RequestSaveAndApplyLayout(self._AreaType, layoutId, 0, { currentData }, function() 
            self:Close()
        end)
    end)
    data:InitCancelClick(nil, function() 
        self._Control:RevertDecoration(self._AreaType, serverData)
        self:Close()
    end)
    
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end

function XUiSkyGardenDormPhotoWall:OnBtnDeleteClick()
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    local content = self._Control:GetOperateText(1)
    data:InitInfo(nil, content):InitToggleActive(false):InitSureClick(nil, function()
        self._PanelWall:ClearDecoration()
        self:UpdateView()
    end)
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end
 
function XUiSkyGardenDormPhotoWall:OnBtnResetClick()
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    local content = self._Control:GetOperateText(2)
    data:InitInfo(nil, content):InitToggleActive(false):InitSureClick(nil, function()
        self._PanelWall:RevertDecoration()
        self:UpdateView()
    end)
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end

function XUiSkyGardenDormPhotoWall:OnBtnSaveClick()
    if not self._PanelWall:TryCheckOpIsSafe(true) then
        return
    end
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    local data = self:GetContainerData()
    self._Control:RequestSaveAndApplyLayout(self._AreaType, layoutId, 0, { data }, function()
        XUiManager.TipMsg(self._Control:GetLayoutChangeText(1))
    end)
end

function XUiSkyGardenDormPhotoWall:OnBtnHideClick()
    if not self._PanelWall:TryCheckOpIsSafe(true) then
        return
    end
    self._IsHide = not self._IsHide
    self.BtnHideClose.gameObject:SetActiveEx(self._IsHide)
    self.BtnHideOpen.gameObject:SetActiveEx(not self._IsHide)
    self._PanelWall:SetVisible(not self._IsHide)
    if self._IsHide then
        self:PlayAnimationWithMask("UiDisable", function() 
            self:SetMultiObjActiveEx(false)
            self._PanelNumber:Close()
        end)
    else
        self:SetMultiObjActiveEx(true)
        self._PanelNumber:Open()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiSkyGardenDormPhotoWall:EnterEditMode()
    self.BtnPresuppose.gameObject:SetActiveEx(false)
    self.BtnCodex.gameObject:SetActiveEx(false)
    self.BtnBack.transform.parent.gameObject:SetActiveEx(false)
    self.BtnSave.gameObject:SetActiveEx(false)
    self.BtnHideClose.gameObject:SetActiveEx(false)
    self.BtnHideOpen.gameObject:SetActiveEx(false)
end

function XUiSkyGardenDormPhotoWall:ExitEditMode()
    self.BtnPresuppose.gameObject:SetActiveEx(true)
    self.BtnCodex.gameObject:SetActiveEx(true)
    self.BtnBack.transform.parent.gameObject:SetActiveEx(true)
    self.BtnSave.gameObject:SetActiveEx(true)
    self.BtnHideClose.gameObject:SetActiveEx(self._IsHide)
    self.BtnHideOpen.gameObject:SetActiveEx(not self._IsHide)
end

function XUiSkyGardenDormPhotoWall:SetMultiObjActiveEx(value)
    if value then
        self.BtnDelete.gameObject:SetActiveEx(true)
        self.BtnReset.gameObject:SetActiveEx(true)
        self.BtnSave.gameObject:SetActiveEx(true)
        self.BtnPresuppose.gameObject:SetActiveEx(true)
        self.BtnCodex.gameObject:SetActiveEx(true)
        self.BtnBack.transform.parent.gameObject:SetActiveEx(true)
    else
        self.BtnDelete.gameObject:SetActiveEx(false)
        self.BtnReset.gameObject:SetActiveEx(false)
        self.BtnSave.gameObject:SetActiveEx(false)
        self.BtnPresuppose.gameObject:SetActiveEx(false)
        self.BtnCodex.gameObject:SetActiveEx(false)
        self.BtnBack.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiSkyGardenDormPhotoWall:OnBtnPresupposeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormPresuppose", self._AreaType)
end

function XUiSkyGardenDormPhotoWall:OnBtnCodeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormCodex", self:GetDisplayTypeId(self._PanelWall:GetTypeId()))
end

function XUiSkyGardenDormPhotoWall:GetDisplayTypeId(tId)
    if not self._DisplayTypeDict then
        local typeList = self._Control:GetHandBookTypeList()

        local dict = {}
        local areaTypeToTypeId = {}
        for _, typeId in pairs(typeList) do
            dict[typeId] = typeId
            local areaType = self._Control:GetAreaType(typeId)
            if not areaTypeToTypeId[areaType] then
                areaTypeToTypeId[areaType] = typeId
            end
        end
        self._DisplayTypeDict = dict
        self._DisplayAreaTypeDict = areaTypeToTypeId
    end
    local targetId = self._DisplayTypeDict[tId]
    if targetId then
        return targetId
    end
    targetId = self._DisplayAreaTypeDict[self._AreaType]
    return targetId
end

---@return XSgContainerFurnitureData
function XUiSkyGardenDormPhotoWall:GetContainerData()
    return self._Control:CloneContainerFurnitureData(self._AreaType)
end

function XUiSkyGardenDormPhotoWall:OnRefreshLayout()
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    self.BtnPresuppose:SetNameByGroup(0, self._Control:GetDormLayoutName(layoutId))
end

function XUiSkyGardenDormPhotoWall:OnApplyNewLayout()
    self:PlayAnimationWithMask("DarkEnable", function()
        self._PanelWall:ApplyNewLayout()
        self:UpdateView()
        self:PlayAnimationWithMask("DarkDisable")
    end)
    
end

function XUiSkyGardenDormPhotoWall:CheckIsFull(majorType)
    return self._PanelNumber:IsFull(majorType)
end

function XUiSkyGardenDormPhotoWall:RefreshCodeNewMark()
    local value = self._Control:CheckHandBookNewMark()
    self.BtnCodex:ShowReddot(value)
end

function XUiSkyGardenDormPhotoWall:RegisterPCEvent()
    CS.XInputManager.RegisterOnPress(CS.XInputManager.XOperationType.System, self._OnPressPCKeyHandler)
end

function XUiSkyGardenDormPhotoWall:UnregisterPCEvent()
    CS.XInputManager.UnregisterOnPress(CS.XInputManager.XOperationType.System, self._OnPressPCKeyHandler)
end

function XUiSkyGardenDormPhotoWall:OnPressPCKeyHandle(inputDeviceType, key, operationType)
    local callback = self._PressCb[key]
    if not callback then
        return
    end
    callback()
end

function XUiSkyGardenDormPhotoWall:OnHandleRTPress()
    self._PanelWall:RotateByHandle(-self._RotateSpeed)
end

function XUiSkyGardenDormPhotoWall:OnHandleLTPress()
    self._PanelWall:RotateByHandle(self._RotateSpeed)
end