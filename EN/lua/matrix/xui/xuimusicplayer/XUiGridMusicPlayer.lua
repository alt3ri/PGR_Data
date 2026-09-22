--
-- Author: wujie
-- Note: 播放器专辑格子相关

local UiGridMusicPlayer = XClass(nil, "UiGridMusicPlayer")

function UiGridMusicPlayer:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.isLock = false

    XTool.InitUiObject(self)
end

function UiGridMusicPlayer:Refresh(data, control)
    local template
    if type(data) == "number" then
        template = XMVCA.XAudio:GetAlbumTemplateById(data)
    else
        template = data
    end
    self.template = template 

    if control then
        local musicID = template.Id or template.MusicId
        if musicID then
            local cdControl = control:GetCDPlayerControl()
            local useStatus, conditionDesc = cdControl:GetMusicUseStatusAndConditionDesc(musicID)
            self.isLock = (useStatus == XMVCA.XMusicPlayer.Enum.MusicUseStatus.unlock)
            self.LockText.text = conditionDesc or ""
        end
    else
        -- 旧逻辑兜底：无 Control 时按 ConditionId 判断
        self.isLock = false
        if template.ConditionId and template.ConditionId ~= 0 then 
            local isReach, lockDesc = XConditionManager.CheckCondition(template.ConditionId)
            self.isLock = not isReach
            self.LockText.text = lockDesc
        end
    end

    local coverPath = template.Cover
    self.RImgCoverSelect:SetRawImage(coverPath)
    self.RImgCoverNotSelect:SetRawImage(coverPath)
    self.RImgCoverSelectLock:SetRawImage(coverPath)
    self.RImgCoverNotSelectLock:SetRawImage(coverPath)
end

function UiGridMusicPlayer:UpdateSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect and not self.isLock)
    self.PanelNotSelect.gameObject:SetActiveEx(not isSelect and not self.isLock)
    self.PanelSelectLock.gameObject:SetActiveEx(isSelect and self.isLock)
    self.PanelNotSelectLock.gameObject:SetActiveEx(not isSelect and self.isLock)
end

return UiGridMusicPlayer