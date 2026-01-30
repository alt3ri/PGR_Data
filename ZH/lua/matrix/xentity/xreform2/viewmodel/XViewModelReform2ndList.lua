---@class XViewModelReform2ndList
local XViewModelReform2ndList = XClass(nil, "XViewModelReform2ndList")

function XViewModelReform2ndList:Ctor(model)
    ---@type XReformModel
    self._Model = model

    self.Data = {
        Pressure = false,
        TxtPressure = false,
        IsPlayPressureEffect = false,
        StageName = false,
        Pressure2NextStar = false,
        PressureIsFull = false,
        StarAmount = 0,
        StarAmountMax = 0,
        IsMatchExtraStar = false,
        TextExtraStar = false,
        ---@type UiReformMobData[]
        MobData = false,
        IsEnableBtnEnter = false,
        IsShowToggleHard = false,
    }
    local toggleFullDesc = XSaveTool.GetData(self._Model:GetToggleFullDescKey())
    self.DataMob = {
        ---@type XUiReformPanelMobData[]
        MobList = false,
        ---@type XReformAffixData[]
        AffixList = false,
        IsDirty = false,
        MobIndexPlayEffect = false,
        Update4Affix = false,
        PlayingAnimation = false,
        IsAutoShowNextMob = false,
        IsShowCompleteButton = false,
        IsFullDesc = toggleFullDesc,
        TextAffixAmount = false,
        TextMobAmount = false,
    }
    self.DataStage = {
        Name = false,
        Number = false,
        Desc = false,
        DescTarget = false,
        IconList = false
    }
    self.DataEnvironment = {
        List = {},
        DataSelectedEnvironment = false,
        ---@type XReform2ndEnv
        SelectedEnvironment = false,
    }

    ---@type XReform2ndStage
    self._Stage = false
    self._CurrentIndex = 1
    ---@type {MobGroup:XReform2ndMobGroup,Index:number}
    self._SelectedMob = {
        MobGroup = false,
        Index = 0,
    }
    self.GridIndex = 0

    self._IsSelectToggleHard = self._Model:GetIsSelectHardMode()
end

---@param stage XReform2ndStage
function XViewModelReform2ndList:SetStage(stage)
    self._Stage = stage
    self.Data.TextExtraStar = XUiHelper.GetText("ReformExtraStar", self._Model:GetStageGoalDescById(stage:GetId()))
end

function XViewModelReform2ndList:Update()
    local data = self.Data
    local stage = self._Stage

    --region pressure
    local pressure = self._Model:GetStagePressureByStage(stage)
    if data.Pressure and pressure ~= data.Pressure then
        data.IsPlayPressureEffect = true
    else
        data.IsPlayPressureEffect = false
    end
    --local pressureMax = stage:GetPressureMax()
    data.TxtPressure = pressure--string.format("<color=#ff8340>%d</color>", pressure)
    data.Pressure = pressure

    local star = self._Model:GetStageStar(stage)
    local starMax = self._Model:GetStageStarMax(stage)
    data.StarAmount = star
    data.StarAmountMax = starMax

    local pressure2NextStar = 0
    local nextStar = star + 1
    if nextStar <= starMax then
        local pressureNextStar = self._Model:GetPressureByStar(nextStar, stage:GetId())
        pressure2NextStar = pressureNextStar - pressure
    end
    if pressure2NextStar > 0 then
        data.Pressure2NextStar = pressure2NextStar--XUiHelper.GetText("ReformNextStar", pressure2NextStar)
        data.PressureIsFull = false
    else
        --data.Pressure2NextStar = XUiHelper.GetText("ReformFullStar")
        data.PressureIsFull = true
    end

    data.IsMatchExtraStar = stage:IsExtraStar()
    --endregion

    --region mob
    data.StageName = self._Model:GetStageName(stage:GetId())
    self:UpdateMobData()
    --endregion

    ---@type XReform2ndChapter
    local chapter = stage:GetChapter(self._Model)
    local isShowToggleHard = chapter:IsShowToggleHard(self._Model)
    self.Data.IsShowToggleHard = isShowToggleHard
end

