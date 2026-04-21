---@class XUiSoloReformKillSettlement: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformSettlement = require("XUi/XUiSoloReform/XUiSoloReformSettlement/XUiSoloReformSettlement")
local XUiSoloReformKillSettlement = XLuaUiManager.Register(XUiSoloReformSettlement, 'UiSoloReformKillSettlement')


function XUiSoloReformKillSettlement:OnStart(stageId, passTime, isNew, scoreparams, cb)
    self._StageId = stageId
    self:RefreshPassTime(stageId, passTime, isNew)
    self:RefreshStageInfo(stageId)
    local score = scoreparams.Score
    local scoreDetail = scoreparams.ScoreDetail
    self:RefreshScore(score)
    self:RefreshScoreDetail(scoreDetail)
    self.BtnLeave.gameObject:SetActiveEx(false)
    self.cb = cb
    self:AddListener()
    self.BtnHelp.gameObject:SetActiveEx(false)--2026年2月3日17:29:33临时隐藏评分详情入口
    self:HideScoreDetail()
end

function XUiSoloReformKillSettlement:AddListener()
    self.BtnHideUi:AddEventListener(handler(self, self.HideUi))
    self.BtnLeave:AddEventListener(handler(self, self.ShowUi))
    self.BtnHelp:AddEventListener(handler(self, self.ShowScoreDetail))
    self.BtnCloseTips:AddEventListener(handler(self, self.HideScoreDetail))
end

function XUiSoloReformKillSettlement:HideUi()
    self.BtnLeave.gameObject:SetActiveEx(true)
    self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    self.Bg.gameObject:SetActiveEx(false)
end

function XUiSoloReformKillSettlement:ShowUi()
    self.BtnLeave.gameObject:SetActiveEx(false)
    self.SafeAreaContentPane.gameObject:SetActiveEx(true)
    self.Bg.gameObject:SetActiveEx(true)
end

function XUiSoloReformKillSettlement:RefreshScore(score)
    self.TxtScore.text = score
    local stageCfg = self._Control:GetSoloReformStageCfg(self._StageId)
    self.RImgRate:SetRawImage(self._Control:GetScoreLevelIcon(score,stageCfg.Difficulty))
    local effectPath = self._Control:GetScoreUIEffectPath(score,stageCfg.Difficulty)
    self.RImgBg.gameObject:SetActiveEx(effectPath ~= nil)
    self.RImgBg:LoadPrefabEx(effectPath)
end



function XUiSoloReformKillSettlement:RefreshScoreDetail(scoreDetail)
    self.GridScoreDetail.gameObject:SetActiveEx(false)
    self:HideScoreDetail()
    for id, score in pairs(scoreDetail) do
        if score <= 0 then
            goto continue
        end
        local desc = self._Control:GetScoreDetail(id)
        if desc == "" then
            goto continue
        end
        local item = XUiHelper.Instantiate(self.GridScoreDetail, self.GridScoreDetail.transform.parent)
        local gridUi = {}
        XUiHelper.InitUiClass(gridUi, item)
        gridUi.TxtScore.text = "+" .. score
        gridUi.TxtDesc.text = desc
        item.gameObject:SetActiveEx(true)
        ::continue::
    end
end

function XUiSoloReformKillSettlement:ShowScoreDetail()
    self.PanelScoreTips.gameObject:SetActiveEx(true)
    self.BtnCloseTips.gameObject:SetActiveEx(true)
end

function XUiSoloReformKillSettlement:HideScoreDetail()
    self.PanelScoreTips.gameObject:SetActiveEx(false)
    self.BtnCloseTips.gameObject:SetActiveEx(false)
end

function XUiSoloReformKillSettlement:Close()
    self.cb()
    self.Super.Close(self)
end

return XUiSoloReformKillSettlement
