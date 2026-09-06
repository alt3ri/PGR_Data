---@class XUiRoleCultureDetailMain : XLuaUi
---@field _Control XCharacterControl
---@field CultureResult XRoleCultureResult
local XUiRoleCultureDetailMain = XLuaUiManager.Register(XLuaUi, "UiRoleCultureDetailMain")

local XUiPanelCultureSkillList = require("XUi/XUiRole/XUiRoleCulture/XUiPanelCultureSkillList")
local XUiGridCultureSkill = require("XUi/XUiRole/XUiRoleCulture/XUiGridCultureSkill")
local XUiPanelCultureStepper = require("XUi/XUiRole/XUiRoleCulture/XUiPanelCultureStepper")
local XUiPanelCultureGradeStepper = require("XUi/XUiRole/XUiRoleCulture/XUiPanelCultureGradeStepper")
local XUiPanelCultureConsume = require("XUi/XUiRole/XUiRoleCulture/XUiPanelCultureConsume")
local XUiPanelAsset      = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCultureCost = require("XUi/XUiRole/XUiGridCultureCost")
local XUiPanelRoleModel  = require("XUi/XUiCharacter/XUiPanelRoleModel")

local COLOR_COST_NORMAL = CS.UnityEngine.Color.black
local COLOR_COST_LACK = CS.UnityEngine.Color.red
local _, COLOR_LEVEL_PREVIEW = CS.UnityEngine.ColorUtility.TryParseHtmlString("#3270BB")

function XUiRoleCultureDetailMain:OnAwake()
    self.CostGrids = {}
    self:RegisterButtonEvent()
end

function XUiRoleCultureDetailMain:RegisterButtonEvent()
    self.BtnStrengthen:AddEventListener(handler(self, self.OnBtnStrengthenClick))
    self.BtnOneclickAllocate:AddEventListener(handler(self, self.OnBtnOneclickAllocateClick))
    self.ToggleExchange:AddEventListener(handler(self, self.OnToggleExchangeClick))
    self.ToggleSkill5:AddEventListener(handler(self, self.OnToggleEnhanceClick))
    self.ToggleSkill6:AddEventListener(handler(self, self.OnToggleEnhanceClick))
    self.BtnSpecialTrainingToggle:AddEventListener(handler(self, self.OnToggleSpecialTrainingClick))
    self.BtnInfo:AddEventListener(handler(self, self.OnBtnInfoClick))
    self.BtnBubbleClose:AddEventListener(handler(self, self.OnBtnBubbleCloseClick))
    self.BtnCloseSkill:AddEventListener(handler(self, self.OnBtnCloseSkillClick))
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)
    self:BindHelpBtn(self.BtnHelp, "RoleCultureDetailMain")

    self.AssetPanel = XUiPanelAsset.New(
            self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.SkillPoint,
            XDataCenter.ItemManager.ItemId.Coin
    )
end

function XUiRoleCultureDetailMain:OnStart(characterId)
    self.CharacterId = characterId

    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.TargetLevel = character.Level
    self.TargetGrade = character.Grade
    self.SkillTargetLevel = 0
    self._SkillInitPending = true
    self.IncludeEnhance = false
    -- 自动兑换开关本地持久化
    self.AutoExchange = self._Control:GetRoleCultureAutoExchange()
    self.UseSpecialTraining = false
    self.CultureResult = nil
    self.CalcArgs = { CharacterId = characterId }

    self:SetupEnhanceShopUnlockSnapshot()
    self.BtnSpecialTrainingToggle:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._Control:GetRoleCultureSpecialItemId()))

    self:InitPanels()
    self:InitSteppers()
    self:InitRoleModel()
end

function XUiRoleCultureDetailMain:InitRoleModel()
    local panelRoleModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.RoleModelPanel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true)
    self.RoleModelPanel:UpdateCharacterModel(self.CharacterId, panelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter)
    self:AdaptScreenAspectRatio()
end

