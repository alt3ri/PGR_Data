local IO = CS.System.IO

local XAllTableData = require("XTableAssetCollect/XTableDirectory/XAllTableData")
local XTableCollectData = require("XTableAssetCollect/XTableCollectData")
local XTableAssetCollectUtil = require("XTableAssetCollect/XTableAssetCollectUtil")
local XTableAssetCollectConst = require("XTableAssetCollect/XTableAssetCollectConst")
local UiRegistry = require("UiRegistry")
local XCollectUiData = require("XTableAssetCollect/XCollectUiData")
local string = string

local OriginalGMeta

local FileType = XTableAssetCollectConst.FileType
local FileTypeLogFileName = XTableAssetCollectConst.FileTypeLogFileName
local TableSourceType = XTableAssetCollectConst.TableSourceType
local AutoGenerateFolderPath = XTableAssetCollectConst.AutoGenerateFolderPath
local ManulFolderPath = XTableAssetCollectConst.ManulFolderPath

local AllTableData
local CollectDataDic
local TableModelNameDic
local SortedUiKeyList
local CollectUiDataDic
local UnMatchModelUiDic
local CurFileType -- 当前文件类型
local CurFileName -- 当前文件名
local CurModelName -- 当前模块名
local CurTableSourceType -- 当前配置表收集方式

--收集数据统计
local AllFileTableCount
local CollectedTableCount
local UnCollectedTableCount
local UncollectedPercent
local CollectedPathDic
local TotalUiCount
local UnMatchModelUiCount

--region 处理配置表信息
local AddTableInfo = function(path)
    local fullTablePath = CS.XTableManager.GetFullPath(path)
    if not IO.File.Exists(fullTablePath) then return end

    local collectData = CollectDataDic[CurFileType]
    collectData:AddTable(CurFileName, CurModelName, path, CurTableSourceType)

    TableModelNameDic[CurModelName] = true
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

    CollectDataDic = {
        [FileType.Model] = XTableCollectData.New(FileType.Model),
        [FileType.Config] = XTableCollectData.New(FileType.Config),
        [FileType.Manager] = XTableCollectData.New(FileType.Manager),
        [FileType.Movie] = XTableCollectData.New(FileType.Movie),
        [FileType.Fight] = XTableCollectData.New(FileType.Fight),
        [FileType.Common] = XTableCollectData.New(FileType.Common),
        [FileType.Ignore] = XTableCollectData.New(FileType.Ignore),
        [FileType.ManulConfig] = XTableCollectData.New(FileType.ManulConfig),
    }

    TableModelNameDic = {}
    SortedUiKeyList = {}
    CollectUiDataDic = {}
    UnMatchModelUiDic = {}

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
    CurTableSourceType = TableSourceType.Regular

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
    local collectData = CollectDataDic[CurFileType]
    local fileInfo = collectData:GetFileInfo(CurFileName)
    if not fileInfo then return end

    CurTableSourceType = TableSourceType.SameDirectory

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
    CurTableSourceType = TableSourceType.None

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
    CurTableSourceType = TableSourceType.None

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
    CurTableSourceType = sourceType
    CurFileName = FileTypeLogFileName[fileType]
    CurModelName = "X" .. CurFileName

    local filePath = ManulFolderPath .. CurFileName .. ".tab"
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

local CollectManulConfig = function()
    CurFileType = FileType.ManulConfig
    CurTableSourceType = TableSourceType.ManulConfig
    CurFileName = FileTypeLogFileName[FileType.ManulConfig]

    local filePath = ManulFolderPath .. CurFileName .. ".tab"
    local tableContent = CS.XTableManager.LoadFileFromDebugDir(filePath)
    local tableLineDataList = string.Split(tableContent, "\r\n")

    for i = 2, #tableLineDataList do
        local lineData = string.Split(tableLineDataList[i], "\t")

        if lineData[1] ~= "" then
            CurModelName = lineData[1]

        elseif lineData[3] ~= "" then
            local path = lineData[3]

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
    CurTableSourceType = TableSourceType.ModelInit
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
        CurTableSourceType = TableSourceType.ConfigCenterCreate

        -- 该文件是使用了XConfigCenter.CreateTableConfig接口初始化的
        for _, tableKey in pairs(_G[CurFileName].TableKey.dic) do
            _G[CurFileName].GetAllConfigs(tableKey)
        end
    end
end

local CollectConfigTableByInit = function()
    if _G[CurFileName].Init then
        CurTableSourceType = TableSourceType.ConfigInit
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
            CurTableSourceType = TableSourceType.ManagerInit

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

--region 收集UI
local CollectUIPrefab = function()
    TotalUiCount = 0
    UnMatchModelUiCount = 0

    for uiKey, luaFilePath in pairs(UiRegistry) do
        TotalUiCount = TotalUiCount + 1

        local collectUiData = XCollectUiData.New(uiKey)
        CollectUiDataDic[uiKey] = collectUiData

        local modelUiFolderName = string.match(luaFilePath, "XUi/([^/]+)/")
        local uiModelName = string.gsub(modelUiFolderName, "^XUi", "")
        
        if TableModelNameDic[uiModelName] then
            collectUiData:SetModelName(uiModelName)

        elseif TableModelNameDic["X" .. uiModelName] then
            collectUiData:SetModelName("X" .. uiModelName)

        elseif TableModelNameDic["XFuben" .. uiModelName] then
            collectUiData:SetModelName("XFuben" .. uiModelName)

        else
            UnMatchModelUiCount = UnMatchModelUiCount + 1
            UnMatchModelUiDic[uiModelName] = UnMatchModelUiDic[uiModelName] or {}
            table.insert(UnMatchModelUiDic[uiModelName], uiKey)
        end
    end
