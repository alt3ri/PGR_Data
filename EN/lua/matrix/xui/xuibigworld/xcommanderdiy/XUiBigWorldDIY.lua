local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldDIYModelHelper = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYModelHelper")
local XUiBigWorldDIYGridPosition = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYGridPosition")
local XUiBigWorldDIYGridColour = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYGridColour")
local XUiBigWorldDIYPreview = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYPreview")

---@class XUiBigWorldDIY : XBigWorldUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnFashion XUiComponent.XUiButton
---@field BtnHeadPortrait XUiComponent.XUiButton
---@field PanelTabGroup XUiButtonGroup
---@field BtnResetting XUiComponent.XUiButton
---@field BtnSave XUiComponent.XUiButton
---@field BtnEyes XUiComponent.XUiButton
---@field BtnHand XUiComponent.XUiButton
---@field ListPosition UnityEngine.RectTransform
---@field GridPosition UnityEngine.RectTransform
---@field PanelColour UnityEngine.RectTransform
---@field ListColour UnityEngine.RectTransform
---@field GridColour UnityEngine.RectTransform
---@field PanelGender UnityEngine.RectTransform
---@field TxtName UnityEngine.UI.Text
---@field BtnSelectMan XUiComponent.XUiButton
---@field BtnSelectWoman XUiComponent.XUiButton
---@field PanelComponent UnityEngine.RectTransform
---@field PanelPreviewPopup UnityEngine.RectTransform
---@field BtnChange XUiComponent.XUiButton
---@field BtnLensIn XUiComponent.XUiButton
---@field BtnLensOut XUiComponent.XUiButton
---@field BtnPreviewClose XUiComponent.XUiButton
---@field SliderCharacter UnityEngine.UI.Slider
---@field PanelDrag XDrag
---@field _Control XBigWorldCommanderDIYControl
local XUiBigWorldDIY = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldDIY")

-- region 生命周期

function XUiBigWorldDIY:OnAwake()
    local itemSize = self.GridPosition.rect
    local parentSize = self.GridPosition.parent.parent.rect

    local spaceX = 40
    local spaceY = 70
    self.ColCount = math.floor(parentSize.width / (itemSize.width + spaceX))
    self.RowCount = math.ceil(parentSize.height / (itemSize.height + spaceY))
    self.MaxCount = self.ColCount * self.RowCount

    ---@type XBWCommanderDIYTypeEntity[]
    self._TypeEntitys = self._Control:GetTypeEntitys()
    self._TabGroupList = { self.BtnFashion, self.BtnHeadPortrait, self.BtnEyes, self.BtnHand }

    ---@type XDynamicTableNormal
    self._PartDynamicTable = XDynamicTableNormal.New(self.ListPosition)
    self._CurrentSelectTypeIndex = 0
    self._CurrentSelectPartIndex = 0
    ---@type XBWCommanderDIYColorEntity[]
    self._CurrentColorEntitys = false

    ---@type XUiBigWorldDIYGridColour
    self._CurrentSelectColorGrid = false
    ---@type XUiBigWorldDIYGridColour[]
    self._ColorGridList = {}

    ---@type XUiBigWorldDIYModelHelper
    self._ModelHelper = XUiBigWorldDIYModelHelper.New(self.UiModelGo, self.PanelDrag)

    self._IsInit = false
    self._IsFrist = false

    self._IsPlayPreviewEnable = false
    self._IsPlayPreviewDisable = false

    self._CameraMoveRange = self._Control:GetCameraMoveRange()

    ---@type XUiBigWorldDIYPreview
    self._PreviewUi = XUiBigWorldDIYPreview.New(self.PanelPreviewPopup, self)

    self:_InitUi()
    self:_RegisterButtonClicks()
    self._Control:TemporaryFashionInfo()
end

function XUiBigWorldDIY:OnStart()
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self:_InitFirstPanel()
    self:_ShowPanel()
    self:ClosePreview()
end

function XUiBigWorldDIY:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIY:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIY:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_UI_BIG_WORLD_DIY_DESTROY)
end

-- endregion

function XUiBigWorldDIY:ChangeSelect(index, isIncompatible)
    if self._CurrentSelectPartIndex then
        ---@type XUiBigWorldDIYGridPosition
        local selectGrid = self._PartDynamicTable:GetGridByIndex(self._CurrentSelectPartIndex)

        if selectGrid then
            selectGrid:SetSelect(false, false)
        end
    end

    self:ChangeSelectPart(index, isIncompatible)
