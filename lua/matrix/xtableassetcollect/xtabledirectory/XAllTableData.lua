local IO = CS.System.IO
local XTableDirectoryData = require("XTableAssetCollect/XTableDirectory/XTableDirectoryData")
local XTableAssetCollectUtil = require("XTableAssetCollect/XTableAssetCollectUtil")

local this = XClass(nil, "XAllTableData")

function this:Ctor()
    self.directoryData = XTableDirectoryData.New("Table")
    self.fileTableList = {}
    self.fileTableDic = {}
end

function this:Init()
    self.fileTableList = {}
    self.fileTableDic = {}
    
    local resultList = XTableAssetCollectUtil.GetFileTableList()
    for _, path in ipairs(resultList) do
        self:AddFilePath(path)
    end
end

-- 添加配置表路径
-- 传入格式：Client/Fuben/FubenActivityTimeTips.tab
function this:AddFilePath(filePath)
    if not self.fileTableDic[filePath] then
        self.fileTableDic[filePath] = true
        table.insert(self.fileTableList, filePath)
        self:RecordFileDirectory(filePath)
    end
end

-- 记录配置表路径
-- 传入格式：Client/Fuben/FubenActivityTimeTips.tab
function this:RecordFileDirectory(filePath)
    local pathList = string.Split(filePath, "/")

    local curDirectory = self.directoryData
    if #pathList > 0 then
        for i = 1, #pathList - 1 do
            local directory = pathList[i]
            curDirectory:AddDirectory(directory)
            curDirectory = curDirectory:GetDirectory(directory)
        end

        curDirectory:AddFile(pathList[#pathList], filePath)
    end
end

-- 获取该配置表文件夹下所有的配置表
-- 例如：传入Client/Fuben/FubenActivityTimeTips.tab，返回Client/Fuben/下所有其他配置表
function this:GetSameDirectoryFilePathList(filePath)
    local resultFilePathList = {}

    if XTableAssetCollectUtil.NeedIgnoreSameDirectoryFile(filePath) then return resultFilePathList end

    local pathList = string.Split(filePath, "/")
    local curDirectory = self.directoryData
    if #pathList > 0 then
        for i = 1, #pathList - 1 do
            curDirectory = curDirectory:GetDirectory(pathList[i])
        end

        resultFilePathList = curDirectory:GetFilePathList()
    end

    return resultFilePathList
end

return this