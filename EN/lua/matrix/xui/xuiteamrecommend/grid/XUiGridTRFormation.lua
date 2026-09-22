-- 引用LuaUi：UiTeamRecommendMain
---@class XUiGridTRFormation : XUiNode Tab2阵容格子
---@field RoleGridPool table[]
local XUiGridTRFormation = XClass(XUiNode, "XUiGridTRFormation")

function XUiGridTRFormation:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnShowFormation, self.OnBtnShowFormationClick)
    self:InitMatchNodePool()
    self:InitRoleGridPool()
end

--- 从Node1模板补齐3个匹配度三角节点
function XUiGridTRFormation:InitMatchNodePool()
    self.MatchNodePool = {}
    local template = self.ImgPanelMatchRed.transform.parent
    local parent = template.parent
    for i = 1, 3 do
        local node = i == 1 and template.gameObject or XUiHelper.Instantiate(template.gameObject, parent)
        self.MatchNodePool[i] = {
            Red = node.transform:Find("ImgPanelMatchRed").gameObject,
            Yellow = node.transform:Find("ImgPanelMatchYellow").gameObject,
            Green = node.transform:Find("ImgPanelMatchGreen").gameObject,
        }
    end
end

--- 从GridRole模板Instantiate3个角色格子，用UiObject取引用
function XUiGridTRFormation:InitRoleGridPool()
    self.RoleGridPool = {}
    local template = self.GridRole
    if not template then return end
    template.gameObject:SetActiveEx(false)

    for i = 1, 3 do
        local go = XUiHelper.Instantiate(template.gameObject)
        go.transform:SetParent(self.ListRole, false)
        go:SetActiveEx(false)

        self.RoleGridPool[i] = XTool.InitUiObjectByUi({}, go)
    end
end

--- 刷新阵容格子
---@param formationGridData table { Formation=cfg, BaseFormation=cfg }
---@param characterId number 传入的角色ID
function XUiGridTRFormation:Refresh(formationGridData, characterId)
    if not formationGridData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)
    self.FormationGridData = formationGridData
    self.CharacterId = characterId

    local formationCfg = formationGridData.Formation
    local baseFormationCfg = formationGridData.BaseFormation
    -- 阵容名
    self.TxtTeamRecommendName.text = baseFormationCfg and baseFormationCfg.Desc or ""

    -- 标签名
    local tags = formationCfg and formationCfg.Tags or {}
    self.TxtTagName.text = #tags > 0 and table.concat(tags, ",") or ""

    -- 匹配度
    self:RefreshMatchDegree()

    -- 3个角色头像
    self:RefreshRoleList(formationGridData)
end

function XUiGridTRFormation:RefreshMatchDegree()
    local matchCount = 0
    local formationData = self.FormationGridData.TargetFormation or self.FormationGridData.ServerFormation
    local characterDatas = formationData and formationData.CharacterDatas

    if not characterDatas or #characterDatas <= 0 then
        characterDatas = {}
        for _, baseCharacterId in ipairs(self.FormationGridData.BaseFormation.BaseCharacterIds) do
            local cfg = XMVCA.XTeamRecommend:GetTeamRecommendBaseCharacter(baseCharacterId)
            table.insert(characterDatas, {
                CharacterId = cfg.CharacterId,
                CharacterQualityStar = cfg.CharacterQualityStar,
                WeaponId = cfg.WeaponId,
            })
        end
    end

    for _, characterData in ipairs(characterDatas) do
        local character = XMVCA.XCharacter:GetCharacter(characterData.CharacterId)
        -- 当前口径：拥有角色是该角色整组匹配分的前置条件。
        if character then
            local characterQualityStar = character.Quality * 1000 + character.Star
            if characterQualityStar >= characterData.CharacterQualityStar then
                matchCount = matchCount + 1
            end

            if #XMVCA.XEquip:GetEnableEquipIdsByTemplateId(characterData.WeaponId, characterData.CharacterId) > 0 then
                matchCount = matchCount + 1
            end
        end
    end

    local isHighMatch = matchCount >= 5
    local isMediumMatch = matchCount >= 3 and not isHighMatch
    local activeCount = isHighMatch and 3 or isMediumMatch and 2 or 1
    for i, node in ipairs(self.MatchNodePool) do
        node.Red:SetActiveEx(not isHighMatch and not isMediumMatch and i <= activeCount)
        node.Yellow:SetActiveEx(isMediumMatch and i <= activeCount)
        node.Green:SetActiveEx(isHighMatch and i <= activeCount)
    end
end

function XUiGridTRFormation:RefreshRoleList(formationGridData)
    local roleList = XMVCA.XTeamRecommend:GetFormationRoleDisplayList(formationGridData, self.CharacterId)

    for i = 1, 3 do
        local item = self.RoleGridPool[i]
        if not item then break end

        local roleData = roleList[i]
        local characterId = roleData and roleData.CharacterId
        if XTool.IsNumberValid(characterId) then
            item.GameObject:SetActiveEx(true)
            item.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
            item.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(roleData.Quality))
            if item.ImgMask then
                item.ImgMask.gameObject:SetActiveEx(not XMVCA.XCharacter:IsOwnCharacter(characterId))
            end
        else
            item.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridTRFormation:SetSelect(isSelect)
    if isSelect == self.IsSelect then return end
    self.IsSelect = isSelect
end

function XUiGridTRFormation:OnBtnShowFormationClick()
    if self.FormationGridData then
        XLuaUiManager.Open("UiTeamRecommendDetail", self.FormationGridData, self.CharacterId)
    end
end

return XUiGridTRFormation
