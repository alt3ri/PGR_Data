---@class XUiPanelTheatre6BubbleAttr : XUiNode 属性气泡
---@field _Control XTheatre6Control
local XUiPanelTheatre6BubbleAttr = XClass(XUiNode, "XUiPanelTheatre6BubbleAttr")

function XUiPanelTheatre6BubbleAttr:OnStart()
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiPanelTheatre6BubbleAttr:SetAttrIds(attrIds)
    local count = #attrIds
    XUiHelper.RefreshCustomizedList(self.GridDetail.parent, self.GridDetail, count, function(index, go)
        local uiObject = {}
        local attrId = attrIds[index]
        local attrConfig = self._Control:GetAttrConfig(attrId)
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.UiImgIcon:SetRawImage(attrConfig.Icon)
        uiObject.UiTxtName.text = attrConfig.Name
        uiObject.UiTxtDesc.text = XUiHelper.ReplaceTextNewLine(attrConfig.Desc)
        uiObject.ImgLine.gameObject:SetActiveEx(index < count)
    end)
end

return XUiPanelTheatre6BubbleAttr