-- 获取普通难度下的关卡
---@return XReform2ndStage
function XViewModelReform2ndList:GetNormalStage()
    ---@type XReform2ndChapter
    local chapter = self._Stage:GetChapter(self._Model)
    if not chapter then
        return
    end
    local normalStage = chapter:GetStageByDifficulty(self._Model, false)
    return normalStage
end

function XViewModelReform2ndList:UpdateMobData()
    local data = self.Data
    local groupOnlyOne = self:GetMobGroup()

    --region mob data
    data.MobData = {}

    local amountMax = groupOnlyOne:GetMobAmountMax()
    local amount = groupOnlyOne:GetMobAmount()
    self.DataMob.TextMobAmount = amount .. "/" .. amountMax

    local mobCanSelect = groupOnlyOne:GetMobCanSelect()

    --是否选满了
    local isFull = amount >= amountMax

    -- 蓝点提示：困难模式新增的词缀与怪物
    local newMobs = false
    if self._IsSelectToggleHard then
        local stageId = self._Stage:GetId()
        local mobsOnHard = mobCanSelect
        local stageNormal = self:GetNormalStage()
        if stageNormal then
            local mobsOnNormal = self._Model:GetMobCanSelectByStage(stageNormal)
            if mobsOnNormal and mobsOnHard then
                -- 找到mobsOnNormal中不存在，但是mobsOnHard中存在的新怪物
                newMobs = {}
                for _, mobOnHard in ipairs(mobsOnHard) do
                    local isExist = false
                    for _, mobOnNormal in ipairs(mobsOnNormal) do
                        if mobOnNormal:GetNpcId(self._Model) == mobOnHard:GetNpcId(self._Model) then
                            isExist = true
                            break
                        end
                    end
                    if not isExist then
                        local npcId = mobOnHard:GetNpcId(self._Model)
                        if XSaveTool.GetData("ReformRedNewMonsterOnHardMode" .. XPlayer.Id .. stageId .. npcId) == nil then
                            newMobs[npcId] = true
                        end
                    end
                end
            else
                XLog.Error("[XViewModelReform2ndList] 该关卡找不到mobs")
            end
        else
            XLog.Error("[XViewModelReform2ndList] 不存在普通难度关卡")
        end
        --XSaveTool.SaveData("ReformRedNewMonsterOnHardMode" .. XPlayer.Id .. stageId, true)
    end

    -- v3.5 group代表一个格子，现在每个格子的怪物，都是固定的，只有一个
    for i = 1, #mobCanSelect do
        -- 请务必理解这点
        -- 由于每个group配置的可选mob内容都是一样的，所以，每个group的位置也代表了固定位置的mob
        local mob = mobCanSelect[i]
        local label = self._Model:GetMobLabel(mob:GetId())
        local isSelected = groupOnlyOne:IsMobSelected(mob)
        local isLock = isFull and not isSelected
        local isRed = false
        if newMobs and newMobs[mob:GetNpcId(self._Model)] then
            isRed = true
        end
        if isSelected and isRed then
            isRed = false
            local stageId = self._Stage:GetId()
            XSaveTool.SaveData("ReformRedNewMonsterOnHardMode" .. XPlayer.Id .. stageId .. mob:GetNpcId(self._Model), true)
            if XMain.IsZlbDebug then
                XLog.Debug("选中怪物，并取消红点:" .. mob:GetNpcId(self._Model))
            end
        end

        ---@class UiReformMobData
        local mobData = {
            Name = self._Model:GetMobName(mob:GetId()),
            Icon = self._Model:GetMobIcon(mob:GetId()),
            --TextLevel = XUiHelper.GetText("ReformMobLevel", self._Model:GetMobLevel(mob:GetId())),
            Pressure = self._Model:GetMobPressureByMob(mob),
            MobGroup = groupOnlyOne,
            Index = i,
            IsSelected = isSelected,
            IsLock = isLock,
            Mob = mob,
            Label = label,
            IsHard = self._IsSelectToggleHard,
            IsRed = isRed,
        }
        data.MobData[#data.MobData + 1] = mobData
    end
    data.IsEnableBtnEnter = groupOnlyOne:GetMobAmount() > 0
    --endregion
end

function XViewModelReform2ndList:SetButtonGroupIndex(index)
    self._CurrentIndex = index
end

function XViewModelReform2ndList:SetNextButtonGroupIndex()
    if self:IsMaxButtonGroupIndex() then
        return false
    end
    local groupData = self.Data.MobData
    for i = 1, #groupData do
        local data = groupData[i]
        if data.IsAdd then
            self:SetSelectedMobGroup(data)
        end
    end
    return true
end

function XViewModelReform2ndList:IsMaxButtonGroupIndex()
    local group = self._Model:GetMonsterGroupByIndex(self._Stage, self._CurrentIndex)
    return group:GetMobAmount() >= group:GetMobAmountMax()
end

function XViewModelReform2ndList:GetButtonGroupIndex()
    return self._CurrentIndex
end

-----@param stage1 XReform2ndStage
-----@param stage2 XReform2ndStage
--function XViewModelReform2ndList:SyncStage2Another(stage1, stage2)
--    local model = self._Model
--    if not stage2 then
--        local chapter = stage1:GetChapter(model)
--        local stageList = chapter:GetStageList(model)
--        if not stageList[2] then
--            return false
--        end
--        if stageList[1] == stage1:GetId() then
--            stage2 = model:GetStage(stageList[2])
--        else
--            stage2 = model:GetStage(stageList[1])
--        end
--    end
--    if not stage2 then
--        return false
--    end
--
--    ---@type XReform2ndMobGroup[]
--    local mobGroupList1 = model:GetMobGroupByStage(stage1)
--
--    ---@type XReform2ndMobGroup[]
--    local mobGroupList2 = model:GetMobGroupByStage(stage2)
--
--    -- 三层遍历, 同步怪物组, 怪物, 词缀
--    for i = 1, #mobGroupList1 do
--        local mobGroup1 = mobGroupList1[i]
--        local mobGroup2 = mobGroupList2[i]
--        if mobGroup1:IsEmpty() then
--            mobGroup2:ClearMob()
--        else
--            local mobAmount1 = mobGroup1:GetMobAmount()
--            local mobAmount2 = mobGroup2:GetMobAmount()
--            for j = 1, mobAmount1 do
--                local mobSelected1 = mobGroup1:GetMob(j)
--                local index = mobGroup1:GetMobCanSelectIndex(mobSelected1)
--                if index then
--                    local mobCanSelect2 = mobGroup2:GetMobCanSelect()
--                    local mobSelected2 = mobCanSelect2[index]
--                    if mobSelected2 then
--                        mobSelected2 = mobSelected2:Clone()
--                        mobGroup2:SetMob(j, mobSelected2)
--
--                        local affixListCanSelect1 = self:GetAffixCanSelectByMob(mobSelected1)
--                        local affixListCanSelect2 = self:GetAffixCanSelectByMob(mobSelected2)
--                        for k = 1, #affixListCanSelect1 do
--                            local affix1 = affixListCanSelect1[k]
--                            local affix2 = affixListCanSelect2[k]
--                            if mobSelected1:IsAffixSelected(affix1) then
--                                mobSelected2:SetAffixSelected(affix2)
--                            else
--                                mobSelected2:SetAffixUnselected(affix2)
--                            end
--                        end
--                    end
--                else
--                    mobGroup2:SetMob(j, false)
--                end
--            end
--            for j = mobAmount1 + 1, mobAmount2 do
--                mobGroup2:SetMob(j, false)
--            end
--        end
--    end
--    return stage2
--end

function XViewModelReform2ndList:RequestResetReformData()
    local stage = self._Stage
    local model = self._Model

    ---@type XReform2ndChapter
    local chapter = stage:GetChapter(model)
    local stageList = chapter:GetStageList(model)
    for i = 1, #stageList do
        local stageId = stageList[i]
        local childStage = model:GetStage(stageId)

        local groups = model:GetMobGroupByStage(childStage)
        for i = 1, #groups do
            local group = groups[i]

            local mobCanSelect = group:GetMobCanSelect()
            for i = 1, #mobCanSelect do
                local mob = mobCanSelect[i]
                mob:ClearAffixSelected()
            end

            local mobAmount = group:GetMobAmountMax()
            for j = 1, mobAmount do
                group:ClearMob()
            end
            XMVCA.XReform:RequestSave(group)
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_UPDATE_MOB)
end

