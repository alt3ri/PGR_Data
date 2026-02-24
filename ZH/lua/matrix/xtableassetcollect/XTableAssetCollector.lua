local IO = CS.System.IO
local string = string
local OriginalGMeta

local XAllTableData = require("XTableAssetCollect/XTableDirectory/XAllTableData")
local XTableCollectData = require("XTableAssetCollect/XCollectData/XTableCollectData")
local XUiCollectData = require("XTableAssetCollect/XCollectData/XUiCollectData")

local XTableAssetCollectUtil = require("XTableAssetCollect/XTableAssetCollectUtil")
local XTableAssetCollectConst = require("XTableAssetCollect/XTableAssetCollectConst")

local UiRegistry = require("UiRegistry")
local UIBindControl = require("MVCA/UIBindControl")

local FileType = XTableAssetCollectConst.FileType
local FileTypeLogFileName = XTableAssetCollectConst.FileTypeLogFileName
local CollectSourceType = XTableAssetCollectConst.CollectSourceType
local AutoGenerateCollectTableFolder = XTableAssetCollectConst.AutoGenerateCollectTableFolder
local AutoGenerateCollectUiFolder = XTableAssetCollectConst.AutoGenerateCollectUiFolder
local ManualFolderPath = XTableAssetCollectConst.ManualFolderPath

local AllTableData
local TableCollectDataDic
local UiCollectDataDic
local ModelNameDic

local CurFileType -- 当前文件类型
local CurFileName -- 当前文件名
local CurModelName -- 当前模块名
local CurSourceType -- 当前配置表收集方式

--收集数据统计
local AllFileTableCount
local CollectedTableCount
local UnCollectedTableCount
local UncollectedPercent
local CollectedPathDic

local SortedUiKeyList
local TotalUiCount
local CollectedUiCount
local UnCollectedUiCount
local CollectedUiKeyDic -- 已收集过的uiKey

--region 处理配置表信息
local AddTableInfo = function(tablePath)
    if tablePath == nil then return end

    local fullTablePath = CS.XTableManager.GetFullPath(tablePath)
    if not IO.File.Exists(fullTablePath) then return end

    local collectData = TableCollectDataDic[CurFileType]
    collectData:AddTable(CurFileName, CurModelName, tablePath, CurSourceType)

    ModelNameDic[CurModelName] = true
end

local AddUiKey = function(uiKey)
    local collectData = UiCollectDataDic[CurFileType]
    collectData:AddUiKey(CurModelName, uiKey, CurSourceType)

    ModelNameDic[CurModelName] = true

    if not CollectedUiKeyDic[uiKey] then
        CollectedUiKeyDic[uiKey] = true
        CollectedUiCount = CollectedUiCount + 1
    end
end
--endregion

--region _G
local RedirectGMeta = function()
    OriginalGMeta = getmetatable(_G)
    setmetatable(_G, {})
end

local RecoverGMeta = function()
    setmetatable(_G, OriginalGMeta)
end
--endregion

--region XTableManager
local InjectReadAllByIntKey = function(path, xTable, identifier)
    AddTableInfo(path)

    return XTableManager._originalReadAllByIntKey(path, xTable, identifier)
end

local InjectReadByIntKey = function(path, xTable, identifier)
    AddTableInfo(path)

    return XTableManager._originalReadByIntKey(path, xTable, identifier)
end

local InjectReadAllByStringKey = function(path, xTable, identifier)
    AddTableInfo(path)

    return XTableManager._originalReadAllByStringKey(path, xTable, identifier)
end

local InjectReadByStringKey = function(path, xTable, identifier)
    AddTableInfo(path)

    return XTableManager._originalReadByStringKey(path, xTable, identifier)
end

