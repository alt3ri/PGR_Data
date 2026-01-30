local XUiGridStage = require("XUi/XUiFubenMainLineChapter/XUiGridStage")

--- 特殊关卡
---@class XUiGridStageEx: XUiGridStage
local XUiGridStageEx = XClass(XUiGridStage, 'XUiGridStageEx')

---@overload
function XUiGridStageEx:OnBtnStageClick()
    XLuaUiManager.Open('UiMainLineExhibitionPopupComic', self.Stage)

    XUiGridStage.OnBtnStageClick(self)
end

---@overload
function XUiGridStageEx:Refresh()
    XUiGridStage.Refresh(self)

    if not self.Enabled then return end

    local component = self.Components["PanelStoryActive"]
    local go = component and (component.GameObject or component.gameObject)
    if not XTool.UObjIsNil(go) then
        if component.TxtStage then
            component.TxtStage.text = XMVCA.XMainLine2:GetClientConfigParams('NewbiePreChapterExStageName', 1)
        end
    end
end

return XUiGridStageEx