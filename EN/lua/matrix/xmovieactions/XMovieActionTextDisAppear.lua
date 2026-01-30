---@class XMovieActionTextDisAppear
---@field UiRoot XUiMovie
local XMovieActionTextDisAppear = XClass(XMovieActionBase, "XMovieActionTextDisAppear")

function XMovieActionTextDisAppear:OnInit(actionData)
    self.Params = actionData.Params
end

function XMovieActionTextDisAppear:OnRunning()
    if not self.Params or #self.Params == 0 then
        self.UiRoot:DisAppearAllText()
    else
        for _, param in pairs(self.Params) do
            local arr = XMVCA.XMovie:SplitParam(param, "|")
            local id = arr[1]
            local isAnim = arr[2] == "1"
            self.UiRoot:DisAppearText(id, isAnim)
        end
    end
end

function XMovieActionTextDisAppear:IsDisAppear(textId)
    if not self.Params or #self.Params == 0 then
        return true
    else
        for _, param in pairs(self.Params) do
            local arr = XMVCA.XMovie:SplitParam(param, "|")
            local id = arr[1]
            if id == textId then
                return true
            end
        end
    end
    return false
end

return XMovieActionTextDisAppear