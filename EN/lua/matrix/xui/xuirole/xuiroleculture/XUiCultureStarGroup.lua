---@class XUiCultureStarGroup
local XUiCultureStarGroup = XClass(nil, "XUiCultureStarGroup")

local MAX_STAR = 4

local GRADING = {
    { Star = 1, MaxGrade = 1 },  -- 列兵
    { Star = 2, MaxGrade = 3 },  -- 军士
    { Star = 3, MaxGrade = 6 },  -- 精锐
    { Star = 3, MaxGrade = 9 },  -- 特种
    { Star = 4, MaxGrade = 13 }, -- 王牌
}

function XUiCultureStarGroup:Ctor(rootUi, owner)
    self.RootUi = rootUi
    self.Stars = {}
    self.OnStars = {}
    self.MaxBgs = {}
    for i = 1, MAX_STAR do
        self.Stars[i] = owner["ImgStar" .. i]
        self.OnStars[i] = owner["ImgOnStar" .. i]
        self.MaxBgs[i] = owner["BgMax" .. i]
    end
end

function XUiCultureStarGroup:Refresh(characterId, grade, isOver)
    local gradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, grade)
    local totalStar, onStar = self:GetStarInfo(grade)
    for i = 1, MAX_STAR do
        local star, on = self.Stars[i], self.OnStars[i]
        self.RootUi:SetUiSprite(star, gradeConfig.NoStar)
        star.gameObject:SetActiveEx(i <= totalStar)
        self.RootUi:SetUiSprite(on, gradeConfig.Star)
        on.gameObject:SetActiveEx(i <= onStar)
        local maxBg = self.MaxBgs[i]
        if maxBg then
            maxBg.gameObject:SetActiveEx(isOver == true and i <= totalStar)
        end
    end
end

function XUiCultureStarGroup:GetStarInfo(grade)
    local prevMax = 0
    for i = 1, #GRADING do
        local seg = GRADING[i]
        if grade <= seg.MaxGrade then
            return seg.Star, grade - prevMax
        end
        prevMax = seg.MaxGrade
    end

    return MAX_STAR, MAX_STAR
end

return XUiCultureStarGroup
