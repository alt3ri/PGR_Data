local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEAVGNode
local XTheatre5PVEAVGNode = XClass(XTheatre5PVENode, "XTheatre5PVEAVGNode")

function XTheatre5PVEAVGNode:_OnEnter()
    local storyLineContentCfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)
    --todo 这里的playMovie不能改成非isRelease模式，因为剧情会改变渲染环境，播放完成后选择界面人物曝光，这里锁等UI框架改了后再去掉
    self._MainControl:LockControl()
    XDataCenter.MovieManager.PlayMovie(storyLineContentCfg.AvgContent,function()
        self._MainControl:UnLockControl()
        XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId, function()
            --触发引导
            XDataCenter.GuideManager.CheckGuideOpen()
        end)
    end)
end

function XTheatre5PVEAVGNode:_OnExit()

end

return XTheatre5PVEAVGNode