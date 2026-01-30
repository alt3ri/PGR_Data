--- 宝箱选择item
---@class XUiTheatre5PVEChooseRewardItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEChooseRewardItem = XClass(XUiNode, 'XUiTheatre5PVEChooseRewardItem')
local XUiGridTheatre5ItemTag = require('XUi/XUiTheatre5/XUiTheatre5BubbleItemDetail/XUiGridTheatre5ItemTag')

function XUiTheatre5PVEChooseRewardItem:OnStart()
    self.UiTheatre5GridRelic = self.UiTheatre5GridRelic or XUiHelper.TryGetComponent(self.Transform, "PanelBase/UiTheatre5GridRelic", "RectTransform")
    self.RelicIcon = self.RelicIcon or XUiHelper.TryGetComponent(self.Transform, "PanelBase/UiTheatre5GridRelic/PanelNone/PanelRelic/RImgIcon", "RawImage")
    ---@type XTheatre5Item
    self._Theatre5Item = nil
    self._TagGrids = {}
    self._AffixList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnChoose, self.OnClickChoose, true, true)
end

function XUiTheatre5PVEChooseRewardItem:Update(theatre5Item, index)
    self._Theatre5Item = theatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(self._Theatre5Item.ItemId)
    local isSkill = itemCfg.Type == XMVCA.XTheatre5.EnumConst.ItemType.Skill
    local isGem = theatre5Item.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip
    if self.GemIconNode then
        self.GemIconNode.gameObject:SetActiveEx(isGem)
    end
    self.PanelGem.gameObject:SetActiveEx(isGem)
    if self.SkillIconNode then
        self.SkillIconNode.gameObject:SetActiveEx(isSkill)
    end
    self.PanelSkill.gameObject:SetActiveEx(isSkill)
    self:UpdateCommon(itemCfg)
    if isSkill then
        self:UpdateSkill(itemCfg)
    elseif isGem then
        self:UpdateGem(itemCfg)
    end
    if self.StoryGroup then
        self.StoryGroup.gameObject:SetActiveEx(isGem)
    end

    if self.TxtStory then
        self.TxtStory.text = XUiHelper.ReplaceTextNewLine(itemCfg.Info)
    end

    if self.UiTheatre5GridRelic then
        local isRelic = itemCfg.Type == XMVCA.XTheatre5.EnumConst.ItemType.Relic
        if isRelic then
            self.UiTheatre5GridRelic.gameObject:SetActiveEx(true)
            if self.RelicIcon then
                self.RelicIcon:SetRawImage(itemCfg.IconRes)
            else
                XLog.Error("[XUiTheatre5PVEChooseRewardItem] 找不到RelicIcon，饰品图标的ui")
            end
        else
            self.UiTheatre5GridRelic.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre5PVEChooseRewardItem:UpdateCommon(itemCfg)
    self.TxtTitle.text = itemCfg.Name
    self:UpdateDesc()
    self:UpdateTag(itemCfg)
    self:UpdateAffix(itemCfg)
end

function XUiTheatre5PVEChooseRewardItem:UpdateDesc()
    local itemCfg = self._Control:GetTheatre5ItemCfgById(self._Theatre5Item.ItemId)
    self.TxtDes.text = self._Control:GetItemDesc(itemCfg)
end

