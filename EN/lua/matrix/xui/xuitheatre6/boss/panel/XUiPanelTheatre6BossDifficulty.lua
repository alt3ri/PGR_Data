---@class XUiPanelTheatre6BossDifficulty : XUiNode Boss单个难度信息面板（左右复用）
---@field _Control XTheatre6Control
local XUiPanelTheatre6BossDifficulty = XClass(XUiNode, "XUiPanelTheatre6BossDifficulty")

function XUiPanelTheatre6BossDifficulty:OnStart()
    self._ActiveSkillGrids = {}
    self._PassiveSkillGrids = {}
    self._RewardGrids = {}
    
    self.GridActiveSkill.gameObject:SetActiveEx(false)
    self.GridPassiveSkill.gameObject:SetActiveEx(false)
    self.GridRewardItem.gameObject:SetActiveEx(false)
    
    self.BtnView:AddEventListener(handler(self, self.OnBtnViewClick))
end

---设置难度数据
---@param roomId number 房间Id
---@param isHard boolean 是否困难难度
function XUiPanelTheatre6BossDifficulty:SetData(roomId, fightId, isHard)
    self._RoomId = roomId
    self._FightId = fightId
    self._IsHard = isHard

    self:RefreshScore()
    self:RefreshActiveSkills()
    self:RefreshPassiveSkills()
    self:RefreshRewards()
end

---刷新评分
function XUiPanelTheatre6BossDifficulty:RefreshScore()
    local score = self._Control:GetDifficultyScore(self._FightId, self._IsHard)
    self.UiTxtScore.text = tostring(score)
end

---刷新主动技能列表
function XUiPanelTheatre6BossDifficulty:RefreshActiveSkills()
    local skillConfigs = self._Control:GetBossActiveSkills(self._FightId, self._IsHard)

    XTool.UpdateDynamicItem(
            self._ActiveSkillGrids,
            skillConfigs,
            self.GridActiveSkill,
            require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossSkill"),
            self
    )
    self.ActiveSkillEmpty.gameObject:SetActiveEx(#skillConfigs <= 0)
end

---刷新被动技能列表
function XUiPanelTheatre6BossDifficulty:RefreshPassiveSkills()
    local skillConfigs = self._Control:GetBossPassiveSkills(self._FightId, self._IsHard)

    XTool.UpdateDynamicItem(
            self._PassiveSkillGrids,
            skillConfigs,
            self.GridPassiveSkill,
            require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossSkill"),
            self
    )
    self.PassiveSkillEmpty.gameObject:SetActiveEx(#skillConfigs <= 0)
end

---刷新奖励列表
function XUiPanelTheatre6BossDifficulty:RefreshRewards()
    local rewards = self._Control:GetRewardPoolsByRoom(self._FightId, self._IsHard)

    XTool.UpdateDynamicItem(
            self._RewardGrids,
            rewards,
            self.GridRewardItem,
            require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossReward"),
            self
    )
end

---点击查看详情按钮
function XUiPanelTheatre6BossDifficulty:OnBtnViewClick()
    XLuaUiManager.Open("UiTheatre6PopupBossCompare", self._RoomId, self._FightId, nil, self._IsHard and 2 or 1)
end

return XUiPanelTheatre6BossDifficulty
