--- 技能替换确认弹窗
---@class XUiPBRPopupSkillReplace: XLuaUi
---@field protected _Control
local XUiPBRPopupSkillReplace = XLuaUiManager.Register(XLuaUi, "UiPBRPopupSkillReplace")
local XUiPBRShopNewDetailGridItem = require("XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewDetailGridItem")

--region Ui生命周期

function XUiPBRPopupSkillReplace:OnAwake()
    self.BtnCancel:AddEventListener(handler(self, self.Close))
    self.BtnSure:AddEventListener(handler(self, self.OnBtnSureClick))
end

function XUiPBRPopupSkillReplace:OnStart(oldItemId, newItemId, sureCb)
    self.SureCb = sureCb

    -- PanelDetailNew/Old 本身即商品结构根，直接复用商品格子（详情模式隐藏购买按钮/升阶提示）
    ---@type XUiPBRShopNewDetailGridItem
    self.NewDetail = XUiPBRShopNewDetailGridItem.New(self.PanelDetailNew, self, self)
    ---@type XUiPBRShopNewDetailGridItem
    self.OldDetail = XUiPBRShopNewDetailGridItem.New(self.PanelDetailOld, self, self)

    self.NewDetail:Refresh(newItemId, true)
    self.OldDetail:Refresh(oldItemId, true)
end

--endregion

function XUiPBRPopupSkillReplace:OnBtnSureClick()
    local cb = self.SureCb
    
    self:Close()

    if cb then
        cb()
    end
end

return XUiPBRPopupSkillReplace