function XUiTheatre5PVEChooseRewardItem:UpdateTag(itemCfg)
    if not XTool.IsTableEmpty(self._TagGrids) then
        for i, v in pairs(self._TagGrids) do
            v:Close()
        end
    end
    self.ListItemTag.gameObject:SetActiveEx(#itemCfg.Tags > 0)

    self._TagCellList = XUiHelper.RefreshUiObjectList(self._TagCellList, self.ListItemTag.transform, self.UiTheatre5GridItemTag, #itemCfg.Tags, function(index, cell)
        local grid = self._TagGrids[cell]

        if not grid then
            grid = XUiGridTheatre5ItemTag.New(cell.GameObject, self)
            self._TagGrids[cell] = grid
        end

        grid:Open()
        grid:Refresh(self._Control:GetTheatre5ItemTagCfgById(itemCfg.Tags[index]))
    end)
end

function XUiTheatre5PVEChooseRewardItem:UpdateAffix(itemCfg)
    if self.ImgLine then
        self.ImgLine.gameObject:SetActiveEx(#itemCfg.Keywords > 0)
    end
    if self.Content then
        self._AffixList = XUiHelper.RefreshUiObjectList(self._AffixList, self.Content.transform, self.GridAffix, #itemCfg.Keywords, function(index, grid)
            local keywordCfg = self._Control:GetTheatre5ItemKeyWordCfgById(itemCfg.Keywords[index])
            if keywordCfg then
                grid.TxtTitle.text = keywordCfg.KeyWord
                grid.TxtDes.text = XUiHelper.ReplaceTextNewLine(keywordCfg.Desc)
            end
        end)
    end
end

--技能
function XUiTheatre5PVEChooseRewardItem:UpdateSkill(itemCfg)
    self:UpdateSkillIcon(itemCfg)
    self:UpdateSkillCD(itemCfg)
end

function XUiTheatre5PVEChooseRewardItem:UpdateSkillIcon(itemCfg)
    local skillIconPanel = XTool.InitUiObjectByUi({}, self.SkillIconNode)
    skillIconPanel.RImgIcon:SetRawImage(itemCfg.IconRes)
end

function XUiTheatre5PVEChooseRewardItem:UpdateSkillCD(itemCfg)
    local skillCfg = self._Control:GetTheatre5SkillCfgById(itemCfg.Id)
    if skillCfg then
        self.TxtCdNum.text = tostring(skillCfg.CoolDownSec)
    end
end

--宝珠
function XUiTheatre5PVEChooseRewardItem:UpdateGem(itemCfg)
    self:UpdateGemIcon(itemCfg)
    self:UpdateGemAttr(itemCfg)
end

function XUiTheatre5PVEChooseRewardItem:UpdateGemIcon(itemCfg)
    local GemIconPanel = XTool.InitUiObjectByUi({}, self.GemIconNode)
    GemIconPanel.RImgIcon:SetRawImage(itemCfg.IconRes)
    local color = self._Control:GetClientConfigGemQualityColor(itemCfg.Quality)
    if color then
        GemIconPanel.RawImgBgQuality.color = color
    end
end

function XUiTheatre5PVEChooseRewardItem:GetRuneAttr()
    local runeAttrCfg = self._Control:GetRuneAttr(self._Theatre5Item)
    return runeAttrCfg
end

function XUiTheatre5PVEChooseRewardItem:UpdateGemAttr(itemCfg)
    local runeCfg = self._Control:GetTheatre5ItemRuneCfgById(itemCfg.Id)
    if not runeCfg or not XTool.IsNumberValid(runeCfg.RuneAttrId) then
        return
    end
    local runeAttrCfg = self:GetRuneAttr()
    if runeAttrCfg then
        self.PanelGem.gameObject:SetActiveEx(true)
        self._AttrList = XUiHelper.RefreshUiObjectList(self._AttrList, self.PanelGem.transform, self.GridAttribute, #runeAttrCfg.AttrTypes, function(index, grid)
            ---@type XTableTheatre5AttrShow
            local attrShowCfg = self._Control:GetTheatre5AttrShowCfgByType(runeAttrCfg.AttrTypes[index])
            if attrShowCfg then
                grid.TxtName.text = attrShowCfg.AttrName
            end
            grid.TxtNum.text = runeAttrCfg.AttrValues[index] or 0
        end)
    end
end

function XUiTheatre5PVEChooseRewardItem:OnClickChoose()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_PVE_ITEM_BOX_SELECT, self._Theatre5Item)
end

function XUiTheatre5PVEChooseRewardItem:OnDestroy()
    self._Theatre5Item = nil
    self._TagGrids = nil
    self._AffixList = nil
end

return XUiTheatre5PVEChooseRewardItem