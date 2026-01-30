---@class XUiBigWorldMenu : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldControl
local XUiBigWorldMenu = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMenu")

function XUiBigWorldMenu:OnAwake()
    XMVCA.XBigWorldUI:Remove("UiBigWorldTeachTips")
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldMenu:OnStart()
    self:InitView()
end

function XUiBigWorldMenu:OnEnable()
    self:RefreshRedPoint()
    self:RegisterListeners()
end

function XUiBigWorldMenu:OnDisable()
    self:RemoveListeners()
end

function XUiBigWorldMenu:OnDestroy()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_ON_BIG_WORLD_MENU_CLOSED)
end

function XUiBigWorldMenu:InitUi()
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()

    self.PanelMap = self.Transform:FindTransform("PanelMapList")

    if not XTool.UObjIsNil(self.PanelMap) then
        self.PanelMap.gameObject:SetActiveEx(XMVCA.XBigWorldMap:CheckLevelHasMap(levelId))
    end

    self.BtnSet.gameObject:SetActiveEx(true)
    self.BtnCamera.gameObject:SetActive(true)
end

function XUiBigWorldMenu:InitCb()
    self:AddUiButtonEvent(self.BtnTanchuangClose, handler(self, self.Close))
    self:AddUiButtonEvent(self.BtnExitGarden, handler(self, self.ExitGarden))
    self:AddUiButtonEvent(self.BtnHandbook, handler(self, self.OnBtnHandbookClick))
    self:AddUiButtonEvent(self.BtnStory, handler(self, self.OnBtnStoryClick))
    self:AddUiButtonEvent(self.BtnBackpack, handler(self, self.OnBtnBackpackClick))
    self:AddUiButtonEvent(self.BtnMessage, handler(self, self.OnBtnMessageClick))
    self:AddUiButtonEvent(self.BtnTeam, handler(self, self.OnBtnTeamClick))
    self:AddUiButtonEvent(self.BtnCamera, handler(self, self.OnBtnCameraClick))
    self:AddUiButtonEvent(self.BtnHelp, handler(self, self.OnBtnHelpClick))
    self:AddUiButtonEvent(self.BtnSet, handler(self, self.OnBtnSetClick))
    self:AddUiButtonEvent(self.BtnMap, handler(self, self.OnBtnMapClick))
end

function XUiBigWorldMenu:InitView()
end

function XUiBigWorldMenu:AddUiButtonEvent(btn, click)
    if not btn or not click then
        return
    end
    btn:AddEventListener(click)
end

function XUiBigWorldMenu:OnBtnHandbookClick()
    self._Control:OpenExplore()
end

function XUiBigWorldMenu:OnBtnStoryClick()
    self._Control:OpenQuest()
end

function XUiBigWorldMenu:OnBtnBackpackClick()
    self._Control:OpenBackpack()
end

function XUiBigWorldMenu:OnBtnMessageClick()
    self._Control:OpenMessage()
end

function XUiBigWorldMenu:OnBtnTeamClick()
    self._Control:OpenTeam()
end

function XUiBigWorldMenu:OnBtnCameraClick()
    local ctrl = self._Control
    self:Close()
    ctrl:OpenPhoto()
end

function XUiBigWorldMenu:OnBtnHelpClick()
    self._Control:OpenTeaching()
end

function XUiBigWorldMenu:OnBtnSetClick()
    self._Control:OpenSetting()
end

function XUiBigWorldMenu:OnBtnMapClick()
    self._Control:OpenMap()
end

function XUiBigWorldMenu:ExitGarden()
    XLuaUiManager.Remove(self.Name)
    XMVCA.XBigWorldGamePlay:ExitGame()
end

function XUiBigWorldMenu:RegisterListeners()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_UNLOCK, self.RefreshButtonHelpRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshQuestRedPoint, self)
end

function XUiBigWorldMenu:RemoveListeners()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_UNLOCK, self.RefreshButtonHelpRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshQuestRedPoint, self)
end

function XUiBigWorldMenu:RefreshRedPoint()
    self:RefreshButtonHelpRedPoint()
    self:RefreshQuestRedPoint()
end

function XUiBigWorldMenu:RefreshButtonHelpRedPoint()
    self.BtnHelp:ShowReddot(XMVCA.XBigWorldTeach:CheckHasUnReadTeach())
end

function XUiBigWorldMenu:RefreshQuestRedPoint()
    self.BtnStory:ShowReddot(XMVCA.XBigWorldQuest:CheckQuestRed())
end

return XUiBigWorldMenu