--- 分辨率适配（PassportModelAdapt 1.44|1.8|2.34）
function XUiRoleCultureDetailMain:AdaptScreenAspectRatio()
    local nearRoot = self.UiModelGo.transform:FindTransform("NearRoot")
    if not nearRoot then
        return
    end
    local cameraNames = { "CamNearMainPad", "CamNearMainStandard", "CamNearMainWidescreen"}
    local ratios = string.Split(CS.XGame.ClientConfig:GetString("PassportModelAdapt"))

    local width = CS.XUiManager.RealScreenWidth
    local height = CS.XUiManager.RealScreenHeight
    local realRatio = math.max(width, height) / math.min(width, height)

    local currentIndex = 1
    for _, targetRatio in pairs(ratios) do
        if realRatio > tonumber(targetRatio) then
            currentIndex = currentIndex + 1
        else
            break
        end
    end

    for i, name in ipairs(cameraNames) do
        local cam = nearRoot:FindTransform(name)
        if cam then
            cam.gameObject:SetActiveEx(i == currentIndex)
        end
    end
end

function XUiRoleCultureDetailMain:OnEnable()
    if not self.CharacterId then
        return
    end

    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnDestroy()
    if self.RoleModelPanel then
        self.RoleModelPanel:HideAllEffects()
    end
    self._Control:ReleaseRoleCultureExecute()
end

function XUiRoleCultureDetailMain:InitPanels()
    self.CultureSkillList = XUiPanelCultureSkillList.New(self.PanelSkillPreview, self)
    self.CultureConsume = XUiPanelCultureConsume.New(self.PanelConsume, self)

    -- 主页面三个技能格：展示排序后前 3 技能，点击打开 PanelSkillPreview
    self.MainSkillGrids = {
        XUiGridCultureSkill.New(self.GridSkill1, self),
        XUiGridCultureSkill.New(self.GridSkill2, self),
        XUiGridCultureSkill.New(self.GridSkill3, self),
    }
    local onGridClick = handler(self, self.OnMainSkillGridClick)
    for _, grid in ipairs(self.MainSkillGrids) do
        grid:SetClickCb(onGridClick)
    end

    -- PanelSkillPreview 非常驻，初始关闭（走 XUiNode 生命周期，不能直接 SetActiveEx）
    self._SkillPreviewOpen = false
    self.CultureSkillList:Close()
end

function XUiRoleCultureDetailMain:InitSteppers()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    self.LevelStepper = XUiPanelCultureStepper.New(self.PanelLevelUp, self)
    self.LevelStepper:Init({
        Min = character.Level,
        Max = XMVCA.XCharacter:GetMaxAvailableLevel(characterId),
        GetMaxAffordable = handler(self, self.GetMaxReachableLevel),
        OnValueChanged = handler(self, self.OnTargetLevelChanged),
        OnMaxClick = handler(self, self.OnLevelMaxClick),
    })

    self.GradeStepper = XUiPanelCultureGradeStepper.New(self.PanelUpgrade, self, characterId)
    self.GradeStepper:Init({
        Min = character.Grade,
        Max = XMVCA.XCharacter:GetCharMaxGrade(characterId),
        GetMaxAffordable = handler(self, self.GetMaxReachableGrade),
        IsMaterialLack = handler(self, self.IsGradeMaterialLack),
        OnValueChanged = handler(self, self.OnTargetGradeChanged),
        OnMaxClick = handler(self, self.OnGradeMaxClick),
    })

    self.SkillStepper = XUiPanelCultureStepper.New(self.PanelSkill, self)
    self.SkillStepper:Init({
        Min = 0,
        Max = 0,
        GetMaxAffordable = handler(self, self.GetMaxReachableSkillLevel),
        OnValueChanged = handler(self, self.OnSkillTargetLevelChanged),
        OnMaxClick = handler(self, self.OnSkillMaxClick),
        IsMaxNoCost = handler(self, self.IsSkillStepperMaxNoCost),
    })
end

--region 步进器回调与查询

function XUiRoleCultureDetailMain:GetMaxReachableLevel()
    return self.CultureResult and self.CultureResult.MaxReachableLevel or 0
end

function XUiRoleCultureDetailMain:GetMaxReachableGrade()
    return self.CultureResult and self.CultureResult.MaxReachableGrade or 0
