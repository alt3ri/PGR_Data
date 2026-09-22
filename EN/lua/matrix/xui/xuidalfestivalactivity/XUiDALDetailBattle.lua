-- DAL 联动战斗关详情，复用预制 Assets/Product/Ui/Prefab/UiDALStage/UiDALDetailBattle.prefab
-- （由 MainLine2 战斗详情预制拷贝而来，数据源换为 FubenFestivalActivityManager + 通用 XFuben）
-- 仅接核心流程：标题/描述/关卡图/目标/通关标记/出战角色/进入战斗。
-- MainLine2 专属面板（成就、多关卡左右切换、目标进度）DAL 关卡表无对应字段，暂隐藏。
---@class XUiDALDetailBattle: XLuaUi
local XUiDALDetailBattle = XLuaUiManager.Register(XLuaUi, "UiDALDetailBattle")

local FIRST_INDEX = 1   -- 出战角色列表首位（显示 FirstTag）

function XUiDALDetailBattle:OnAwake()
    self:HideUnsupportedPanels()
    self:RegisterUiEvents()
    self.CharacterUiObjs = { self.GridCharacter }
end

function XUiDALDetailBattle:OnStart(stageId, festivalId, closeCb)
    self.StageId = stageId
    self.FestivalId = festivalId
    self.CloseCb = closeCb
    self:Refresh()
end

function XUiDALDetailBattle:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
        self.CloseCb = nil
    end
    self.CharacterUiObjs = nil
end

-- 隐藏暂未支持的 MainLine2 专属面板/按钮
function XUiDALDetailBattle:HideUnsupportedPanels()
    local function hide(node)
        if node and node.gameObject then
            node.gameObject:SetActiveEx(false)
        end
    end
    hide(self.BtnMode)
    hide(self.ImgVtTag)
    hide(self.PanelPoint)
    hide(self.BtnLeft)
    hide(self.BtnRight)
    hide(self.PanelAchievement)
    hide(self.BtnAchievement)
    hide(self.TxtCharacterTips)
end

function XUiDALDetailBattle:RegisterUiEvents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnEnter:AddEventListener(function() self:OnBtnEnterClick() end)
end

function XUiDALDetailBattle:OnBtnCloseClick()
    self:Close()
end

function XUiDALDetailBattle:Refresh()
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(self.FestivalId, self.StageId)
    if not fStage then return end
    self.FStage = fStage

    local stageCfg = fStage:GetStageCfg()
    local chapter = fStage:GetChapter()
    local title = fStage:GetName()
    if chapter then
        self.TxtName.text = string.format("%s%d %s", chapter:GetStagePrefix(), fStage:GetOrderIndex(), title)
    else
        self.TxtName.text = title
    end
    if self.TxtName2 then
        self.TxtName2.text = title
    end
    self.TxtDesc.text = stageCfg and stageCfg.Description or ""
    if self.TxtTarget and stageCfg and stageCfg.StarDesc then
        self.TxtTarget.text = stageCfg.StarDesc[1] or ""
    end
    self.RImgIcon:SetRawImage(fStage:GetStoryIcon())
    self.ClearTag.gameObject:SetActiveEx(fStage:GetIsPass())

    if self.TxtTargetProgress then
        self.TxtTargetProgress.text = ""
    end

    self:RefreshCharacters()
end

-- 刷新出战角色（仅关卡配置的机器人；DAL 无怪物头像/指挥官替换配置）
function XUiDALDetailBattle:RefreshCharacters()
    for _, uiObj in pairs(self.CharacterUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local stageCfg = self.FStage:GetStageCfg()
    if not stageCfg or #stageCfg.RobotId <= 0 then return end
    -- displayIndex 为实际显示顺序：跳过已重建 NPC 后连续递增，作为格子键与首位判定，与配置下标解耦
    local displayIndex = 0
    for _, robotId in ipairs(stageCfg.RobotId) do
        -- 已重建为 NPC 的 robot 不在出战头像列表显示
        if not XTool.IsNumberValid(XRobotManager.GetRebuildNpcId(robotId)) then
            displayIndex = displayIndex + 1
            local uiObj = self.CharacterUiObjs[displayIndex]
            if not uiObj then
                local go = CS.UnityEngine.Object.Instantiate(self.GridCharacter.gameObject, self.CharacterList.transform)
                uiObj = go:GetComponent(typeof(CS.UiObject))
                self.CharacterUiObjs[displayIndex] = uiObj
            end
            local icon = XRobotManager.GetRobotSmallHeadIcon(robotId)
            uiObj:GetObject("RImgCharater"):SetRawImage(icon)
            uiObj:GetObject("FirstTag").gameObject:SetActiveEx(displayIndex == FIRST_INDEX)
            uiObj:GetObject("BtnChange").gameObject:SetActiveEx(false)
            uiObj.gameObject:SetActiveEx(true)
        end
    end
end

function XUiDALDetailBattle:OnBtnEnterClick()
    if not self.FStage then
        XLog.Error("XUiDALDetailBattle:OnBtnEnterClick 函数错误: 关卡信息为空")
        return
    end
    local chapter = self.FStage:GetChapter()
    if chapter then
        local isInTime, tips = chapter:GetIsInTimeAndTips()
        if not isInTime then
            XUiManager.TipMsg(tips)
            return
        end
    end
    local passedCounts = self.FStage:GetPassCount()
    local maxChallengeNum = self.FStage:GetMaxChallengeNum()
    if maxChallengeNum > 0 and passedCounts >= maxChallengeNum then
        XUiManager.TipText("FubenChallengeCountNotEnough")
        return
    end
    if XDataCenter.FubenManager.CheckPreFight(self.FStage:GetStageCfg()) then
        XMVCA.XFuben:OpenUiBattleRoleRoom(self.FStage:GetStageId())
        self:Close()
    end
end

return XUiDALDetailBattle
