--- 详情预制体的根
---@class XUiPunishaarEnemyTips: XUiNode
---@field protected _Control
---@field Parent
---@field PanelTop UnityEngine.RectTransform 敌人基础信息面板挂载点（挂 XUiPanelPunishaarEnemyBase，随其 Open/Close 显隐）
---@field PanelNoneSkill UnityEngine.RectTransform 无技能空态（Refresh 按 skill 数判显隐，不靠 prefab 默认）
---@field ListDesc UnityEngine.RectTransform 技能列表父节点（Refresh 按 skill 数判显隐，不靠 prefab 默认）
---@field GridSkill UnityEngine.RectTransform 技能 grid 模板（OnStart 主动 SetActiveEx(false) 隐藏，不靠 prefab 默认）
local XUiPanelPunishaarEnemyBase = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarEnemyTips/XUiPanelPunishaarEnemyBase")
local XUiGridPunishaarEnemySkill = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarEnemyTips/XUiGridPunishaarEnemySkill")
local XUiPunishaarEnemyTips = XClass(XUiNode, "XUiPunishaarEnemyTips")

--- 挂点显隐主动管（不靠 prefab 默认）：模板/空态/列表初始隐，Refresh 按数据判；PanelTop 随 EnemyBase Open 显
function XUiPunishaarEnemyTips:OnStart()
    if self.GridSkill then
        self.GridSkill.gameObject:SetActiveEx(false)  -- 模板隐藏
    end
    if self.PanelNoneSkill then
        self.PanelNoneSkill.gameObject:SetActiveEx(false)  -- 空态默认隐
    end
    if self.ListDesc then
        self.ListDesc.gameObject:SetActiveEx(false)  -- 列表默认隐（Refresh 按 skill 数显）
    end
    if self.PanelTop then
        self._EnemyBase = XUiPanelPunishaarEnemyBase.New(self.PanelTop, self)
        self._EnemyBase:Open()
    end
end

--- 刷新敌人详情：按 fightId 取 Fight+Enemy+EnemySkill[] 刷 EnemyBase + 克隆 GridSkill #69
---@param fightId number（ShowEnemy 直接传，禁止临时 ViewModel #70）
function XUiPunishaarEnemyTips:Refresh(fightId)
    if not fightId then return end
    local gc = self._Control and self._Control.GameControl
    if not gc then return end
    local fightCfg = gc:GetTablePunishaarFight(fightId, true)
    if not fightCfg then return end
    -- 敌人基础信息
    if self._EnemyBase then
        self._EnemyBase:Refresh(fightId)
    end
    -- 技能列表：预查有效 skillCfg（表未导出时 skillCfg nil → 过滤），hasSkill 用有效数非 #skillIds
    local skillIds = fightCfg.EnemySkill
    local validSkills = {}
    if skillIds then
        for _, skillId in ipairs(skillIds) do
            local skillCfg = gc:GetTablePunishaarEnemySkill(skillId, true)
            if skillCfg then
                validSkills[#validSkills + 1] = skillCfg
            end
        end
    end
    local hasSkill = #validSkills > 0
    
    if self.PanelNoneSkill then
        self.PanelNoneSkill.gameObject:SetActiveEx(not hasSkill)
    end
    
    if self.ListDesc then
        self.ListDesc.gameObject:SetActiveEx(hasSkill)
    end
    
    if not hasSkill then
        return 
    end

    if self._SkillGridDict == nil then
        self._SkillGridDict = {}
    else
        for i, v in pairs(self._SkillGridDict) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.GridSkill.transform.parent, self.GridSkill, #validSkills, function(index, go)
        local grid = self._SkillGridDict[go]
        if not grid then
            grid = XUiGridPunishaarEnemySkill.New(go, self)
            self._SkillGridDict[go] = grid
        end
        grid:Open()
        grid:Refresh(validSkills[index])
    end)
end

return XUiPunishaarEnemyTips