end

function XUiRoleCultureDetailMain:IsGradeMaterialLack()
    return self.CultureResult and self.CultureResult.IsGradeMaterialLack == true
end

function XUiRoleCultureDetailMain:GetMaxReachableSkillLevel()
    return self.CultureResult and self.CultureResult.MaxReachableSkillLevel or 0
end

--- 技能步进器：当前角色等级下技能可达最高是否不耗材料（加号禁用判定）
function XUiRoleCultureDetailMain:IsSkillStepperMaxNoCost()
    return self._Control:IsSkillMaxNoCost(self:CollectCalcArgs(), self.CultureResult)
end

function XUiRoleCultureDetailMain:OnTargetLevelChanged(value)
    self.TargetLevel = value
    --新等级下晋升条件上限（只查条件不算材料）
    local maxGrade = self._Control:CalcMaxReachableGrade(self.CharacterId, value)
    if self.TargetGrade > maxGrade then
        self.TargetGrade = maxGrade
    end
    self:OnPreviewChanged()
end

--- 等级步进器"最大"按钮特殊逻辑
function XUiRoleCultureDetailMain:OnLevelMaxClick()
    local result = self.CultureResult
    if not result or not result.MaxReachableLevel then
        return true
    end
    if self.TargetLevel <= result.MaxReachableLevel then
        return true
    end
    self.TargetLevel = result.MaxReachableLevel
    local maxGrade = self._Control:CalcMaxReachableGrade(self.CharacterId, self.TargetLevel)
    if self.TargetGrade > maxGrade then
        self.TargetGrade = maxGrade
    end
    self:OnPreviewChanged()
    return false
end

function XUiRoleCultureDetailMain:OnTargetGradeChanged(value)
    self.TargetGrade = value
    self:OnPreviewChanged()
end

--- 晋升步进器"最大"按钮遍历检查
function XUiRoleCultureDetailMain:OnGradeMaxClick()
    local result = self.CultureResult
    if not result then
        return true
    end
    local maxReachable = result.MaxReachableGrade or 0
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    local affordableGrade = character.Grade
    for grade = character.Grade + 1, maxReachable do
        if self._Control:CheckRoleCultureTotalAffordable(result, self.TargetLevel, grade, self.SkillTargetLevel) then
            affordableGrade = grade
        else
            break
        end
    end
    self.TargetGrade = affordableGrade
    self:OnPreviewChanged()
    return false
end

function XUiRoleCultureDetailMain:OnSkillTargetLevelChanged(value)
    self.SkillTargetLevel = value
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnSkillMaxClick()
    self._SkillFromMaxOrAllocate = true
end

--endregion

--region 按钮

function XUiRoleCultureDetailMain:OnBtnOneclickAllocateClick()
    local targetLevel, targetGrade, skillTargetLevel = self._Control:CalcRoleCultureAutoAllocate(self:CollectCalcArgs())
    self.TargetLevel = targetLevel
    self.TargetGrade = targetGrade
    self.SkillTargetLevel = skillTargetLevel
    self._SkillFromMaxOrAllocate = true
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnToggleExchangeClick()
    self.AutoExchange = not self.AutoExchange
    -- 自动兑换开关本地持久化
    self._Control:SetRoleCultureAutoExchange(self.AutoExchange)
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnToggleEnhanceClick()
    self.IncludeEnhance = not self.IncludeEnhance
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnToggleSpecialTrainingClick()
    self.UseSpecialTraining = not self.UseSpecialTraining
    if self.UseSpecialTraining then
        local characterId = self.CharacterId
        self.TargetLevel = XMVCA.XCharacter:GetMaxAvailableLevel(characterId)
        self.TargetGrade = XMVCA.XCharacter:GetCharMaxGrade(characterId)
        -- SkillTargetLevel 由 RefreshAll 按满级条件下的实际上限同步，避免用切换前的旧预览值
        self.IncludeEnhance = false
    else
        self:ResetPreviewToCurrent()
        return
    end
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:OnBtnInfoClick()
    self.PanelBubble.gameObject:SetActiveEx(true)
    self.UiTxtDesc.text = CS.XTextManager.GetText("RoleCultureDetail")
