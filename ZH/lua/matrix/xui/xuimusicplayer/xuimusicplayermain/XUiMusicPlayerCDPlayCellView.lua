--[[
-- XUiMusicPlayerCDPlayCellView.lua
-- 唱片格子：封面显示(4态) + 拖拽切换 + 限免时间
--]]

---@class XUiMusicPlayerCDPlayCellView : XUiNode
---@field _Control XMusicPlayerControl
---@field DragCdMain XGoInputHandler
---@field GoCDSelectLock UnityEngine.RectTransform
---@field GoCDSelect UnityEngine.RectTransform
---@field GoCDNotSelectLock UnityEngine.RectTransform
---@field GoCDNotSelect UnityEngine.RectTransform
---@field RImgCoverSelectLock UnityEngine.UI.RawImage
---@field RImgCoverSelect UnityEngine.UI.RawImage
---@field RImgCoverNotSelectLock UnityEngine.UI.RawImage
---@field RImgCoverNotSelect UnityEngine.UI.RawImage
---@field RImgMainCDImg UnityEngine.UI.RawImage
---@field GoMainCDLimitedTime UnityEngine.GameObject
---@field TxtLimitedTime UnityEngine.UI.Text
---@field RImgMusicGongxing UnityEngine.UI.RawImage
---@field RImgMusicHuan UnityEngine.ParticleSystem
---@field RImgMusicHuan02 UnityEngine.UI.RawImage
---@field RImgMusicHuan04 UnityEngine.ParticleSystem
---@field ParticelSanjiao UnityEngine.ParticleSystem
local XUiMusicPlayerCDPlayCellView = XClass(XUiNode, "XUiMusicPlayerCDPlayCellView")

function XUiMusicPlayerCDPlayCellView:InitComponents()
    self._CDDragStartPos = nil
    self._CDDragPointerId = nil
    self.DragCdMain:AddBeginDragListener(function(eventData) self:_OnCDBeginDrag(eventData) end)
    self.DragCdMain:AddEndDragListener(function(eventData) self:_OnCDEndDrag(eventData) end)
    self.DragCdMain:AddPointerClickListener(function(eventData) self:OnCDViewClick() end)
    self._AutoRotation = self.RImgCoverSelect:GetComponent(typeof(CS.AutoRotation_V2))
    if self.ParticelSanjiao then
        self._ParticleRenderer = self.ParticelSanjiao:GetComponent(typeof(CS.UnityEngine.ParticleSystemRenderer))
    end
    if self.RImgMusicHuan then
        self._ParticleRendererHuan = self.RImgMusicHuan:GetComponent(typeof(CS.UnityEngine.ParticleSystemRenderer))
    end
    if self.RImgMusicHuan04 then
        self._ParticleRendererHuan04 = self.RImgMusicHuan04:GetComponent(typeof(CS.UnityEngine.ParticleSystemRenderer))
    end
end

function XUiMusicPlayerCDPlayCellView:OnStart(...)
    self:InitComponents()
end

function XUiMusicPlayerCDPlayCellView:OnEnable()
    self:_SetEvent(true)
    self:_RefreshColorFX()
end

function XUiMusicPlayerCDPlayCellView:OnDisable()
    self:_SetEvent(false)
end

function XUiMusicPlayerCDPlayCellView:OnDestroy()
end

