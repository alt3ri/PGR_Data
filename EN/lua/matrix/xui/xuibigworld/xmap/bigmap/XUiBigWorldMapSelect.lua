---@class XUiBigWorldMapSelect : XUiNode
---@field PanelImgSelect UnityEngine.RectTransform
---@field Options XUiButtonGroup
---@field BtnOption XUiComponent.XUiButton
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapSelect = XClass(XUiNode, "XUiBigWorldMapSelect")

function XUiBigWorldMapSelect:OnStart()
    self._LevelId = 0
    ---@type XBWMapPinData[]
    self._PinDatas = {}

    self._OptionCache = {}
    
    self._TransformBind = self.PanelImgSelect.gameObject:GetComponent(typeof(CS.XTransformBind))
    if not self._TransformBind then
        self._TransformBind = self.PanelImgSelect.gameObject:AddComponent(typeof(CS.XTransformBind))
    end

    self:_InitUi()
end

function XUiBigWorldMapSelect:OnDisable()
    if self._TransformBind then
        self._TransformBind:SetTarget(nil)
    end
end

function XUiBigWorldMapSelect:OnOptionClick(index)
    local pinData = self._PinDatas[index]

    if pinData then
        self.Parent:OpenSelectPinDetail(self._LevelId, pinData)
    end
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:Refresh(levelId, pinDatas, target)
    self._PinDatas = pinDatas
    self._LevelId = levelId
    self:_RefreshOptions(pinDatas)
    self:_RefreshPosition(target)
end

---@param pinDatas XBWMapPinData[]
function XUiBigWorldMapSelect:_RefreshOptions(pinDatas)
    local optionList = {}

    if not XTool.IsTableEmpty(pinDatas) then
        for i, pinData in pairs(pinDatas) do
            local option = self._OptionCache[i]
            local briefIcon = self._Control:GetPinBriefIconByStyleId(pinData.StyleId)

            if not option then
                option = XUiHelper.Instantiate(self.BtnOption, self.Options.transform)
                self._OptionCache[i] = option
            end

            if not string.IsNilOrEmpty(briefIcon) then
                option:SetSprite(briefIcon)
            end

            option.gameObject:SetActiveEx(true)
            option:SetNameByGroup(0, pinData.Name)
            table.insert(optionList, option)
        end
    end
    for i = #optionList + 1, #self._OptionCache do
        local option = self._OptionCache[i]

        option.gameObject:SetActiveEx(false)
    end

    self.Options:Init(optionList, Handler(self, self.OnOptionClick))
    self.Options:CancelSelect()

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Options.transform)
end

function XUiBigWorldMapSelect:_RefreshPosition(target)
    if self._TransformBind then
        self._TransformBind:SetTarget(target)
    end
    local x, y, z = target.transform:GetPosition()
    self.Transform:SetPosition(x, y, z)
    self:_RefreshRing()
end

function XUiBigWorldMapSelect:_RefreshRing(position)
    local axisConversion = self.Parent:GetAxisConversion()
    local distance = self._Control:GetNearDistance()
    local width = axisConversion:ScreenToUIDistance(self.Transform, distance, 1920)

    if self.Ring then
        self.Ring:SetUISizeDelta(width, width)
    end
end

function XUiBigWorldMapSelect:_InitUi()
    self.Ring = self.Transform:FindTransform("Ring")
    self.BtnOption.gameObject:SetActiveEx(false)
    self.Options.transform:SetParent(self.PanelImgSelect)
end

return XUiBigWorldMapSelect
