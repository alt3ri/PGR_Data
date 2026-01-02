local XUiDlcMultiPlayerSkillDesc = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterSkill/XUiDlcMultiPlayerSkillDesc")
---@class XUiDlcMultiPlayerSkill : XLuaUi
---@field private _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerSkill = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerSkill")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp

XUiDlcMultiPlayerSkill.ViewStatus = {
    Normal = 0,
    ChangeSkill = 1,
    RejectChange = 2
}
function XUiDlcMultiPlayerSkill:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcMultiPlayerSkill:OnStart()
    ---@type XUiDlcMultiPlayerSkillDesc
    self._CatCamp = XUiDlcMultiPlayerSkillDesc.New(self.CatSkillDescPanel, self, CampEnum.Cat)
    ---@type XUiDlcMultiPlayerSkillDesc
    self._MouseCamp = XUiDlcMultiPlayerSkillDesc.New(self.MouseSkillDescPanel, self, CampEnum.Mouse)
    self._CatCamp:Open()
    self._MouseCamp:Open()
    self._CatCamp:Refresh()
    self._MouseCamp:Refresh()
    self.BtnChange.gameObject:SetActiveEx(true)
    self.BtnCommit.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerSkill:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA,
    }
end

function XUiDlcMultiPlayerSkill:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA then
        self._CatCamp:Refresh()
        self._MouseCamp:Refresh()
    end
end

function XUiDlcMultiPlayerSkill:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnChange:AddEventListener(handler(self, self.SetAllChangeSkill))
    self.BtnCommit:AddEventListener(handler(self, self.SetAllNormel))
end

function XUiDlcMultiPlayerSkill:OnBtnCloseClick()
    if self._CatCamp.CurStatus ~= self.ViewStatus.Normal or self._MouseCamp.CurStatus ~= self.ViewStatus.Normal then
        return
    end
    self:Close()
end

function XUiDlcMultiPlayerSkill:OnSkillChangeClick()
    -- 请求更换技能
    self._Control:RequestDlcMultiplayerSelectSkill(self._CatCamp:GetSelectSkillIdList(),
        self._MouseCamp:GetSelectSkillIdList(), function()
        -- 提示更换成功
        XUiManager.TipMsg(self._Control:GetDlcMultiplayerConfigConfigByKey("SkillChangeSuccessTips").Values[1])
    end)
end

function XUiDlcMultiPlayerSkill:SetRejectOther(camp)
    if camp == CampEnum.Cat then
        self._MouseCamp:SetStatus(self.ViewStatus.RejectChange)
    else
        self._CatCamp:SetStatus(self.ViewStatus.RejectChange)
    end
end

function XUiDlcMultiPlayerSkill:SetAllNormel()
    
    local isContain = table.contains(self._CatCamp:GetSelectSkillIdList(), 0)
    isContain =isContain or  table.contains(self._MouseCamp:GetSelectSkillIdList(), 0)
    if isContain then
        XUiManager.TipMsg(XUiHelper.GetText("DlcMultiPlayerSkillTips1"))
        return
    end
    self._CatCamp:SetStatus(self.ViewStatus.Normal)
    self._MouseCamp:SetStatus(self.ViewStatus.Normal)
    self.BtnChange.gameObject:SetActiveEx(true)
    self.BtnCommit.gameObject:SetActiveEx(false)
    self.BtnClose:SetDisable(false)
    self:OnSkillChangeClick()
end

function XUiDlcMultiPlayerSkill:SetAllChangeSkill()
    self._CatCamp:SetStatus(self.ViewStatus.ChangeSkill)
    self._MouseCamp:SetStatus(self.ViewStatus.ChangeSkill)
    self.BtnChange.gameObject:SetActiveEx(false)
    self.BtnCommit.gameObject:SetActiveEx(true)
    self.BtnClose:SetDisable(true)

end

function XUiDlcMultiPlayerSkill:SetCommitStatus()
    local isContain = table.contains(self._CatCamp:GetSelectSkillIdList(), 0)
    isContain =isContain or  table.contains(self._MouseCamp:GetSelectSkillIdList(), 0)
    self.BtnCommit:SetDisable(isContain)
end



return XUiDlcMultiPlayerSkill
