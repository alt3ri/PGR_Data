---@class XUiTheatre6RoomBoss : XLuaUi Boss/小怪房间
---@field _Control XTheatre6Control
local XUiTheatre6RoomBoss = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomBoss")

local DragAction = XEnumConst.Theatre6.DragAction
local Direction = XEnumConst.Theatre6.Direction

function XUiTheatre6RoomBoss:OnAwake()
    self:InitComponent()
    self.BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
end

function XUiTheatre6RoomBoss:OnStart()
    self._ModelData = self._Control:GetCurPlayModeData()
    self:InitData()
    self:ShowRoleInfo()
    self:InitDrag()
end

function XUiTheatre6RoomBoss:OnEnable()
    self._PanelAsset:Refresh()
    self._PanelBossDetail:SetData(self._RoomId, self._FightId)
    
    self._SelectMonsterIds = {}
    self._SelectMonsterIds[Direction.Left] = self._Control:GetBossIdByRoom(self._FightId, false)
    self._SelectMonsterIds[Direction.Right] = self._Control:GetBossIdByRoom(self._FightId, self._IsBoss)

    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
end

function XUiTheatre6RoomBoss:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
end

function XUiTheatre6RoomBoss:InitData()
    local roomData = self._Control:GetCurRoomData()
    local stageConfig = self._Control:GetStageConfig(self._ModelData.StageId)
    local floorConfig = self._Control:GetStageFloorConfig(stageConfig.FloorIds[self._ModelData.CurFloorIdx + 1])
    self._RoomId = floorConfig.RoomIds[roomData.RoomIdx + 1]
    self._IsBoss = roomData.RoomType == XEnumConst.Theatre6.RoomType.Boss --boss or 小怪
    self._FightId = roomData.FightId
end

function XUiTheatre6RoomBoss:ShowRoleInfo()
    self.BtnCharacter:SetRawImage(self._Control:GetHeadIcon())
    self.BtnCharacter:SetName(self._ModelData.ScoreTotal)
end

function XUiTheatre6RoomBoss:InitComponent()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopStage").New(self.PanelStage, self)
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BossDetail
    self._PanelBossDetail = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossDetail").New(self.PanelBossDetail, self)
    
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)
end

function XUiTheatre6RoomBoss:InitDrag()
    self.PanelTriggerBoss.gameObject:SetActiveEx(self._IsBoss)
    self.PanelTriggerLittleMonster.gameObject:SetActiveEx(not self._IsBoss)

    local triggerObj = {}
    XUiHelper.InitUiClass(triggerObj, self._IsBoss and self.PanelTriggerBoss or self.PanelTriggerLittleMonster)
    self.BtnLeft = triggerObj.BtnLeft
    self.BtnRight = triggerObj.BtnRight
    
    ---@type XUiPanelTheatre6Drag
    self._Drag = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Drag").New(self.UiPanelCard, self)
    self._Drag:RegistActionHandler(DragAction.EnterTargetArea, handler(self, self.OnEnterChooseArea))
    self._Drag:RegistActionHandler(DragAction.LeaveTargetArea, handler(self, self.OnLeaveChooseArea))
    self._Drag:RegistActionHandler(DragAction.End, handler(self, self.OnEndChoose))
    self._Drag:SetTargetSelf()
    self._Drag:SetConfirmDistance(self._Control:GetIntClientConfigValue("EitherorChooseDistance"))
    self._Drag:SetScene(self.Transform)
end

function XUiTheatre6RoomBoss:OnBtnCharacterClick()
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", self.BtnCharacter.transform)
end

function XUiTheatre6RoomBoss:OnEnterChooseArea(direction)
    self.BtnLeft:SetButtonState(direction == Direction.Left and XUiButtonState.Press or XUiButtonState.Normal)
    self.BtnRight:SetButtonState(direction == Direction.Right and XUiButtonState.Press or XUiButtonState.Normal)
end

function XUiTheatre6RoomBoss:OnLeaveChooseArea()
    self.BtnLeft:SetButtonState(XUiButtonState.Normal)
    self.BtnRight:SetButtonState(XUiButtonState.Normal)
end

function XUiTheatre6RoomBoss:OnEndChoose(direction)
    self:OnLeaveChooseArea()
    if not direction then
        return
    end

    --玩家在仓库中，存在同key且等级更高的技能
    if self._Control:ExistsHighLevelSkill() then
        self._Control:ShowPopup(XUiHelper.GetText("Theatre6FightHighSkillTip"), function()
            self:EnterFight(direction)
        end)
        return
    end

    --玩家存在空的技能槽，且仓库中存在与已装配技能不同key的技能
    if self._Control:CheckCanEquipSkill() then
        self._Control:ShowPopup(XUiHelper.GetText("Theatre6FightEquipSkillTip"), function()
            self:EnterFight(direction)
        end)
        return
    end

    self:EnterFight(direction)
end

function XUiTheatre6RoomBoss:EnterFight(direction)
    self._Control:RequestFightRoomSlide(direction, self._SelectMonsterIds[direction], function()
        XLuaUiManager.Open("UiTheatre6Loading")
    end)
end

return XUiTheatre6RoomBoss