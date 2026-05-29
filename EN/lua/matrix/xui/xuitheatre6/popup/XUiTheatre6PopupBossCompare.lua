---@class XUiTheatre6PopupBossCompare : XLuaUi Boss对比
---@field _Control XTheatre6Control
local XUiTheatre6PopupBossCompare = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupBossCompare")

function XUiTheatre6PopupBossCompare:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

function XUiTheatre6PopupBossCompare:OnStart(roomId, fightId, params, selectIndex)
    if roomId then
        local roomConfig = self._Control:GetStageRoomConfig(roomId)
        self._IsBoss = roomConfig.Type == XEnumConst.Theatre6.RoomType.Boss

        self._MonsterIds = {}
        self._MonsterIds[1] = self._Control:GetBossIdByRoom(fightId, false)
        if self._IsBoss then
            self._MonsterIds[2] = self._Control:GetBossIdByRoom(fightId, true) --小怪只有EasyMonster配置
        end
    elseif params then
        self._IsBoss = params.IsBoss
        self._MonsterIds = params.MonsterIds
    else
        XLog.Error("BOSS对比界面参数错误")
        return
    end
    self._SelectIndex = selectIndex or 1

    require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail").New(self.PanelRoleDetail, self)
    ---@type XUiPanelTheatre6BossAttrDetail
    self._BossDetail = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossAttrDetail").New(self.PanelBossDetail, self)
    ---@type XUiPanelTheatre6BubbleAttr
    self._AttrBubble = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleAttr").New(self.PanelAttributeDetail, self)
    self._AttrBubble:Close()
    ---@type XUiPanelTheatre6BubbleTag
    self._TagBubble = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BubbleTag").New(self.PanelTagDetail, self)
    self._TagBubble:Close()
end

function XUiTheatre6PopupBossCompare:OnEnable()
    self:InitTab()
end

function XUiTheatre6PopupBossCompare:InitTab()
    self.ListTab.gameObject:SetActiveEx(self._IsBoss)
    if self._IsBoss then
        self.ListTab:Init({ self.GridNormalTab, self.GridHardTab }, function(index)
            self._BossDetail:SetData(self._MonsterIds[index])
        end)
        self.ListTab:SelectIndex(self._SelectIndex)
    else
        self._BossDetail:SetData(self._MonsterIds[1])
    end
end

--XUiPanelTheatre6BossAttrDetail调用
function XUiTheatre6PopupBossCompare:OpenAttrBubble(attrIds)
    self._AttrBubble:Open()
    self._AttrBubble:SetAttrIds(attrIds)
end

return XUiTheatre6PopupBossCompare