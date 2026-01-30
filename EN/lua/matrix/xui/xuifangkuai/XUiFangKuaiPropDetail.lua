---@class XUiFangKuaiPropDetail : XLuaUi 大方块道具详情弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiPropDetail = XLuaUiManager.Register(XLuaUi, "UiFangKuaiPropDetail")

function XUiFangKuaiPropDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCloseDetail, self.Close)
end

function XUiFangKuaiPropDetail:OnStart(stageId)
    local blockTypes = self._Control:GetArchieveByBlockTypes(stageId)
    XUiHelper.RefreshCustomizedList(self.GridFangKuai.parent, self.GridFangKuai, #blockTypes, function(index, go)
        local uiObject = {}
        local config = blockTypes[index]
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgIcon:SetRawImage(config.Icon)
        uiObject.TxtTitle.text = config.Name
        uiObject.TxtDesc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
    end)
end

return XUiFangKuaiPropDetail