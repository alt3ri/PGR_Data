local XUiGridShopSubCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopSubCard")
local XUiPanelPunishaarTalkTips = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiCommonTop/UiRoleModelUiShow/XUiPanelPunishaarTalkTips")

--- 敌人侧子面板（战前 PreFight 态显）：整体坐标换算设图标 + 技能图标 UI 排序 + BtnEnemyDetails 战前激活开详情
---@class XUiPanelPunishaarEnemyDetail: XUiNode
---@field protected _Control
---@field Parent
---@field UiPunishaarSubCard UnityEngine.RectTransform 敌人侧图标预制挂载点（整体坐标换算设位置，节点复用）
---@field BtnEnemyDetails XUiComponent.XUiButton 敌人详情按钮（仅 PreFight 态激活，点击开 EnemyTips 详情气泡 #69）
---@field DetailRoot UnityEngine.RectTransform 敌人侧整体定位锚点（坐标换算设位 + ShowEnemy posUi 用）#70
---@field UiPunishaarTalkTips UnityEngine.RectTransform 对话气泡子节点挂载点（挂 XUiPanelPunishaarTalkTips，商人 ShopDialog 非空时显）#对话接入
local XUiPanelPunishaarEnemyDetail = XClass(XUiNode, "XUiPanelPunishaarEnemyDetail")

function XUiPanelPunishaarEnemyDetail:OnStart()
    -- 挂点显隐主动管
    if self.UiPunishaarSubCard then
        self.UiPunishaarSubCard.gameObject:SetActiveEx(false)  -- 图标模板默认隐
    end
    if self.BtnEnemyDetails then
        self.BtnEnemyDetails.gameObject:SetActiveEx(false)  -- 默认隐（PreFight 才显）
        self.BtnEnemyDetails:AddEventListener(handler(self, self._OnBtnEnemyDetailsClick))
    end
    -- 对话气泡子面板（XUiNode 初始化；New 后默认隐，Show/Hide 由 FightMain 切态经 RoleModelUiShow 转发）#对话接入
    if self.UiPunishaarTalkTips then
        self._TalkTips = XUiPanelPunishaarTalkTips.New(self.UiPunishaarTalkTips, self)
        self.UiPunishaarTalkTips.gameObject:SetActiveEx(false)  -- 初始隐（防 prefab 默认 active 残留显，对齐 UiPunishaarSubCard/BtnEnemyDetails 范式）
    end
end

--- 敌人侧整体坐标换算 + 技能图标 UI 排序 + BtnEnemyDetails 战前激活 #70
---@param modelShow XUiPunishaarModelShow
---@param cam UnityEngine.Camera UiNearCamera
function XUiPanelPunishaarEnemyDetail:Refresh(modelShow, cam)
    -- 整体坐标换算：敌人模型挂点 → DetailRoot UI 位置
    if modelShow and modelShow._EnemyModelPanel and self.DetailRoot then
        local worldPos = modelShow._EnemyModelPanel.Transform.position
        local screenPos = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(cam, worldPos)
        local parent = self.DetailRoot.parent
        if parent then
            local ok, localPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    parent, screenPos, CS.XUiManager.Instance.UiCamera)
            if ok then
                self.DetailRoot.anchoredPosition = localPos
            end
        end
    end
    -- 取 fightId + fightCfg（双轨源，参 RefreshEnemyModel）
    local gc = self._Control and self._Control.GameControl
    local fightId = gc and self:_GetFightId(gc)
    local fightCfg = gc and fightId and gc:GetTablePunishaarFight(fightId, true)
    -- 技能图标：按 EnemySkill[] 克隆 UiPunishaarSubCard
    local skillIds = fightCfg and fightCfg.EnemySkill
    local skillCount = skillIds and #skillIds or 0
    if skillCount > 0 and self.UiPunishaarSubCard then
        local parent = self.UiPunishaarSubCard.parent
        self.UiPunishaarSubCard.gameObject:SetActiveEx(false)
        if self._SkillGridDict == nil then
            self._SkillGridDict = {}
        end
        XUiHelper.RefreshCustomizedList(parent, self.UiPunishaarSubCard, skillCount, function(index, go)
            local grid = self._SkillGridDict[go]
            if not grid then
                grid = XUiGridShopSubCard.New(go, self)
                self._SkillGridDict[go] = grid
            end
            grid:Open()
            local skillCfg = gc:GetTablePunishaarEnemySkill(skillIds[index], true)
            grid:RefreshSkill(skillCfg and skillCfg.SkillIcon)
        end)
    end
    -- BtnEnemyDetails 仅 PreFight 态激活（战前可查看敌人详情；Fighting/Shopping/Base 隐，对齐 :9 字段注释设计意图）。
    -- Refresh 跟 Show 走，Show 在 PreFight/Fighting 都调（敌方槽+技能图标战斗中要显），故按 FightState 区分按钮激活而非无条件显。
    if self.BtnEnemyDetails then
        local runControl = self._Control and self._Control.GameControl and self._Control.GameControl.RunControl
        local fightState = runControl and runControl:GetCurrentFightState()
        local isPreFight = fightState == XMVCA.XPunishaar.EnumConst.FightState.PreFight
        self.BtnEnemyDetails.gameObject:SetActiveEx(isPreFight)
    end