end

function XUiBigWorldDIY:ChangeSelectPart(index, isIncompatible)
    if index ~= self._CurrentSelectPartIndex then
        self:_ChangeSelectPart(index, self._CurrentSelectPartIndex, isIncompatible)
        self._CurrentSelectPartIndex = index
        self:_PlayCurrentEffect()
        self:ClosePreview()
    end
end

---@param entity XBWCommanderDIYColorEntity
function XUiBigWorldDIY:ChangeSelectColor(grid, entity)
    if self._CurrentSelectColorGrid then
        self._CurrentSelectColorGrid:SetSelect(false)
    end

    local gender = self._Control:GetCurrentGender()

    self._CurrentSelectColorGrid = grid
    self._ModelHelper:ChangeMaterials(gender, entity)
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIY:ShowColor(entity, isPlayEnable)
    local isShowColor = entity:IsAllowSelectColor()

    if isShowColor then
        self._CurrentColorEntitys = entity:GetColorEntitys()
        self.PanelColour.gameObject:SetActiveEx(true)
        self:_RefreshColorList(isPlayEnable)
    else
        self:_HideColorPanel()
    end
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIY:OpenPreview(entity)
    if entity and entity:IsPreview() and not entity:IsUnlock() then
        self:_PlayPreviewEnable(function()
            self._PreviewUi:Open()
            self._PreviewUi:Refresh(entity)
            self.BtnPreviewClose.gameObject:SetActiveEx(true)
        end)
    end
end

function XUiBigWorldDIY:ClosePreview()
    self:_PlayPreviewDisable(function()
        self._PreviewUi:Close()
        self.BtnPreviewClose.gameObject:SetActiveEx(false)
    end)
end

function XUiBigWorldDIY:RefreshTabRedDot(typeId)
    if not XTool.IsTableEmpty(self._TypeEntitys) then
        for i, entity in pairs(self._TypeEntitys) do
            if entity:GetTypeId() == typeId then
                local tab = self._TabGroupList[i]

                if tab then
                    tab:ShowReddot(entity:IsNew())
                end

                break
            end
        end
    end
end

-- region 按钮事件

function XUiBigWorldDIY:OnBtnBackClick()
    if self._Control:CheckNeedSyncInfo() then
        local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

        confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYConfirmTips"))
        confirmData:InitToggleActive(false)
        confirmData:InitCancelClick(nil, function()
            self._Control:ResetCommanderFashion()
            self:Close()
        end)
        confirmData:InitSureClick(nil, function()
            self._Control:TrySaveFashionInfo(Handler(self, self.Close))
        end)
        XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
    else
        self:Close()
    end
end

function XUiBigWorldDIY:OnBtnResettingClick()
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYResettingTips"))
    confirmData:InitToggleActive(false)
    confirmData:InitSureClick(nil, function()
        self._Control:ResetCommanderFashion()
        self._ModelHelper:Release()
        self:_LoadCurrentModel()
        self:_RefreshTabGroup()
        self:_PlayResettingAction()
    end)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XUiBigWorldDIY:OnBtnSaveClick()
    if self._IsFrist then
        self._Control:TryOpenPreviewSavePopup(function()
            self:_TryOpenPerspectiveUi(function()
                local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

                confirmData:InitInfo(nil, XMVCA.XBigWorldService:GetText("DIYConfirmTips"))
                confirmData:InitToggleActive(false)
                confirmData:InitSureClick(nil, function()
                    self._Control:SaveFashionInfo(Handler(self, self.Close))
                end)
                XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
            end)
        end)
    else
        self._Control:TrySaveFashionInfo(function()
            self:_ReloadCurrentModel()
            self:_RefreshTabGroup()
        end)
    end
end

function XUiBigWorldDIY:OnBtnSelectManClick()
    local maleEnum = XEnumConst.PlayerFashion.Gender.Male
    self._Control:SetInitDiy(true)
    self:_ChangeModel(maleEnum)
    self:_ShowPanel()
    self._ModelHelper:PlayStandAnimation(maleEnum)
end

