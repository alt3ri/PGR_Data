local XUiGridDlcRelinkCharacterSkill = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkCharacterSkill")

local DAMAGE_INFINITY_SYMBOL = "∞"
local DAMAGE_LIMIT_ATTR = "DmgLimitP"

---@class XUiDlcRelinkPopupSkillDetail : XLuaUi
---@field private _Control XDlcRelinkControl
---@field BubbleHurt UiObject
---@field BtnDesc XUiComponent.XUiButton
---@field VideoPlayer XVideoPlayerUGUI
---@field TxtDesc XUiComponent.XUiRichTextCustomRender
local XUiDlcRelinkPopupSkillDetail = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupSkillDetail")

function XUiDlcRelinkPopupSkillDetail:OnAwake()
    self.BubbleHurt.gameObject:SetActiveEx(false)
    self.BubbleAffixDetail.gameObject:SetActiveEx(false)
    self.GridAffix.gameObject:SetActiveEx(false)
    self.GridSkillTag.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    self.IsShowHurtBubble = false
    self.IsSimpleDesc = not self._Control:GetSkillDescIsDetail()

    self.SecondSkillIds = {}
    self.CurSecondSkillIndex = 1
    self.CurSecondSkillId = nil

    ---@type UiObject[]
    self.GridTagList = {}
    ---@type UiObject[]
    self.GridAffixList = {}
    self.IsShowAffixDetail = false
end

function XUiDlcRelinkPopupSkillDetail:OnStart(skillId, characterId, isRemodel, callback, isNotSelf)
    self.SkillId = skillId
    self.CharacterId = characterId
    self.IsRemodel = isRemodel
    self.Callback = callback
    self.IsNotSelf = isNotSelf or false

    self:RefreshGridSkill()
    self:RefreshInfo()
    self:RefreshDamage()
    self:RefreshSkillDetail()
end

function XUiDlcRelinkPopupSkillDetail:OnDisable()
    if self.VideoPlayer then
        self.VideoPlayer:Stop()
        self.PanelVideo.gameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkPopupSkillDetail:RefreshGridSkill()
    if not self.GridSkillUi then
        ---@type XUiGridDlcRelinkCharacterSkill
        self.GridSkillUi = XUiGridDlcRelinkCharacterSkill.New(self.GridSkill, self)
    end
    self.GridSkillUi:Open()
    self.GridSkillUi:Refresh(self.SkillId, self.CharacterId, self.IsRemodel, self.IsNotSelf)
end

function XUiDlcRelinkPopupSkillDetail:RefreshInfo()
    self.TxtTitle.text = self._Control:GetSkillDescName(self.SkillId)
    self.TxtTitleType.text = self._Control:GetSkillDescTypeDesc(self.SkillId)
    local cd = self._Control:GetSkillDescCd(self.SkillId)
    self.TxtCd.text = string.format(self._Control:GetClientConfig("SkillDetailCdFormat"), cd)
    self.TxtCd.gameObject:SetActiveEx(XTool.IsNumberValid(cd))
end

function XUiDlcRelinkPopupSkillDetail:RefreshDamage()
    -- 伤害
    local curDamage = self._Control:GetSkillCurrentDamage(self.SkillId, self.CharacterId, self.IsNotSelf)
    local maxDamage = self._Control:GetSkillMaxDamageLimit(self.SkillId, self.CharacterId, self.IsNotSelf)
    if maxDamage > 0 then
        curDamage = math.min(curDamage, maxDamage)
    end
    self.TxtNumHurt.text = string.format("%s/%s", curDamage, maxDamage > 0 and maxDamage or DAMAGE_INFINITY_SYMBOL)
    self.TxtMax.gameObject:SetActiveEx(curDamage >= maxDamage and maxDamage > 0)

    -- 重置伤害气泡状态
    self.IsShowHurtBubble = false
    self.BubbleHurt.gameObject:SetActiveEx(false)
end

function XUiDlcRelinkPopupSkillDetail:RefreshSkillDetail()
    self.BtnDesc:SetButtonState(self.IsSimpleDesc and CS.UiButtonState.Normal or CS.UiButtonState.Select)
    local secondSkillIds = self._Control:GetSkillDescSecondSkill(self.SkillId)
    local hasSecondSkills = not XTool.IsTableEmpty(secondSkillIds)
    self.BtnChange.gameObject:SetActiveEx(hasSecondSkills)

    self.SecondSkillIds = { self.SkillId }
    if hasSecondSkills then
        for _, id in ipairs(secondSkillIds) do
            if id ~= self.SkillId then
                table.insert(self.SecondSkillIds, id)
            end
        end
    end

    self.CurSecondSkillIndex = 1
    self:RefreshSecondSkill()
end

function XUiDlcRelinkPopupSkillDetail:RefreshSecondSkill()
    self.CurSecondSkillId = self.SecondSkillIds[self.CurSecondSkillIndex]
    self.TxtSecondTitle.text = self._Control:GetSkillDescSubtitle(self.CurSecondSkillId)
    self:RefreshTagList()
    self:RefreshDesc()
    self:RefreshVideo()
end

