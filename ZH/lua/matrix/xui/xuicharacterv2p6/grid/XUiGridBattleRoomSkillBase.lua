---@class XUiGridBattleRoomSkillBase XUiGridBattleRoomSkillBase
---@field _Control XCharacterControl
local XUiGridBattleRoomSkillBase = XClass(XUiNode, "XUiGridBattleRoomSkillBase")
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiGridBattleRoomSkillBase:Ctor(ui, parent, switchCb)
    self.Parent = parent
    self.SwitchCb = switchCb
    self.BtnSelect.CallBack = function()
        self:OnClickBtnSelect()
    end
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
    self.TxtSkillName.gameObject:SetActiveEx(false)
    self.TxtSkillbrief.gameObject:SetActiveEx(false)
end

function XUiGridBattleRoomSkillBase:Refresh(skillId, skillLevel, isCurrent, indexInSkillGroup)
    self.SkillId = skillId

    self.SelectIcon.gameObject:SetActiveEx(isCurrent)
    self.BtnSelect.gameObject:SetActiveEx(not isCurrent)

    -- local gradeConfig = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
    local config = self.Parent.SkillExchangeDesConfig
   
    -- 技能名
    self.TxtSkillBT.text = config.Name
    -- 技能描述
    for _, go in pairs(self.TxtSkillTitleGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.TxtSkillSpecificGo) do
        go:SetActiveEx(false)
    end
    for index, message in pairs({config.SpecificDesLite[indexInSkillGroup]}) do
        local title = config.Title[indexInSkillGroup]
        if title then
            self:SetTextInfo(DescribeType.Title, index, title)
        end
        self:SetTextInfo(DescribeType.Specific, index, message)
    end
end

function XUiGridBattleRoomSkillBase:SetTextInfo(txtType, index, info)
    local txtSkillGo = {}
    local target
    if txtType == DescribeType.Title then
        txtSkillGo = self.TxtSkillTitleGo
        target = self.TxtSkillName.gameObject
    else
        txtSkillGo = self.TxtSkillSpecificGo
        target = self.TxtSkillbrief.gameObject
    end
    local txtGo = txtSkillGo[index]
    if not txtGo then
        txtGo = XUiHelper.Instantiate(target, self.PanelReward)
        txtSkillGo[index] = txtGo
    end
    txtGo:SetActiveEx(true)
    local goTxt = txtGo:GetComponent(typeof(CS.UnityEngine.UI.Text))
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
    txtGo.transform:SetAsLastSibling()
end

function XUiGridBattleRoomSkillBase:OnClickBtnSelect()
end

return XUiGridBattleRoomSkillBase