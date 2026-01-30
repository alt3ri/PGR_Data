
---@class XUiBigWorldProcessExploreRegion : XUiNode
---@field PanelComplete UnityEngine.RectTransform
---@field TxtRegionName UnityEngine.UI.Text
---@field ImgRegion UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field ImgLock UnityEngine.UI.Image
---@field BtnRegion XUiComponent.XUiButton
---@field Parent XUiBigWorldProcessExploreGrid
local XUiBigWorldProcessExploreRegion = XClass(XUiNode, "XUiBigWorldProcessExploreRegion")

function XUiBigWorldProcessExploreRegion:OnStart()
    ---@type XBWCourseExplorePOIEntity
    self._Entity = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessExploreRegion:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessExploreRegion:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessExploreRegion:OnDestroy()
end

function XUiBigWorldProcessExploreRegion:OnBtnRegionClick()
    if self._Entity then
        local skipId = self._Entity:GetSkipId()

        if XTool.IsNumberValid(skipId) then
            XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
        end
    end
end

---@param poiEntity XBWCourseExplorePOIEntity
function XUiBigWorldProcessExploreRegion:Refresh(poiEntity)
    self._Entity = poiEntity
    self.PanelComplete.gameObject:SetActiveEx(poiEntity:IsComplete())
    self.ImgLock.gameObject:SetActiveEx(poiEntity:IsLock())
    self.TxtRegionName.text = poiEntity:GetName()
    self.ImgRegion:SetImage(poiEntity:GetIcon())
    self.TxtNum.text = poiEntity:GetProgressText()
end

function XUiBigWorldProcessExploreRegion:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnRegion:AddEventListener(handler(self, self.OnBtnRegionClick))
end

function XUiBigWorldProcessExploreRegion:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessExploreRegion:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessExploreRegion:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessExploreRegion:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessExploreRegion:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiBigWorldProcessExploreRegion
