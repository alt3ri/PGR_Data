---@class XUiTheatre6PopupRoleDetail : XLuaUi 角色详情弹窗
---@field _Control XTheatre6Control
local XUiTheatre6PopupRoleDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupRoleDetail")

function XUiTheatre6PopupRoleDetail:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

---@param data table 可选，传入存档数据则展示存档详情，不传则展示当前战斗状态
---@param taskUpgradeSkillIds table<number, true> 可选,RoomChooseTask 入口透传的可升级 SkillId 集合
function XUiTheatre6PopupRoleDetail:OnStart(target, data, taskUpgradeSkillIds)
    require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail").New(self.PanelRoleDetail, self, data, nil, nil, taskUpgradeSkillIds)
    ---@type XUiPanelTheatre6BubbleAttr
    self._AttrBubble = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleAttr").New(self.BubbleAttributeDetail, self)
    self._AttrBubble:Close()
    ---@type XUiPanelTheatre6SkillDetail
    self._SkillDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6SkillDetail").New(self.BubbleSkillDetail, self)
    self._SkillDetail:Close()
end

function XUiTheatre6PopupRoleDetail:OpenAttrBubble(attrIds)
    self._AttrBubble:Open()
    self._AttrBubble:SetAttrIds(attrIds)
end

function XUiTheatre6PopupRoleDetail:OnDisable()

end

function XUiTheatre6PopupRoleDetail:OnDestroy()

end

return XUiTheatre6PopupRoleDetail