end

function XUiRoleCultureDetailMain:OnBtnBubbleCloseClick()
    self.PanelBubble.gameObject:SetActiveEx(false)
end

--- 主页面技能格点击：打开 PanelSkillPreview 并刷新
function XUiRoleCultureDetailMain:OnMainSkillGridClick()
    self:OpenSkillPreview()
end

function XUiRoleCultureDetailMain:OpenSkillPreview()
    self._SkillPreviewOpen = true
    self.CultureSkillList:Open()
    if self.CultureResult then
        self.CultureSkillList:Refresh(self.CultureResult)
    end
end

function XUiRoleCultureDetailMain:OnBtnCloseSkillClick()
    self._SkillPreviewOpen = false
    self.CultureSkillList:Close()
end

function XUiRoleCultureDetailMain:OnBtnStrengthenClick()
    if self.UseSpecialTraining then
        self:OnSpecialTrainingStrengthenClick()
        return
    end

    local result = self.CultureResult
    if not result then
        return
    end
    if next(result.LackMap) then
        XUiManager.TipText("RoleCultureItemNotEnough")
        return
    end
    
    if #result.ExchangePlan > 0 then
        local data = self._Control:BuildCultureCostPreviewData(result)
        XLuaUiManager.Open("UiRoleExchangeTipPopup", data.ExchangeList, handler(self, self.DoStrengthen))
    else
        XUiManager.DialogTip(nil, CS.XTextManager.GetText("RoleCultureDoubleCheck"), XUiManager.DialogType.Normal, nil,
            handler(self, self.DoStrengthen))
    end
end

--- 特训强化：等级非最低（>1）时二次确认文本提示已有进度
function XUiRoleCultureDetailMain:OnSpecialTrainingStrengthenClick()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if character.Level > 1 then
        XUiManager.DialogTip(nil, CS.XTextManager.GetText("RoleCultureHaveProgress",XDataCenter.ItemManager.GetItemName(self._Control:GetRoleCultureSpecialItemId())), XUiManager.DialogType.Normal, nil,
                handler(self, self.DoSpecialTraining))
    else
        XUiManager.DialogTip(nil, CS.XTextManager.GetText("RoleCultureDoubleCheck"), XUiManager.DialogType.Normal, nil,
                handler(self, self.DoSpecialTraining))
    end
end

function XUiRoleCultureDetailMain:DoSpecialTraining()
    self.PreCultureSnapshot = self:CaptureCultureSnapshot()
    XLuaUiManager.Open("UiEquipEnhanceProgressPopup", {
        Pd = { CharacterId = self.CharacterId },
        IsSpecialTraining = true,
        HideAbort = true,
        OnClose = handler(self, self.OnProgressPopupClose),
    })
end

function XUiRoleCultureDetailMain:DoStrengthen()
    local result = self.CultureResult
    if not result then
        return
    end
    
    self.PreCultureSnapshot = self:CaptureCultureSnapshot()
    
    XLuaUiManager.Open("UiEquipEnhanceProgressPopup", {
        Pd = result,
        OnClose = handler(self, self.OnProgressPopupClose),
    })
end

--- 快照
function XUiRoleCultureDetailMain:CaptureCultureSnapshot()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    local attribs = character.Attribs
    return {
        Level = character.Level,
        Grade = character.Grade,
        Life = attribs[XNpcAttribType.Life],
        Attack = attribs[XNpcAttribType.AttackNormal],
        Defense = attribs[XNpcAttribType.DefenseNormal],
        Crit = attribs[XNpcAttribType.Crit],
    }
end

function XUiRoleCultureDetailMain:OnProgressPopupClose(isSuccess)
    self:RecordCultureFinish(isSuccess)
    self:OpenStrengthenTip()
    self.PreCultureSnapshot = nil
    if isSuccess then
        self:ReplayUpgradeEffect()
    end
    --强化后角色等级可能提升,触发商店解锁条件变化;检测变化并按需重拉商店,再刷新预览
    self:CheckShopUnlockChangedAndReload(function()
        self:ResetPreviewToCurrent()
    end)
