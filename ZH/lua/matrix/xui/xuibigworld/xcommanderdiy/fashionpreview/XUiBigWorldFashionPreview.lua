local PreviewGrid = require("XUi/XUiBigWorld/XCommanderDIY/FashionPreview/XUiBigWorldDIYPreviewGrid")
local XUiDIYCamHelper = require("XUi/XUiBigWorld/XCommanderDIY/FashionPreview/XUiDIYCamHelper")
local XUiBigWorldDIYModelHelper = require("XUi/XUiBigWorld/XCommanderDIY/XUiBigWorldDIYModelHelper")
local XUiGridList = require("XUi/XUiBigWorld/XCommanderDIY/FashionPreview/XUiGridList")
---@field _Control XBigWorldCommanderDIYControl
---@field UiModelGo UnityEngine.GameObject
---@field PanelDrag XDrag
---@field _CameraHelper XUiDIYCamHelper
---@field _ModelHelper XUiBigWorldDIYModelHelper
---@field ListColour UnityEngine.GameObject
---@field _GridList XUiGridList
---@class XUiBigWorldFashionPreview : XLuaUi
local XUiBigWorldFashionPreview = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldFashionPreview")
local congifKey = {
    [XEnumConst.PlayerFashion.Gender.Male] = "PreviewPartsMaleColor",
    [XEnumConst.PlayerFashion.Gender.Female] = "PreviewPartsFemaleColor"
}
function XUiBigWorldFashionPreview:OnAwake()
    self._CurrentSelectGender = self._Control:GetCurrentGender()
    self:InitComponents()
    ---@type XUiBigWorldDIYModelHelper
    self._ModelHelper = XUiBigWorldDIYModelHelper.New(self.UiModelGo, self.PanelDrag)
    self._CameraHelper = XUiDIYCamHelper.New(self._Control, self._ModelHelper, self.UiModelGo)
    self._CameraHelper:InitUI(self.SliderCharacter, self.BtnLensIn, self.BtnLensOut, self._CurrentSelectGender)
    self.GridColour.gameObject:SetActiveEx(false)
    self._GridList = XUiGridList.New(self.GridColour, self.ListColour, PreviewGrid, self,
        Handler(self, self.OnSelectColor))

    ---@type XBWCommanderDIYOutfitData
    self.outfitData = self._Control:CreateTemporaryWearDataMap()
    self.ColorData = {}
    self._ColorEntitysList = {}
    self._CurrentSelectColorData = nil
end

function XUiBigWorldFashionPreview:InitComponents()
    -- Button
    self:RegisterClickEvent(self.BtnLensIn, self.OnBtnLensInClick, true)
    self:RegisterClickEvent(self.BtnLensOut, self.OnBtnLensOutClick, true)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick, true)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeGenderClick, true)
    -- Slider
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderCharacter, self.OnSliderCharacterValueChanged, true)

end

-- 开始预览，初始化预览数据和UI
function XUiBigWorldFashionPreview:OnStart(previewId)
    self.PreviewId = previewId
    local previewConfigs = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPreviewConfigs(self.PreviewId)
    -- 强制读第一个作为 预览的PartId
    self.PartId = previewConfigs.PreviewParts[1]
    self.OutfitType = previewConfigs.OutfitType
    self:RefreshColorData()
    self:InitUI()
    self:InitModel()
end

-- 颜色选择回调：选中颜色后触发性别切换
function XUiBigWorldFashionPreview:OnSelectColor(index, isSelect, data)
    if isSelect then
        self._CurrentSelectColorData = data
        self:ChangeGender(self._CurrentSelectGender)
    end
end

function XUiBigWorldFashionPreview:OnDisable()
end

function XUiBigWorldFashionPreview:OnDestroy()
end

-- 初始化UI显示信息
function XUiBigWorldFashionPreview:InitUI()
    local partConfig = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPartConfigById(self.PartId)
    local partDesc = XMVCA.XBigWorldCommanderDIY:GetPartItemWorldDescription(self.PartId)
    self.BtnLensIn:SetButtonState(CS.UiButtonState.Normal)
    self.BtnLensOut:SetButtonState(CS.UiButtonState.Normal)
    self.UiTxtName.text = partConfig.GoodsName
    self.UiTxtDesc.text = partDesc

end

-- 初始化模型：默认选中第一个颜色
function XUiBigWorldFashionPreview:InitModel()
    if self.ColorData and #self.ColorData > 0 then
        local defaultSelectIndex = 1
        self._GridList:SetSelect(defaultSelectIndex, true)
    else
        self:ChangeGender(self._CurrentSelectGender)
    end
end