---region event
function XUiMusicPlayerCDPlayCellView:_SetEvent(flag)
    local XMusicPlayerEventId = XMVCA.XMusicPlayer.EventIds
    if flag then
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_PLAYER_MUSIC_CHANGE, self._OnCurPlayMusicChange, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_PLAYER_PLAY_STATE_CHANGE, self._OnPlayStateChange, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_VIEW_ZHEN_ENABLE_COMPLETE, self._OnZhenEnableComplete, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_VIEW_WILL_UPDATE_STATE, self._OnMainViewWillUpdateState, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_VIEW_UPDATE_STATE, self._OnMainViewStatusChange, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_CHANGE_UI_COLOR_STYLE, self._OnColorStyleChange, self)
        self._Control:AddEventListener(XMusicPlayerEventId.EVENT_COLOR_MATERIAL_LOADED, self._OnColorMaterialLoaded, self)
        if not self._LimitTimeTimerId then
            self._LimitTimeTimerId = XScheduleManager.ScheduleForever(function()
                self:_RefreshLimitTime(self._MusicID)
            end, 1000, 0)
        end
    else
        if self._LimitTimeTimerId then
            XScheduleManager.UnSchedule(self._LimitTimeTimerId)
            self._LimitTimeTimerId = nil
        end
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_PLAYER_MUSIC_CHANGE, self._OnCurPlayMusicChange, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_PLAYER_PLAY_STATE_CHANGE, self._OnPlayStateChange, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_VIEW_ZHEN_ENABLE_COMPLETE, self._OnZhenEnableComplete, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_VIEW_WILL_UPDATE_STATE, self._OnMainViewWillUpdateState, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_VIEW_UPDATE_STATE, self._OnMainViewStatusChange, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_CHANGE_UI_COLOR_STYLE, self._OnColorStyleChange, self)
        self._Control:RemoveEventListener(XMusicPlayerEventId.EVENT_COLOR_MATERIAL_LOADED, self._OnColorMaterialLoaded, self)
    end
end

function XUiMusicPlayerCDPlayCellView:_OnCurPlayMusicChange()
    self:_RefreachRotateStatus()
    if self._MusicID then
        self:Refresh(self._MusicID)
    end
    self:_InImmerseHideNoPlayCD()
end

function XUiMusicPlayerCDPlayCellView:_OnZhenEnableComplete()
    local cdControl = self._Control:GetCDPlayerControl()
    local isSelect = cdControl:GetCurPlayingMusicID() == self._MusicID
    self:_RefreachRotateStatus()
end

function XUiMusicPlayerCDPlayCellView:_OnPlayStateChange(isPlaying)
    self:_RefreachRotateStatus()
end

--- WILL: 状态变更前, cell先播退出动画
function XUiMusicPlayerCDPlayCellView:_OnMainViewWillUpdateState(lastStatus, targetStatus)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if self:_IsCurSelect() then
        if lastStatus == XMusicPlayerEnum.MusicMainUIStatus.immerse
            and targetStatus ~= XMusicPlayerEnum.MusicMainUIStatus.immersePro then
            self:PlayAnimation("Disable")
        end
    end
end

--- DID: 状态变更后, cell播进入动画
function XUiMusicPlayerCDPlayCellView:_OnMainViewStatusChange(lastStatus, curStatus)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum

    if self:_IsCurSelect() then
        if curStatus == XMusicPlayerEnum.MusicMainUIStatus.immerse
            and lastStatus ~= XMusicPlayerEnum.MusicMainUIStatus.immersePro then
            self:PlayAnimation("Enable")
        end
    end

    self:_InImmerseHideNoPlayCD()

end

function XUiMusicPlayerCDPlayCellView:_OnColorStyleChange()
    self:_RefreshColorFX()
end

function XUiMusicPlayerCDPlayCellView:_OnColorMaterialLoaded()
    self:_RefreshColorFX()
end
---endregion

---region ui event
function XUiMusicPlayerCDPlayCellView:_OnCDBeginDrag(eventData)
    if self:_IsInCDListExpandStatus() then return end
    if not eventData then return end
    self._CDDragPointerId = eventData.pointerId
    self._CDDragStartPos = eventData.position
end

