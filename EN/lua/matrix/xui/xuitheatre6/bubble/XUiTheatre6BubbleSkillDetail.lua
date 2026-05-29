---@class XUiTheatre6BubbleSkillDetail : XLuaUi 技能气泡弹框
---@field _Control XTheatre6Control
local XUiTheatre6BubbleSkillDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6BubbleSkillDetail")

function XUiTheatre6BubbleSkillDetail:OnAwake()
    self.BubbleSkillDetail.gameObject:SetActiveEx(true)
    ---@type XUiPanelTheatre6SkillDetail
    self._SkillDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6SkillDetail").New(
    self.BubbleSkillDetail, self)
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6BubbleSkillDetail:OnStart(skillId, target, param, avoidTransforms)
    self._SkillId = skillId
    self._SkillDetail:Refresh(skillId, param)
    self.InShop = param and param.IsInShop
    XUiHelper.ShowBubbleToTarget(self.PanelBubble, target, self.Transform, avoidTransforms)
end

function XUiTheatre6BubbleSkillDetail:OnEnable()
    if self.InShop then
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SKILL_BUBBLE_OPEN, self._SkillId)
    end
end

function XUiTheatre6BubbleSkillDetail:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_SKILL_BUBBLE_CLOSE)
    if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
        XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
    end
end

return XUiTheatre6BubbleSkillDetail
