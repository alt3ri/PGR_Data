--- 肉鸽6单次战斗结算左侧面板
---@class XUiPanelTheatre6RoundLeft : XUiNode
---@field _Control XTheatre6Control
local XUiPanelTheatre6RoundLeft = XClass(XUiNode, "XUiPanelTheatre6RoundLeft")
local XUiGridTheatre6RoundData = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6RoundData")
local SHOW_TYPE = XEnumConst.Theatre6.SHOW_TYPE

function XUiPanelTheatre6RoundLeft:OnStart()
    self._ShowType = SHOW_TYPE.MyRole
    self._AttributeGrids = {}
    self._DataGrids = {}
    self.BtnSwitchBoss:AddEventListener(handler(self, self.OnBtnSwitchBossClick))
    self.BtnSwitchRole:AddEventListener(handler(self, self.OnBtnSwitchRoleClick))
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridData.gameObject:SetActiveEx(false)
end

---@param settleData table DlcFightSettleData
function XUiPanelTheatre6RoundLeft:Refresh(settleData, monsterId, totalScore, isChooseRoom)
    self._SettleData = settleData
    self._MonsterId = monsterId
    self._TotalScore = totalScore
    self._IsChooseRoom = isChooseRoom
    self._RoleData = self._SettleData.ResultData.WorldData.Theatre6GameplayData.SelfData

    self:CheckChooseFightHideHealth()
    self:RefreshResult()
    self:RefreshRoleInfo()
    self:RefreshAttribute()
    self:RefreshDataList()
end

function XUiPanelTheatre6RoundLeft:RefreshResult()
    local isWin = self._SettleData.ResultData.IsPlayerWin
    self.TxtWin.gameObject:SetActiveEx(isWin)
    self.TxtLose.gameObject:SetActiveEx(not isWin)

    local modelData = self._Control:GetCurPlayModeData()
    self.RImgHeartIcon:SetRawImage(self._Control:GetHpIcon())
    self.TxtHeartLeft.text = modelData.Health
    self.TxtHeartRight.text = string.format("/%s", modelData.InitHealth)

    if not self._IsChooseRoom then
        local loseHp
        for _, result in pairs(self._SettleData.Theatre6FightResult.RewardGoodsList) do
            if result.RewardType == XEnumConst.Theatre6.EventRewardType.Hp then
                loseHp = result.Amount
                break
            end
        end
        if loseHp and loseHp < 0 then
            self.TxtHeartReduce.gameObject:SetActiveEx(true)
            self.TxtHeartReduce.text = loseHp
        else
            self.TxtHeartReduce.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelTheatre6RoundLeft:RefreshRoleInfo()
    local isMyRole = self._ShowType == SHOW_TYPE.MyRole
    local icon = self._Control:GetFashionConfig(self._RoleData.FashionId).Portrait
    
    self.RImgBgMe.gameObject:SetActiveEx(isMyRole)
    self.RImgBgEnemy.gameObject:SetActiveEx(not isMyRole)
    self.PanelMyRole.gameObject:SetActiveEx(isMyRole)
    self.PanelEnemyRole.gameObject:SetActiveEx(not isMyRole)
    self.BtnSwitchBoss.gameObject:SetActiveEx(isMyRole)
    self.BtnSwitchRole.gameObject:SetActiveEx(not isMyRole)

    if isMyRole then
        self.RoleSelf:SetRawImage(icon)
        self.TxtMyRate.text = self._TotalScore
    else
        self.RoleEnemy:SetRawImage(icon)
        self.TxtEnemyRate.text = self._Control:GetMonsterScore(self._MonsterId)
    end
end

function XUiPanelTheatre6RoundLeft:RefreshAttribute()
    local attribValues = {}
    local attrConfigs = self._Control:GetAttrConfigs()

    for id, value in pairs(self._RoleData.Attribs) do
        local key = XEnumConst.Theatre6.NpcAttrib[id]
        attribValues[key] = value
    end

    for id, value in pairs(self._RoleData.GameplayAttribs) do
        local key = XEnumConst.Theatre6.GameplayAttrib[id]
        attribValues[key] = value
    end

    self._AttributeGrids = XUiHelper.RefreshUiObjectList(self._AttributeGrids, self.GridAttribute.parent, self.GridAttribute, #attrConfigs, function(i, grid)
        local attrConfig = attrConfigs[i]
        grid.RImgIcon:SetRawImage(attrConfig.Icon)
        grid.TxtNum.text = attribValues[attrConfig.AttrKey] or 0
    end)
end

function XUiPanelTheatre6RoundLeft:RefreshDataList()
    local roleData
    if self._ShowType == SHOW_TYPE.MyRole then
        roleData = self._SettleData.ResultData.Theatre6CheckData.MyData
    else
        roleData = self._SettleData.ResultData.Theatre6CheckData.EnemyData
    end
    local damageList = self._Control:GetRoundSettlementDamageList(roleData)

    self.GridData.gameObject:SetActiveEx(false)
    XTool.UpdateDynamicItem(self._DataGrids, damageList, self.GridData, XUiGridTheatre6RoundData, self)
end

function XUiPanelTheatre6RoundLeft:OnBtnSwitchRoleClick()
    self:SwitchData(SHOW_TYPE.MyRole, self._SettleData.ResultData.WorldData.Theatre6GameplayData.SelfData)
end

function XUiPanelTheatre6RoundLeft:OnBtnSwitchBossClick()
    self:SwitchData(SHOW_TYPE.Enemy, self._SettleData.ResultData.WorldData.Theatre6GameplayData.EnemyData)
end

function XUiPanelTheatre6RoundLeft:SwitchData(showType, roleData)
    self._ShowType = showType
    self._RoleData = roleData
    if self.Parent.AnimQiehuan then
        self.Parent.AnimQiehuan:Play()
    end
    self:RefreshRoleInfo()
    self:RefreshAttribute()
    self:RefreshDataList()
end

--二择房间的战斗结算 需要隐藏健康值
function XUiPanelTheatre6RoundLeft:CheckChooseFightHideHealth()
    if self._IsChooseRoom then
        self.RImgHeartIcon.gameObject:SetActiveEx(false)
        self.TxtHeartReduce.gameObject:SetActiveEx(false)
        self.TxtHeartRight.gameObject:SetActiveEx(false)
    end
end

return XUiPanelTheatre6RoundLeft