function XUiMusicPlayerCDPlayCellView:_OnCDEndDrag(eventData)
    if self:_IsInCDListExpandStatus() then
        self._CDDragStartPos = nil
        self._CDDragPointerId = nil
        return
    end

    local startPos = self._CDDragStartPos
    local pointerId = self._CDDragPointerId
    self._CDDragStartPos = nil
    self._CDDragPointerId = nil

    if not startPos or not eventData or not eventData.position then
        return
    end

    if pointerId ~= nil and eventData.pointerId ~= pointerId then
        return
    end

    local deltaX = eventData.position.x - startPos.x
    local deltaY = eventData.position.y - startPos.y
    local absX = math.abs(deltaX)
    local absY = math.abs(deltaY)

    local minDistance = 50
    local ratio = 2.0
    if absX < minDistance then
        return
    end
    if absY > absX * ratio then
        return
    end

    if deltaX < 0 then
        self:_OnDragRight()
    else
        self:_OnDragLeft()
    end
end

function XUiMusicPlayerCDPlayCellView:OnCDViewClick()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if self:_IsInCDListExpandStatus() then
        self._Control:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_VIEW_CALL_SWITCH_STATE, XMusicPlayerEnum.MusicMainUIStatus.mainCD)
        return
    end
    self._Control:SetJumpAlbumCollectionClickMusicID(self._MusicID)
    self._Control:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_VIEW_CALL_SWITCH_STATE, XMusicPlayerEnum.MusicMainUIStatus.CDListExpand)
end
---endregion

---由动态列表回调，传入索引和父View
function XUiMusicPlayerCDPlayCellView:UpdateCDCellData(index, parentView)
    self._ParentView = parentView
    self._Index = index
    local rawList = parentView._Control:GetCDPlayerControl():GetCurRawMusicIdList()
    self._MusicID = rawList and rawList[index]
    self:Refresh(self._MusicID)
end

function XUiMusicPlayerCDPlayCellView:Refresh(musicID)
    self._MusicID = musicID
    if self._MusicID  == nil then return end
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local cdControl = self._Control:GetCDPlayerControl()
    local co = self._Control:GetMusicPlayerconfigControl():GetMusicPlayerAlbumCOByid(musicID)
    if not co then
        return
    end

    self:_OnColorStyleChange()

    local curMusicStatus = cdControl:GetMusicUseStatusAndConditionDesc(musicID)
    local isSelect = cdControl:GetCurPlayingMusicID() == musicID
    local isLock = curMusicStatus == XMusicPlayerEnum.MusicUseStatus.unlock

    self.GoCDSelectLock.gameObject:SetActive(false)
    self.GoCDSelect.gameObject:SetActive(false)
    self.GoCDNotSelectLock.gameObject:SetActive(false)
    self.GoCDNotSelect.gameObject:SetActive(false)

    if isSelect and isLock then
        self.GoCDSelectLock.gameObject:SetActive(true)
        if self.RImgCoverSelectLock then
            self.RImgCoverSelectLock:SetRawImage(co.Cover)
        end
    elseif isSelect then
        self.GoCDSelect.gameObject:SetActive(true)
        self.RImgCoverSelect:SetRawImage(co.Cover)
    elseif isLock then
        self.GoCDNotSelectLock.gameObject:SetActive(true)
        self.RImgCoverNotSelectLock:SetRawImage(co.Cover)
    else
        self.GoCDNotSelect.gameObject:SetActive(true)
        self.RImgCoverNotSelect:SetRawImage(co.Cover)
    end

    self:_InImmerseHideNoPlayCD() --沉浸模式只显示一个CD
    local curStatus = self:_GetMusicPlayerUIStatus()
    if curStatus == XMusicPlayerEnum.MusicMainUIStatus.immerse or curStatus == XMusicPlayerEnum.MusicMainUIStatus.immersePro then
         -- self:ForceSkipToEndAnimation("Default")
        self:ForceSkipToEndAnimation("Chengjin")
    else
        self:PlayAnimation("Default")
    end

    
    XScheduleManager.ScheduleOnce(function()
        self:_InImmerseHideNoPlayCD()
    end, 0)

    self:_RefreachRotateStatus() 
    self:_RefreshLimitTime(musicID)
end

