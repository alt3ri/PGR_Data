local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEBattleChapterStartNode
---@field _Id chapterId 
local XTheatre5PVEBattleChapterStartNode = XClass(XTheatre5PVENode, "XTheatre5PVEBattleChapterStartNode")

function XTheatre5PVEBattleChapterStartNode:Ctor()

end

function XTheatre5PVEBattleChapterStartNode:SetData(...)

end

function XTheatre5PVEBattleChapterStartNode:_OnEnter()

end

function XTheatre5PVEBattleChapterStartNode:_OnExit()
    self._ChapterData = nil
end

return XTheatre5PVEBattleChapterStartNode