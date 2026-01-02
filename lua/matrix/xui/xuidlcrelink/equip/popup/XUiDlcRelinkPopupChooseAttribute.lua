---@class XUiDlcRelinkPopupChooseAttribute : XLuaUi 选择装备属性弹框
---@field _Control XDlcRelinkControl
local XUiDlcRelinkPopupChooseAttribute = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupChooseAttribute")

function XUiDlcRelinkPopupChooseAttribute:OnAwake()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
end

function XUiDlcRelinkPopupChooseAttribute:OnStart(param)
    if not param then
        XLog.Error("传参错误.")
        return
    end
    
    ---@type XTableDlcRelinkFactorDesc[]
    local datas = {}
    for _, v in pairs(self._Control:GetFactorDescConfigs()) do
        table.insert(datas, v)
    end
    table.sort(datas, function(a, b)
        return a.Order < b.Order
    end)
    
    XUiHelper.RefreshCustomizedList(self.GridCharacteristic.parent, self.GridCharacteristic, #datas, function(i, go)
        local name = datas[i].Name
        local id = datas[i].Id
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.GridCharacteristic:SetName(name)
        uiObject.GridCharacteristic:AddEventListener(function()
            param.AttrId = id
            uiObject.GridCharacteristic:SetButtonState(XUiButtonState.Select)
            self:Close()
        end)
    end)
end

return XUiDlcRelinkPopupChooseAttribute