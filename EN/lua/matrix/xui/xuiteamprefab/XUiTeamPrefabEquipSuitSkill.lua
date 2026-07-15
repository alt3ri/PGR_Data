local XUiGridSuitSkill = XClass(nil, "XUiGridSuitSkill")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local PAGE_SUIT_CONT = 3 -- 一页展示套装的数量

local XUiTeamPrefabEquipSuitSkill = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabEquipSuitSkill")

function XUiTeamPrefabEquipSuitSkill:OnAwake()
    self:InitSkillListGo()
    self:SetButtonCallBack()
end

-- 重写初始化方法，接收预设数据
---@param teamPrefab XTeamPrefab
---@param pos number 队伍位置
function XUiTeamPrefabEquipSuitSkill:OnStart(teamPrefab, pos)
    self.TeamPrefab = teamPrefab
    self.CurrentPos = pos
    self.CharacterId = teamPrefab:GetEntityIdByTeamPos(pos)
    self.PageIndex = 0 -- 保持原版从0开始的分页逻辑
    self.SuitInfoList = {}
end

function XUiTeamPrefabEquipSuitSkill:OnEnable()
    self:UpdateView()
end

function XUiTeamPrefabEquipSuitSkill:InitSkillListGo()
    self.SkillGridList = {}
    for i = 1, PAGE_SUIT_CONT do
        local go = self.SkillItem
        if i > 1 then
            go = CSInstantiate(self.SkillItem, self.PanelSkillList)
        end
        local uiGridSuitSkill = XUiGridSuitSkill.New(go)
        table.insert(self.SkillGridList, uiGridSuitSkill)
    end
end

function XUiTeamPrefabEquipSuitSkill:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBgClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
end

function XUiTeamPrefabEquipSuitSkill:OnBtnLeftClick()
    if self.CanLeftPage then
        self.PageIndex = self.PageIndex - 1
        self:UpdateSuitList()
    end
end

function XUiTeamPrefabEquipSuitSkill:OnBtnRightClick()
    if self.CanRightPage then
        self.PageIndex = self.PageIndex + 1
        self:UpdateSuitList()
    end
end

function XUiTeamPrefabEquipSuitSkill:UpdateView()
    -- 从预设中获取套装信息列表（复用原版数据结构）
    self.SuitInfoList = self.TeamPrefab:GetWearingSuitInfoListByPos(self.CurrentPos)
    local canSwitch = #self.SuitInfoList > PAGE_SUIT_CONT
    self.BtnLeft.gameObject:SetActiveEx(canSwitch)
    self.BtnRight.gameObject:SetActiveEx(canSwitch)
    
    self.PageIndex = 0
    self:UpdateSuitList()
end

-- 刷新套装列表（保持原版分页逻辑）
function XUiTeamPrefabEquipSuitSkill:UpdateSuitList()
    -- 预设里该位的全部意识
    local awarenessData = self.TeamPrefab:GetAllAwarenessData(self.CurrentPos)  -- 若无该函数，可用 self.TeamPrefab.AwarenessData[self.CurrentPos]
    for i = 1, PAGE_SUIT_CONT do
        local infoIndex = self.PageIndex * PAGE_SUIT_CONT + i
        local suitInfo = self.SuitInfoList[infoIndex]
        local uiGridSuitSkill = self.SkillGridList[i]

        if suitInfo and awarenessData then
            local wearCnt = 0
            for _, item in pairs(awarenessData) do
                if item and item.EquipId then
                    local tid = XMVCA.XEquip:GetEquipTemplateId(item.EquipId)
                    local cfg = XMVCA.XEquip:GetConfigEquip(tid)
                    if cfg and cfg.SuitId == suitInfo.SuitId then
                        wearCnt = wearCnt + 1
                    end
                end
            end
            suitInfo.WearCnt = wearCnt  -- ✅ 只统计预设中真实穿戴数量
        else
            suitInfo = suitInfo or nil
            if suitInfo then suitInfo.WearCnt = 0 end
        end

        uiGridSuitSkill:UpdateView(self.CharacterId, suitInfo)
    end
    self:UpdateSwitchBtn()
end


-- 刷新切换按钮状态（复用原版逻辑）
function XUiTeamPrefabEquipSuitSkill:UpdateSwitchBtn()
    local canSwitch = #self.SuitInfoList > PAGE_SUIT_CONT
    self.CanLeftPage = self.PageIndex > 0
    self.CanRightPage = #self.SuitInfoList > (self.PageIndex + 1) * PAGE_SUIT_CONT
    self.BtnLeft:SetDisable(not self.CanLeftPage)
    self.BtnRight:SetDisable(not self.CanRightPage)
end

-------------------------------------#region XUiGridSuitSkill --------------------------------

function XUiGridSuitSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self) -- 使用封装好的初始化方法

    -- 初始化激活/未激活描述列表（复用原版结构）
    self.ActiveDesList = {self.TxtActiveDes}
    self.UnActiveDesList = {self.TxtUnActiveDes}
end

function XUiGridSuitSkill:UpdateView(characterId, suitInfo)
    local haveInfo = suitInfo ~= nil
    self.Normal.gameObject:SetActiveEx(haveInfo)
    self.Disable.gameObject:SetActiveEx(not haveInfo)
    if not haveInfo then
        return
    end

    -- 套装图标
    local iconPath = XMVCA.XEquip:GetEquipSuitIconPath(suitInfo.SuitId)
    self.RImgIcon:SetRawImage(iconPath)

    -- XUiGridSuitSkill:UpdateView（关键替换）
    local activeCount = suitInfo.WearCnt or 0          -- ✅ 只用预设穿戴数量
    local isOverrun   = suitInfo.IsOverrun == true     -- 仍可用来显示“可由超限激活”的提示

    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(
        suitInfo.SuitId,
        activeCount,
        isOverrun,
        isOverrun
    )

    -- 重置描述显示
    for _, desGo in ipairs(self.ActiveDesList) do
        desGo.gameObject:SetActiveEx(false)
    end
    for _, desGo in ipairs(self.UnActiveDesList) do
        desGo.gameObject:SetActiveEx(false)
    end

    local activeIndex = 1
    local unActiveIndex = 1

    -- 刷新技能描述（复用原版创建逻辑）
    for _, skillInfo in ipairs(skillDesList) do
        local desGo
        if skillInfo.IsActive then
            desGo = self.ActiveDesList[activeIndex]
            if not desGo then
                desGo = CSInstantiate(self.TxtActiveDes, self.DescContent)
                table.insert(self.ActiveDesList, desGo)
            end
            activeIndex = activeIndex + 1
        else
            desGo = self.UnActiveDesList[unActiveIndex]
            if not desGo then
                desGo = CSInstantiate(self.TxtUnActiveDes, self.DescContent)
                table.insert(self.UnActiveDesList, desGo)
            end
            unActiveIndex = unActiveIndex + 1
        end
        desGo.gameObject:SetActiveEx(true)
        desGo.transform:SetAsLastSibling()
        desGo:GetComponent("Text").text = skillInfo.SkillDes
        local txtTitle = XUiHelper.TryGetComponent(desGo.transform, "TxtTitle", "Text")
        txtTitle.text = skillInfo.PosDes
    end

    -- 无激活技能时隐藏正常状态
    local noActive = activeIndex == 1
    if noActive then
        self.Normal.gameObject:SetActiveEx(false)
        self.Disable.gameObject:SetActiveEx(true)
    end
end

-------------------------------------#endregion XUiGridSuitSkill --------------------------------

return XUiTeamPrefabEquipSuitSkill