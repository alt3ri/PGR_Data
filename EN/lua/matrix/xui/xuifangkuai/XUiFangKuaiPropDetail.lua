---@class XUiFangKuaiPropDetail : XLuaUi 大方块道具详情弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiPropDetail = XLuaUiManager.Register(XLuaUi, "UiFangKuaiPropDetail")

function XUiFangKuaiPropDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCloseDetail, self.Close)
end

function XUiFangKuaiPropDetail:OnStart(stageId, propDetailType)
    self._StageId = stageId
    if propDetailType == XEnumConst.FangKuai.PropDetail.Block then
        self:ShowBlockDetail()
    elseif propDetailType == XEnumConst.FangKuai.PropDetail.Item then
        self:ShowItemDetail()
    end
    self.TxtTitle.text = self._Control:GetClientConfig("PropDetailTitle", propDetailType)
end

function XUiFangKuaiPropDetail:ShowBlockDetail()
    local blockTypes = self._Control:GetArchieveByBlockTypes(self._StageId)
    XUiHelper.RefreshCustomizedList(self.GridFangKuai.parent, self.GridFangKuai, #blockTypes, function(index, go)
        local uiObject = {}
        local config = blockTypes[index]
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgIcon:SetRawImage(config.Icon)
        uiObject.TxtTitle.text = config.Name
        uiObject.TxtDesc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
    end)
end

function XUiFangKuaiPropDetail:ShowItemDetail()
    local showItems = self._Control:GetStageConfig(self._StageId).ShowItem
    XUiHelper.RefreshCustomizedList(self.GridFangKuai.parent, self.GridFangKuai, #showItems, function(index, go)
        local uiObject = {}
        local config = self._Control:GetItemConfig(showItems[index])
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgIcon:SetRawImage(config.Icon)
        uiObject.TxtTitle.text = config.Name
        uiObject.TxtDesc.text = XUiHelper.ReplaceTextNewLine(config.Desc)
    end)
end

return XUiFangKuaiPropDetail