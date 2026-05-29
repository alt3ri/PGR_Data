local Fuben = {}
local Character = {}
local DlcCharacter = {}
local DlcFuben = {}
local DlcCondition = {}
local BigWorld = {}
local Player = {}
local SetConfigs = {}
local LoginManager = {}
local Equip = {}
local Set = {}
local PhotographManager = {}
local X3CProxy = {}
local Theatre4 = {}
local UIInterface = {}
local Theatre5 = {}
local ConditionManager = {}
local UiDialog = {}
local VideoManager = {}
local CommonGuide = {}
local Movie = {}
local Function = {}
local Theatre6 = {}
local Time = {}
local FashionManager = {}

local TrueString = "True"
local FalseString = "False"

function Fuben.CheckSettleFight()
    return XDataCenter.FubenManager.CheckSettleFight()
end

function Fuben.GetStageRebootId(stageId)
    return XDataCenter.FubenManager.GetStageRebootId(stageId)
end

function Fuben.GetStageBgmId(stageId)
    return XDataCenter.FubenManager.GetStageBgmId(stageId)
end

function Fuben.GetStageAmbientSound(stageId)
    return XDataCenter.FubenManager.GetStageAmbientSound(stageId)
end

function Fuben.GetStageOnlineMsgId(stageId)
    return XDataCenter.FubenManager.GetStageOnlineMsgId(stageId)
end

function Fuben.GetStageForceAllyEffect(stageId)
    return XDataCenter.FubenManager.GetStageForceAllyEffect(stageId)
end

function Fuben.GetStageResetHpCounts(stageId)
    return XDataCenter.FubenManager.GetStageResetHpCounts(stageId)
end

function Fuben.GetAssistTemplateInfo()
    return XDataCenter.FubenManager.GetAssistTemplateInfo()
end

function Fuben.GetStageCfg(stageId)
    return XDataCenter.FubenManager.GetStageCfg(stageId)
end

function Fuben.GetStageType(stageId)
    return XDataCenter.FubenManager.GetStageType(stageId)
end

--点击黑屏，模拟关闭教学操作
function Fuben.CloseGuideUI()
    local uiGuide = CsXUiManager.Instance:FindTopUi("UiGuide")
    if uiGuide then
        local proxy = uiGuide.UiProxy.UiLuaTable
        proxy:OnBtnPassClick() 
    end
end

function Fuben.GetStageName(stageId)
    local _, stageName = XMVCA.XFuben:GetFubenNames(stageId)
    return stageName
end

function Character.GetFightCharHeadIcon(character, characterId)
    return XMVCA.XCharacter:GetFightCharHeadIcon(character, characterId)
end

function Character.GetCharSmallHeadIconByCharacter(character)
    return XMVCA.XCharacter:GetCharSmallHeadIconByCharacter(character)
end

function Character.GetCharacter(id)
    return XMVCA.XCharacter:GetCharacter(id)
end

function Character.GetCharacterNpcDic(id)
    return XMVCA.XCharacter:GetCharacterNpcDic(id)
end

function Character.GetCharacterIdByNpcId(id)
    return XMVCA.XCharacter:GetCharacterIdByNpcId(id)
end

function DlcCharacter.GetFightCharHeadIcon(worldType, worldNpcData)
    if not worldNpcData then
        XLog.Error("CsCallLua.DlcCharacter.GetFightCharHeadIcon 参数错误: worldNpcData == null")

        return nil
    end
    
    local headIcon = XMVCA.XDlcHelper:GetDlcFightCharHeadIcon(worldType, worldNpcData)
    return headIcon
end

function DlcCharacter.GetCommandantNpcData()
    return XMVCA.XBigWorldCharacter:GetCommandantNpcData()
end

function DlcFuben.GetWorldType(worldId)
    return XMVCA.XDlcWorld:GetWorldTypeById(worldId)
end

function DlcFuben.GetModelIdByWorldNpcData(worldType, npcData)
    if not npcData then
        XLog.Error("CsCallLua.DlcFuben.GetModelIdByCharacterData 参数错误: npcData == null")

        return nil
    end

    local characterData = npcData.Character

    if not characterData then
        XLog.Error("CsCallLua.DlcFuben.GetModelIdByCharacterData 参数错误: npcData.Character == null")

        return nil
    end
    
    local modelId = XMVCA.XDlcHelper:GetDlcModelIdWithWorldType(worldType, characterData)

    if string.IsNilOrEmpty(modelId) then
        return nil
    end

    return modelId
end

