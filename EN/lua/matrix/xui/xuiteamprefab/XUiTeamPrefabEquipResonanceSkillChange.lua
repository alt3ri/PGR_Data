local XUiGridEquipResonanceSkillChangeV2P6 = require("XUi/XUiEquip/XUiGridEquipResonanceSkillChangeV2P6")
local XUiTeamPrefabEquipResonanceSkillChange = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabEquipResonanceSkillChange")

function XUiTeamPrefabEquipResonanceSkillChange:OnAwake()
    self.GridResonanceSkill.gameObject:SetActiveEx(false)

    self.ResonanceSkillGrids = {}
    self:SetButtonCallBack()
end

---@param teamPrefab XTeamPrefab
---@param characterId number
---@param equipId number
---@param currentPos number
function XUiTeamPrefabEquipResonanceSkillChange:OnStart(teamPrefab, characterId, equipId, currentPos, confirmCb)
    self.TeamPrefab = teamPrefab
    self.CharacterId = characterId
    self.EquipId = equipId
    self.CurrentPos = currentPos
    self.ConfirmCb = confirmCb

    -- 从预设中获取共鸣技能数据
    local resonanceDict = self.TeamPrefab:GetWeaponResonance(self.CurrentPos) or {}

    -- 共鸣数量、当前位置对应技能
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local resonanceInfoDic = equip:GetResonanceInfoDic()
    self.ResonanceCount = 0
    self.ResonanceOperatedPosSkillDic = {} -- 被操作的
    self.IsSelectFull = true
    for _, info in pairs(resonanceInfoDic) do
        if info and info.CharacterId == self.CharacterId then 
            self.ResonanceCount = self.ResonanceCount + 1
            self.ResonanceOperatedPosSkillDic[info.Slot] = resonanceDict[info.Slot] or 0
        end
    end

    self:UpdateView()
end

function XUiTeamPrefabEquipResonanceSkillChange:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiTeamPrefabEquipResonanceSkillChange:OnBtnEnterClick()
    -- 未选满技能
    if not self.IsSelectFull then
        return
    end

    -- 更新预设中的共鸣技能数据
    -- 因为操作前把非同共鸣角色的skillId过滤了，这里要检测并加回来
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local resonanceInfoDic = equip:GetResonanceInfoDic()
    local resonanceDictInTeamPrefab = self.TeamPrefab:GetWeaponResonance(self.CurrentPos) or {} 
    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT, 1 do
        local infoInResonanceOperatedPosSkillDic = self.ResonanceOperatedPosSkillDic[i]
        local skillIdInTeamPrefab = resonanceDictInTeamPrefab[i]
        local infoInRealEquip = resonanceInfoDic[i]
        if not infoInResonanceOperatedPosSkillDic and skillIdInTeamPrefab and infoInRealEquip.CharacterId ~= self.CharacterId then
            self.ResonanceOperatedPosSkillDic[i] = skillIdInTeamPrefab
        end
    end
    self.TeamPrefab:CopyRealWeaponResonance(self.ResonanceOperatedPosSkillDic, self.CurrentPos)

    if self.ConfirmCb then
        self.ConfirmCb()
    end

    self:Close()
end

-- 刷新界面
function XUiTeamPrefabEquipResonanceSkillChange:UpdateView()
    -- 角色名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    self.TxtCharacterName.text = charConfig.Name
    self.TxtCharacterNameOther.text = charConfig.TradeName

    -- 当前共鸣数量
    self:UpdateSelectSkillCount()
    self.TxtMaxSkillCount.text = tostring("/"..self.ResonanceCount)

    self:UpdateSkillList()
end

-- 刷新当前选择的技能数
function XUiTeamPrefabEquipResonanceSkillChange:UpdateSelectSkillCount()
    local selectCnt = 0
    for _, skillId in pairs(self.ResonanceOperatedPosSkillDic) do
        if skillId and skillId ~= 0 then
            selectCnt = selectCnt + 1
        end
    end
    self.TxtCurSkillCount.text = tostring(selectCnt)
end

-- 刷新技能列表
function XUiTeamPrefabEquipResonanceSkillChange:UpdateSkillList()
    local pos = 1 -- 三个位置的技能列表都是一样，取第一个
    self.SkillInfoList = XMVCA.XEquip:GetResonancePreviewSkillInfoList(self.EquipId, self.CharacterId, pos)
    for index, skillInfo in ipairs(self.SkillInfoList) do
        local skillGrid = self.ResonanceSkillGrids[index]
        if not skillGrid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)
            item.transform:SetParent(self.PanelSkillContent.transform, false)
            item.gameObject:SetActiveEx(true)
            skillGrid = XUiGridEquipResonanceSkillChangeV2P6.New(item, self)
            self.ResonanceSkillGrids[index] = skillGrid
        end

        skillGrid:Refresh(self.EquipId, skillInfo)
        skillGrid:UpdateSelectState(self.ResonanceOperatedPosSkillDic)
    end
end

function XUiTeamPrefabEquipResonanceSkillChange:OnGridSkillClick(selectSkillId)
    -- 技能是否已选中
    local selectPos
    for pos, skillId in pairs(self.ResonanceOperatedPosSkillDic) do
        if skillId == selectSkillId then 
            selectPos = pos
            break
        end
    end

    -- 已选中的取消选中
    if selectPos then
        self.ResonanceOperatedPosSkillDic[selectPos] = 0
    else
        -- 技能未满的，可以成功选中
        local isSelectSuccess = false
        for pos, skillId in pairs(self.ResonanceOperatedPosSkillDic) do
            if skillId == 0 then
                self.ResonanceOperatedPosSkillDic[pos] = selectSkillId
                isSelectSuccess = true
                break
            end
        end

        -- 技能已选满，选中失败
        if not isSelectSuccess then
            return
        end
    end

    -- 刷新技能的选中
    for index, skillInfo in ipairs(self.SkillInfoList) do
        local skillGrid = self.ResonanceSkillGrids[index]
        skillGrid:UpdateSelectState(self.ResonanceOperatedPosSkillDic)
    end
    self:UpdateSelectSkillCount()

    -- 刷新确定按钮
    self.IsSelectFull = true
    for pos, skillId in pairs(self.ResonanceOperatedPosSkillDic) do
        if skillId == 0 then
            self.IsSelectFull = false
            break
        end
    end
    self.BtnEnter:SetDisable(not self.IsSelectFull)
end

return XUiTeamPrefabEquipResonanceSkillChange