end

--- 显敌方元素（Open 幂等 + 显 DetailRoot + Refresh：定位 DetailRoot + 克隆技能图标 + 激活 BtnEnemyDetails）。跟敌人模型 Show 走。#副卡槽联动
---@param modelShow XUiPunishaarModelShow
---@param cam UnityEngine.Camera
function XUiPanelPunishaarEnemyDetail:Show(modelShow, cam)
    self:Open()
    if self.DetailRoot then
        self.DetailRoot.gameObject:SetActiveEx(true)
    end
    self:Refresh(modelShow, cam)
end

--- 隐敌方元素（不 Close GO——卡牌侧副卡 grid 可能挂本 GO 下，关 GO 会连带隐卡牌侧；只隐敌方专属：BtnEnemyDetails + 技能图标 grid + DetailRoot，GO 留 active 不波及卡牌侧）。#副卡槽联动
function XUiPanelPunishaarEnemyDetail:Hide()
    if self.BtnEnemyDetails then
        self.BtnEnemyDetails.gameObject:SetActiveEx(false)
    end
    if self._SkillGridDict then
        for _, grid in pairs(self._SkillGridDict) do
            grid:Close()
        end
    end
    if self.DetailRoot then
        self.DetailRoot.gameObject:SetActiveEx(false)
    end
end

--- 取 fightId：直接读当前节点 FightInfo（与 GetCurrentFightId 同源，保证怪物详情与敌人模型数据源一致）。
--- 旧版优先 PeekBattleInitData（开战契约），但契约只在 Fighting 态建（PreFight 不准备），通关节点切换后 PreFight 怔契约残存上一节点 fightId → 怪物详情显示旧节点怪物。#怪物详情跨节点
---@param gc table GameControl
---@return number|nil
function XUiPanelPunishaarEnemyDetail:_GetFightId(gc)
    local stage = gc._Model and gc._Model:GetCurrentStage()
    local node = stage and stage.CurrentNode
    local fightInfo = node and node.FightInfo
    if not fightInfo then return nil end
    local fightId = fightInfo.SelectedFightId
    if fightId and fightId ~= 0 then return fightId end
    return fightInfo.RandomFightIds and fightInfo.RandomFightIds[1]
end

--- 点 BtnEnemyDetails → 开敌人详情气泡（经 _GetTipsHost 上溯找 ShowEnemyTips 宿主，对齐卡牌 _OnCardClick 范式）#69
function XUiPanelPunishaarEnemyDetail:_OnBtnEnemyDetailsClick()
    local host = self:_GetTipsHost()
    if not host then return end
    local gc = self._Control and self._Control.GameControl
    if not gc then return end
    local fightId = self:_GetFightId(gc)
    if not fightId then return end
    host:ShowEnemyTips(fightId, self.DetailRoot)
end

--- 沿 Parent 链上溯找 ShowEnemyTips 宿主（对齐 XUiGridShopCard._GetTipsHost 范式）#70
---@return table|nil
function XUiPanelPunishaarEnemyDetail:_GetTipsHost()
    local p = self.Parent
    while p do
        if p.ShowEnemyTips then return p end
        p = p.Parent
    end
    return nil
end

--- 显示对话气泡（设文本 + 显）。经 RoleModelUiShow 转发，FightMain Shopping 态 ShopDialog 非空时调。#对话接入
---@param text string 对话文本
function XUiPanelPunishaarEnemyDetail:ShowTalkTips(text)
    if self._TalkTips then
        self._TalkTips:Show(text)
    end
end

--- 隐藏对话气泡。切走 Shopping / 敌人态（无对话字段）调。
function XUiPanelPunishaarEnemyDetail:HideTalkTips()
    if self._TalkTips then
        self._TalkTips:Hide()
    end
end

return XUiPanelPunishaarEnemyDetail