function XUiBigWorldDIY:OnBtnSelectWomanClick()
    local femaleEnum = XEnumConst.PlayerFashion.Gender.Female
    self._Control:SetInitDiy(true)
    self:_ChangeModel(femaleEnum)
    self:_ShowPanel()
    self._ModelHelper:PlayStandAnimation(femaleEnum)
end

function XUiBigWorldDIY:OnBtnChangeClick()
    local gender = self._Control:GetCurrentValidGender()

    if gender == XEnumConst.PlayerFashion.Gender.Male then
        self:_ChangeSex(XEnumConst.PlayerFashion.Gender.Female)
    else
        self:_ChangeSex(XEnumConst.PlayerFashion.Gender.Male)
    end
end

function XUiBigWorldDIY:OnBtnLensInClick()
    self:_ChangeBodyCamera(false)
end

function XUiBigWorldDIY:OnBtnLensOutClick()
    self:_ChangeBodyCamera(true)
end

function XUiBigWorldDIY:OnBtnPreviewCloseClick()
    self:ClosePreview()
end

function XUiBigWorldDIY:OnSliderCharacterChange(value)
    local offset = value * self._CameraMoveRange

    self:_MoveNearCamera(offset)
end

function XUiBigWorldDIY:OnTabGroupClick(index)
    self:_RefreshPartList(index)
    self:_ChangeTypeCamera(index)
    self:_RefreshTabRedDots()
end

---@param grid XUiBigWorldDIYGridPosition
function XUiBigWorldDIY:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._PartDynamicTable:GetData(index)

        grid:Refresh(entity, index)
        if self._Control:CheckAnyPartEntityIsUse(entity) then
            self._CurrentSelectPartIndex = index
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayEnableAnimation()
    end
end

function XUiBigWorldDIY:PlayEnableAnimation()
    if not self:IsPlayAnimationsOneByOne() then
        return
    end
    self._LastPlayIndex = self._CurrentSelectTypeIndex
    local allUseGird = self._PartDynamicTable:GetGrids()
    for index, grid in pairs(allUseGird) do
        if index <= self.MaxCount then
            local col = math.ceil(index / self.ColCount)
            local row = (index - 1) % self.ColCount + 1
            grid:PlayEnableAnimation(col + row - 1)
        else
            grid:PlayEnableAnimation(1)
        end
    end
end

function XUiBigWorldDIY:IsPlayAnimationsOneByOne()
    return self._CurrentSelectTypeIndex ~= self._LastPlayIndex
end

-- endregion

-- region 私有方法

function XUiBigWorldDIY:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnResetting, self.OnBtnResettingClick, true)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick, true)
    self:RegisterClickEvent(self.BtnSelectMan, self.OnBtnSelectManClick, true)
    self:RegisterClickEvent(self.BtnSelectWoman, self.OnBtnSelectWomanClick, true)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick, true)
    self:RegisterClickEvent(self.BtnLensIn, self.OnBtnLensInClick, true)
    self:RegisterClickEvent(self.BtnLensOut, self.OnBtnLensOutClick, true)
    self:RegisterClickEvent(self.BtnPreviewClose, self.OnBtnPreviewCloseClick, true)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacter, self.OnSliderCharacterChange, true)
    self.PanelTabGroup:Init(self._TabGroupList, Handler(self, self.OnTabGroupClick))
end

function XUiBigWorldDIY:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIY:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIY:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIY:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIY:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldDIY:_InitUi()
    self.GridPosition.gameObject:SetActiveEx(false)
    self.GridColour.gameObject:SetActiveEx(false)
    self.SliderCharacter.gameObject:SetActiveEx(false)
end

function XUiBigWorldDIY:_InitTypeTab()
    if not XTool.IsTableEmpty(self._TypeEntitys) then
        for i, tab in pairs(self._TabGroupList) do
            local entity = self._TypeEntitys[i]

            if entity and not entity:IsNil() and not entity:IsSuit() then
                tab:SetNameByGroup(0, entity:GetName())
            end
        end
    end

    self.PanelTabGroup:SelectIndex(1)
end

function XUiBigWorldDIY:_InitSexGroup()
    local gender = self._Control:GetCurrentValidGender()

    self:_ChangeSex(gender)
end

function XUiBigWorldDIY:_InitDynamicTable()
    self._PartDynamicTable:SetDelegate(self)
    self._PartDynamicTable:SetProxy(XUiBigWorldDIYGridPosition, self)