function XViewModelReform2ndList:RequestSaveReformData()
    local stageId = self._Stage:GetId()
    local team = XDataCenter.Reform2ndManager.GetTeam(stageId)
    local replaceStageId4Affix = self._Model:GetSubStage(self._Stage)
    if replaceStageId4Affix then
        stageId = replaceStageId4Affix
        if XMain.IsEditorDebug then
            XLog.Error(string.format("[XViewModelReform2ndList] 触发替换, %s替换为:%s", self._Stage:GetId(), replaceStageId4Affix))
        end
    end
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, require("XUi/XUiReform2nd/MainPage/XUiReform2ndBattleRoleRoom"))
end

---@param data UiReformMobData
function XViewModelReform2ndList:SetSelectedMobGroup(data)
    self._SelectedMob.MobGroup = data.MobGroup
    self._SelectedMob.Index = data.Index
    local mobData = self.Data.MobData
    for i = 1, #mobData do
        if mobData[i] == data then
            self.GridIndex = i
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_MOB_GROUP)
end

function XViewModelReform2ndList:UpdateSelectedMob()
    local data = self.DataMob
    local mobGroup = self._SelectedMob.MobGroup
    if not mobGroup then
        return
    end
    local isHardModeUnlock = self._Model:GetStageIsUnlockedDifficulty(self._Stage)
    local mobList = mobGroup:GetMobCanSelect()
    local mobCanSelect = {}
    for i = 1, #mobList do
        local mob = mobList[i]
        local isHardMode = self._Model:GetMobIsHardMode(mob:GetId())
        local isShow = true
        if isHardMode and not isHardModeUnlock then
            isShow = false
        end
        if isShow then
            local isSelected, mobSelected = mobGroup:IsMobSelected(mob)
            -- 因为被选中的mob可能添加了词缀, 不同于候选mob
            if isSelected then
                mob = mobSelected
            end
            local affixIconList = self:GetAffixIconList(mob)
            ---@class XUiReformPanelMobData
            local mobData = {
                Name = self._Model:GetMobName(mob:GetId()),
                Level = self._Model:GetMobLevel(mob:GetId()),
                Icon = self._Model:GetMobIcon(mob:GetId()),
                IconBuff = affixIconList,
                Pressure = self._Model:GetMobPressureByMob(mob),
                IsSelected = isSelected,
                Mob = mob,
            }
            mobCanSelect[#mobCanSelect + 1] = mobData
        end
    end
    data.MobList = mobCanSelect

    local stage = self._Stage
    local monsterGroup = self._Model:GetMonsterGroupByIndex(stage, self._CurrentIndex)
    if monsterGroup:IsEmpty() then
        data.IsAutoShowNextMob = true
    end

    local isShowCompleteButton = false

    -- 已选好一个怪的时候
    if self._SelectedMob.MobGroup then
        local mob = self._SelectedMob.MobGroup:GetMob(1)
        if mob then
            isShowCompleteButton = true
        end
    end

    -- 自动选择中
    if data.IsAutoShowNextMob then
        isShowCompleteButton = false

        if self._SelectedMob.MobGroup and self._SelectedMob.Index > 1 then
            local mob = self._SelectedMob.MobGroup:GetMob(self._SelectedMob.Index)
            if not mob then
                isShowCompleteButton = true
            end
        end
    end

    data.IsShowCompleteButton = isShowCompleteButton
end

function XViewModelReform2ndList:CloseAutoShowNextMob()
    self.DataMob.IsAutoShowNextMob = false
end

function XViewModelReform2ndList:GetNormalAffixList()
    local stageOnNormal = self:GetNormalStage()
    if stageOnNormal then
        local mobs = self._Model:GetMobCanSelectByStage(stageOnNormal)
        local firstMob = mobs[1]
        if firstMob then
            return self:GetAffixCanSelectByMob(firstMob)
        end
    end
    return false
end

function XViewModelReform2ndList:UpdateMobAffix()
    local data = self.DataMob
    local groupOnlyOne = self:GetMobGroup()
    if not groupOnlyOne then
        return
    end

    local mob = groupOnlyOne:GetMobCanSelect()[1]
    if not mob then
        return
    end
    local isHardModeUnlock = self._Model:GetStageIsUnlockedDifficulty(self._Stage)

    local affixAmount = mob:GetAffixAmount()
    local maxAffixAmount = self._Model:GetMobAffixMaxCountByMob(mob)
    data.TextAffixAmount = affixAmount .. "/" .. maxAffixAmount

    local isFull = affixAmount >= maxAffixAmount
    local affixList = self:GetAffixCanSelectByMob(mob)

    -- 蓝点提示：困难模式新增的词缀与怪物
    local newAffix = false
    if self._IsSelectToggleHard then
        local stageId = self._Stage:GetId()
        local affixOnHard = affixList
        local affixOnNormal = self:GetNormalAffixList()
        if affixOnHard and affixOnNormal then
            newAffix = {}
            for i = 1, #affixOnHard do
                local affix = affixOnHard[i]
                local isExist = false
                for j = 1, #affixOnNormal do
                    local affixNormal = affixOnNormal[j]
                    if affix:GetId() == affixNormal:GetId() then
                        isExist = true
                        break
                    end
                end
                if not isExist then
                    local affixId = affix:GetId()
                    if XSaveTool.GetData("ReformRedNewAffixOnHardMode" .. XPlayer.Id .. stageId .. affixId) == nil then
                        newAffix[affixId] = true
                    end
                end
            end
        else
            XLog.Error("[XViewModelReform2ndList] 不存在普通难度词缀?")
        end
        --XSaveTool.SaveData("ReformRedNewAffixOnHardMode" .. XPlayer.Id .. stageId, true)
    end

    data.AffixList = {}
    local isFullDesc = data.IsFullDesc
    for i = 1, #affixList do
        ---@type XReform2ndAffix
        local affix = affixList[i]
        local isShow = true
        if self._Model:GetAffixIsHardMode(affix:GetId()) and not isHardModeUnlock then
            isShow = false
        end
        local isSelected = mob:IsAffixSelected(affix)

        local isShowMask = false
        if not isSelected then
            if self._Model:CheckAffixMutex(mob, affix) then
                isShowMask = true
            end
        end

        if isShow then
            local desc
            if isFullDesc then
                desc = self._Model:GetAffixDesc(affix:GetId())
            else
                desc = self._Model:GetAffixSimpleDesc(affix:GetId())
            end
            local isRed = false
            if newAffix and newAffix[affix:GetId()] then
                isRed = true
            end
            if isSelected and isRed then
                isRed = false
                local stageId = self._Stage:GetId()
                XSaveTool.SaveData("ReformRedNewAffixOnHardMode" .. XPlayer.Id .. stageId .. affix:GetId(), true)
                XLog.Debug("选中词缀，并取消红点:" .. affix:GetId())
            end
            local isLock = isFull and not isSelected
            ---@class XReformAffixData
            local dataAffix = {
                Name = self._Model:GetAffixName(affix:GetId()),
                Desc = desc,
                Icon = self._Model:GetAffixIcon(affix:GetId()),
                Pressure = self._Model:GetAffixPressure(affix:GetId()),
                IsSelected = isSelected,
                IsLock = isLock,
                Affix = affix,
                IsMutex = self._Model:IsMutexAffix(affix:GetId()),
                IsShowMask = isShowMask,
                IsHard = self._IsSelectToggleHard,
                IsRed = isRed,
            }
            data.AffixList[#data.AffixList + 1] = dataAffix
        end
    end
end

function XViewModelReform2ndList:SetIsFullDesc(value)
    self.DataMob.IsFullDesc = value
    XSaveTool.SaveData(self._Model:GetToggleFullDescKey(), value)
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_AFFIX)
end

function XViewModelReform2ndList:GetIsFullDesc()
    return self.DataMob.IsFullDesc
end

---@param mob XReform2ndMob
function XViewModelReform2ndList:GetAffixIconList(mob)
    local affixIconList = {}
    local affixList = mob:GetAffixList()
    for i = 1, #affixList do
        local affix = affixList[i]
        local icon = self._Model:GetAffixIcon(affix:GetId())
        ---@class XUiReformAffixIconData
        local data = {
            Name = self._Model:GetAffixName(affix:GetId()),
            Desc = self._Model:GetAffixSimpleDesc(affix:GetId()),
            DescDetail = self._Model:GetAffixDesc(affix:GetId()),
            Icon = icon,
            IsEmpty = false
        }
        affixIconList[i] = data
    end
    local affixAmountMax = self._Model:GetMobAffixMaxCountByMob(mob)
    for i = #affixList + 1, affixAmountMax do
        affixIconList[i] = {
            Icon = false,
            IsEmpty = true
        }
    end
    return affixIconList
end

function XViewModelReform2ndList:IsMobSelected()
    local mobGroup = self._SelectedMob.MobGroup
    local index = self._SelectedMob.Index
    return mobGroup:GetMob(index) and true or false
end

function XViewModelReform2ndList:ClearSelected()
    self._SelectedMob.Index = 0
end

function XViewModelReform2ndList:ClearMobDirty()
    if self.DataMob.IsDirty then
        self.DataMob.MobIndexPlayEffect = self._SelectedMob.Index
        self.DataMob.IsDirty = false
    end
end

---@param data UiReformMobData
function XViewModelReform2ndList:SetSelectedMob(data)
    local mobGroup = data.MobGroup
    if mobGroup then
        local mob = data.Mob
        if mob then
            --选中
            local isMobSelected, index = mobGroup:IsMobSelected(mob)
            if isMobSelected then
                mobGroup:SetMob(index, false)
                self._SelectedMob.Index = mobGroup:GetMobAmount() + 1
                self.DataMob.IsDirty = true

                -- 未选中
            else
                local pressure = self._Model:GetMobPressureByMob(mob)
                if self._Model:IsOverPressure(self._Stage, pressure) then
                    XUiManager.TipText("ReformPressureMax")
                    return false
                end
                local mobClone = mob:Clone()
                if not mobGroup:AddMob(mobClone) then
                    XUiManager.TipText("ReformSelectFull")
                    return false
                end

                local mobCanSelect = mobGroup:GetMobCanSelect()
                local firstMob = mobCanSelect[1]
                if firstMob then
                    local affix = firstMob:GetAffixList()
                    for i = 1, #affix do
                        mobClone:SetAffixSelected(affix[i])
                    end
                end

                -- 新增加的放到最左边
                self._SelectedMob.Index = 1
                self.DataMob.IsDirty = true
                --else
                --    local pressure = self._Model:GetMobPressureByMob(mob) - self._Model:GetMobPressureByMob(mobSelected)
                --    if self._Model:IsOverPressure(self._Stage, pressure) then
                --        XUiManager.TipText("ReformPressureMax")
                --        return false
                --    end
                --    mobGroup:SetMob(index, mob:Clone())
                --    self.DataMob.IsDirty = true
            end

            --local stage2 = self:SyncStage2Another(mobGroup:GetStage())
            --if stage2 then
            --    XMVCA.XReform:RequestSave(self._Model:GetMonsterGroupByIndex(stage2), nil, nil, true)
            --end
            --XMVCA.XReform:RequestSave(mobGroup, nil, nil, true)
        else
            XLog.Error("[XViewModelReform2ndList] select mob error, mob is empty")
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_MOB)
    return true
