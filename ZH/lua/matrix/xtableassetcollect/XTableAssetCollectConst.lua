local this = {}

this.TableDirectory = "../../Product/Table/"
this.TableDirectoryStrLen = #this.TableDirectory
this.IgnoreExtension = ".sha1ignore.tab"
this.TableExtension = ".tab"

this.CollectLogFolderPath = "../../Product/Temp/CollectTableData/"
this.ModelTableFolderPath = this.CollectLogFolderPath .. "ModelTable/"
this.AutoGenerateFolderPath = this.ModelTableFolderPath .. "AutoGenerate/"
this.ManulFolderPath = this.ModelTableFolderPath .. "Manul/"
this.StatisticFolderPath = this.CollectLogFolderPath .. "Statistic/"
this.ModelTableDataPath = this.StatisticFolderPath .. "ModelTable.tab"
this.AllResourceStatisticDataPath = this.StatisticFolderPath .. "ModelTableResource.tab"
this.ModelUiDataPath = this.StatisticFolderPath .. "ModelUi.tab"
this.EmptyModelUiDataPath = this.StatisticFolderPath .. "EmptyModelUi.tab"
this.AllModelNameDataPath = this.StatisticFolderPath .. "AllModelName.tab"
this.ModelTableStatisticDataPath = this.StatisticFolderPath .. "ModelTable统计数据.txt"
this.ModelUIPrefabStatisticDataPath = this.StatisticFolderPath .. "ModelUi统计数据.txt"

this.LuaFileDirectory = "../../Product/Lua/Matrix/"
this.LuaFileDirectoryLen = #this.LuaFileDirectory
this.LuaUIFolder = this.LuaFileDirectory .. "XUi/"

this.NeedCollectTableFolderList = {
    "../../Product/Table/Client",
    "../../Product/Table/Share",
}

this.TableRegularPatternList = {
    '"(Client/[^"]+%.tab)"',
    '"(Share/[^"]+%.tab)"',
}

this.FightTablePathList = {
    "Client/Fight/",
    "Client/StatusSyncFight/",
    "Share/Fight/",
    "Share/StatusSyncFight/",
    "Client/ResourceLut/",
}

this.MovieTablePathList = {
    "Client/Movie/",
    "Share/Movie/",
    "Client/Story/",
    "Share/Story/",
}

this.FileType = {
    Model = 1,
    Config = 2,
    Manager = 3,
    Movie = 4,
    Fight = 5,
    Common = 6,
    Ignore = 7,
    ManulConfig = 8,
}

this.FileTypeLogFileName = {
    [this.FileType.Model] = "Model",
    [this.FileType.Config] = "Config",
    [this.FileType.Manager] = "Manager",
    [this.FileType.Movie] = "Movie",
    [this.FileType.Fight] = "Fight",
    [this.FileType.Common] = "Common",
    [this.FileType.Ignore] = "Ignore",
    [this.FileType.ManulConfig] = "ManulConfig",
}

this.TableSourceType = {
    None = 0,
    ModelInit = 1,
    ConfigCenterCreate = 2,
    ConfigInit = 3,
    ManagerInit = 4,
    SameDirectory = 5,
    Regular = 6,
    ManulCommon = 7,
    ManulIgnore = 8,
    ManulConfig = 9,
}

this.TableSourceTypeTips = {
    [this.TableSourceType.None] = "",
    [this.TableSourceType.ModelInit] = "Model的init接口收集",
    [this.TableSourceType.ConfigCenterCreate] = "XConfigCenter.CreateTableConfig接口收集",
    [this.TableSourceType.ConfigInit] = "Config文件自己的Init接口收集",
    [this.TableSourceType.ManagerInit] = "Manager的Init接口收集",
    [this.TableSourceType.SameDirectory] = "相同的目录中收集",
    [this.TableSourceType.Regular] = "正则匹配",
    [this.TableSourceType.ManulCommon] = "Common表中手动配置",
    [this.TableSourceType.ManulIgnore] = "Ignore表中手动配置",
    [this.TableSourceType.ManulConfig] = "ManulConfig表中手动配置",
}

--不需要生成收集数据的类型，Common类型是手动收集的
this.SkipGenerateCollectDataType = {
    [this.FileType.Common] = true,
    [this.FileType.Ignore] = true,
}

return this