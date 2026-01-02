
---@class XUiBigWorldTaskPopupEndingDetail : XBigWorldUi
---@field _Control XBigWorldQuestControl
---@field _GridCommon XUiGridBWItem
local XUiBigWorldTaskPopupEndingDetail = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskPopupEndingDetail")

function XUiBigWorldTaskPopupEndingDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTaskPopupEndingDetail:OnStart(questId, resultId, showTag)
    self._QuestId = questId
    self._ResultId = resultId
    self._ShowTag = showTag or false
    self:InitView()
end

function XUiBigWorldTaskPopupEndingDetail:InitUi()
    self._GridCommon = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem").New(self.UiBigWorldItemGrid, self)
    
    self._IsPCMode = CS.XUiPc.XUiPcManager.IsPcMode()
    self._IsFromInvitation = XMVCA.XBigWorldUI:IsUiLoad("UiBigWorldTaskMainInvitation")
end

function XUiBigWorldTaskPopupEndingDetail:InitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnDownload:AddEventListener(handler(self, self.OnBtnDownloadClick))
    self.BtnView:AddEventListener(handler(self, self.OnBtnViewClick))
    self.BtnAgain:AddEventListener(handler(self, self.OnBtnAgainClick))
end

function XUiBigWorldTaskPopupEndingDetail:InitView()
    self.RImgEnding:SetRawImage(self._Control:GetInviteQuestResultBanner(self._ResultId))
    self.TxtName.text = self._Control:GetInviteQuestResultName(self._ResultId)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._Control:GetInviteQuestResultDesc(self._ResultId))
    
    self:RefreshReward(self._Control:GetInviteQuestResultRewardId(self._ResultId))

    self.BtnView.gameObject:SetActiveEx(self._IsPCMode)
    self.BtnAgain.gameObject:SetActiveEx(not self._IsFromInvitation)
    
    self:RefreshTagNew(self._ShowTag)
end

function XUiBigWorldTaskPopupEndingDetail:RefreshReward(rewardId)
    if rewardId and rewardId > 0 then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if not XTool.IsTableEmpty(rewardList) then
            self._GridCommon:Update(rewardList[1])
            self._GridCommon:RefreshReceive(XMVCA.XBigWorldQuest:CheckInviteResultFinish(self._ResultId))
        else
            self._GridCommon:Close()
        end
    else
        self._GridCommon:Close()
    end
end

function XUiBigWorldTaskPopupEndingDetail:RefreshTagNew(isShow)
    if not self.TagNew then
        return
    end
    self.TagNew.gameObject:SetActiveEx(isShow)
end

function XUiBigWorldTaskPopupEndingDetail:OnBtnDownloadClick()
    local texture = self.RImgEnding.texture
    if XTool.UObjIsNil(texture) then
        XLog.Error("贴图为空！！！")
        return
    end
    local fileName = string.format("INVITE_%s%s", XTime.GetServerNowTimestamp(), XPlayer.Id)
    local fileNameWithExt = string.format("%s.png", fileName)
    if CS.XTool.ExistsCaptureImg(fileNameWithExt) then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("LocalTextureExist"))
        return
    end
    if CS.XTool.SaveUnreadableTexture(fileName, texture) then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_SS_SaveSucess"))
    end
end

function XUiBigWorldTaskPopupEndingDetail:OnBtnViewClick()
    if not self._IsPCMode then
        self.BtnView.gameObject:SetActiveEx(false)
        return
    end
    local path = CS.XTool.GetCaptureImgPath()
    path = string.gsub(path, "/", "\\")
    if not CS.System.IO.Directory.Exists(path) then
        CS.System.IO.Directory.CreateDirectory(path)
    end
    CS.UnityEngine.Application.OpenURL(path)
end

function XUiBigWorldTaskPopupEndingDetail:OnBtnAgainClick()
    self:Close()
    XMVCA.XBigWorldQuest:OpenInvitationView(self._QuestId)
end