end

function XUiBigWorldDIY:_InitComponent()
    self:_InitTypeTab()
    self:_InitSexGroup()
    self:_InitDynamicTable()
    self._IsInit = true
end

function XUiBigWorldDIY:_InitFirstPanel()
    if not self._Control:CheckIsInitDIY() then
        self._IsFrist = true
        self.BtnBack.gameObject:SetActiveEx(false)
        self.BtnResetting.gameObject:SetActiveEx(false)
        self.BtnSave:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("DIYFirstConfirmText"))
    else
        self._IsFrist = false
        self.BtnBack.gameObject:SetActiveEx(true)
        self.BtnResetting.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldDIY:_MoveNearCamera(offset)
    self._ModelHelper:MoveNearCamera(self._Control:GetCurrentValidGender(), offset)
end

function XUiBigWorldDIY:_ShowPanel()
    if self._Control:CheckIsInitDIY() then
        self:_ShowComponentPanel()
        self:_LoadCurrentModel()
    else
        self:_ShowGenderPanel()
        self:_LoadAllModel()
    end
end

function XUiBigWorldDIY:_ShowGenderPanel()
    self.PanelComponent.gameObject:SetActiveEx(false)
    self.PanelGender.gameObject:SetActiveEx(true)
    self:_ChangeCamera("Main")
end

function XUiBigWorldDIY:_ShowComponentPanel()
    self.PanelComponent.gameObject:SetActiveEx(true)
    self.PanelGender.gameObject:SetActiveEx(false)
    self:_InitComponent()
end

function XUiBigWorldDIY:_HideColorPanel()
    self._CurrentColorEntitys = false
    self:_RefreshColorList(false)
    self.PanelColour.gameObject:SetActiveEx(false)
end

function XUiBigWorldDIY:_ChangeSex(index)
    self:_ChangeTypeCamera(self._CurrentSelectTypeIndex)
    if index == XEnumConst.PlayerFashion.Gender.Male then
        self:_ChangeModel(XEnumConst.PlayerFashion.Gender.Male)
    else
        self:_ChangeModel(XEnumConst.PlayerFashion.Gender.Female)
    end
    self:_RefreshComponentPanel()
    self:_PlayCurrentEffect()
end

function XUiBigWorldDIY:_RefreshTabGroup()
    local currentIndex = self._CurrentSelectTypeIndex or 1

    self._CurrentSelectTypeIndex = 0
    self.PanelTabGroup:SelectIndex(currentIndex)
end

function XUiBigWorldDIY:_RefreshComponentPanel()
    if self._IsInit then
        self:_RefreshTabGroup()
    end
end

function XUiBigWorldDIY:_RefreshPartList(index)
    if self._CurrentSelectTypeIndex ~= index then
        local entity = self._TypeEntitys[index]

        self:ClosePreview()
        self:_RefreshAnimation(entity:GetTypeId())
        self:_PlayDragRotationTween()
        if entity and not entity:IsNil() then
            local entitys = entity:GetDisplayPartEntitys()

            if XTool.IsTableEmpty(entitys) then
                self:_HideColorPanel()
            end
            self._CurrentSelectTypeIndex = index
            self._CurrentSelectPartIndex = 0
            self._PartDynamicTable:SetDataSource(entitys)
            self._PartDynamicTable:ReloadDataSync()
        end
    end
end

function XUiBigWorldDIY:_RefreshCurrentPartList()
    ---@type XUiBigWorldDIYGridPosition[]
    local grids = self._PartDynamicTable:GetGrids()

    for _, grid in pairs(grids) do
        grid:RefreshCurrent()
    end
end

function XUiBigWorldDIY:_RefreshAnimation(typeId, gender)
    local entryAnimation = self._Control:GetEntryAnimationNameByType(typeId)

    gender = gender or self._Control:GetCurrentValidGender()
    self._ModelHelper:PlayChangePartAnimation(gender, entryAnimation, typeId)
end

function XUiBigWorldDIY:_RefreshTabRedDots()
    if not XTool.IsTableEmpty(self._TypeEntitys) then
        for i, tab in pairs(self._TabGroupList) do
            local entity = self._TypeEntitys[i]

            if entity then
                tab:ShowReddot(entity:IsNew())
            end
        end
    end
end