end

function XUiRoleCultureDetailMain:ReplayUpgradeEffect()
    if not self.Effect then
        return
    end
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
end

--- 角色养成埋点：培养目标与最终结果
function XUiRoleCultureDetailMain:RecordCultureFinish(isSuccess)
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    if not character then
        return
    end
    -- 技能最终状态：技能ID → 当前等级
    local skillLevels = {}
    local posDic = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(character.Id)
    for _, skillGroupIds in pairs(posDic or table.empty) do
        for _, skillGroupId in pairs(skillGroupIds) do
            local skillId = character:GetGroupCurSkillId(skillGroupId)
            if skillId > 0 then
                skillLevels[skillId] = character:GetSkillLevel(skillGroupId)
            end
        end
    end
    local dict = {
        character_id = self.CharacterId,
        target_level = self.TargetLevel or character.Level,
        target_grade = self.TargetGrade or character.Grade,
        target_skill_level = self.SkillTargetLevel or 0,
        is_auto_allocate = self._SkillFromMaxOrAllocate == true and 1 or 0,
        final_state = {
            [self.CharacterId] = {
                level = character.Level,
                grade = character.Grade,
                skill_levels = skillLevels,
            },
        },
        is_target_reached = {
            level = character.Level >= (self.TargetLevel or 0) and 1 or 0,
            grade = character.Grade >= (self.TargetGrade or 0) and 1 or 0,
            skill = isSuccess and 1 or 0,
        },
    }
    CS.XRecord.Record(dict, "1000006", "RoleOneClickCulture")
end

--- 记录当前跃升/独域商店解锁状态快照（用于强化后对比是否从未解锁变已解锁）
function XUiRoleCultureDetailMain:SetupEnhanceShopUnlockSnapshot()
    self._EnhanceShopUnlocked = XShopManager.IsShopUnlock(XShopManager.EnhanceShopId)
    self._UniqueShopUnlocked = XShopManager.IsShopUnlock(XShopManager.UniqueShopId)
    
    local hasEnhance = XMVCA.XCharacter:CheckIsShowEnhanceSkill(self.CharacterId)
    local isNormalType = XMVCA.XCharacter:GetCharacterType(self.CharacterId) == XEnumConst.CHARACTER.CharacterType.Normal
    self._ShowToggleSkill5 = hasEnhance and isNormalType and self._EnhanceShopUnlocked
    self._ShowToggleSkill6 = hasEnhance and not isNormalType and self._UniqueShopUnlocked
end

--- 强化后对比跃升/独域商店解锁状态;从未解锁变已解锁则重拉对应商店数据
function XUiRoleCultureDetailMain:CheckShopUnlockChangedAndReload(cb)
    local prevEnhance = self._EnhanceShopUnlocked
    local prevUnique = self._UniqueShopUnlocked
    XShopManager.GetBaseInfo(function()
        self:SetupEnhanceShopUnlockSnapshot()
        local curEnhance = self._EnhanceShopUnlocked
        local curUnique = self._UniqueShopUnlocked
        local changed = (prevEnhance ~= curEnhance) or (prevUnique ~= curUnique)
        if not changed then
            if cb then cb() end
            return
        end
        local shopIds = {}
        if curEnhance then
            table.insert(shopIds, XShopManager.EnhanceShopId)
        end
        if curUnique then
            table.insert(shopIds, XShopManager.UniqueShopId)
        end
        if #shopIds == 0 then
            if cb then cb() end
            return
        end
        XShopManager.RequestShopValidInfo(shopIds, function()
            XShopManager.GetShopInfoList(shopIds, function()
                if cb then cb() end
            end, XShopManager.ShopType.Common, true)
        end)
    end)
end