function XUiDlcRelinkPopupSkillDetail:RefreshTagList()
    local tags = self._Control:GetSkillDescTags(self.CurSecondSkillId)
    local hasTags = not XTool.IsTableEmpty(tags)
    self.ListTag.gameObject:SetActiveEx(hasTags)
    if not hasTags then
        return
    end

    for index, tag in ipairs(tags) do
        local grid = self.GridTagList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridSkillTag, self.ListTag)
            self.GridTagList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtTag").text = tag
    end

    for index = #tags + 1, #self.GridTagList do
        local grid = self.GridTagList[index]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcRelinkPopupSkillDetail:RefreshDesc()
    local desc
    if self.IsSimpleDesc then
        desc = self._Control:GetSkillDescSimpleDesc(self.CurSecondSkillId)
    else
        desc = self._Control:GetSkillDescDesc(self.CurSecondSkillId)
    end
    local entryNameList = self._Control:GetSkillDescEntryName(self.CurSecondSkillId)
    if not XTool.IsTableEmpty(entryNameList) then
        desc = XUiHelper.FormatText(desc, table.unpack(entryNameList))
    end

    -- 设置链接点击回调
    self.TxtDesc.onLinkClick = function(arg)
        self:RefreshAffixList(arg)
    end
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(desc)
end

function XUiDlcRelinkPopupSkillDetail:RefreshVideo()
    local videoConfigId = self._Control:GetSkillDescVideoConfigId(self.CurSecondSkillId)
    if not XTool.IsNumberValid(videoConfigId) then
        self.PanelVideo.gameObject:SetActiveEx(false)
        return
    end

    self.PanelVideo.gameObject:SetActiveEx(true)
    self.VideoPlayer:SetInfoByVideoId(videoConfigId)
    self.VideoPlayer:RePlay()
end

function XUiDlcRelinkPopupSkillDetail:RefreshAffixList(arg)
    local entryNameList = self._Control:GetSkillDescEntryName(self.CurSecondSkillId)
    local entryDescList = self._Control:GetSkillDescEntryDesc(self.CurSecondSkillId)

    local hasEntry = not XTool.IsTableEmpty(entryNameList)
    self.BubbleAffixDetail.gameObject:SetActiveEx(hasEntry)
    if not hasEntry then
        self.IsShowAffixDetail = false
        return
    end

    self.IsShowAffixDetail = true
    local curIndex = tonumber(arg) or 0
    for index, entryName in ipairs(entryNameList) do
        local grid = self.GridAffixList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridAffix, self.BubbleAffixDetail)
            self.GridAffixList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtTitle").text = entryName
        local entryDesc = entryDescList and entryDescList[index] or ""
        grid:GetObject("TxtDetail").text = entryDesc
        grid:GetObject("Select").gameObject:SetActiveEx(index == curIndex)
    end

    for index = #entryNameList + 1, #self.GridAffixList do
        local grid = self.GridAffixList[index]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiDlcRelinkPopupSkillDetail:HideAffixDetail()
    self.IsShowAffixDetail = false
    self.BubbleAffixDetail.gameObject:SetActiveEx(false)
end

function XUiDlcRelinkPopupSkillDetail:RegisterUiEvents()
    self.BtnClose.IsEventPass = true
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnHurt:AddEventListener(handler(self, self.OnBtnHurtClick))
    self.BtnDesc:AddEventListener(handler(self, self.OnBtnDescClick))
    self.BtnChange:AddEventListener(handler(self, self.OnBtnChangeClick))
end

function XUiDlcRelinkPopupSkillDetail:OnBtnCloseClick()
    if self.IsShowAffixDetail then
        self:HideAffixDetail()
        return
    end

    if self.Callback then
        self.Callback()
    end
    self:Close()
end

function XUiDlcRelinkPopupSkillDetail:OnBtnHurtClick()
    self.IsShowHurtBubble = not self.IsShowHurtBubble
    self.BubbleHurt.gameObject:SetActiveEx(self.IsShowHurtBubble)
    if self.IsShowHurtBubble then
        self.BubbleHurt:GetObject("Text").text = self._Control:GetCharacterAttribName(DAMAGE_LIMIT_ATTR)
        self.BubbleHurt:GetObject("TxtDetail").text = self._Control:GetCharacterAttribDesc(DAMAGE_LIMIT_ATTR)
    end
end

function XUiDlcRelinkPopupSkillDetail:OnBtnDescClick()
    if self.IsShowAffixDetail then
        self:HideAffixDetail()
    end

    self.IsSimpleDesc = not self.IsSimpleDesc
    
    self._Control:SetSkillDescIsDetail(not self.IsSimpleDesc)
    
    self:RefreshDesc()
end

function XUiDlcRelinkPopupSkillDetail:OnBtnChangeClick()
    if XTool.IsTableEmpty(self.SecondSkillIds) or #self.SecondSkillIds <= 1 then
        return
    end

    if self.IsShowAffixDetail then
        self:HideAffixDetail()
    end

    -- 切换到下一个技能
    self.CurSecondSkillIndex = (self.CurSecondSkillIndex % #self.SecondSkillIds) + 1
    self:RefreshSecondSkill()
end

return XUiDlcRelinkPopupSkillDetail
