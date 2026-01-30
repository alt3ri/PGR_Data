local IO = CS.System.IO
local XTableAssetCollectConst = require("XTableAssetCollect/XTableAssetCollectConst")
local TableSourceTypeTips = XTableAssetCollectConst.TableSourceTypeTips
local FileType = XTableAssetCollectConst.FileType

local this = {}

this.GetFileTableList = function()
    local resultList = {}

    for _, path in ipairs(XTableAssetCollectConst.NeedCollectTableFolderList) do
        local files = IO.Directory.GetFiles(path, "*.*", IO.SearchOption.AllDirectories);
        local len = files.Length
        for i = 0, len - 1 do
            local file = files[i]
            file = string.gsub(file, "\\", "/")

            if string.EndsWith(file, XTableAssetCollectConst.TableExtension) 
                and not string.EndsWith(file, XTableAssetCollectConst.IgnoreExtension) then

                file = string.sub(file, XTableAssetCollectConst.TableDirectoryStrLen + 1)
                table.insert(resultList, file)

            end
        end
    end

    return resultList
end

this.GetLuaFilePathList = function(customeDirectory)
    local configDirectory = XTableAssetCollectConst.LuaFileDirectory .. customeDirectory
    return IO.Directory.GetFiles(configDirectory, "*.lua", IO.SearchOption.AllDirectories)
end

this.NeedIgnoreSameDirectoryFile = function(filePath)
    for _, pattern in ipairs(XTableAssetCollectConst.FightTablePathList) do
        if string.match(filePath, pattern) then return true end
    end

    return false
end

this.ProcessLuaFilePath = function(path)
    path = string.gsub(path, "\\", "/")

    local filePath = string.sub(path, XTableAssetCollectConst.LuaFileDirectoryLen + 1)
    local fileName = XTool.GetFileNameWithoutExtension(filePath)

    return filePath, fileName
end

this.RequireLuaFile = function(filePath, fileName)
    if not _G[fileName] then
        filePath = string.gsub(filePath, ".lua", "")
        require(filePath)
    end
end

this.GetStreamingWriter = function(path)
    local sw

    if not IO.File.Exists(path) then
        sw = IO.File.CreateText(path)
    else
        IO.File.WriteAllText(path, "")
        sw = IO.File.AppendText(path)
    end

    return sw
end

this.GetStreamingReader = function(path)
    local sr = IO.File.OpenText(path)
    return sr
end

this.IsMovieTable = function(tablePath)
    for _, pattern in ipairs(XTableAssetCollectConst.MovieTablePathList) do
        if string.match(tablePath, pattern) then return true end
    end

    return false
end

this.IsFightTable = function(tablePath)
    for _, pattern in ipairs(XTableAssetCollectConst.FightTablePathList) do
        if string.match(tablePath, pattern) then return true end
    end

    return false
end

this.ExtractTablePathByRegular = function(input)
    local result

    for _, pattern in ipairs(XTableAssetCollectConst.TableRegularPatternList) do
        local match = string.match(input, pattern)
        if match then
            result = match
            break
        end
    end

    return result
end

this.GetTableSourceTypeTips = function(type)
    if TableSourceTypeTips[type] then
        return TableSourceTypeTips[type]
    else
        return "不支持, 请添加到类型定义中"
    end
end

this.GetLogTitle = function(collectData)
    if collectData.fileType ~= FileType.Movie then
        return string.format("文件总数：%s, 配置表总数：%s", #collectData.fileInfoList, collectData.totalTableCount)
    else
        return string.format("剧情配置表总数：%s", collectData.totalTableCount)
    end
end

this.RemoveTrailingConfig = function(str)
    if str:sub(-7) == "Configs" then
        return str:sub(1, -8)
    elseif str:sub(-6) == "Config" then
        return str:sub(1, -7)
    else
        return str
    end
end

--分割配置表一个单元格的内容
this.SplitTableCellContent = function(cellStr)
    local result = {}

    -- 使用模式匹配按 | 和 # 分割
    for part in cellStr:gmatch("[^|#]+") do
        table.insert(result, part)
    end

    return result
end

this.matchAssetPath = function(path)
    return path:match("^Assets(/[%w_-]+)+%.[%w]+$") ~= nil
end

this.matchExternalPath = function(path)
    return path:match("^External(/[%w_-]+)+%.[%w]+$") ~= nil
end

this.matchPackagesPath = function(path)
    return path:match("^Packages(/[%w_-]+)+%.[%w]+$") ~= nil
end

this.IsAssetPath = function(path)
    return this.matchAssetPath(path) or this.matchExternalPath(path) or this.matchPackagesPath(path)
end

return this