end
--endregion

--region 结束
local CulculateCollectedData = function()
    AllFileTableCount = #AllTableData.fileTableList

    CollectedTableCount = 0

    CollectedPathDic = {}
    for _, collectData in pairs(CollectDataDic) do
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

local GenerateCollectTabeData = function()
    for fileType, collectData in pairs(CollectDataDic) do
        local fileName = FileTypeLogFileName[fileType]
        local filePath = AutoGenerateFolderPath .. fileName .. ".tab"

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

local GenerateAllTableData = function()
    local content = {}
    local lineDataPattern = "%s\t%s\t%s\t%s"
    content[#content+1] = string.format(lineDataPattern, "FileName","ModelName","TablePath","CollectSource")
    content[#content+1] = string.format(lineDataPattern, "文件名","模块名","配置表路径", "来源")

    for _, collectData in pairs(CollectDataDic) do
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

local GenerateModelUiData = function()
    local content = {}
    content[#content+1] = "UiKey\tModelName"
    content[#content+1] = "Ui表的id\t模块名"

    for _, uiKey in ipairs(SortedUiKeyList) do
        local uiData = CollectUiDataDic[uiKey]
        content[#content+1] = string.format("%s\t%s", uiKey, uiData:GetModelName())
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelUiDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local GenerateEmptyModelUiData = function()
    local content = {}
    content[#content+1] = "UiKey\tModelName"
    content[#content+1] = "Ui表的id\t模块名"

    for _, uiKey in ipairs(SortedUiKeyList) do
        local uiData = CollectUiDataDic[uiKey]
        if uiData:GetModelName() == "" then
            content[#content+1] = string.format("%s\t%s", uiKey, uiData:GetModelName())
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.EmptyModelUiDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local GenerateAllModelNameData = function()
    local content = {}

    for modelName, _ in pairs(TableModelNameDic) do
        content[#content+1] = modelName
    end

    table.sort(content, function(a, b)
        return a < b
    end)

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.AllModelNameDataPath, content, CS.System.Text.Encoding.GetEncoding("GBK"))
end

local GenerateModelTableStatisticData = function()
    local content = {}

    content[#content+1] = string.format("配置表总数：%s, 已收集的配置表数：%s, 未收集的配置表数：%s, 未收集百分比：%s", AllFileTableCount, CollectedTableCount, UnCollectedTableCount, UncollectedPercent)
    
    for fileType, collectData in pairs(CollectDataDic) do
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

local GenerateModelUiStatisticData = function()
    local content = {}

    content[#content+1] = string.format("ui总数: %s, 已收集的ui数: %s, 未收集的ui数: %s, 未收集百分比: %s", TotalUiCount, TotalUiCount - UnMatchModelUiCount, UnMatchModelUiCount, UnMatchModelUiCount / TotalUiCount)
    content[#content+1] = ""

    content[#content+1] = "==========未匹配到对应业务模块名的ui列表=================="

    for modelName, uiKeyList in pairs(UnMatchModelUiDic) do
        content[#content+1] = string.format("ui模块名:%s", modelName)

        for _, uiKey in ipairs(uiKeyList) do
            content[#content+1] = string.format("\t%s", uiKey)
        end
    end

    content = table.concat(content, "\r\n")
    IO.File.WriteAllText(XTableAssetCollectConst.ModelUIPrefabStatisticDataPath, content)
end

local OnFinishCollect = function()
    if not IO.Directory.Exists(AutoGenerateFolderPath) then
        IO.Directory.CreateDirectory(AutoGenerateFolderPath)
    end

    CulculateCollectedData()

    GenerateCollectTabeData()
    GenerateAllTableData()
    GenerateAllModelNameData()
    GenerateModelUiData()
    GenerateEmptyModelUiData()

    GenerateModelTableStatisticData()
    GenerateModelUiStatisticData()
end
--endregion

--region 入口
function XTableManager.CollectModelData()
    RedirectGMeta()
    RedirectXTableManager()
    RedirectXConfigUtil()
    RedirectXConfigCenter()

    OnBeforCollect()

    CollectManualTable(FileType.Common, TableSourceType.ManulCommon)
    CollectManualTable(FileType.Ignore, TableSourceType.ManulIgnore)
    CollectManulConfig()
    CollectMovieTable()
    CollectFightTable()
    CollectModelTable()
    CollectTableByConfigFile()
    CollectTableByManager()
    CollectUIPrefab()

    OnFinishCollect()

    RecoverXTableManager()
    RecoverXConfigUtil()
    RecoverXConfigCenter()
    RecoverGMeta()
end
--endregion