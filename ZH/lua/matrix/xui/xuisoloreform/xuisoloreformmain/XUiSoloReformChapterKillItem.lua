---@class XUiSoloReformChapterKillItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterItem = require("XUi/XUiSoloReform/XUiSoloReformMain/XUiSoloReformChapterItem")
local XUiSoloReformChapterKillItem = XClass(XUiSoloReformChapterItem, 'XUiSoloReformChapterKillItem')

function XUiSoloReformChapterKillItem:OnClickChapter()
    if not self._IsUnlock then
        return
    end
    self._Control:DispatchEvent(XMVCA.XSoloReform.EventId.EVENT_CLICK_KILL_CHAPTER, self._ChapterCfg.Id)
end

function XUiSoloReformChapterKillItem:GetColor()
    return "#F2A7B0"
end

function XUiSoloReformChapterKillItem:Update(chapterCfg)
    self.Super.Update(self, chapterCfg)
    self:RefreshKill()
end

function XUiSoloReformChapterKillItem:RefreshKill()
    local score = self._Control:GetKillChapterMaxScore(self._ChapterCfg.Id)
    self.TxtScoreNone.gameObject:SetActiveEx(not score)
    if score then
        self.BtnGridChapter:SetNameByGroup(2, score)
    else
        self.BtnGridChapter:SetNameByGroup(2, "")
    end
    if score then
        local levelicon = self._Control:GetScoreLevelIcon(score,self._ChapterCfg.Difficulty)
        self.BtnGridChapter:SetRawImageVisible(levelicon ~= nil)
        self.BtnGridChapter:SetRawImage(levelicon)
    else
        self.BtnGridChapter:SetRawImageVisible(score ~= nil)
    end
end

return XUiSoloReformChapterKillItem
