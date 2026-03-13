local this = XClass(nil, "XUiCollectData")

function this:Ctor(fileType)
    self.fileType = fileType
    
    self.modelInfoList = {}
    self.modelInfoDic = {}

    self.totalUiDic = {}
    self.totalUiCount = 0
end

function this:GetModelInfo(modelName)
    return self.modelInfoDic[modelName]
end

function this:AddModelInfo(modelName)
    if not self.modelInfoDic[modelName] then
        local modelInfo = {}
        modelInfo.modelName = modelName
        modelInfo.uiInfoList = {}
        modelInfo.uiDic = {}
        
        self.modelInfoDic[modelName] = modelInfo
        table.insert(self.modelInfoList, modelInfo)
    end
end

function this:GetOrAddModelInfo(modelName)
    if not self.modelInfoDic[modelName] then
        self:AddModelInfo(modelName)
    end

    return self.modelInfoDic[modelName]
end

function this:AddUiKey(modelName, uiKey, sourceType)
    if not self.totalUiDic[uiKey] then
        self.totalUiDic[uiKey] = true
        self.totalUiCount = self.totalUiCount + 1
    end

    local modelInfo = self:GetOrAddModelInfo(modelName)

    if not modelInfo.uiDic[uiKey] then
        local assetInfo = {
            uiKey = uiKey,
            sourceType = sourceType,
        }

        table.insert(modelInfo.uiInfoList, assetInfo)
        modelInfo.uiDic[uiKey] = true
    end
end

return this