-- 刷新颜色数据：根据性别和部件获取可用颜色列表
function XUiBigWorldFashionPreview:RefreshColorData()
    local resId = self._Control:GetResIdByGender(self.PartId, self._CurrentSelectGender)
    local groupId = self._Control:GetDlcPlayerFashionResColorGroupIdById(resId)
    if XTool.IsNumberValid(groupId) then
        local previewConfigs = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPreviewConfigs(self.PreviewId)
        local forceColorIds = previewConfigs[congifKey[self._CurrentSelectGender]]
        local colorIds = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
        if not XTool.IsTableEmpty(forceColorIds) then
            -- 业务逻辑，有配置颜色的时候，只显示第一个颜色
            colorIds = {forceColorIds[1]}
        end
        table.clear(self.ColorData)
        for index, colorId in pairs(colorIds) do
            self._ColorEntitysList[index] = self._ColorEntitysList[index] or {}
            local entity = self._ColorEntitysList[index]
            local config = self._Control:GetDlcPlayerFashionColorConfigById(colorId)
            entity.Id = config.Id
            entity.Priority = config.Priority
            entity.GroupId = config.GroupId
            entity.Icon = config.Icon
            entity.MaterialName = config.MaterialName
            table.insert(self.ColorData, entity)
        end
    else
        table.clear(self.ColorData)
    end
    for _, entitys in pairs(self.ColorData) do
        table.sort(entitys, function(entityA, entityB)
            return entityA.Priority > entityB.Priority
        end)
    end
    self._GridList:Refresh(self.ColorData)
    self.PanelColour.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.ColorData))
end

function XUiBigWorldFashionPreview:OnBtnLensInClick()
    self._CameraHelper:ChangeBodyCamera(false)
end

function XUiBigWorldFashionPreview:OnBtnLensOutClick()
    self._CameraHelper:ChangeBodyCamera(true)
end

-- 性别切换按钮点击：切换性别并更新预览
function XUiBigWorldFashionPreview:OnBtnChangeGenderClick()
    self._CurrentSelectGender = self._CurrentSelectGender == XEnumConst.PlayerFashion.Gender.Male and
                                    XEnumConst.PlayerFashion.Gender.Female or XEnumConst.PlayerFashion.Gender.Male
    self:ChangeGender(self._CurrentSelectGender)
end

-- 获取相反性别
function XUiBigWorldFashionPreview:GetAnotherGender(gender)
    return gender == XEnumConst.PlayerFashion.Gender.Male and XEnumConst.PlayerFashion.Gender.Female or
               XEnumConst.PlayerFashion.Gender.Male
end

-- 性别切换主流程：刷新装备数据、颜色数据、模型和特效
function XUiBigWorldFashionPreview:ChangeGender(gender)
    self:RefreshOutfitData()
    self:RefreshColorData()
    self:_ChangeModel(gender)
    local isNearCamera = false
    self._CameraHelper:SetGender(gender)
    self._CameraHelper:ChangeBodyCamera(isNearCamera)
    self._ModelHelper:PlayEffect(gender)
end

-- 刷新装备数据：根据预览配置穿戴部件
function XUiBigWorldFashionPreview:RefreshOutfitData()
    local previewConfigs = XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionPreviewConfigs(self.PreviewId)
    local forceColorIds = previewConfigs[congifKey[self._CurrentSelectGender]]
    for i, partId in ipairs(previewConfigs.PreviewParts) do
        self.outfitData:WearPart(partId, forceColorIds[i])
    end
end

-- 模型切换核心流程：卸载旧模型、加载新模型、应用材质、切换相机
function XUiBigWorldFashionPreview:_ChangeModel(gender)
    local fashionPartId = self.outfitData:GetWearData(XEnumConst.PlayerFashion.PartType.Fashion):GetPartId()
    local fashionColor = XMVCA.XBigWorldCommanderDIY:GetCurrentDefaultColorIdByPartId(fashionPartId)
    self._ModelHelper:TryUnloadModel(self:GetAnotherGender(gender))
    self._ModelHelper:LoadFashionModel(fashionPartId, gender)
    self._ModelHelper:LoadMaterials(fashionColor, fashionPartId, gender):BindModelDragTarget(gender)
    for _, partType in pairs(XEnumConst.PlayerFashion.PartType) do
        local partId = self.outfitData:GetWearData(partType):GetPartId()
        if XTool.IsNumberValid(partId) and partType ~= XEnumConst.PlayerFashion.PartType.Fashion and partId ~=
            self.PartId then
            self:_RefreshTargetPartModel(partId, gender)
        end
    end
    self:_RefreshTargetPartModel(self.PartId, gender, self._CurrentSelectColorData and self._CurrentSelectColorData.Id)
    self._ModelHelper:PlayRotationTween(gender, self)
end

-- 刷新指定部件模型：加载部件模型和材质
function XUiBigWorldFashionPreview:_RefreshTargetPartModel(partId, gender, colorId)
    local resId = XMVCA.XBigWorldCommanderDIY:GetResIdByPartId(partId, gender)
    colorId = colorId or XMVCA.XBigWorldCommanderDIY:GetDlcPlayerFashionResDefaultColorIdById(resId)
    self._ModelHelper:LoadPartModel(partId, gender, XEnumConst.PlayerFashion.PartType.Fashion)
    self._ModelHelper:LoadMaterials(colorId, partId, gender)
end

function XUiBigWorldFashionPreview:OnSliderCharacterValueChanged(value)
    self._CameraHelper:MoveNearCamera(value * self._CameraHelper:GetCameraMoveRange())
end

function XUiBigWorldFashionPreview:OnBtnBackClick()
    self:Close()
end

return XUiBigWorldFashionPreview
