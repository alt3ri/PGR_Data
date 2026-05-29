---@class XUiPanelTheatre6TopStage : XUiNode 房间顶部关卡面板
---@field _Control XTheatre6Control
local XUiPanelTheatre6TopStage = XClass(XUiNode, "XUiPanelTheatre6TopStage")

function XUiPanelTheatre6TopStage:OnStart()
    local modelData = self._Control:GetCurPlayModeData()
    local stageConfig = self._Control:GetStageConfig(modelData.StageId)
    self.UiTxtNum.text = string.format("%s/%s", modelData.CurFloorIdx + 1, #stageConfig.FloorIds)

    local floorId = stageConfig.FloorIds[modelData.CurFloorIdx + 1]
    local floorConfig = self._Control:GetStageFloorConfig(floorId)
    local roomIds = floorConfig.RoomIds
    local count = #roomIds

    self._FinalRoomId = roomIds[count]
    local finalRoomConfig = self._Control:GetStageRoomConfig(self._FinalRoomId)
    local isFinalBoss = finalRoomConfig.Type == XEnumConst.Theatre6.RoomType.Boss
    if isFinalBoss then
        ---@type XUiGridTheatre6StageIcon
        self._Boss = require("XUi/XUiTheatre6/Stage/Grid/XUiGridTheatre6StageIcon").New(self.GridBoss, self)
        self._Boss:SetRoomData(count, self._FinalRoomId)
        self._Boss:SetLineVisible(false)

        local btnBoss = self.GridBoss:GetComponent(typeof(CS.XUiComponent.XUiButton))
        btnBoss:AddEventListener(handler(self, self.OnBossClick))
    else
        self.GridBoss.gameObject:SetActiveEx(false)
    end

    local showListCount = isFinalBoss and count - 1 or count
    local roomData = self._Control:GetCurRoomData()
    local targetIndex = math.min(roomData.RoomIdx + 1, showListCount)
    local targetOffsetX = 0
    XUiHelper.RefreshCustomizedList(self.GridStage.parent, self.GridStage, showListCount, function(i, go)
        ---@type XUiGridTheatre6StageIcon
        local grid = require("XUi/XUiTheatre6/Stage/Grid/XUiGridTheatre6StageIcon").New(go, self)
        grid:SetRoomData(i, roomIds[i])
        grid:SetLineVisible(i < showListCount)
        
        local width = grid.Transform.rect.width
        if i < targetIndex then
            targetOffsetX = targetOffsetX + width + self.Layout.spacing
        end
    end)

    self:ScrollToCurRoom(showListCount, targetOffsetX)
end

---滚动到当前正在进行的房间位置
---@param showListCount number 显示的房间数量
---@param targetOffsetX number 目标房间节点在Content中的x偏移量
function XUiPanelTheatre6TopStage:ScrollToCurRoom(showListCount, targetOffsetX)
    if showListCount <= 1 then
        return
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)

    local contentWidth = self.Content.rect.width
    local viewportWidth = self.ListStage.viewport.rect.width
    local scrollableWidth = contentWidth - viewportWidth
    if scrollableWidth <= 0 then
        return
    end

    -- 将目标节点滚动到视口最左侧
    self.ListStage.horizontalNormalizedPosition = math.max(0, math.min(1, targetOffsetX / scrollableWidth))
end

function XUiPanelTheatre6TopStage:OnBossClick()
    local modelData = self._Control:GetCurPlayModeData()
    local finalFightId = modelData.BossRoomDataDb.LastFightId
    self._Control:OpenBossPreview(self._FinalRoomId, finalFightId)
end

return XUiPanelTheatre6TopStage
