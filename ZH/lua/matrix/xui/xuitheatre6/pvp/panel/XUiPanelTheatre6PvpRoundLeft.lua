---@class XUiPanelTheatre6PvpRoundLeft : XUiNode 肉鸽6Pvp战斗结算左侧面板
---@field _Control XTheatre6Control
local XUiPanelTheatre6PvpRoundLeft = XClass(XUiNode, "XUiPanelTheatre6PvpRoundLeft")

local XUiGridTheatre6RoundData = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6RoundData")
local SHOW_TYPE = XEnumConst.Theatre6.SHOW_TYPE

function XUiPanelTheatre6PvpRoundLeft:OnStart()
    self._ShowType = SHOW_TYPE.MyRole
    self._AttributeGrids = {}
    self._DataGrids = {}
    self.BtnSwitchBoss:AddEventListener(handler(self, self.OnBtnSwitchBossClick))
    self.BtnSwitchRole:AddEventListener(handler(self, self.OnBtnSwitchRoleClick))
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridData.gameObject:SetActiveEx(false)

    self:CheckChooseFightHideHealth()
end

---@param fightResult XTheatre6PvpFightResult
function XUiPanelTheatre6PvpRoundLeft:Refresh(fightResult)
    self._IsWin = fightResult.IsFinalWin
    self._BattleData = self._Control:GetPvpTinyBattleState()
    self._EnemySaveFiles = self._Control:GetEnemySaveFiles(self._BattleData.EnemyData)
    self:RefreshResult()
end

function XUiPanelTheatre6PvpRoundLeft:CheckChooseFightHideHealth()
    self.RImgHeartIcon.gameObject:SetActiveEx(false)
    self.TxtHeartReduce.gameObject:SetActiveEx(false)
    self.TxtHeartRight.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6PvpRoundLeft:UpdateRoundData(i)
    local fileDataList = self._Control:GetPvpCurrentLineupFileDataList(XEnumConst.Theatre6.Pvp.LineupMode.Attack)
    local summaryDatas = self._Control:GetSummaryData()

    --XTheatre6Record
    self._SummaryData = summaryDatas[i]
    ---@type Theatre6FileData
    self._FileData = fileDataList[i]
    ---@type Theatre6FileData
    self._EnemyData = self._EnemySaveFiles[i]

    self:UpdateView()
end

function XUiPanelTheatre6PvpRoundLeft:UpdateView()
    self._CurFileData = self._ShowType == SHOW_TYPE.MyRole and self._FileData or self._EnemyData
    self._CurRoleRecord = self._ShowType == SHOW_TYPE.MyRole and self._SummaryData.SelfRecord or self._SummaryData.EnemyRecord
    
    self:RefreshRoleInfo()
    self:RefreshAttribute()
    self:RefreshDataList()
end

function XUiPanelTheatre6PvpRoundLeft:RefreshResult()
    self.TxtWin.gameObject:SetActiveEx(self._IsWin)
    self.TxtLose.gameObject:SetActiveEx(not self._IsWin)
end

function XUiPanelTheatre6PvpRoundLeft:RefreshRoleInfo()
    local isMyRole = self._ShowType == SHOW_TYPE.MyRole
    local icon = self._Control:GetFashionConfig(self._CurFileData.FashionId).Portrait
    local score = self._CurFileData.Score

    self.RImgBgMe.gameObject:SetActiveEx(isMyRole)
    self.RImgBgEnemy.gameObject:SetActiveEx(not isMyRole)
    self.PanelMyRole.gameObject:SetActiveEx(isMyRole)
    self.PanelEnemyRole.gameObject:SetActiveEx(not isMyRole)
    self.BtnSwitchBoss.gameObject:SetActiveEx(isMyRole)
    self.BtnSwitchRole.gameObject:SetActiveEx(not isMyRole)

    if isMyRole then
        self.RoleSelf:SetRawImage(icon)
        self.TxtMyRate.text = score
    else
        self.RoleEnemy:SetRawImage(icon)
        self.TxtEnemyRate.text = score
    end
end

function XUiPanelTheatre6PvpRoundLeft:RefreshAttribute()
    local attribValues = {}
    local attrConfigs = self._Control:GetShowAttrConfigs()

    for _, data in ipairs(self._CurFileData.Attrs) do
        attribValues[data.AttrId] = data.Value
    end

    self._AttributeGrids = XUiHelper.RefreshUiObjectList(self._AttributeGrids, self.GridAttribute.parent, self.GridAttribute, #attrConfigs, function(i, grid)
        local attrConfig = attrConfigs[i]
        grid.RImgIcon:SetRawImage(attrConfig.Icon)
        grid.TxtNum.text = attribValues[attrConfig.Id] or 0
    end)
end

function XUiPanelTheatre6PvpRoundLeft:RefreshDataList()
    local damageList = self._Control:GetPvpRoundSettlementDamageList(self._CurRoleRecord, true)
    if XTool.IsTableEmpty(damageList) then
        self._Control:SetPvpRoundSettlementEmptyDamage(damageList, self._CurFileData)
    end
    self.GridData.gameObject:SetActiveEx(false)
    XTool.UpdateDynamicItem(self._DataGrids, damageList, self.GridData, XUiGridTheatre6RoundData, self)
end

function XUiPanelTheatre6PvpRoundLeft:SwitchData(showType)
    self._ShowType = showType
    if self.Parent.AnimQiehuan then
        self.Parent.AnimQiehuan:Play()
    end
    self:UpdateView()
end

function XUiPanelTheatre6PvpRoundLeft:OnBtnSwitchRoleClick()
    self:SwitchData(SHOW_TYPE.MyRole)
end

function XUiPanelTheatre6PvpRoundLeft:OnBtnSwitchBossClick()
    self:SwitchData(SHOW_TYPE.Enemy)
end

return XUiPanelTheatre6PvpRoundLeft