function DlcFuben.GetModelIdByFashionId(worldType, fashionId, colorId)
    if not XTool.IsNumberValid(fashionId) then
        XLog.Error("CsCallLua.DlcFuben.GetModelIdByFashionId 参数错误: fashionId is invalid")

        return nil
    end
    
    local modelId = XMVCA.XDlcHelper:GetDlcModelIdWithWorldTypeAndFashionId(worldType, fashionId, colorId)

    if string.IsNilOrEmpty(modelId) then
        return nil
    end

    return modelId
end

function DlcFuben.GetAnimExpressionSOGroupIdByWorldType(worldType, fashionId)
    if not fashionId then
        XLog.Error("CsCallLua.DlcFuben.GetAnimExpressionSOGroupIdByWorldType 参数错误: fashionId == null")

        return 0
    end
    local groupId = XMVCA.XDlcHelper:GetAnimExpressionSOGroupId(worldType, fashionId)
    return groupId
end

function DlcFuben.CheckLevelPlayFullCleared(worldType, levelPlayId)
    if not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("CsCallLua.DlcFuben.CheckLevelPlayFullCleared 参数错误: levelPlayId is invalid")
        return false
    end

    return XMVCA.XDlcHelper:CheckLevelPlayFullCleared(worldType, levelPlayId)
end

function DlcFuben.CheckLevelPlayCleared(worldType, levelPlayId)
    if not XTool.IsNumberValid(levelPlayId) then
        XLog.Error("CsCallLua.DlcFuben.CheckLevelPlayFullCleared 参数错误: levelPlayId is invalid")
        return false
    end

    return XMVCA.XDlcHelper:CheckLevelPlayCleared(worldType, levelPlayId)
end

function DlcFuben.GetColorNameByColorId(colorId)
    if XTool.IsNumberValid(colorId) then
        return XMVCA.XBigWorldCommanderDIY:GetMaterialNameByColorId(colorId)
    end

    return nil
end

function DlcFuben.GetColorNameByColorId(colorId)
    if XTool.IsNumberValid(colorId) then
        return XMVCA.XBigWorldCommanderDIY:GetMaterialNameByColorId(colorId)
    end

    return nil
end

function DlcFuben.GetNpcPartModelDataByPartData(npcPartData)
    if not npcPartData or not npcPartData.PartList then
        return nil
    end

    local partList = XTool.CsList2LuaTable(npcPartData.PartList)

    return XMVCA.XBigWorldCommanderDIY:GetNpcPartModelData(partList)
end

function DlcFuben.GetNpcPartDataByGender(gender)
    return XMVCA.XBigWorldCommanderDIY:GetNpcPartDataByGender(gender)
end

function BigWorld.GetCurrentGender()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldCommanderDIY) then
        XLog.Error("未初始化DIY模块，请勿调用当前接口！")
        return XEnumConst.PlayerFashion.Gender.Male
    end
    return XMVCA.XBigWorldCommanderDIY:GetCurrentGender()
end

function DlcFuben.GetBigWorldText(key)
    return XMVCA.XBigWorldService:GetText(key)
end

function DlcFuben.InitDefaultFightDelegate()
    ---@type XDlcActivityAgency
    local agency = require("XModule/XBase/XDlcActivityAgency")

    CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = Handler(agency, agency.DlcGetBaseAttrib)
    CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = Handler(agency, agency.DlcGetNpcAttrib)
    CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = Handler(agency, agency.DlcGetWorldNpcBornMagicLevelMap)
end

function DlcFuben.ClearDefaultFightDelegate()
    CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = nil
    CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = nil
    CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = nil
end

function DlcCondition.CheckCondition(conditionId)
    return XMVCA.XBigWorldService:CheckCondition(conditionId)
end

function DlcCondition.GetDlcConditionDesc(conditionId)
    return XMVCA.XBigWorldService:GetDlcConditionDesc(conditionId)
end

function Player.GetLevel()
    return XPlayer.GetLevel()
end

function Player.GetGender()
    return XPlayer.Gender
end

--- 获取玩家头像、头像框
function Player.GetHeadPortraitImgSrcById(id)
    ---@type XTableHeadPortrait
    local cfg = XDataCenter.HeadPortraitManager.GetHeadPortraitInfoById(id)

    if cfg then
        return cfg.ImgSrc
    end
    return ''
end

function SetConfigs.GetDefaultKeyMapIds(id)
    local cfg = XSetConfigs.GetControllerMapCfg()
    return cfg[id] and cfg[id].DefaultKeyMapIds
