using System.Reflection;
using System.Runtime.InteropServices;

// AssemblyTitle не генерируется автоматически (GenerateAssemblyTitleAttribute=false
// в Directory.Build.props), поэтому задаётся здесь вручную. Остальные версия-зависимые
// атрибуты (Version, Product и т.д.) генерируются MSBuild-ом из Directory.Build.props.
[assembly: AssemblyTitle("test_template")]

// ComVisible не поддерживается автогенерацией GenerateAssemblyInfo в .NET SDK, поэтому
// задаётся здесь вручную, как и раньше.
[assembly: ComVisible(false)]

// Следующий GUID служит для идентификации библиотеки типов, если этот проект будет видимым для COM
[assembly: Guid("a50cfa2e-095a-4a52-8bd3-ae3cf1e1a4c9")]