local RedirectXTableManager = function()
    XTableManager._originalReadAllByIntKey = XTableManager.ReadAllByIntKey
    XTableManager._originalReadByIntKey = XTableManager.ReadByIntKey
    XTableManager._originalReadAllByStringKey = XTableManager.ReadAllByStringKey
    XTableManager._originalReadByStringKey = XTableManager.ReadByStringKey

    XTableManager.ReadAllByIntKey = InjectReadAllByIntKey
    XTableManager.ReadByIntKey = InjectReadByIntKey
    XTableManager.ReadAllByStringKey = InjectReadAllByStringKey
    XTableManager.ReadByStringKey = InjectReadByStringKey
end

local RecoverXTableManager = function()
    XTableManager.ReadAllByIntKey = XTableManager._originalReadAllByIntKey
    XTableManager.ReadAllByStringKey = XTableManager._originalReadAllByStringKey
    XTableManager.ReadByIntKey = XTableManager._originalReadByIntKey
    XTableManager.ReadByStringKey = XTableManager._originalReadByStringKey
end
--endregion

--region XConfigUtil
local InjectInitConfig = function(xConfigUtil, argList)
    for path, _ in pairs(argList) do
        AddTableInfo(path)
    end

    xConfigUtil:_originalInitConfig(argList)
end

local InjectAddSingleConfig = function(xConfigUtil, path, args)
    AddTableInfo(path)

    xConfigUtil:_originalAddSingleConfig(path, args)
end

local RedirectXConfigUtil = function()
    XConfigUtil._originalInitConfig = XConfigUtil.InitConfig
    XConfigUtil._originalAddSingleConfig = XConfigUtil.AddSingleConfig

    XConfigUtil.InitConfig = InjectInitConfig
    XConfigUtil.AddSingleConfig = InjectAddSingleConfig
end

local RecoverXConfigUtil = function()
    XConfigUtil.InitConfig = XConfigUtil._originalInitConfig
    XConfigUtil.AddSingleConfig = XConfigUtil._originalAddSingleConfig
end
--endregion

--region XConfigCenter
local InjectCreateGetPropertyByFunc = function(config, name, readFunc)
    readFunc()

    XConfigCenter._originalCreateGetPropertyByFunc(config, name, readFunc)
end

local InjectCreateGetPropertyByArgs = function(config, name, funcName, path, tableConfig, readId)
    AddTableInfo(path)

    XConfigCenter._originalCreateGetPropertyByArgs(config, name, funcName, path, tableConfig, readId)
end

local RedirectXConfigCenter = function()
    XConfigCenter._originalCreateGetPropertyByFunc = XConfigCenter.CreateGetPropertyByFunc
    XConfigCenter._originalCreateGetPropertyByArgs = XConfigCenter.CreateGetPropertyByArgs

    XConfigCenter.CreateGetPropertyByFunc = InjectCreateGetPropertyByFunc
    XConfigCenter.CreateGetPropertyByArgs = InjectCreateGetPropertyByArgs
end

local RecoverXConfigCenter = function()
    XConfigCenter.CreateGetPropertyByFunc = XConfigCenter._originalCreateGetPropertyByFunc
    XConfigCenter.CreateGetPropertyByArgs = XConfigCenter._originalCreateGetPropertyByArgs
end
--endregion

--region 初始化
local InitAllFileTable = function()
    AllTableData = XAllTableData.New()
    AllTableData:Init()
end

local OnBeforCollect = function()
    InitAllFileTable()

    TableCollectDataDic = {
        [FileType.Model] = XTableCollectData.New(FileType.Model),
        [FileType.Config] = XTableCollectData.New(FileType.Config),
        [FileType.Manager] = XTableCollectData.New(FileType.Manager),
        [FileType.Movie] = XTableCollectData.New(FileType.Movie),
        [FileType.Fight] = XTableCollectData.New(FileType.Fight),
        [FileType.Common] = XTableCollectData.New(FileType.Common),
        [FileType.Ignore] = XTableCollectData.New(FileType.Ignore),
        [FileType.ManualConfig] = XTableCollectData.New(FileType.ManualConfig),
    }

    UiCollectDataDic = {
        [FileType.UiFile] = XUiCollectData.New(FileType.UiFile),
        [FileType.ManualUi] = XUiCollectData.New(FileType.ManualUi),
    }

    ModelNameDic = {}
    SortedUiKeyList = {}
    CollectedUiKeyDic = {}
    CollectedUiCount = 0

    for uiKey, _ in pairs(UiRegistry) do
        table.insert(SortedUiKeyList, uiKey)
    end

    table.sort(SortedUiKeyList, function(a, b)
        return a < b
    end)
