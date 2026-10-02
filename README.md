# test_template — шаблон плагина для Revit

Репозиторий — это рабочий `dotnet new`-шаблон (`.template.config\template.json`, short name `tiver-revit-plugin`) для создания новых плагинов Revit, поддерживающих версии **2019–2027** из одной кодовой базы.

## 1. Назначение и структура

Solution `test_template.sln` состоит из шести проектов:

| Проект | Назначение |
|---|---|
| `RevitStartup\` | Точка входа плагина в Revit. `Application\ExternalApplication.cs` — `IExternalApplication`, `Application\RibbonManager.cs` — создание вкладки/панели/кнопки на ленте, `Manifest\test_template.addin`, `Updater\` |
| `test_template\` | Модуль плагина без WPF. |
| `test_templateWPF\` | WPF-вариант модуля плагина |
| `Styles\` | Общие WPF-стили и ресурсы (Material Design) |
| `InstallerWIX\` | WiX-проект **одного общего MSI**, который ставит плагин сразу под все версии Revit 2019–2027. |
| `InstallerWIXSeparate\` | WiX-проект, который собирает **отдельный MSI на каждую версию**. |

Код собирается под три .NET taргета в зависимости от версии Revit:
- **net48** — R2019–R2024
- **net8.0-windows** — R2025–R2026
- **net10.0-windows** — R2027

## 2. Что нужно переименовать/настроить при создании нового плагина

### Автоматически (через `dotnet new`)
- Имя `test_template` во всех именах файлов/папок и в содержимом файлов (`sourceName` в `template.json`).
- Все GUID'ы шаблона (см. `symbols` в `.template.config\template.json`): `ClientId` адина, addin-компоненты и upgrade-коды инсталляторов для каждого года 2019–2027, upgrade-код общего бандла, GUID компонента `RegisterVersion`. Все они перегенерируются на каждое создание проекта — руками их трогать не нужно.

### Вручную
- **`RevitStartup\Manifest\test_template.addin`** - Проверить/поправить `<Name>`, `<Assembly>` (путь до .dll), `<FullClassName>` и при необходимости `<VendorId>`/`<VendorDescription>`, если плагин не под брендом TiverGroup.

- **`Directory.Build.props`** (корень репозитория) — общие метаданные сборки:
  ```xml
  <Version>1.0.0.0</Version>
  <Copyright>Copyright ©  2026</Copyright>
  <Company>TiverGroup</Company>
  <Product>test_template</Product>
  ```
  `Version`, `Copyright`, `Company`, `Product` нужно обновить под конкретный продукт — эти значения попадают в метаданные собранных сборок и используются `InstallerWIXSeparate\build-all.ps1` при формировании имени MSI.

- **`RevitStartup\Application\RibbonManager.cs`** — здесь задаются название вкладки/панели и кнопки на ленте Revit:
  ```csharp
  const string TabName = "TiverGroup";
  ...
  _creationPanel = application.CreateRibbonPanel(TabName, "test_template");
  var button = new PushButtonData("ModuleOneButton", "Module One", ThisAssemblyPath, "test_template.Command.ModuleOneCommand");
  ```
  `TabName`, имя панели ("test_template") и параметры кнопки (внутреннее имя, текст, полное имя класса команды) — заменить на реальные для нового плагина. Четвёртый аргумент `PushButtonData` — это **полное имя класса команды**, реализующей `IExternalCommand` (например `test_template.Command.ModuleOneCommand` из `test_template\Commands\ModuleOneCommand.cs`) — если оно не совпадает с реальным классом, кнопка на ленте не будет работать.

- **Важная оговорка про `RevitStartup` и `test_templateWPF`:** механизм `dotnet new` (`sourceName: "test_template"`) заменяет только буквальную строку `test_template` — имена и неймспейсы проектов `RevitStartup` и `test_templateWPF` он **не** переименовывает. 

## 3. Скрипты сборки

### `build.ps1` 
Собирает весь код и упаковывает общий инсталлятор одним запуском:
1. Находит `msbuild.exe` через `vswhere` (или в `PATH`).
2. Собирает `test_template.sln` под тремя мета-конфигурациями — `BuildNET48`, `BuildNET8`, `BuildNET10` (`Platform=x64`). Каждая мета-конфигурация запускает у каждого code-проекта таргет `AfterTargets="Build"`, который рекурсивно пересобирает проект под реальные версии:
   - `BuildNET48` → R2019, R2020, R2021, R2022, R2023, R2024
   - `BuildNET8` → R2025, R2026
   - `BuildNET10` → R2027
3. Если все три шага прошли успешно — собирает `InstallerWIX\InstallerWIX.wixproj` (`Configuration=Release`, `Platform=x86`) — это единый MSI, содержащий все версии сразу.
4. Выводит путь к готовому MSI (`InstallerWIX\bin\Release\*.msi`).

### `Copy-FolderContents.ps1`
Простой скрипт который копирует файлы из папки подключённого google drive в папку проекта. Нужен для ресурсов которые не упаковываются в dll а вызываются при работе плагина (семейства revit, pdf файлы инструкций)

### `convert-office-to-pdf.ps1`
Скрипт для пересохранения .pptx и .docx файлов в pdf. Проходит по дирректории с файлами и пересохраняет только файлы с нужными расширениями

Запуск:
```powershell
.\Copy-FolderContents.ps1 -SourceFolder "C:\Src" -DestinationFolder "D:\Dst" -Recurse -Force &&
.\convert-office-to-pdf.ps1 -FolderPath "D:\Dst" &&
.\build.ps1
```

### `InstallerWIXSeparate\build-all.ps1`
Собирает **отдельный MSI на каждую версию** Revit (предполагает, что код уже собран — сам код не пересобирает):
1. Находит `msbuild.exe` так же, как `build.ps1`.
2. Читает `Version` из `Directory.Build.props`.
3. Для версий 2019–2027 вызывает `msbuild InstallerWIXSeparate.wixproj /t:Clean,Build /p:Configuration=Release /p:RevitVersion=<год>`.
4. Перекладывает получившиеся `test_template <версия> Revit <год> setup.msi` в `InstallerWIXSeparate\output\`.

Запуск:
```powershell
.\InstallerWIXSeparate\build-all.ps1
```

### `Github action`
`\.github\workflows\release.yml` - при push в master (заменить на main при необходимости), проект собирается через `build.ps1`, создаётся таг и новый релиз.

## 4. Как создать новый плагин из шаблона

1. Установить шаблон (один раз, путь — до этого репозитория):
   ```powershell
   dotnet new install "D:\tiver\Шаблоны\test_template"
   ```
2. Создать новый проект из шаблона:
   ```powershell
   dotnet new tiver-revit-plugin -n <ИмяПлагина> -o <папка-назначения>
   ```
   Это автоматически:
   - заменит `test_template` на `<ИмяПлагина>` во всех именах файлов/папок и в содержимом файлов;
   - сгенерирует новые GUID для `ClientId`, всех addin-компонентов и upgrade-кодов 2019–2027, upgrade-кода бандла и компонента `RegisterVersion` — все значения будут уникальны для нового плагина, конфликтов с оригинальным шаблоном не будет.
3. После генерации пройтись по разделу 2 этой инструкции руками:
   - проверить/поправить `RevitStartup\Manifest\<Имя>.addin`;
   - обновить `Directory.Build.props`;
   - поправить `RibbonManager.cs` (вкладка/панель/кнопка/класс команды);
   - при необходимости переименовать `RevitStartup`/`test_templateWPF` (не делается автоматически);
   - настроить собственные учётные данные для приватного NuGet-фида.

Если нужно переустановить шаблон после правок в `.template.config\template.json`:
```powershell
dotnet new uninstall "D:\tiver\Шаблоны\test_template"
dotnet new install "D:\tiver\Шаблоны\test_template"
```

## 5. Отдельные шаблоны модулей (`test_template` / `test_templateWPF`)

Помимо шаблона целого solution (`tiver-revit-plugin`), в репозитории есть два независимых `dotnet new`-шаблона **уровня проекта** — по одному на каждый модуль (`test_template\.template.config`, `test_templateWPF\.template.config`). Они устанавливаются той же командой `dotnet new install` (см. раздел 4) и генерируют **только код модуля** — без `RevitStartup`, `Styles` и инсталляторов.

Генерация:
```powershell
dotnet new tiver-revit-module -n <ИмяМодуля> -o <папка>       # модуль без WPF
dotnet new tiver-revit-module-wpf -n <ИмяМодуля> -o <папка>   # WPF-модуль
```

Это удобно, когда нужно добавить ещё один модуль в уже существующий плагин (свой или сгенерированный из `tiver-revit-plugin`), не пересоздавая весь solution заново. После генерации:
- добавить сгенерированный `.csproj` как проект в существующее решение;
- прописать кнопку/панель и полное имя класса команды в `RevitStartup\Application\RibbonManager.cs` — см. раздел 2;
- учитывать, что метаданные сборки (`Version`, `Company`, `Product`) модуль получает из `Directory.Build.props` того решения, в которое его добавили — сам по себе шаблон модуля файл `Directory.Build.props` не создаёт.