function XUiRoleCultureDetailMain:OpenStrengthenTip()
    local before = self.PreCultureSnapshot
    if not before then
        return
    end
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    local attribs = character.Attribs
    local afterLife = attribs[XNpcAttribType.Life]
    local afterAttack = attribs[XNpcAttribType.AttackNormal]
    local afterDefense = attribs[XNpcAttribType.DefenseNormal]
    local afterCrit = attribs[XNpcAttribType.Crit]

    local afterAttribs = {
        Life = afterLife,
        Attack = afterAttack,
        Defense = afterDefense,
        Crit = afterCrit,
    }
    -- 强化后属性与快照逐项对比，四项均无变化则不弹窗
    if FixToDouble(afterAttribs.Life) == FixToDouble(before.Life)
        and FixToDouble(afterAttribs.Attack) == FixToDouble(before.Attack)
        and FixToDouble(afterAttribs.Defense) == FixToDouble(before.Defense)
        and FixToDouble(afterAttribs.Crit) == FixToDouble(before.Crit)
    then
        return
    end

    XLuaUiManager.Open("UiRoleStrengthenTip", {
        CharacterId = self.CharacterId,
        AfterLevel = character.Level,
        AfterGrade = character.Grade,
        BeforeAttribs = { Life = before.Life, Attack = before.Attack, Defense = before.Defense, Crit = before.Crit },
        AfterAttribs = afterAttribs,
    })
end

--endregion

--region 刷新

--- 把 UI 持有的选择字段收集为 Control 计算入参
function XUiRoleCultureDetailMain:CollectCalcArgs()
    local args = self.CalcArgs
    args.TargetLevel = self.TargetLevel
    args.TargetGrade = self.TargetGrade
    -- 特训态技能拉满：传足够大的目标值，Control 内部会按各技能条件上限 math.min 钳制
    args.SkillTargetLevel = self.UseSpecialTraining and math.maxinteger or self.SkillTargetLevel
    args.IncludeEnhance = self.IncludeEnhance and (self._ShowToggleSkill5 or self._ShowToggleSkill6)
    args.AutoExchange = self.AutoExchange
    return args
end

--- 预览选项变化
function XUiRoleCultureDetailMain:OnPreviewChanged()
    if self.UseSpecialTraining then
        -- 特训态：不计算资源消耗，复用空结果只更新标量字段
        if not self._SpecialTrainingResult then
            self._SpecialTrainingResult = {
                LevelCostMap = table.empty,
                GradeCostMap = table.empty,
                SkillCostMap = table.empty,
                FinalCostMap = table.empty,
                ExchangePlan = table.empty,
                LackMap = table.empty,
                SkillPreviewList = table.empty,
                MaxFullSkillCur = 0,
                MaxFullSkillAdd = 0,
                MaxFullSkillTotal = 0,
            }
        end
        local r = self._SpecialTrainingResult
        local characterId = self.CharacterId
        local maxLevel = XMVCA.XCharacter:GetMaxAvailableLevel(characterId)
        r.MaxSkillLevel = self._Control:CalcMaxSkillLevel(characterId, maxLevel)
        r.MaxReachableLevel = maxLevel
        r.MaxReachableGrade = XMVCA.XCharacter:GetCharMaxGrade(characterId)
        r.MaxReachableSkillLevel = r.MaxSkillLevel
        -- 特训态：普通技能显示到满级（轻量计算，不计材料/消耗）
        -- 一键养成道具不升跃升/独域
        local list, curFull, addFull, total = self._Control:CalcRoleCultureSkillPreviewOnly({
            CharacterId = characterId,
            TargetLevel = maxLevel,
            SkillTargetLevel = math.maxinteger,
            IncludeEnhance = false,
        })
        r.SkillPreviewList = list
        r.MaxFullSkillCur = curFull
        r.MaxFullSkillAdd = addFull
        r.MaxFullSkillTotal = total
        self.CultureResult = r
    else
        self.CultureResult = self._Control:CalcRoleCulturePreview(self:CollectCalcArgs())
        if self.CultureResult then
            local maxSkill = self.CultureResult.MaxSkillLevel or 0
            if self.SkillTargetLevel > maxSkill then
                self.SkillTargetLevel = maxSkill
            end
        end
    end
    self:RefreshAll()
end