end

-- 按键设置，是否需要同时把相同按键映射到不同映射功能中
function SetConfigs.IsControllerMapSetButtonType(id)
    local cfg = XSetConfigs.GetControllerMapCfg()
    return cfg[id] and cfg[id].Type == XSetConfigs.ControllerSetItemType.SetButton
end

function SetConfigs.GetStageName(stageId, ignoreError)
    return XFubenConfigs.GetStageName(stageId, ignoreError)
end

function SetConfigs.GetStageRobotIdList(stageId, ignoreError)
    return XFubenConfigs.GetStageRobotIdList(stageId, ignoreError)
end

function LoginManager.SetHeartbeatTimeout(heartbeatTimeout)
    XLoginManager.SetHeartbeatTimeout(heartbeatTimeout)
end

-- 重置心跳超时时间
function LoginManager.ResetHeartbeatTimeout()
    XLoginManager.ResetHeartbeatTimeout()
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponModelNameList(templateId)
    local nameList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    for _, modelId in pairs(template.ModelTransId) do
        local modelName = XMVCA.XEquip:GetEquipModelName(modelId, usage)
        table.insert(nameList, modelName)
    end
    return nameList
end

function Equip.GetWeaponModelNameListByModelId(id)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local modelName = XMVCA.XEquip:GetEquipModelName(id, usage)
    return modelName
end


--- @desc 获取武器Low模型名字列表(战斗用)
function Equip.GetWeaponLowModelNameList(templateId)
    local nameList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    if template == null then return nameList end
    
    for _, modelId in pairs(template.ModelTransId) do
        local modelName = XMVCA.XEquip:GetEquipLowModelName(modelId, usage)
        table.insert(nameList, modelName)
    end
    return nameList
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponModelNameListByFight(fightNpcData)
    local nameList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(nameList, XMVCA.XEquip:GetEquipModelName(modelId, usage))
            end
            break
        end
    end
    return nameList or {}
end

-- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponLowModelNameListByFight(fightNpcData)
    local nameList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(nameList, XMVCA.XEquip:GetEquipLowModelName(modelId, usage))
            end
            break
        end
    end
    return nameList or {}
end


--- @desc 获取武器模型Hash,同组使用一个Name.hash，获取一次就行
function Equip.GetWeaponModelHashListByFight(fightNpcData)
    local name = ""
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                name =  XMVCA.XEquip:GetEquipModelHash(modelId, usage)
                break
            end
        end
    end
    return name
end


--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器动画controller(战斗用)
function Equip.GetWeaponControllerList(templateId)
    local controllerList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    for _, modelId in pairs(template.ModelTransId) do
        local controller = XMVCA.XEquip:GetEquipAnimController(modelId, usage)
        table.insert(controllerList, controller or "")
    end
    return controllerList
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模动画controller(战斗用)
function Equip.GetWeaponControllerListByFight(fightNpcData)
    local controllerList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId =
        fightNpcData.WeaponFashionId or
        XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(controllerList, XMVCA.XEquip:GetEquipAnimController(modelId, usage))
            end
            break
        end
    end
    return controllerList
end

--[[ MVCA改造时，XEquipManager未找到该函数，翻以前日志也未找到
function Equip.GetWeaponAnimStateNameByFight(fightNpcData)
    
end
]]

--- @desc 获取角色武器共鸣特效(战斗用)
function Equip.GetWeaponResonanceEffectPathByFight(fightNpcData)
    return XMVCA.XEquip:GetWeaponResonanceEffectPathByFight(fightNpcData)
end

--- @desc 获取灵敏度值(战斗用)
function Set.GetSensitivityValue(id)
    return XDataCenter.SetManager.GetSensitivityValue(id)
end

--- @desc 设置灵敏度(战斗用)
function Set.SetSensitivityValue(id, value)
    XDataCenter.SetManager.SetSensitivityValue(id, value)
end

--- @desc 打开灵敏度设置界面(战斗用)
function Set.OpenSensitivityUi()
    XDataCenter.SetManager.OpenSensitivityUi()
end

function PhotographManager.SharePhotoBefore(texture)
    local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
    XDataCenter.PhotographManager.SharePhotoBefore(photoName, texture, XPlatformShareConfigs.PlatformType.Local)
end

function X3CProxy.Receive(cmd, data)
    return XMVCA.X3CProxy:Receive(cmd, data)
end

function X3CProxy.CheckPrintEnable()
    return XMVCA.X3CProxy:CheckPrintEnable()
