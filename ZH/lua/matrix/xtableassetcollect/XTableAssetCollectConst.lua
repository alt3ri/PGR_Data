local this = {}

this.TableDirectory = "../../Product/Table/"
this.TableDirectoryStrLen = #this.TableDirectory
this.IgnoreExtension = ".sha1ignore.tab"
this.TableExtension = ".tab"
this.SouceTableDirectory = "../../Product/SourceTable/"

this.CollectLogFolderPath = "../../Product/Temp/CollectTableData/"
this.ModelTableFolderPath = this.CollectLogFolderPath .. "ModelTable/"
this.AutoGenerateFolderPath = this.ModelTableFolderPath .. "AutoGenerate/"
this.AutoGenerateCollectTableFolder = this.AutoGenerateFolderPath .. "Table/"
this.AutoGenerateCollectUiFolder = this.AutoGenerateFolderPath .. "Ui/"
this.ManualFolderPath = this.ModelTableFolderPath .. "Manual/"
this.StatisticFolderPath = this.CollectLogFolderPath .. "Statistic/"
this.ModelTableDataPath = this.StatisticFolderPath .. "ModelTable.tab"
this.ModelUiDataPath = this.StatisticFolderPath .. "ModelUi.tab"
this.EmptyModelUiDataPath = this.StatisticFolderPath .. "EmptyModelUi.tab"
this.AllModelNameDataPath = this.StatisticFolderPath .. "AllModelName.tab"
this.ModelTableStatisticDataPath = this.StatisticFolderPath .. "配置表统计数据.txt"
this.ModelUiStatisticDataPath = this.StatisticFolderPath .. "UI预制体统计数据.txt"

this.LuaFileDirectory = "../../Product/Lua/Matrix/"
this.LuaFileDirectoryLen = #this.LuaFileDirectory
this.LuaUIFolder = this.LuaFileDirectory .. "XUi/"
this.SourceUiTable = this.SouceTableDirectory .. "Ui/Ui.stab"

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
    ManualConfig = 8,
    UiFile = 9,
    ManualUi = 10,
}

this.FileTypeLogFileName = {
    [this.FileType.Model] = "Model",
    [this.FileType.Config] = "Config",
    [this.FileType.Manager] = "Manager",
    [this.FileType.Movie] = "Movie",
    [this.FileType.Fight] = "Fight",
    [this.FileType.Common] = "Common",
    [this.FileType.Ignore] = "Ignore",
    [this.FileType.ManualConfig] = "ManualConfig",
    [this.FileType.UiFile] = "UiFile",
    [this.FileType.ManualUi] = "ManualUi",
}

this.CollectSourceType = {
    None = 0,
    ModelInit = 1,
    ConfigCenterCreate = 2,
    ConfigInit = 3,
    ManagerInit = 4,
    SameDirectory = 5,
    Regular = 6,
    ManualCommon = 7,
    ManualIgnore = 8,
    ManualConfig = 9,
    UiFile = 10,
    ManualUi = 11,
}

this.CollectSourceTypeTips = {
    [this.CollectSourceType.None] = "",
    [this.CollectSourceType.ModelInit] = "Model的init接口收集",
    [this.CollectSourceType.ConfigCenterCreate] = "XConfigCenter.CreateTableConfig接口收集",
    [this.CollectSourceType.ConfigInit] = "Config文件自己的Init接口收集",
    [this.CollectSourceType.ManagerInit] = "Manager的Init接口收集",
    [this.CollectSourceType.SameDirectory] = "相同的目录中收集",
    [this.CollectSourceType.Regular] = "正则匹配",
    [this.CollectSourceType.ManualCommon] = "Manual/Common表中手动配置",
    [this.CollectSourceType.ManualIgnore] = "Manual/Ignore表中手动配置",
    [this.CollectSourceType.ManualConfig] = "Manual/ManualConfig表中手动配置",
    [this.CollectSourceType.UiFile] = "分析UI的Lua代码",
    [this.CollectSourceType.ManualUi] = "Manual/ManualUi表中手动配置",
}

return this