--- 重置角色当前状态
function XUiRoleCultureDetailMain:ResetPreviewToCurrent()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    self.TargetLevel = character.Level
    self.TargetGrade = character.Grade
    self.SkillTargetLevel = 0
    self._SkillInitPending = true
    -- 自动兑换沿用本地存档，不随预览重置
    self.AutoExchange = self._Control:GetRoleCultureAutoExchange()
    self.UseSpecialTraining = false
    self:OnPreviewChanged()
end

function XUiRoleCultureDetailMain:RefreshAll()
    local result = self.CultureResult
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    -- 特训态：三项均拉满，技能步进器同步到满级条件下的实际上限
    if self.UseSpecialTraining then
        self.SkillTargetLevel = result.MaxSkillLevel
    elseif self._SkillFromMaxOrAllocate and XTool.IsTableEmpty(result.SkillCostMap) then
        self.SkillTargetLevel = 0
    end
    self._SkillFromMaxOrAllocate = false

    local skillMin = result.FreeSkillLevel or 0
    if self._SkillInitPending then
        self._SkillInitPending = false
        self.SkillTargetLevel = skillMin
    end
    if self.SkillTargetLevel < skillMin then
        self.SkillTargetLevel = skillMin
    end

    self.LevelStepper:Refresh(self.TargetLevel, character.Level, XMVCA.XCharacter:GetMaxAvailableLevel(characterId))
    self.GradeStepper:Refresh(self.TargetGrade, character.Grade, XMVCA.XCharacter:GetCharMaxGrade(characterId))
    self.SkillStepper:Refresh(self.SkillTargetLevel, skillMin, result.MaxSkillLevel)

    self:RefreshCultureInfo(self.TargetLevel, self.TargetGrade)
    self:RefreshMainSkillGrids(result)
    -- PanelSkillPreview 仅在打开时刷新，关闭时不刷新其子节点以免报错
    if self._SkillPreviewOpen then
        self.CultureSkillList:Refresh(result)
    end
    if self.UseSpecialTraining then
        -- 特训态：消耗栏固定显示特训道具 ×1
        self.CultureConsume:RefreshSpecialTraining(self._Control:GetRoleCultureSpecialItemId(), 1)
    else
        self.CultureConsume:Refresh(result)
    end
    self:RefreshEnhanceToggle()
    self:RefreshExchangeToggle()
    self:RefreshPanelCost()
    local specialItemCount = self._Control:GetRoleCultureSpecialItemCount()
    local hasSpecialItem = specialItemCount > 0
    local hasUpgradable = hasSpecialItem and self._Control:CheckRoleCultureHasAnyUpgradable(self:CollectCalcArgs())
    self:RefreshBtnStrengthen(hasUpgradable)
    self:RefreshSpecialTraining(hasSpecialItem, hasUpgradable)
    -- 一键分配按钮：特训态隐藏；否则所有培养项（含跃升/独域）均拉满时隐藏
    local showAllocate = not self.UseSpecialTraining
        and self._Control:CheckRoleCultureHasAnyUpgradable(self:CollectCalcArgs(), true)
    self.BtnOneclickAllocate.gameObject:SetActiveEx(showAllocate)
end

--- 特训道具开关
function XUiRoleCultureDetailMain:RefreshSpecialTraining(hasItem, hasUpgradable)
    self.BtnSpecialTrainingToggle.gameObject:SetActiveEx(hasItem)
    if not hasItem then
        self:ApplySpecialTrainingLock(false)
        return
    end

    local using = self.UseSpecialTraining
    -- 按钮三态各有独立数量文本，按 UiButton 多态规则全部填入持有数量
    local countText = tostring(self._Control:GetRoleCultureSpecialItemCount())
    self.TxtSpecialItemNum.text = countText
    self.TxtSpecialItemNumSelect.text = countText
    self.TxtSpecialItemNumDisable.text = countText
    -- 三维均封顶时禁用；否则按是否选中显示 Select/Normal
    -- 注：SetButtonState 内部按状态自管 disable，故用单次 SetButtonState 而非额外 SetDisable
    local state
    if not hasUpgradable then
        state = CS.UiButtonState.Disable
        self.BtnSpecialTrainingToggle:SetDisable(true, false)
    elseif using then
        state = CS.UiButtonState.Select
    else
        state = CS.UiButtonState.Normal
    end
    self.BtnSpecialTrainingToggle:SetButtonState(state)

    self:ApplySpecialTrainingLock(using)
