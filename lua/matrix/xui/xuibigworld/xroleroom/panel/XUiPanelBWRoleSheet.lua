local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridBWRoleTeam : XUiNode
---@field Parent XUiPanelBWRoleSheet
local XUiGridBWRoleTeam = XClass(XUiNode, "XUiGridBWRoleTeam")

local FullTeamEntityCount = XMVCA.XBigWorldCharacter:GetFullTeamEntityCount()
local Delay = 80

function XUiGridBWRoleTeam:OnStart()
    self.BtnCharacter:AddEventListener(handler(self, self.OnClickBtnRole))
    self._CanvasGroup = self.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
end

function XUiGridBWRoleTeam:Refresh(characterId, pos)
    self._Id = characterId
    self._Pos = pos
    local agency = XMVCA.XBigWorldCharacter
    self.RImgHeadIcon:SetRawImage(agency:GetSquareHeadIcon(characterId))
    self.TxtName.text = agency:GetCharacterName(characterId)
    local showPos = pos > 0
    self.PanelOrder.gameObject:SetActiveEx(showPos)
    if showPos then
        self.TxtOrder.text = pos
    end
    self._IsSelect = showPos
    self.PanelInTeam.gameObject:SetActiveEx(showPos)
    if self.UiBigWorldPanelStory then
        local isTrial = XMVCA.XBigWorldCharacter:CheckCharacterTrial(characterId)
        self.UiBigWorldPanelStory.gameObject:SetActiveEx(isTrial)
    end
end

function XUiGridBWRoleTeam:OnClickBtnRole()
    local team = self.Parent:GetDlcTeam()
    if not team then
        return
    end
    local select = not self._IsSelect
    local pos = 0
    -- 操作：选中
    if select then
        pos = team:GetFirstEmptyPos()
        --正常编队-还未满员
        if pos > FullTeamEntityCount then
            XMVCA.XBigWorldService:TipText("TeamFullText")
            return
        end
        team:AddLast(self._Id, true)
    else
        if self._Pos > 0 then
            -- 操作：取消选中
            pos = team:UpdateTeamByPos(self._Pos, 0)
            self._IsSelect = select
        end
    end
    self.Parent:SetupDynamicTableOnlyRefresh()
end

function XUiGridBWRoleTeam:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiGridBWRoleTeam:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = 0
    end
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        self:PlayAnimation("CharacterGridEnable")
        self:StopAnimationTimer()
    end, (index - 1) * Delay)
end

---@class XUiPanelBWRoleSheet : XUiNode 快捷编队
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldRoleRoom
local XUiPanelBWRoleSheet = XClass(XUiNode, "XUiPanelBWRoleSheet")

function XUiPanelBWRoleSheet:OnStart()
    local itemSize = self.PlayerInfoCharacterGrid.rect
    local parentSize = self.PlayerInfoCharacterGrid.parent.parent.rect
    local spaceX = 20
    local spaceY = 20
    self.ColCount = math.floor(parentSize.width / (itemSize.width + spaceX))
    self.RowCount = math.ceil(parentSize.height / (itemSize.height + spaceY))
    self.MaxCount = self.ColCount * self.RowCount
        
    self:InitCb()
    self:InitView()
end

function XUiPanelBWRoleSheet:OnEnable(...)
    self:PlayAnimationWithMask("PlayerInfoBaseNewEnable")
end

function XUiPanelBWRoleSheet:OnDisable()
    self._IsPlayed = false
end

function XUiPanelBWRoleSheet:Close()
    self:PlayAnimationWithMask("PlayerInfoBaseNewDisable", function()
        XUiNode.Close(self)
    end)
end

function XUiPanelBWRoleSheet:InitCb()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiPanelBWRoleSheet:InitView()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self._DynamicTable:SetProxy(XUiGridBWRoleTeam, self)
    self._DynamicTable:SetDelegate(self)

    self.PlayerInfoCharacterGrid.gameObject:SetActiveEx(false)
end

function XUiPanelBWRoleSheet:RefreshView(teamId)
    self._TeamId = teamId
    self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(teamId)
    self._DataList = XMVCA.XBigWorldCharacter:SortTeamList(teamId, true)
    self:SetupDynamicTable()
end

function XUiPanelBWRoleSheet:SetupDynamicTable()
    local isEmpty = XTool.IsTableEmpty(self._DataList)
    self.PanelCharacterNone.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end

    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(1)
end

function XUiPanelBWRoleSheet:SetupDynamicTableOnlyRefresh()
    local grids = self._DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        local entityId = self._DataList[index]
        local pos = self._Team:GetEntityPos(entityId)
        grid:Refresh(entityId, pos)
    end
end

function XUiPanelBWRoleSheet:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entityId = self._DataList[index]
        local pos = self._Team:GetEntityPos(entityId)
        grid:Refresh(entityId, pos)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayEnableAnimation()
    end
end

---@return XBWTeam
function XUiPanelBWRoleSheet:GetDlcTeam()
    if not self._Team then
        self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    end
    return self._Team
end

function XUiPanelBWRoleSheet:OnBtnConfirmClick()
    XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, function()
        self:SetupDynamicTable()
        self.Parent:OnBtnDetailClicked()
    end)
end

function XUiPanelBWRoleSheet:PlayEnableAnimation()
    if self._IsPlayed then
        return
    end
    
    local allUseGird = self._DynamicTable:GetGrids()
    for index, grid in pairs(allUseGird) do
        if index <= self.MaxCount then
            local col = math.ceil(index / self.ColCount)
            local row = (index - 1) % self.ColCount + 1
            grid:PlayEnableAnimation(col + row - 1)
        else
            grid:PlayEnableAnimation(1)
        end
    end
    self._IsPlayed = true
end

return XUiPanelBWRoleSheet