function XUiBigWorldDIY:_RefreshColorList(isPlayEnable)
    if not XTool.IsTableEmpty(self._CurrentColorEntitys) then
        for i, entity in pairs(self._CurrentColorEntitys) do
            local grid = self._ColorGridList[i]

            if not grid then
                local gridObject = XUiHelper.Instantiate(self.GridColour, self.ListColour)

                grid = XUiBigWorldDIYGridColour.New(gridObject, self)
                self._ColorGridList[i] = grid
            end

            if self._Control:CheckColorEntityIsUse(entity) then
                self._CurrentSelectColorGrid = grid
            end

            grid:Open()
            grid:Refresh(entity)
            if isPlayEnable then
                grid:PlayEnableAnimation(i - 1)
            end
        end
        for i = table.nums(self._CurrentColorEntitys) + 1, table.nums(self._ColorGridList) do
            self._ColorGridList[i]:Close()
        end
    else
        for _, grid in pairs(self._ColorGridList) do
            grid:Close()
        end
    end
end

function XUiBigWorldDIY:_ChangeModel(gender, entitys)
    entitys = entitys or self._Control:GetUsePartEntitys()
    self._Control:ChangeGender(gender)
    self._ModelHelper:ChangeModel(gender, entitys, true)
    self:_PlayChangeSexAction(gender)
end

function XUiBigWorldDIY:_ChangeCamera(key)
    self._ModelHelper:ChangeCamera(key)
end

