local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEChatNode
local XTheatre5PVEChatNode = XClass(XTheatre5PVENode, "XTheatre5PVEChatNode")


function XTheatre5PVEChatNode:_OnEnter()
    local storyLineContentCfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)
    local sceneChatStoryPoolCfg = self._MainModel:GetPveSceneChatStoryPoolCfg(storyLineContentCfg.ContentId)
    self._SceneChatCfgs = self._MainModel:GetPveSceneChatCfgs(sceneChatStoryPoolCfg.SceneChatGroup)
    --chatGroupId, characters
    self._MainControl:OpenPVEChat(sceneChatStoryPoolCfg.SceneChatGroup, sceneChatStoryPoolCfg.Characters, function()
        local nodeCompletedCallback = self._NodeCompletedCallback
        XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId, function(success)
            if success then
                if nodeCompletedCallback then
                    nodeCompletedCallback()
                end
            end        
        end)
    end)
   
end

function XTheatre5PVEChatNode:_OnExit()

end

return XTheatre5PVEChatNode