function XUiMusicPlayerCDPlayCellView:_RefreshLimitTime(musicID)
    if not XTool.IsNumberValid(musicID) then
        return
    end
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local cdControl = self._Control:GetCDPlayerControl()
    local useStatus = cdControl:GetMusicUseStatusAndConditionDesc(musicID)

    if useStatus == XMusicPlayerEnum.MusicUseStatus.limitedFree then
        local co = self._Control:GetMusicPlayerconfigControl():GetMusicPlayerAlbumCOByid(musicID)
        self.GoMainCDLimitedTime.gameObject:SetActive(true)
        self.TxtLimitedTime.text = cdControl:GetTimeIdLeftStr(co.ExperienceTimeId)
    else
        self.GoMainCDLimitedTime.gameObject:SetActive(false)
    end
end

function XUiMusicPlayerCDPlayCellView:_IsInCDListExpandStatus()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    return self:_GetMusicPlayerUIStatus() == XMusicPlayerEnum.MusicMainUIStatus.musicList
end

function XUiMusicPlayerCDPlayCellView:_GetMusicPlayerUIStatus()
    return self._ParentView:GetMusicPlayerUIStatus()
end

function XUiMusicPlayerCDPlayCellView:_OnDragLeft()
    self._ParentView:OnCDSwipe(false)
end

function XUiMusicPlayerCDPlayCellView:_OnDragRight()
    self._ParentView:OnCDSwipe(true)
end


function XUiMusicPlayerCDPlayCellView:_ISInImmerse()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local curStatus = self:_GetMusicPlayerUIStatus()
    return curStatus == XMusicPlayerEnum.MusicMainUIStatus.immerse
        or curStatus == XMusicPlayerEnum.MusicMainUIStatus.immersePro
end


function XUiMusicPlayerCDPlayCellView:_InImmerseHideNoPlayCD()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local cdControl = self._Control:GetCDPlayerControl()
    local isSelect = cdControl:GetCurPlayingMusicID() == self._MusicID

    if self:_ISInImmerse() then
        if isSelect then
            self.GameObject:SetActive(true)
        else
            self.GameObject:SetActive(false)
        end
    else
        self.GameObject:SetActive(true)
    end
end

function XUiMusicPlayerCDPlayCellView:_IsCurSelect()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local cdControl = self._Control:GetCDPlayerControl()
    local isSelect = cdControl:GetCurPlayingMusicID() == self._MusicID
    return  isSelect
end

function XUiMusicPlayerCDPlayCellView:_RefreachRotateStatus()
    local needRotate = self:_IsCurSelect() and self._Control:GetCDAutoRotateEnabled()
    self._AutoRotation.enabled = needRotate
end


function XUiMusicPlayerCDPlayCellView:_RefreshColorFX()
    local UiMaterialKey = XMVCA.XMusicPlayer.Enum.UiMaterialKey

    local mat = self._Control:GetCurColorMat(UiMaterialKey.MusicGongxing)
    if mat and self.RImgMusicGongxing then
        self.RImgMusicGongxing.material = mat
    end

    mat = self._Control:GetCurColorMat(UiMaterialKey.MusicHuan)
    if mat and self._ParticleRendererHuan then
        self._ParticleRendererHuan.sharedMaterial = mat
    end

    mat = self._Control:GetCurColorMat(UiMaterialKey.MusicHuan02)
    if mat and self.RImgMusicHuan02 then
        self.RImgMusicHuan02.material = mat
    end

    mat = self._Control:GetCurColorMat(UiMaterialKey.MusicHuan04)
    if mat and self._ParticleRendererHuan04 then
        self._ParticleRendererHuan04.sharedMaterial = mat
    end

    mat = self._Control:GetCurColorMat(UiMaterialKey.Sanjiao2)
    if mat and self._ParticleRenderer then
        self._ParticleRenderer.sharedMaterial = mat
    end
end


return XUiMusicPlayerCDPlayCellView
