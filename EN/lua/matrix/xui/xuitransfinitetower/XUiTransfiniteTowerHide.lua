---超限启航·词缀预览页（复用 UiFubenBossSingleHide 的词缀列表结构，去掉页签与信息页）
---@class XUiTransfiniteTowerHide : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field BtnClose XUiComponent.XUiButton
---@field TxtTitle UnityEngine.UI.Text
---@field PanelContent UnityEngine.RectTransform
---@field GridBuffDetails UnityEngine.RectTransform
local XUiTransfiniteTowerHide = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerHide")

function XUiTransfiniteTowerHide:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.GridBuffDetails.gameObject:SetActiveEx(false)
    self._TraitGrids = {}
end

---@param stageCfgId number 选中层配置id（展示该层全部词缀）
function XUiTransfiniteTowerHide:OnStart(stageCfgId)
    self._StageCfgId = stageCfgId
end

function XUiTransfiniteTowerHide:OnEnable()
    self:Refresh()
end

function XUiTransfiniteTowerHide:Refresh()
    self._Traits = self._Control:GetStageTraitList(self._StageCfgId)
    XUiHelper.RefreshUiObjectList(self._TraitGrids, self.PanelContent, self.GridBuffDetails.gameObject,
        #self._Traits, handler(self, self.RefreshTraitGrid))
end

function XUiTransfiniteTowerHide:RefreshTraitGrid(index, grid)
    local trait = self._Traits[index]
    local name = XUiHelper.TryGetComponent(grid.Transform, "TxtName", "Text")
    local desc = XUiHelper.TryGetComponent(grid.Transform, "TxtDesc", "Text")
    local icon = XUiHelper.TryGetComponent(grid.Transform, "RImgIcon", "RawImage")
    local bg = XUiHelper.TryGetComponent(grid.Transform, "ImgfTriangleBg", "Image")
    name.text = trait.Name
    desc.text = trait.Desc
    icon:SetRawImage(trait.Icon)
    if trait.TriangleBg then
        bg:SetSprite(trait.TriangleBg)
    end
end

return XUiTransfiniteTowerHide
