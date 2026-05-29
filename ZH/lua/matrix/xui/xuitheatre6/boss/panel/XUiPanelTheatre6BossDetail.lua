---@class XUiPanelTheatre6BossDetail : XUiNode Boss详情总面板
---@field _Control XTheatre6Control
---@field _PanelCard XUiPanelTheatre6BossCard Boss卡片面板
---@field _PanelLeft XUiPanelTheatre6BossDifficulty 左侧难度面板（普通）
---@field _PanelRight XUiPanelTheatre6BossDifficulty 右侧难度面板（困难）
local XUiPanelTheatre6BossDetail = XClass(XUiNode, "XUiPanelTheatre6BossDetail")

function XUiPanelTheatre6BossDetail:OnStart()
    self._PanelCard = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossCard").New(self.UiPanelCard, self)
    self._PanelLeft = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossDifficulty").New(self.PanelLeft, self)
    self._PanelRight = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossDifficulty").New(self.PanelRight, self)

    self.UiPanelMinion.gameObject:SetActiveEx(false)
    self.BtnView.gameObject:SetActiveEx(false)
    self.BtnView:AddEventListener(handler(self, self.OnBtnViewClick))
end

---设置Boss详情数据
---@param roomId number 房间Id
function XUiPanelTheatre6BossDetail:SetData(roomId, fightId)
    self._RoomId = roomId
    self._FightId = fightId
    self._PanelCard:SetData(fightId)

    local roomConfig = self._Control:GetStageRoomConfig(self._RoomId)
    local isBoss = roomConfig.Type == XEnumConst.Theatre6.RoomType.Boss
    self.UiPanelBoss.gameObject:SetActiveEx(isBoss)
    self._PanelLeft:SetVisible(isBoss)
    self._PanelRight:SetVisible(isBoss)
    self.UiPanelMinion.gameObject:SetActiveEx(not isBoss)
    self.BtnView.gameObject:SetActiveEx(not isBoss)

    if isBoss then
        self._PanelLeft:SetData(roomId, fightId, false)
        self._PanelRight:SetData(roomId, fightId, true)
    end
end

function XUiPanelTheatre6BossDetail:OnBtnViewClick()
    XLuaUiManager.Open("UiTheatre6PopupBossCompare", self._RoomId, self._FightId)
end

return XUiPanelTheatre6BossDetail