end

function XViewModelReform2ndList:SetAffixSelected4MobList(mobList, affix, value, noTip)
    for i = 1, #mobList do
        local mob = mobList[i]
        if not value then
            mob:SetAffixUnselected(affix)
        else
            if mob:GetAffixAmount() >= self._Model:GetMobAffixMaxCountByMob(mob) then
                if not noTip then
                    XUiManager.TipText("ReformAffixMax")
                end
                return false
            end
            if self._Model:IsOverPressure(self._Stage, self._Model:GetAffixPressure(affix:GetId())) then
                if not noTip then
                    XUiManager.TipText("ReformPressureMax")
                end
                return false
            end
            -- 互斥检测
            local isMutex = self._Model:CheckAffixMutex(mob, affix)
            if isMutex then
                if not noTip then
                    XUiManager.TipText("ReformAffixMutex2")
                end
                return false
            end

            mob:SetAffixSelected(affix)
        end
    end
end

---@param data XReformAffixData
function XViewModelReform2ndList:SetAffixSelected(data)
    local affix = data.Affix
    local mobGroup = self:GetMobGroup()

    local mobCanSelect = mobGroup:GetMobCanSelect()
    self:SetAffixSelected4MobList(mobCanSelect, affix, not data.IsSelected)

    local mobList = mobGroup:GetMobList()
    self:SetAffixSelected4MobList(mobList, affix, not data.IsSelected)

    self.DataMob.IsDirty = true
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_AFFIX)
    --XMVCA.XReform:RequestSave(mobGroup)
    return false
