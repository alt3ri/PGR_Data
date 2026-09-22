---@class XUiTeamRecommendDetail : XLuaUi
local XUiTeamRecommendDetail = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendDetail")

function XUiTeamRecommendDetail:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

---@param formationGridData table { Formation=cfg, BaseFormation=cfg, ServerFormation=快照, TargetFormation=目标快照 }
---@param characterId number 入口角色ID
---@param isFromMyChoice boolean|nil true=从GridMyChoice（入口角色目标）进入；来源身份OnStart定死，此后不变
function XUiTeamRecommendDetail:OnStart(formationGridData, characterId, isFromMyChoice)
    self.FormationGridData = formationGridData
    self.CharacterId = characterId
    self.IsFromMyChoice = isFromMyChoice

    self:RefreshTeamName()
    self:RefreshTagName()
end

--- 首次打开和从上层界面（目标详情删除目标等）返回都走这里，按最新目标缓存刷新卡片按钮
function XUiTeamRecommendDetail:OnEnable()
    self:RefreshCharList()
end

function XUiTeamRecommendDetail:InitButton()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self:BindHelpBtn(self.BtnHelp, "OneClickCultivationRule")
end


function XUiTeamRecommendDetail:InitDynamicTable()
    local XUiGridTRCharTargetCard = require("XUi/XUiTeamRecommend/Grid/XUiGridTRCharTargetCard")
    self.CharDynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelCharList, XUiGridTRCharTargetCard)
    self.CharDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnCharDynamicTableEvent(event, index, grid)
    end)
end

function XUiTeamRecommendDetail:RefreshTeamName()
    local baseFormationCfg = self.FormationGridData and self.FormationGridData.BaseFormation
    self.TxtTeamName.text = baseFormationCfg and baseFormationCfg.Desc or ""
end

function XUiTeamRecommendDetail:RefreshTagName()
    local formationCfg = self.FormationGridData and self.FormationGridData.Formation
    local tags = formationCfg and formationCfg.Tags or {}
    self.TxtTagName.text = #tags > 0 and table.concat(tags, ",") or ""
end

function XUiTeamRecommendDetail:OnCharDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local recommendCharData = self.CharDataList and self.CharDataList[index]
        grid:Refresh(recommendCharData, self.TxtTeamName.text, nil, self.FormationGridData)
    end
end

function XUiTeamRecommendDetail:RefreshCharList(index)
    local formationOverrideData = self:GetFormationDetailOverrideData()
    if formationOverrideData and self:RefreshFormationOverrideCharList(formationOverrideData, index) then
        return
    end

    self:RefreshCfgCharList(index)
end

function XUiTeamRecommendDetail:RefreshCfgCharList(index)
    self.CharDataList = {}

    local baseFormationCfg = self.FormationGridData and self.FormationGridData.BaseFormation
    local baseCharacterIds = baseFormationCfg and baseFormationCfg.BaseCharacterIds or {}
    for _, baseCharacterId in ipairs(baseCharacterIds) do
        local cfg = XMVCA.XTeamRecommend:GetTeamRecommendBaseCharacter(baseCharacterId)
        local recommendCharData = XMVCA.XTeamRecommend:FromCfgData(cfg)
        if recommendCharData then
            table.insert(self.CharDataList, recommendCharData)
        end
    end
    XMVCA.XTeamRecommend:MoveCurrentCharacterToFirst(self.CharDataList, self.CharacterId)

    self.CharDynamicTable:SetDataSource(self.CharDataList)
    self.CharDynamicTable:ReloadDataSync(index or 1)
end

function XUiTeamRecommendDetail:RefreshFormationOverrideCharList(formationData, index)
    local characterDatas = formationData and formationData.CharacterDatas
    if not characterDatas or #characterDatas <= 0 then
        return false
    end

    self.CharDataList = {}
    for _, characterData in ipairs(characterDatas) do
        local recommendCharData = XMVCA.XTeamRecommend:FromServerData(characterData)
        if recommendCharData then
            table.insert(self.CharDataList, recommendCharData)
        end
    end
    XMVCA.XTeamRecommend:MoveCurrentCharacterToFirst(self.CharDataList, self.CharacterId)

    self.CharDynamicTable:SetDataSource(self.CharDataList)
    self.CharDynamicTable:ReloadDataSync(index or 1)
    return true