end

function X3CProxy.SetPrintEnable(value)
    return XMVCA.X3CProxy:SetPrintEnable(value)
end

function CommonGuide.CheckGuideOpen()
    XDataCenter.GuideManager.CheckGuideOpen()
end

function Theatre4.GetGoldCount()
    return XMVCA:GetAgency(ModuleId.XTheatre4):GetGoldCount()
end

function Theatre4.GetGoldName()
    return XMVCA:GetAgency(ModuleId.XTheatre4):GetGoldName()
end

function Theatre4.GetCostItemText()
    return CS.XTextManager.GetText("RebootCostText", Theatre4.GetGoldName())
end

function UIInterface.CallUIFunction(uiName, uiFunc)
    local ui = XFightUiManager.GetChildUiFight(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy)
    end
end

function UIInterface.CallUIFunctionP1(uiName, uiFunc, p1)
    local ui = XFightUiManager.GetChildUiFight(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1)
    end
end

function UIInterface.CallUIFunctionP2(uiName, uiFunc, p1, p2)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2)
    end
end

function UIInterface.CallUIFunctionP3(uiName, uiFunc, p1, p2, p3)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2, p3)
    end
end

function UIInterface.CallUIFunctionP4(uiName, uiFunc, p1, p2, p3, p4)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2, p3, p4)
    end
end

--region 战斗资源分析

function Fuben.GetFightTutorialConfig(templateId)
    return XMVCA:GetAgency(ModuleId.XUiFightTutorial):GetConfig(templateId)
end

--endregion

--region 肉鸽5

---@param xautoChessData XAutoChessData
function Theatre5.TestCalNpcAttribsAndBackXAutoChessData(xautoChessData)
    local autoChessData = {}
    
    autoChessData.CharacterId = xautoChessData.CharacterId
    autoChessData.CharacterLevel = xautoChessData.CharacterLevel
    autoChessData.Attribs = {}
    autoChessData.RuneEvolves = {}
    autoChessData.Skills = {}
    autoChessData.Relics = {}
    
    for i = 0, xautoChessData.RuneEvolves.Count - 1 do
        local runeEvolve = xautoChessData.RuneEvolves[i]
        autoChessData.RuneEvolves[i + 1] = {
            RuneId = runeEvolve.RuneId,
            IsStrengthen = runeEvolve.IsStrengthen,
        }
    end

    for i = 0, xautoChessData.Relics.Count - 1 do
        autoChessData.Relics[i + 1] = xautoChessData.Relics[i]
    end

    for i = 0, xautoChessData.Skills.Count - 1 do
        autoChessData.Skills[i + 1] = xautoChessData.Skills[i]
    end
    
    return XMVCA.XTheatre5.BattleCom:TestCalNpcAttribsAndBackXAutoChessData(autoChessData)
end

function Theatre5.GetTheatre5ItemCfgById(id)
    return XMVCA.XTheatre5:GetTheatre5ItemCfgById(id)
end

function Theatre5.GetTheatre5ItemTagCfgById(id)
    return XMVCA.XTheatre5:GetTheatre5ItemTagCfgById(id)
end

function Theatre5.GetTheatre5ItemRuneAttrCfgById(id)
    return XMVCA.XTheatre5:GetTheatre5ItemRuneAttrCfgById(id)
end

function Theatre5.GetTheatre5AttrShowCfgByType(type)
    return XMVCA.XTheatre5:GetTheatre5AttrShowCfgByType(type)
end

function Theatre5.GetTheatre5ItemKeyWordCfgById(id)
    return XMVCA.XTheatre5:GetTheatre5ItemKeyWordCfgById(id)
end

function Theatre5.GetTheatre5QualityHexColor(quality)
    return XMVCA.XTheatre5:GetClientConfigGemQualityColor(quality)
end

function Theatre5.GetDlcPortraitByCharacterIdAndFashionId(templateId, fashionId)
    return XMVCA.XTheatre5:ExGetDlcPortraitByCharacterIdAndFashionId(templateId, fashionId)
end
--endregion

function ConditionManager.CheckCondition(conditionId)
    return XConditionManager.CheckCondition(conditionId)
end

function BigWorld.OpenBigWorldUi(uiName, args)
    if args then
        local ret = XMVCA.XBigWorldUI:Open(uiName, table.unpack(args))
        CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_BIG_WORLD_OPEN_UI_STATUS, uiName, ret and TrueString or FalseString)
        return ret
    end
    local ret = XMVCA.XBigWorldUI:Open(uiName)
    CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_BIG_WORLD_OPEN_UI_STATUS, uiName, ret and TrueString or FalseString)
    return ret