end
--endregion

--region 正则收集配置表
local CollectTableByRegular = function(luaFilePath)
    CurSourceType = CollectSourceType.Regular

    local sr = XTableAssetCollectUtil.GetStreamingReader(luaFilePath)

    while sr:Peek() >= 0 do
        local content = sr:ReadLine()
        --忽略注释
        if not string.StartsWith(content, "--") then
            local tablePath = XTableAssetCollectUtil.ExtractTablePathByRegular(content)
            if tablePath then
                if AllTableData.fileTableDic[tablePath] then
                    AddTableInfo(tablePath)
                else
                    --不存在该配置表，可能是匹配错误了
                    XLog.Warning(string.format("匹配到不存在的配置表：%s \n文件名: %s \n所在行内容: %s", tablePath, CurFileName, content))
                end
            end
        end
    end

    sr:Close()
end
--endregion

--region 收集同目录下的配置表
local CollectSameDirectoryTable = function()
    local collectData = TableCollectDataDic[CurFileType]
    local fileInfo = collectData:GetFileInfo(CurFileName)
    if not fileInfo then return end

    CurSourceType = CollectSourceType.SameDirectory

    for _, tableInfo in ipairs(fileInfo.tableInfoList) do
        local tablePath = tableInfo.tablePath

        local directoryName = XTableAssetCollectUtil.GetDirectoryName(tablePath)
        if directoryName == "Client/Fuben" or directoryName == "Share/Fuben" then
            goto continue
        end

        local sameDirectoryTableList = AllTableData:GetSameDirectoryFilePathList(tablePath)

        for _, path in ipairs(sameDirectoryTableList) do
            --排除已收集的配置表和剧情表
            if not fileInfo.tableDic[path] and not XTableAssetCollectUtil.IsMovieTable(path) then
                AddTableInfo(path)
            end
        end

        :: continue ::
    end
end
--endregion

--region 收集剧情表
local CollectMovieTable = function()
    CurFileType = FileType.Movie
    CurSourceType = CollectSourceType.None

    for _, tablePath in ipairs(AllTableData.fileTableList) do
        if XTableAssetCollectUtil.IsMovieTable(tablePath) then
            CurFileName = FileTypeLogFileName[FileType.Movie]
            CurModelName = "X" .. CurFileName
            AddTableInfo(tablePath)
        end
    end
end
--endregion

--region 收集战斗表
local CollectFightTable = function()
    CurFileType = FileType.Fight
    CurSourceType = CollectSourceType.None

    for _, tablePath in ipairs(AllTableData.fileTableList) do
        if XTableAssetCollectUtil.IsFightTable(tablePath) then
            CurFileName = FileTypeLogFileName[FileType.Fight]
            CurModelName = "X" .. CurFileName
            AddTableInfo(tablePath)
        end
    end
end
--endregion

--region 收集手动配置的表
local CollectManualTable = function(fileType, sourceType)
    CurFileType = fileType
    CurSourceType = sourceType
    CurFileName = FileTypeLogFileName[fileType]
    CurModelName = "X" .. CurFileName

    local filePath = ManualFolderPath .. CurFileName .. ".tab"
    local tableContent = CS.XTableManager.LoadFileFromDebugDir(filePath)
    local tableLineDataList = string.Split(tableContent, "\r\n")

    for i = 1, #tableLineDataList do
        local lineData = string.Split(tableLineDataList[i], "\t")
        local tablePath = lineData[1]
        if tablePath then
            AddTableInfo(tablePath)
        end
    end