end

function XViewModelReform2ndList:RequestSaveSelectedMobGroup(oneKeyConfig)
    if self.DataMob.IsDirty then
        local mobGroup = self:GetMobGroup()

        -- 3.5 不把内容同步到另一关
        --local stage1 = mobGroup:GetStage()
        --local stage2 = self:SyncStage2Another(stage1)
        --if stage2 then
        --    local mogGroup2 = self._Model:GetMonsterGroupByIndex(stage2)
        --    XMVCA.XReform:RequestSave(mogGroup2, nil, oneKeyConfig)
        --end
        self.DataMob.IsDirty = false
        XMVCA.XReform:RequestSave(mobGroup, nil, oneKeyConfig)
    end
end

function XViewModelReform2ndList:UpdateStage()
    local data = self.DataStage
    local stage = self._Stage
    data.Name = self._Model:GetStageName(stage:GetId())
    local chapter = stage:GetChapter(self._Model)
    if chapter then
        data.Desc = self._Model:GetChapterEventDescById(chapter:GetId())
    end
    data.DescTarget = self._Model:GetStageGoalDescById(stage:GetId())
    data.Number = stage:GetStageNumberText()

    local iconList = {}
    local characterIdList = self._Model:GetStageRecommendCharacterIds(stage:GetId())
    for i = 1, #characterIdList do
        local characterId = characterIdList[i]
        local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
        iconList[#iconList + 1] = icon
    end
    data.IconList = iconList
end

function XViewModelReform2ndList:SetUpdate4Affix(value)
    self.DataMob.Update4Affix = value
end

function XViewModelReform2ndList:SetPlayingAnimationScroll(value)
    self.DataMob.PlayingAnimation = value
end

--region environment
function XViewModelReform2ndList:UpdateEnvironment()
    local stage = self._Stage
    local environments = stage:GetEnvironments(self._Model)
    local list = {}
    self.DataEnvironment.List = list
    local currentEnvironment = stage:GetSelectedEnvironment(self._Model)

    for i = 1, #environments do
        local environment = environments[i]
        ---@class XViewModelReformEnvironment
        local dataEnvironment = {
            Name = environment:GetName(self._Model),
            Icon = environment:GetTextIcon(self._Model),
            Desc = environment:GetDesc(self._Model),
            AddScore = environment:GetAddScore(self._Model),
            EnvironmentId = environment:GetId(),
            IsSelected = environment == currentEnvironment,
            Index = i,
        }
        list[#list + 1] = dataEnvironment
    end
end

function XViewModelReform2ndList:UpdateSelectedEnvironment()
    local stage = self._Stage
    local currentEnvironment = stage:GetSelectedEnvironment(self._Model)
    if currentEnvironment then
        local data = {}
        self.DataEnvironment.DataSelectedEnvironment = data
        data.Name = currentEnvironment:GetName(self._Model)
        data.Icon = currentEnvironment:GetIcon(self._Model)
        data.Desc = currentEnvironment:GetDesc(self._Model)
        data.Index = 1
    else
        self.DataEnvironment.DataSelectedEnvironment = nil
    end
end

function XViewModelReform2ndList:GetUiDataEnvironment()
    return self.DataEnvironment
end

function XViewModelReform2ndList:RequestSetEnvironment()
    if not self.DataEnvironment.SelectedEnvironment then
        XLog.Error("[XViewModelReform2ndList] select nothing")
        return
    end
    local stageId = self._Stage:GetId()
    local environmentId = self.DataEnvironment.SelectedEnvironment:GetId()
    XMVCA.XReform:RequestSelectEnvironment(stageId, environmentId)
end

function XViewModelReform2ndList:SetSelectedEnvironment(environmentId)
    local stage = self._Stage
    local environments = stage:GetEnvironments()
    for i = 1, #environments do
        local environment = environments[i]
        if environment:GetId() == environmentId then
            self.DataEnvironment.SelectedEnvironment = environment
            self:RequestSetEnvironment()
        end
    end
end
--endregion

---@param mob XReform2ndMob
function XViewModelReform2ndList:GetAffixCanSelectByMob(mob)
    return self._Model:GetAffixCanSelectByMob(mob)
end

-- 有且只有一个互斥词缀
function XViewModelReform2ndList:CheckAffixMutex(forceFixAffixMutex)
    if not self._SelectedMob then
        return false
    end
    local mobList = self._SelectedMob.MobGroup:GetMobList()
    return self._Model:CheckMobListAffixMutex(mobList, forceFixAffixMutex)
end

function XViewModelReform2ndList:IsShowToggleHard()
    return self.Data.IsShowToggleHard
end

function XViewModelReform2ndList:OnClickToggleHard(isOn)
    self._IsSelectToggleHard = isOn
    self._Model:SetIsSelectHardMode(isOn)

    -- 未进入关卡界面
    if not self._Stage then
        return
    end

    local model = self._Model

    ---@type XReform2ndChapter
    local chapter = self._Stage:GetChapter(model)
    if not chapter then
        return
    end
    local stage2Select = chapter:GetStageByDifficulty(model, isOn)
    if not stage2Select then
        return
    end
    self:SetStage(stage2Select)
end

function XViewModelReform2ndList:HasRecommend()
    local recommendConfig = self._Model:GetReformRecommend(self._Stage:GetId())
    return recommendConfig and recommendConfig.Mob and #recommendConfig.Mob > 0
end

function XViewModelReform2ndList:OnClickRecommend()
    self.DataMob.IsDirty = true

    local recommendConfig = self._Model:GetReformRecommend(self._Stage:GetId())
    local mobGroup = self._Model:GetMonsterGroupByIndex(self._Stage)
    self._SelectedMob.MobGroup = mobGroup

    mobGroup:ClearMob()
    local mobCanSelect = mobGroup:GetMobCanSelect()
    for i = 1, #mobCanSelect do
        local mob = mobCanSelect[i]
        mob:ClearAffixSelected()
    end

    local mobList = mobGroup:GetMobList()
    for i = 1, #recommendConfig.Mob do
        local index = recommendConfig.Mob[i]
        local mob = mobCanSelect[index]:Clone()
        mobGroup:SetMob(i, mob)

        local affixIndexList = recommendConfig.Affix[i]
        for j = 1, #affixIndexList do
            local affixIndex = affixIndexList[j]
            local affixCanSelect = self:GetAffixCanSelectByMob(mob)
            self:SetAffixSelected4MobList(mobCanSelect, affixCanSelect[affixIndex], true, true)
            self:SetAffixSelected4MobList(mobList, affixCanSelect[affixIndex], true, true)
        end
    end

    self:RequestSaveSelectedMobGroup(true)
end

function XViewModelReform2ndList:IsSelectToggleHard()
    return self._IsSelectToggleHard
end

---@return XReform2ndChapter
function XViewModelReform2ndList:GetCurrentChapter()
    return self._Stage:GetChapter(self._Model)
end

function XViewModelReform2ndList:IsOnStage(stageId)
    if self._Stage then
        return self._Stage:GetId() == stageId
    end
    return false
end

function XViewModelReform2ndList:GetCurrentStageId()
    return self._Stage and self._Stage:GetId()
end

function XViewModelReform2ndList:GetMobGroup()
    local groupArray = self._Model:GetMobGroupByStage(self._Stage)
    local groupOnlyOne = groupArray[1]
    return groupOnlyOne
end

return XViewModelReform2ndList
