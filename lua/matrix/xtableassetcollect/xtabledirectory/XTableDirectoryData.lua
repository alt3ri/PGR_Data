
local this = XClass(nil, "XTableDirectoryData")

function this:Ctor(directoryName)
    self.name = directoryName or "root"
    self.directoryDic = {}
    self.directoryList = {}
    self.fileDic = {}
    self.fileList = {}
end

function this:AddDirectory(directoryName)
    if not self.directoryDic[directoryName] then
        local directory = this.New(directoryName)
        self.directoryDic[directoryName] = directory
        table.insert(self.directoryList, directory)
    end
end

function this:GetDirectory(directoryName)
    return self.directoryDic[directoryName]
end

function this:AddFile(fileName, filePath)
    if not self.fileDic[fileName] then
        local file = {}
        file.name = fileName
        file.path = filePath
        self.fileDic[fileName] = file
        table.insert(self.fileList, file)
    end
end

function this:GetFilePathList()
    local resultFilePathList = {}

    for _, filePath in pairs(self.fileList) do
        table.insert(resultFilePathList, filePath.path)
    end

    for _, directory in pairs(self.directoryList) do
        local childDirectoryFilePathList = directory:GetFilePathList()
        for _, filePath in pairs(childDirectoryFilePathList) do
            table.insert(resultFilePathList, filePath)
        end
    end

    return resultFilePathList
end

return this