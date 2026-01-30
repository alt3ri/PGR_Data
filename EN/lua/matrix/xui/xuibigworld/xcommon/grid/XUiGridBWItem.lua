local XUiGridBWGoodsBase = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWGoodsBase")

---@class XUiGridBWItem : XUiGridBWGoodsBase
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field TxtName UnityEngine.UI.Text
---@field PanelCount UnityEngine.RectTransform
---@field TxtCount UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field ImgQuality UnityEngine.UI.Image
---@field Lock UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field BtnClick UnityEngine.UI.Button
local XUiGridBWItem = XClass(XUiGridBWGoodsBase, "XUiGridBWItem")

local stringFormat = string.format

function XUiGridBWItem:OnStart(clickProxy)
    self._ClickProxy = clickProxy
    self:InitUi()
    self:InitCb()
end

function XUiGridBWItem:InitUi()
end

function XUiGridBWItem:InitCb()
    self:_RefreshClickHandler(self.BtnClick, self.OnClick)
end

function XUiGridBWItem:OnClick()

    if self._ClickProxy then
        self._ClickProxy(self._ItemsParams, self._GoodsParams)
        return
    end
    
    XMVCA.XBigWorldUI:OpenGoodsInfo(self._GoodsParams)
end

--- 兼容某些动态创建接口
--------------------------
function XUiGridBWItem:Update(data)
    self:Refresh(data)
end

function XUiGridBWItem:RefreshOther(data)
    self:_RefreshActive(self.PanelProgress, false)
    self:_RefreshActive(self.PanelSite, false)
end

function XUiGridBWItem:RefreshProgressNum(ownCount, targetCount, ownColor, targetColor)
    if XTool.UObjIsNil(self.PanelProgress) then
        return
    end
    self:_RefreshActive(self.PanelProgress, true)
    self.PanelProgress.gameObject:SetActiveEx(true)
    local strOwn, strTarget
    if ownColor then
        strOwn = stringFormat("<color=%s>%d</color>", ownColor, ownCount)
    else
        strOwn = ownCount
    end

    if targetColor then
        strTarget = stringFormat("<color=%s>/%d</color>", targetColor, targetCount)
    else
        strTarget = "/" .. targetCount
    end

    self:_RefreshText(self.TxtNumber, stringFormat("%s%s", strOwn, strTarget))
end

function XUiGridBWItem:IsAllowSkip()
    if self._ItemsParams then
        return self._ItemsParams.IsAllowSkip
    end

    return false
end

function XUiGridBWItem:SetClickProxy(clickProxy)
    self._ClickProxy = clickProxy
end

function XUiGridBWItem:_RefreshClickHandler(component, clickHandler)
    if XTool.UObjIsNil(component) then
        return
    end

    XUiHelper.RegisterCommonClickEvent(self, component, clickHandler)
end

return XUiGridBWItem