function XUiBigWorldDIY:_ChangeTypeCamera(typeId)
    if typeId == XEnumConst.PlayerFashion.PartType.Fashion then
        self:_ChangeBodyCamera(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Eyes then
        self:_ChangeCamera(self:_GetCurrentEyesCameraKey())
        self:_ChangeLensActive(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Hair then
        self:_ChangeCamera(self:_GetCurrentHairCameraKey())
        self:_ChangeLensActive(false)
    elseif typeId == XEnumConst.PlayerFashion.PartType.Hand then
        self:_ChangeCamera(self:_GetCurrentHandCameraKey())
        self:_ChangeLensActive(false)
    end
end

function XUiBigWorldDIY:_ChangeBodyCamera(isIn)
    if isIn then
        self:_ChangeCamera(self:_GetCurrentNearBodyCameraKey())
        self:_ChangeCameraLens(true)
    else
        self:_ChangeCamera(self:_GetCurrentBodyCameraKey())
        self:_ChangeCameraLens(false)
    end
    self.SliderCharacter.gameObject:SetActiveEx(isIn)
end

function XUiBigWorldDIY:_ChangeCameraLens(isIn)
    self.BtnLensOut.gameObject:SetActiveEx(not isIn)
    self.BtnLensIn.gameObject:SetActiveEx(isIn)

    if isIn then
        self.SliderCharacter.value = 0
    end
end

function XUiBigWorldDIY:_ChangeLensActive(isActive)
    self.BtnLensOut.gameObject:SetActiveEx(isActive)
    self.BtnLensIn.gameObject:SetActiveEx(isActive)
    self.SliderCharacter.gameObject:SetActiveEx(isActive)
end

function XUiBigWorldDIY:_GetCurrentBodyCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManBody"
    end

    return "WomanBody"
end

function XUiBigWorldDIY:_GetCurrentHairCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManHair"
    end

    return "WomanHair"
end

function XUiBigWorldDIY:_GetCurrentEyesCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManEyes"
    end

    return "WomanEyes"
end

function XUiBigWorldDIY:_GetCurrentHandCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManHand"
    end

    return "WomanHand"
end

function XUiBigWorldDIY:_GetCurrentNearBodyCameraKey()
    if self._Control:CheckCurrentMaleGender() then
        return "ManNearBody"
    end

    return "WomanNearBody"
end

function XUiBigWorldDIY:_LoadCurrentModel()
    self:_TryLoadModel(self._Control:GetCurrentGender())
end

function XUiBigWorldDIY:_LoadAllModel()
    local entitys = self._Control:GetUsePartEntitys()

    self:_TryLoadModel(XEnumConst.PlayerFashion.Gender.Male, entitys)
    self:_TryLoadModel(XEnumConst.PlayerFashion.Gender.Female, entitys)
end

function XUiBigWorldDIY:_ReloadCurrentModel()
    local entitys = self._Control:GetUsePartEntitys()
    local gender = self._Control:GetCurrentGender()

    self._ModelHelper:ChangeModel(gender, entitys, true)
    self._ModelHelper:PlayResettingAnimation(gender)
end

function XUiBigWorldDIY:_ChangeSelectPart(selectIndex, oldSelectIndex, isIncompatible)
    ---@type XBWCommanderDIYPartEntity
    local entity = self._PartDynamicTable:GetData(selectIndex)

    if entity then
        if entity:IsTemporary() then
            local wearEntity = self._Control:GetUsePartEntityByTypeId(entity:GetTypeId())

            if wearEntity and not wearEntity:IsNil() then
                local gender = self._Control:GetCurrentGender()

                self._ModelHelper:ChangePartModel(gender, wearEntity, XEnumConst.PlayerFashion.PartType.Fashion)
            else
                self._ModelHelper:UnloadPartModel(self._Control:GetCurrentValidGender(), entity:GetTypeId())
            end
        elseif not entity:IsNil() then
            local gender = self._Control:GetCurrentGender()

            if entity:IsFashion() or entity:IsSuit() or isIncompatible then
                local entitys = self._Control:GetUsePartEntitys()

                self._ModelHelper:ChangeModel(gender, entitys, true)
                self:_RefreshCurrentPartList()
                self:_RefreshAnimation(entity:GetTypeId(), gender)
            else
                self._ModelHelper:ChangePartModel(gender, entity, XEnumConst.PlayerFashion.PartType.Fashion)
            end
        end
    end
end

---@param entitys XBWCommanderDIYPartEntity[]
function XUiBigWorldDIY:_TryLoadModel(gender, entitys)
    entitys = entitys or self._Control:GetUsePartEntitys()

    self._ModelHelper:LoadModel(gender, entitys)
    self._ModelHelper:PlayAppearAnimation(gender)
end

function XUiBigWorldDIY:_GetCurrentModelId()
    local entity = self._Control:GetUseFashionPartEntity()

    if entity then
        return entity:GetFashionModelId()
    end

    return ""
end

function XUiBigWorldDIY:_PlayCurrentEffect()
    self._ModelHelper:PlayEffect(self._Control:GetCurrentValidGender())
end

function XUiBigWorldDIY:_PlayResettingAction()
    self._ModelHelper:PlayResettingAnimation(self._Control:GetCurrentValidGender())
end

function XUiBigWorldDIY:_PlayChangeSexAction(gender)
    self._ModelHelper:PlayChangeSexAnimation(gender)
end

function XUiBigWorldDIY:_PlayDragRotationTween()
    self._ModelHelper:PlayRotationTween(self._Control:GetCurrentValidGender(), self)
end

function XUiBigWorldDIY:_TryOpenPerspectiveUi(confirmCb)
    if not self._IsFrist then
        if confirmCb then confirmCb() end
        return false
    end
    if not XMVCA.XBigWorldCommanderDIY:IsFromOpenGuide() then
        if confirmCb then confirmCb() end
        return false
    end
    XMVCA.XBigWorldUI:OpenPerspectiveUi(XMVCA.XBigWorldGamePlay:GetCurrentLevelId(), true, nil, confirmCb)
end

function XUiBigWorldDIY:_PlayPreviewEnable(callback)
    if not self._IsPlayPreviewEnable then
        self._IsPlayPreviewEnable = true

        if self._IsPlayPreviewDisable then
            self._IsPlayPreviewDisable = false
            self:StopAnimation("PreviewPopupDisable", false, true)
        end

        if callback then
            callback()
        end

        self:PlayAnimation("PreviewPopupEnable", function()
            self._IsPlayPreviewEnable = false
        end)
    else
        if callback then
            callback()
        end
    end
end

function XUiBigWorldDIY:_PlayPreviewDisable(callback)
    if not self._IsPlayPreviewDisable then
        self._IsPlayPreviewDisable = true

        if self._IsPlayPreviewEnable then
            self._IsPlayPreviewEnable = false
            self:StopAnimation("PreviewPopupEnable", false, true)
        end

        self:PlayAnimation("PreviewPopupDisable", function()
            self._IsPlayPreviewDisable = false

            if callback then
                callback()
            end
        end)
    else
        if callback then
            callback()
        end
    end
end

-- endregion

return XUiBigWorldDIY