end

function XUiRoleCultureDetailMain:ApplySpecialTrainingLock(isLocked)
    self.LevelStepper:SetLocked(isLocked)
    self.GradeStepper:SetLocked(isLocked)
    self.SkillStepper:SetLocked(isLocked)
    -- 特训态：隐藏自动兑换开关
    self.ToggleExchange.gameObject:SetActiveEx(not isLocked)
end

function XUiRoleCultureDetailMain:RefreshBtnStrengthen(hasUpgradable)
    if self.UseSpecialTraining then
        self.BtnStrengthen:SetDisable(not hasUpgradable,hasUpgradable)
        return
    end
    local hasAction = next(self.CultureResult.DirectCostMap) ~= nil
    self.BtnStrengthen:SetDisable(not hasAction,hasAction)
end

function XUiRoleCultureDetailMain:RefreshEnhanceToggle()
    -- 特训态：跃升/独域开关锁定隐藏，不参与（IncludeEnhance 恒 false）
    if self.UseSpecialTraining then
        self.PanelToggleSkillItem5.gameObject:SetActiveEx(false)
        self.PanelToggleSkillItem6.gameObject:SetActiveEx(false)
        return
    end

    local showSkill5 = self._ShowToggleSkill5
    local showSkill6 = self._ShowToggleSkill6

    self.PanelToggleSkillItem5.gameObject:SetActiveEx(showSkill5)
    self.PanelToggleSkillItem6.gameObject:SetActiveEx(showSkill6)

    if showSkill5 then
        self.ToggleSkill5:SetButtonState(self.IncludeEnhance and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    elseif showSkill6 then
        self.ToggleSkill6:SetButtonState(self.IncludeEnhance and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiRoleCultureDetailMain:RefreshExchangeToggle()
    self.ToggleExchange:SetButtonState(self.AutoExchange
        and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

--- 强化按钮上方资源条
function XUiRoleCultureDetailMain:RefreshPanelCost()
    local costList = self.CultureResult.PanelCostList or table.empty
    self.PanelCost.gameObject:SetActiveEx(#costList ~= 0 and not self.UseSpecialTraining)
    XTool.UpdateDynamicItemByUiCache(
        self.CostGrids, costList, self.PanelCost.transform, XUiGridCultureCost, self)
end

--- 角色等级/晋升信息（原 CultureInformation 逻辑下沉，StarGroup 已删）
function XUiRoleCultureDetailMain:RefreshCultureInfo(targetLevel, targetGrade)
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    local isLevelPreview = targetLevel > character.Level
    local levelColor = isLevelPreview and COLOR_LEVEL_PREVIEW or COLOR_COST_NORMAL
    self.TxtLevel.text = targetLevel
    self.TxtLevel.color = levelColor
    self.TxtLevel2.text = XMVCA.XCharacter:GetCharMaxLevel(characterId)

    local gradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, targetGrade)
    self.RImgIconTitle:SetRawImage(gradeConfig.GradeBigIcon)
end

--- 主页面三个技能格：排序后前 3 + "+XX"
function XUiRoleCultureDetailMain:RefreshMainSkillGrids(result)
    local top3, total = self.CultureSkillList:GetTopSkills(result.SkillPreviewList, 3)
    XTool.UpdateDynamicItemByUiCache(self.MainSkillGrids, top3, self.PanelSkillList.transform, XUiGridCultureSkill, self)

    -- "+XX" 由主页面控制（More/TxtMoreSkill 已注入主页面），不放进 Grid 类
    local showMore = total > 3
    self.More.gameObject:SetActiveEx(showMore)
    if showMore then
        self.TxtMoreSkill.text = "+" .. (total - 3)
    end
end

--endregion

return XUiRoleCultureDetailMain
