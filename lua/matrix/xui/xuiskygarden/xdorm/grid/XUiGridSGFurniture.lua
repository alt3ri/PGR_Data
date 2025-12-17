---@class XUiGridSGFurniture : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWallMenu
---@field RImgIcon UnityEngine.UI.RawImage
local XUiGridSGFurniture = XClass(XUiNode, "XUiGridSGFurniture")

local Delay = 100

function XUiGridSGFurniture:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiGridSGFurniture:OnDisable()
    self._ConfigId = -1
    self:StopAnimationTimer()
end

function XUiGridSGFurniture:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiGridSGFurniture:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = 0
        
    end
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        self:PlayAnimation("GridItemEnable")
        self:StopAnimationTimer()
    end, (index - 1) * Delay)
end

function XUiGridSGFurniture:Refresh(data, selectId, gridType)
    self._GridType = gridType
    if gridType == 1 then --家具
        self:RefreshFurniture(data, selectId)
    elseif gridType == 2 then --本地照片
        self:RefreshLocalPhoto(data, selectId)
    end
end

function XUiGridSGFurniture:RefreshFurniture(configId, selectId)
    if not configId or configId <= 0 then
        self:Close()
        return
    end
    self._ConfigId = configId
    local maxCount = self._Control:GetFurnitureMaxCount(configId)
    local onlyOne = maxCount == 1
    self.RImgIcon.gameObject:SetActiveEx(true)
    self.RImgPhotoMask.gameObject:SetActiveEx(false)
    self.RImgIcon:SetRawImage(self._Control:GetFurnitureIcon(configId))
    self.TxtName.text = self._Control:GetFurnitureName(configId)
    self._IsUnlock = self._Control:CheckFurnitureUnlockByConfigId(configId)
    self.PanelDisable.gameObject:SetActiveEx(not self._IsUnlock)
    self.PanelNow.gameObject:SetActiveEx(false)
    self.PanelNumber.gameObject:SetActiveEx(not onlyOne)
    local ids
    local containerFurnitureData = self._Control:CloneContainerFurnitureData(self._AreaType)
    self._IsCurrent = false
    if onlyOne then
        ids = self._Control:GetFurnitureIdListByConfigId(configId)
        local id = ids and ids[1] or 0
        local f = containerFurnitureData:GetFurniture(id, false)
        self._IsCurrent = f ~= nil or containerFurnitureData:GetContainer():GetId() == id
        self.PanelNow.gameObject:SetActiveEx(self._IsCurrent)
    else
        ids = self._Control:GetNotPutFurnitureIdList(configId, containerFurnitureData, false)
        self.TxtNumber.text = ids and #ids or 0
    end
    self._IdList = ids
    self.ImgTxtMask.gameObject:SetActiveEx(true)
    self:SetSelect(configId == selectId)
end

function XUiGridSGFurniture:RefreshLocalPhoto(data, selectId)
    if not data then
        self:Close()
        return
    end
    --盐
    self._ConfigId = data.CheckSalt
    self._Data = data
    self._IsUnlock = true
    local containerFurnitureData = self._Control:CloneContainerFurnitureData(self._AreaType)
    local tex = XMVCA.XBigWorldAlbum:GetPhotoTexture(data, true)
    self.PanelNumber.gameObject:SetActiveEx(false)
    self.TxtName.text = ""
    self.RImgIcon.gameObject:SetActiveEx(false)
    self.RImgPhotoMask.gameObject:SetActiveEx(true)
    if tex then
        --因为使用了LoadRawImage组件，这里是动态列表，可能会对直接设置Texture造成影响（时序问题）
        if self.LoadRawImage then
            self.LoadRawImage.enabled = false
        end
        self.RImgPhoto.transform.sizeDelta = Vector2(self._RImgPhotoRealWidth, self._RImgPhotoRealHeight)
        self.RImgPhoto.texture = tex
        self._Texture = tex
    else
        self.RImgPhoto.transform.sizeDelta = Vector2(self._RImgPhotoDesignWidth, self._RImgPhotoRealHeight)
        self.RImgPhoto:SetRawImage(self._Control:GetDefaultAlbumPhotoIcon())
        if not self.LoadRawImage then
            self.LoadRawImage = self.RImgPhoto.transform:GetComponent("XLoadRawImage")
        else
            self.LoadRawImage.enabled = true
        end
    end
    self.PanelDisable.gameObject:SetActiveEx(not self._IsUnlock)
    local f = containerFurnitureData:GetFurniture(data.Id, true)
    self._IsCurrent = f ~= nil
    self.PanelNow.gameObject:SetActiveEx(self._IsCurrent)
    self.ImgTxtMask.gameObject:SetActiveEx(false)
    self:SetSelect(self._ConfigId == selectId)
end

function XUiGridSGFurniture:OnRecycle()
    if self._Texture then
        XUiHelper.Destroy(self._Texture)
        self._Texture = nil
        if self.RImgPhoto then
            self.RImgPhoto.texture = nil
        end
    end
end

function XUiGridSGFurniture:InitUi()
    self.UiBigWorldRed.gameObject:SetActiveEx(false)
    self._ScreenRatio = CS.UnityEngine.Screen.width / CS.UnityEngine.Screen.height
    local height = self.RImgPhoto.transform.rect.height
    self._RImgPhotoRealHeight = height
    self._RImgPhotoRealWidth = height * self._ScreenRatio
    self._RImgPhotoDesignWidth = height * 16 / 9
    
    local imgBg = self.Transform:Find("ImgBg")
    if imgBg then
        self._CanvasGroup = imgBg:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

function XUiGridSGFurniture:InitCb()
end

function XUiGridSGFurniture:SetSelect(value, lockTips)
    --未解锁
    if not self:CheckUnlock(lockTips) then
        self.PanelSelect.gameObject:SetActiveEx(false)
        return 0
    end
    --当前已经摆放
    if self._IsCurrent then
        self.PanelSelect.gameObject:SetActiveEx(value)
        return 1
    end
    --没有家具可以摆放了
    if not self:IsAlbumPhoto() and XTool.IsTableEmpty(self._IdList) then
        self.PanelSelect.gameObject:SetActiveEx(false)
        return 0
    end
    self._IsSelect = value
    self.PanelSelect.gameObject:SetActiveEx(value)
    return 2
end

function XUiGridSGFurniture:OnClick()
    local code = self:SetSelect(true, true)
    if code == 0 then
        return
    end
    if self:IsAlbumPhoto() then
        self.Parent:OnSelectFurniture(self._Data.Id, self._ConfigId, self, code == 2)
    else
        self.Parent:OnSelectFurniture(self._IdList[1], self._ConfigId, self, code == 2)
    end
    
end

function XUiGridSGFurniture:CheckUnlock(tips)
    --已经解锁 || 本地照片
    if self._IsUnlock or self:IsAlbumPhoto() then
        return true
    end
    self._IsSelect = false
    self.PanelSelect.gameObject:SetActiveEx(false)
    if tips then
        local desc = self._Control:GetFurnitureLockDesc(self._ConfigId)
        if not string.IsNilOrEmpty(desc) then
            XUiManager.TipMsg(desc)
        end
    end
    return false
end

function XUiGridSGFurniture:GetConfigId()
    return self._ConfigId
end

function XUiGridSGFurniture:IsAlbumPhoto()
    return self._GridType == 2
end

return XUiGridSGFurniture