end

local CollectManualConfig = function()
    CurFileType = FileType.ManualConfig
    CurSourceType = CollectSourceType.ManualConfig
    CurFileName = FileTypeLogFileName[FileType.ManualConfig]

    local filePath = ManualFolderPath .. CurFileName .. ".tab"
    local tableContent = CS.XTableManager.LoadFileFromDebugDir(filePath)
    local tableLineDataList = string.Split(tableContent, "\r\n")

    for i = 2, #tableLineDataList do
        local lineData = string.Split(tableLineDataList[i], "\t")

        if lineData[1] ~= "" then
            CurModelName = lineData[1]

        elseif lineData[2] ~= "" then
            local path = lineData[2]

            if string.EndsWith(path, ".tab") then
                AddTableInfo(path)
            else
                local tablePathList = AllTableData:GetAllFileAtDirectory(path)
                for _, tablePath in ipairs(tablePathList) do
                    AddTableInfo(tablePath)
                end
            end
        end
    end
end

--endregion

--region 收集MVCA
local CollectTableByModelId = function(modelId)
    CurSourceType = CollectSourceType.ModelInit
    CurFileName = modelId .. "Model"
    CurModelName = modelId
    
    --新建model，重新调用配置表初始化
    local modelClass = XMVCAUtil.GetModelCls(modelId)
    local model = modelClass.New(modelId)

    local luaFilePath = XMVCAUtil.GetModelClsPath(modelId)
    --正则匹配
    CollectTableByRegular(XTableAssetCollectConst.LuaFileDirectory .. luaFilePath .. ".lua")
    --收集同目录下的配置表
    CollectSameDirectoryTable()
end

local CollectModelTable = function()
    CurFileType = FileType.Model

    for _, modelId in pairs(ModuleId) do
        CollectTableByModelId(modelId)
    end
end
--endregion

--region 收集旧版配置表
local CollectConfigTableByConfigCenter = function()
    if _G[CurFileName].__isCreatedByConfigCenter then
        CurSourceType = CollectSourceType.ConfigCenterCreate

        -- 该文件是使用了XConfigCenter.CreateTableConfig接口初始化的
        local sortedkeyList = {}

        for key, _ in pairs(_G[CurFileName].TableKey.dic) do
            table.insert(sortedkeyList, key)
        end

        table.sort(sortedkeyList, function(a, b)
            return a < b 
        end)

        for _, key in ipairs(sortedkeyList) do
            _G[CurFileName].GetAllConfigs(_G[CurFileName].TableKey[key])
        end
    end
end

local CollectConfigTableByInit = function()
    if _G[CurFileName].Init then
        CurSourceType = CollectSourceType.ConfigInit
        _G[CurFileName].Init()
    end
end

local CollectTableByConfigFile = function()
    CurFileType = FileType.Config

    local pathList = XTableAssetCollectUtil.GetLuaFilePathList("XConfig/")
    local len = pathList.Length
    for i = 0, len - 1 do
        local path = pathList[i]

        local configFilePath, configFileName = XTableAssetCollectUtil.ProcessLuaFilePath(path)

        if configFileName ~= "XConfigCenter" then
            XTableAssetCollectUtil.RequireLuaFile(configFilePath, configFileName)
            CurFileName = configFileName
            CurModelName = XTableAssetCollectUtil.RemoveTrailingConfig(CurFileName)

            if _G[configFileName] and not _G[configFileName].__isNonSense then
                CollectConfigTableByConfigCenter()
                CollectConfigTableByInit()
                --正则匹配
                CollectTableByRegular(path)
                --收集同目录下的配置表
                CollectSameDirectoryTable()
            end
        end
    end
