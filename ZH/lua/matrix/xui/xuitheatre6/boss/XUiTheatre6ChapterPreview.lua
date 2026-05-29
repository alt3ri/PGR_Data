---@class XUiTheatre6ChapterPreview : XLuaUi 报幕+Boss详情
---@field _Control XTheatre6Control
local XUiTheatre6ChapterPreview = XLuaUiManager.Register(XLuaUi, "UiTheatre6ChapterPreview")

function XUiTheatre6ChapterPreview:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
end

function XUiTheatre6ChapterPreview:OnStart()
    local stageNode = self._Control:GetCurStageNode()
    self._FloorId = stageNode.FloorId
    self._FloorConfig = self._Control:GetStageFloorConfig(self._FloorId)
    self._AnnoConfig = self._Control:GetAnnoConfig(self._FloorConfig.AnnoId)
end

function XUiTheatre6ChapterPreview:OnEnable()
    self.UiTxtChapterName.text = self._AnnoConfig.AnnoName
    self.UiTxtChapterNameNoBoss.text = self._AnnoConfig.AnnoName
    self.UiTxtDetail.text = self._AnnoConfig.AnnoDesc
    self.UiTxtDetailNoBoss.text = self._AnnoConfig.AnnoDesc

    local isShowBoss = self._AnnoConfig.IsShowBoss
    self.UiTxtChapterName.gameObject:SetActiveEx(isShowBoss)
    self.UiTxtChapterNameNoBoss.gameObject:SetActiveEx(not isShowBoss)
    self.UiTxtDetail.gameObject:SetActiveEx(isShowBoss)
    self.UiTxtDetailNoBoss.gameObject:SetActiveEx(not isShowBoss)
    self.PanelBossDetail.gameObject:SetActiveEx(isShowBoss)
    self.ListDetail.gameObject:SetActiveEx(isShowBoss)

    if isShowBoss then
        local modelData = self._Control:GetCurPlayModeData()
        local roomIdx = modelData.BossRoomDataDb.RoomIdx + 1
        local roomId = self._FloorConfig.RoomIds[roomIdx]
        
        ---@type XUiPanelTheatre6BossDetail
        self._PanelBossDetail = require("XUi/XUiTheatre6/Boss/Panel/XUiPanelTheatre6BossDetail").New(self.PanelBossDetail, self)
        self._PanelBossDetail:SetData(roomId, modelData.BossRoomDataDb.FightId)
    end
end

function XUiTheatre6ChapterPreview:OnBtnStartClick()
    self._Control:SetAnnoFinish()
    self._Control:MoveNext()
end

return XUiTheatre6ChapterPreview