end

function BigWorld.DebugCheckNarrativeExist(narrativeId)
    return XMVCA.XBigWorldService:DebugCheckNarrativeExist(narrativeId)
end

function UiDialog.CheckOpenExitFightTips(stageId)
    if not XMVCA.XFubenBossSingle:IsBossSingleStage(stageId) then
        return false
    end
    
    local confirmCb = function()
        CS.XFightInterface.Exit(true)
    end
    XLuaUiManager.Open("UiDialogCanvasDialog", CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("LackOfVideoRes"), XUiManager.DialogType.OnlySure, nil, confirmCb)
    CS.XFight.Instance:Pause()
    XLuaUiManager.Close("UiLoading")
    return true
end

--region CG埋点相关
function VideoManager.RecordVideoStart(id)
    XDataCenter.MovieManager.RecordStorylineStart(id)
end

function VideoManager.RecordVideoEnd(id)
    XDataCenter.MovieManager.RecordStorylineEnd(id)
end

function VideoManager.RecordVideoSkip(id)
    XDataCenter.MovieManager.RecordStorylineSkip(id)
end
--endregion

function VideoManager.PlayMovie(movieId, cb)
    XDataCenter.MovieManager.PlayMovie(movieId, cb, nil, nil, nil, nil, nil, nil, true)
end

function Movie.ExtractGenderContent(content, specGender)
    local content = XMVCA.XMovie:ExtractGenderContent(content, specGender)
    return content
end

function Function.SkipInterface(skipId)
    XFunctionManager.SkipInterface(skipId)
end

function Function.BiwWorldSkipInterface(skipId)
    XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
end

--region 肉鸽6

---@param xautoChessData XAutoChessData
function Theatre6.TestCalNpcAttribsAndBackXAutoChessData(xautoChessData)
    ---@type XTheatre6NpcData
    local autoChessData = {}

    autoChessData.CharacterId = xautoChessData.CharacterId
    autoChessData.Attribs = {}
    autoChessData.Skills = {}
    autoChessData.Relics = {}
    autoChessData.GameplayAttribs = {}

    for i = 0, xautoChessData.Relics.Count - 1 do
        autoChessData.Relics[i + 1] = xautoChessData.Relics[i]
    end

    for i = 0, xautoChessData.Skills.Count - 1 do
        autoChessData.Skills[i + 1] = xautoChessData.Skills[i]
    end

    return XMVCA.XTheatre6.Battle:TestCalNpcAttribsAndBackXAutoChessData(autoChessData)
end

function Theatre6.GetTheatre6CharacterFashion(characterId)
    return XMVCA.XTheatre6:GetFashionByCharacterId(characterId)
end

function Theatre6.GetBuildTagConfig(buildTagId)
    return XMVCA.XTheatre6:GetBuildTagConfig(buildTagId)
end
--endregion

function Time.GetServerNowTimestamp()
    return XTime.GetServerNowTimestamp()
end

function FashionManager.GetRoleDefaultNpcResModelId(characterId)
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local resId = XMVCA.XFashion:GetOwnFashionColorResourcesId(fashionId)
    return XMVCA.XCharacter:GetCharResModel(resId)
end

CsCallLua = {}
CsCallLua.Fuben = Fuben
CsCallLua.Character = Character
CsCallLua.DlcFuben = DlcFuben
CsCallLua.DlcCondition = DlcCondition
CsCallLua.BigWorld = BigWorld
CsCallLua.Player = Player
CsCallLua.SetConfigs = SetConfigs
CsCallLua.LoginManager = LoginManager
CsCallLua.Equip = Equip
CsCallLua.Set = Set
CsCallLua.PhotographManager = PhotographManager
CsCallLua.X3CProxy = X3CProxy
CsCallLua.Theatre4 = Theatre4
CsCallLua.DlcCharacter = DlcCharacter
CsCallLua.UIInterface = UIInterface
CsCallLua.Theatre5 = Theatre5
CsCallLua.ConditionManager = ConditionManager
CsCallLua.UiDialog = UiDialog
CsCallLua.VideoManager = VideoManager
CsCallLua.CommonGuide = CommonGuide
CsCallLua.Movie = Movie
CsCallLua.Function = Function
CsCallLua.Theatre6 = Theatre6
CsCallLua.Time = Time
CsCallLua.FashionManager = FashionManager