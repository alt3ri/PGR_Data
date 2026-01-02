local this = XClass(nil, "XCollectUiData")

function this:Ctor(uiKey)
    self.uiKey = uiKey
    self.modelName = ""
end

function this:SetModelName(modelName)
    self.modelName = modelName
end

function this:GetModelName()
    return self.modelName
end

return this