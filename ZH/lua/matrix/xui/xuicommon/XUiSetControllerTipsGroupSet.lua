-- 通用关卡词缀列表项控件
local XUiSetControllerTipsGroupSet = XClass(XUiNode, "XUiSetControllerTipsGroupSet")

function XUiSetControllerTipsGroupSet:Update(data, i)
    self.ImgControllerIcon:SetSprite(data.Icon)
    self.Label.text = data.Name
end

return XUiSetControllerTipsGroupSet