end

function XUiTeamRecommendDetail:GetTeamCfgId()
    local formationCfg = self.FormationGridData and self.FormationGridData.Formation
    return formationCfg and formationCfg.Id or 0
end

function XUiTeamRecommendDetail:GetFormationDetailOverrideData()
    if not self.FormationGridData then
        return nil
    end

    if self.FormationGridData.TargetFormation then
        return self.FormationGridData.TargetFormation
    end

    if self.FormationGridData.ServerFormation then
        return self.FormationGridData.ServerFormation
    end

    local teamCfgId = self:GetTeamCfgId()
    local serverFormation = XMVCA.XTeamRecommend:GetServerFormationData(self.CharacterId, teamCfgId)
    if serverFormation then
        self.FormationGridData.ServerFormation = serverFormation
    end
    return serverFormation
end

--- 当前展示的阵容快照（协议结构）：快照来源原样返回，配表来源现拼，设目标时所见即所得上传
function XUiTeamRecommendDetail:GetDisplayFormationData()
    local overrideData = self:GetFormationDetailOverrideData()
    if overrideData then
        return overrideData
    end

    local baseFormationCfg = self.FormationGridData and self.FormationGridData.BaseFormation
    return XMVCA.XTeamRecommend:BuildTargetFormationFromCfg(baseFormationCfg)
end

--- 设目标的来源身份：入口是目标格子=3；否则展示动态快照=2、配表死数据=1
---@return number sourceType, number sourceId
function XUiTeamRecommendDetail:GetSetTargetSource()
    local srcType = XEnumConst.TeamRecommend.TargetSrcType
    if self.IsFromMyChoice then
        return srcType.FromOtherTarget, self.CharacterId
    end

    if self:GetFormationDetailOverrideData() then
        return srcType.FromTopDetail, self.CharacterId
    end

    local baseFormationCfg = self.FormationGridData and self.FormationGridData.BaseFormation
    return srcType.FromConfig, baseFormationCfg and baseFormationCfg.Id or 0
end

--- 给被点卡片的角色设阵容目标（CharacterId=卡角色，不是入口角色）
function XUiTeamRecommendDetail:OnTeamRecommendCharSetTarget(recommendCharData)
    local teamCfgId = self:GetTeamCfgId()
    local characterId = recommendCharData and recommendCharData.CharacterId
    if not XTool.IsNumberValid(teamCfgId) or not XTool.IsNumberValid(characterId) then XLog.Error("[XUiTeamRecommendDetail] TeamCfgId or CharacterId is invalid") return end

    local sourceType, sourceId = self:GetSetTargetSource()
    local srcType = XEnumConst.TeamRecommend.TargetSrcType
    local targetFormation
    if sourceType == srcType.FromConfig then
        if not XTool.IsNumberValid(sourceId) then XLog.Error("[XUiTeamRecommendDetail] BaseFormationId is invalid, TeamCfgId = " .. teamCfgId) return end
    elseif sourceType == srcType.FromTopDetail then
        targetFormation = self:GetDisplayFormationData()
        if not targetFormation then XLog.Error("[XUiTeamRecommendDetail] targetFormation is nil, TeamCfgId = " .. teamCfgId) return end
    end

    XMVCA.XTeamRecommend:TeamRecommendSetFormationTargetRequest(characterId, teamCfgId, targetFormation, sourceType, sourceId, function()
        XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", characterId)
    end)
end

--- 卡片角色的阵容目标是否就是当前Detail阵容（按卡判定，不看入口角色）
function XUiTeamRecommendDetail:IsTeamRecommendCharUsingTarget(recommendCharData)
    return XMVCA.XTeamRecommend:IsCharacterFormationTargetUsing(recommendCharData, self:GetTeamCfgId())
end

return XUiTeamRecommendDetail
