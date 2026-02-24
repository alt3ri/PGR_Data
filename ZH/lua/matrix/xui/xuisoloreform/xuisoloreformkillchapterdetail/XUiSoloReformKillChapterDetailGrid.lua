
local XUiSoloReformKillChapterDetailGrid = XClass(XUiNode, "XUiSoloReformKillChapterDetailGrid")



function XUiSoloReformKillChapterDetailGrid:Refresh(fightEventCfg)
    self.GameObject:SetActiveEx(true)
    self.TxtDetail.text = fightEventCfg.Desc
    self.TxtTitle.text = fightEventCfg.Name
    if XTool.IsNumberValid(fightEventCfg.VideoId) and not XTool.UObjIsNil(self.VideoPlayer.VideoPlayerInst) then
        self.VideoPlayer:SetInfoByVideoId(fightEventCfg.VideoId)
        self.VideoPlayer:RePlay()
    end
end
return XUiSoloReformKillChapterDetailGrid