end
--endregion

--region 收集Manager配置表
local CollectTableByManager = function()
    CurFileType = FileType.Manager

    local pathList = XTableAssetCollectUtil.GetLuaFilePathList("XManager/")
    local len = pathList.Length
    for i = 0, len - 1 do
        local path = pathList[i]

        local filePath, fileName = XTableAssetCollectUtil.ProcessLuaFilePath(path)
        XTableAssetCollectUtil.RequireLuaFile(filePath, fileName)

        CurFileName = fileName
        CurModelName = string.gsub(CurFileName, "Manager", "")

        if _G[fileName] and _G[fileName].Init then
            CurSourceType = CollectSourceType.ManagerInit

            local ok, err = pcall(_G[fileName].Init)
            if not ok then
                XLog.Error(string.format("Manager初始化报错:%s, 当前文件名：%s", err, CurFileName))
            end

            --正则匹配
            CollectTableByRegular(path)
            --收集同目录下的配置表
            CollectSameDirectoryTable()
        end
    end
end
--endregion


--region 收集手动配置的模块资源

--endregion

--region 收集UI
local CollectManualUi = function()
    --手动配置的Manual/Asset
    CurFileType = FileType.ManualUi
    CurFileName = FileTypeLogFileName[FileType.ManualUi]
    CurSourceType = CollectSourceType.ManualUi

    local filePath = ManualFolderPath .. CurFileName .. ".tab"
    local tableContent = CS.XTableManager.LoadFileFromDebugDir(filePath)
    local tableLineDataList = string.Split(tableContent, "\r\n")

    for i = 3, #tableLineDataList do
        local lineData = string.Split(tableLineDataList[i], "\t")

        if lineData[1] ~= nil and lineData[1] ~= "" and lineData[2] ~= nil and lineData[2] ~= "" then
            local uiKey = lineData[1]
            CurModelName = lineData[2]

            AddUiKey(uiKey)
        end
    end
end

local CollectUiByFile = function()
    CurFileType = FileType.UiFile

    for _, uiKey in ipairs(SortedUiKeyList) do
        if CollectedUiKeyDic[uiKey] then
            goto continue
        end
        
        local luaFilePath = UiRegistry[uiKey]
        
        local targetModelName = nil

        if UIBindControl[uiKey] then
            --对应的模块名已配置在UIBindControl中
            targetModelName = UIBindControl[uiKey]
        else
            local uiModelName = nil

            --从文件路径分析UI的模块名
            if string.StartsWith(luaFilePath, "XUi/XUiMiniGame") then
                uiModelName = string.match(luaFilePath, "XUi/XUiMiniGame/([^/]+)/")
            else
                local modelUiFolderName = string.match(luaFilePath, "XUi/([^/]+)/")
                uiModelName = string.gsub(modelUiFolderName, "^XUi", "")
                uiModelName = string.gsub(uiModelName, "^Fuben", "")
            end

            if ModelNameDic[uiModelName] then
                targetModelName = uiModelName

            elseif ModelNameDic["X" .. uiModelName] then
                targetModelName = "X" .. uiModelName

            elseif ModelNameDic["XFuben" .. uiModelName] then
                targetModelName = "XFuben" .. uiModelName
                
            elseif ModelNameDic["X" .. uiModelName .. "Activity"] then
                targetModelName = "X" .. uiModelName .. "Activity"
            end
        end

        if targetModelName ~= nil then
            CurModelName = targetModelName
            CurSourceType = CollectSourceType.UiFile
            AddUiKey(uiKey)
        end

        :: continue ::
    end
end
--endregion

--region 结束

