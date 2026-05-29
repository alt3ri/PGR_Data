-- 技能标签Grid（内部类）
local XUiGridSkillTag = XClass(XUiNode, "XUiGridSkillTag")

function XUiGridSkillTag:Update(tagId, index)
    if not tagId then
        return
    end
    local tagConfig = self._Control:GetBuildTagConfig(tagId)
    if tagConfig and tagConfig.Icon then
        self.RImgIcon:SetRawImage(tagConfig.Icon)
    end
    self:Open()
end

-- 星级Grid（内部类）
local XUiGridSkillStar = XClass(XUiNode, "XUiGridSkillStar")

function XUiGridSkillStar:Update(_, index)
    self:Open()
end

---@class XUiGridTheatre6BossSkill : XUiNode Boss技能Grid（主动/被动通用）
---@field _Control XTheatre6Control
local XUiGridTheatre6BossSkill = XClass(XUiNode, "XUiGridTheatre6BossSkill")

function XUiGridTheatre6BossSkill:OnStart()
    self._TagGrids = {}
    self._StarGrids = {}
    self.Tag.gameObject:SetActiveEx(false)
    self.GridStar.gameObject:SetActiveEx(false)
    self.BtnGridSkill:AddEventListener(handler(self, self.OnBtnGridSkillClick))
end

---XTool.UpdateDynamicItem回调
---@param skillConfig XTableTheatre6Skill
---@param index number
function XUiGridTheatre6BossSkill:Update(skillConfig, index)
    if not skillConfig then
        return
    end
    
    if skillConfig.Icon then
        self.RImgIcon:SetRawImage(skillConfig.Icon)
    end
    
    self._SkillId = skillConfig.Id
    self:RefreshTags(skillConfig.BuildTags)
    self:RefreshStars(skillConfig.Quality)
    -- 新标记（Boss预览场景下默认隐藏）
    self.PanelNew.gameObject:SetActiveEx(false)
    -- 禁用遮罩（Boss预览场景下默认隐藏）
    self.ImgMask.gameObject:SetActiveEx(false)
    -- 选中态（Boss预览场景下默认隐藏）
    self.RawImgSelect.gameObject:SetActiveEx(false)
    -- 升级箭头（Boss预览场景下默认隐藏）
    self.ImgUpArrow.gameObject:SetActiveEx(false)

    self:Open()
end

---刷新构建标签列表
---@param buildTags number[]
function XUiGridTheatre6BossSkill:RefreshTags(buildTags)
    if not buildTags or #buildTags == 0 then
        self.ListTag.gameObject:SetActiveEx(false)
        return
    end

    XTool.UpdateDynamicItem(self._TagGrids, buildTags, self.Tag, XUiGridSkillTag, self)
end

---刷新品质星级
---@param quality number
function XUiGridTheatre6BossSkill:RefreshStars(quality)
    local starCount = quality or 0
    local starData = {}
    for i = 1, starCount do
        starData[i] = true
    end

    XTool.UpdateDynamicItem(self._StarGrids, starData, self.GridStar, XUiGridSkillStar, self)
end

function XUiGridTheatre6BossSkill:OnBtnGridSkillClick()
    self._Control:OpenSkillTip(self._SkillId, self.BtnGridSkill.transform)
end

return XUiGridTheatre6BossSkill
