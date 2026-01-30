local this = XClass(nil, "XTableCollectData")

function this:Ctor(fileType)
    self.fileType = fileType
    self.fileCount = 0
    
    self.fileInfoList = {}
    self.fileInfoDic = {}

    self.totalTableDic = {}
    self.totalTableCount = 0
end

function this:GetFileInfo(fileName)
    return self.fileInfoDic[fileName]
end

function this:AddFileInfo(fileName, ModelName)
    if not self.fileInfoDic[fileName] then
        local fileInfo = {}
        fileInfo.fileName = fileName
        fileInfo.ModelName = ModelName
        fileInfo.tableInfoList = {}
        fileInfo.tableDic = {}
        
        self.fileInfoDic[fileName] = fileInfo
        table.insert(self.fileInfoList, fileInfo)

        self.fileCount = self.fileCount + 1
    end
end

function this:GetOrAddFileInfo(fileName, ModelName)
    if not self.fileInfoDic[fileName] then
        self:AddFileInfo(fileName, ModelName)
    end

    return self.fileInfoDic[fileName]
end

function this:AddTable(fileName, ModelName, tablePath, tableSourceType)
    if not self.totalTableDic[tablePath] then
        self.totalTableDic[tablePath] = true
        self.totalTableCount = self.totalTableCount + 1
    end

    local fileInfo = self:GetOrAddFileInfo(fileName, ModelName)

    if not fileInfo.tableDic[tablePath] then
        local tableInfo = {
            sourceType = tableSourceType,
            tablePath = tablePath,
        }

        table.insert(fileInfo.tableInfoList, tableInfo)
        fileInfo.tableDic[tablePath] = true
    end
end

return this