--region 统计配置表
local CulculateCollectedTableData = function()
    AllFileTableCount = #AllTableData.fileTableList

    CollectedTableCount = 0

    CollectedPathDic = {}
    for _, collectData in pairs(TableCollectDataDic) do
        -- 合并所有收集到的表，去重
        for tablePath, _ in pairs(collectData.totalTableDic) do
            if not CollectedPathDic[tablePath] then
                CollectedPathDic[tablePath] = true
                CollectedTableCount = CollectedTableCount + 1
            end
        end
    end

    UnCollectedTableCount = AllFileTableCount - CollectedTableCount
    UncollectedPercent = UnCollectedTableCount / AllFileTableCount * 100
end

local SaveTabeCollectData = function()
    if not IO.Directory.Exists(AutoGenerateCollectTableFolder) then
        IO.Directory.CreateDirectory(AutoGenerateCollectTableFolder)
    end

    for fileType, collectData in pairs(TableCollectDataDic) do
        local fileName = FileTypeLogFileName[fileType]
        local filePath = AutoGenerateCollectTableFolder .. fileName .. ".tab"

        local content = {}
        local lineDataPattern = "%s\t%s\t%s\t%s"
        content[#content+1] = string.format(lineDataPattern, "FileName","ModelName","TablePath","CollectSource")
        content[#content+1] = string.format(lineDataPattern, "文件名","模块名","配置表路径", "来源")

        for _, fileInfo in ipairs(collectData.fileInfoList) do
            content[#content+1] = string.format(lineDataPattern, fileInfo.fileName, "", "", "")
            for _, tableInfo in ipairs(fileInfo.tableInfoList) do
                content[#content+1] = string.format(lineDataPattern, "", tableInfo.modelName, tableInfo.tablePath, XTableAssetCollectUtil.GetTableSourceTypeTips(tableInfo.sourceType))
            end
        end

        content = table.concat(content, "\r\n")
        IO.File.WriteAllText(filePath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
    end
end

local SaveAllTableData = function()
    local content = {}
    local lineDataPattern = "%s\t%s\t%s\t%s"
    content[#content+1] = string.format(lineDataPattern, "FileName","ModelName","TablePath","CollectSource")
    content[#content+1] = string.format(lineDataPattern, "文件名","模块名","配置表路径", "来源")

    for _, collectData in pairs(TableCollectDataDic) do
        for _, fileInfo in ipairs(collectData.fileInfoList) do
            content[#content+1] = string.format(lineDataPattern, fileInfo.fileName, "", "", "")

            for _, tableInfo in ipairs(fileInfo.tableInfoList) do
                content[#content+1] = string.format(lineDataPattern, "", tableInfo.modelName, tableInfo.tablePath, XTableAssetCollectUtil.GetTableSourceTypeTips(tableInfo.sourceType))
            end
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelTableDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local SaveAllModelNameData = function()
    local content = {}

    for modelName, _ in pairs(ModelNameDic) do
        content[#content+1] = modelName
    end

    table.sort(content, function(a, b)
        return a < b
    end)

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.AllModelNameDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local SaveModelTableStatisticData = function()
    local content = {}

    content[#content+1] = string.format("配置表总数：%s, 已收集的配置表数：%s, 未收集的配置表数：%s, 未收集百分比：%s", AllFileTableCount, CollectedTableCount, UnCollectedTableCount, UncollectedPercent)
    
    for fileType, collectData in pairs(TableCollectDataDic) do
        content[#content+1] = string.format("%s配置表数量: %s", FileTypeLogFileName[fileType], collectData.totalTableCount)
    end

    content[#content+1] = ""

    for _, fileTablePath in ipairs(AllTableData.fileTableList) do
        if not CollectedPathDic[fileTablePath] then
            content[#content+1] = string.format("未收集的配置表：%s", fileTablePath)
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelTableStatisticDataPath, content)
end
--endregion

--region 统计UI
local CulculateCollectedUiData = function()
    TotalUiCount = #SortedUiKeyList
    UnCollectedUiCount = TotalUiCount - CollectedUiCount
end

local SaveUiCollectData = function()
    if not IO.Directory.Exists(AutoGenerateCollectUiFolder) then
        IO.Directory.CreateDirectory(AutoGenerateCollectUiFolder)
    end

    for fileType, collectData in pairs(UiCollectDataDic) do
        local fileName = FileTypeLogFileName[fileType]
        local filePath = AutoGenerateCollectUiFolder .. fileName .. ".tab"

        local content = {}
        local lineDataPattern = "%s\t%s\t%s"
        content[#content+1] = string.format(lineDataPattern,"ModelName","uiKey","CollectSource")
        content[#content+1] = string.format(lineDataPattern,"模块名","UI表的id", "来源")

        for _, modelInfo in ipairs(collectData.modelInfoList) do
            content[#content+1] = string.format(lineDataPattern, modelInfo.modelName, "", "")
            for _, uiInfo in ipairs(modelInfo.uiInfoList) do
                content[#content+1] = string.format(lineDataPattern, "", uiInfo.uiKey, XTableAssetCollectUtil.GetTableSourceTypeTips(uiInfo.sourceType))
            end
        end

        content = table.concat(content, "\r\n")
        IO.File.WriteAllText(filePath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
    end
end

local SaveAllUiData = function()
    local content = {}
    local lineDataPattern = "%s\t%s\t%s"
    content[#content+1] = string.format(lineDataPattern,"ModelName","uiKey","CollectSource")
    content[#content+1] = string.format(lineDataPattern,"模块名","UI表的id", "来源")

    for _, collectData in pairs(UiCollectDataDic) do
        for _, modelInfo in ipairs(collectData.modelInfoList) do
            content[#content+1] = string.format(lineDataPattern, modelInfo.modelName, "", "")

            for _, uiInfo in ipairs(modelInfo.uiInfoList) do
                content[#content+1] = string.format(lineDataPattern, "", uiInfo.uiKey, XTableAssetCollectUtil.GetTableSourceTypeTips(uiInfo.sourceType))
            end
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelUiDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local SaveModelUiStatisticData = function()
    local content = {}

    content[#content+1] = string.format("ui总数: %s, 已收集的ui数: %s, 未收集的ui数: %s, 未收集百分比: %s", TotalUiCount, CollectedUiCount, UnCollectedUiCount, UnCollectedUiCount / TotalUiCount)
    content[#content+1] = ""

    content[#content+1] = "==========未匹配到对应业务模块名的ui列表=================="

    for _, uiKey in ipairs(SortedUiKeyList) do
        if not CollectedUiKeyDic[uiKey] then
            content[#content+1] = uiKey
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelUiStatisticDataPath, content)
end
--endregion


local OnFinishCollect = function()
    CulculateCollectedTableData()
    CulculateCollectedUiData()

    --配置表
    SaveTabeCollectData()
    SaveAllTableData()
    SaveModelTableStatisticData()

    --资源
    SaveUiCollectData()
    SaveAllUiData()
    SaveModelUiStatisticData()

    SaveAllModelNameData()
end
--endregion

--region 入口
local CollecTable = function()
    CollectManualTable(FileType.Common, CollectSourceType.ManualCommon)
    CollectManualTable(FileType.Ignore, CollectSourceType.ManualIgnore)
    CollectManualConfig()
    CollectMovieTable()
    CollectFightTable()
    CollectModelTable()
    CollectTableByConfigFile()
    CollectTableByManager()
end

local CollectAsset = function()
    CollectManualUi()
    CollectUiByFile()
end

function XTableManager.CollectModelData()
    RedirectGMeta()
    RedirectXTableManager()
    RedirectXConfigUtil()
    RedirectXConfigCenter()

    OnBeforCollect()

    CollecTable()
    CollectAsset()

    OnFinishCollect()

    RecoverXTableManager()
    RecoverXConfigUtil()
    RecoverXConfigCenter()
    RecoverGMeta()
end
--endregion