set-executionpolicy remotesigned
# 定义默认路径
$downloadPath = "C:\Users\Administrator\Downloads\steamruku"
$configFile = Join-Path $env:APPDATA "SteamToolConfig.ini"
$currentVersion = "1.0.7"  # 当前脚本版本
$updateUrl = "https://gh.catmak.name/https://github.com/huanggua666/ruku/blob/main/%E4%BE%BF%E6%8D%B7%E5%85%A5%E5%BA%93.ps1"
$githubMirrors = @(
    "https://gh.catmak.name/",  # 默认首选
    "https://gh.llkk.cc/",
    "https://ghfile.geekertao.top/",
    "https://github.dpik.top/",
    "https://ghp.ml1.one/"
)

# 首次运行标志文件
$firstRunFile = Join-Path $env:APPDATA "SteamTool_FirstRun.flag"

# 检测是否首次运行
function Test-FirstRun {
    # 如果标志文件不存在就是首次运行
    return -not (Test-Path $firstRunFile)
}

# 标记为非首次运行
function Set-NotFirstRun {
    $null = New-Item -Path $firstRunFile -ItemType File -Force
}

function Show-Welcome {
    Clear-Host
    Write-Host @"
███████╗████████╗███████╗ █████╗ ███╗   ███╗
██╔════╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
███████╗   ██║   █████╗  ███████║██╔████╔██║
╚════██║   ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║
███████║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║
╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
"@ -ForegroundColor Cyan

    Write-Host "欢迎首次使用 Steam入库工具!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host "重要提示:" -ForegroundColor Red -NoNewline
    Write-Host " 使用前请务必阅读以下注意事项:" -ForegroundColor Yellow
    Write-Host "1. 本工具需要以管理员权限运行" -ForegroundColor Magenta
    Write-Host "2. 使用前请关闭Steam客户端和杀毒软件" -ForegroundColor Magenta
    Write-Host "3. 首次使用会自动下载必要组件" -ForegroundColor Magenta
    Write-Host "4. 详细使用教程请选择菜单选项8" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host "按任意键继续..." -ForegroundColor Cyan
    
    # 兼容性更好的按键等待方法
    try {
        # 方法1：尝试标准控制台读取
        [Console]::ReadKey($true) | Out-Null
    }
    catch {
        # 方法2：如果失败则使用备用方法
        Write-Host "`n(如果界面卡住，请直接按Enter键)" -ForegroundColor Yellow
        $null = Read-Host
    }
    
    Clear-Host
}

# 在脚本主逻辑开始处调用
if (Test-FirstRun) {
    Show-Welcome
    Set-NotFirstRun
}

# 检查更新的函数
function Check-Update {
    try {
        Write-Host "正在检查更新..." -ForegroundColor Cyan
        
        # 尝试从各个镜像获取最新版本
        $latestScriptContent = $null
        foreach ($mirror in $githubMirrors) {
            $mirrorUrl = $mirror + "https://github.com/huanggua666/ruku/blob/main/%E4%BE%BF%E6%8D%B7%E5%85%A5%E5%BA%93.ps1"
            try {
                $latestScriptContent = (Invoke-WebRequest -Uri $mirrorUrl -UseBasicParsing -ErrorAction Stop).Content
                break  # 如果成功获取内容，跳出循环
            }
            catch {
                Write-Host "镜像 $mirror 不可用: $_" -ForegroundColor Yellow
                continue
            }
        }

        if (-not $latestScriptContent) {
            Write-Host "无法从任何镜像获取最新版本" -ForegroundColor Red
            return $false
        }

        # 从脚本内容中提取版本号
        if ($latestScriptContent -match '\$currentVersion\s*=\s*"([\d\.]+)"') {
            $latestVersion = $matches[1]
            
            if ($latestVersion -gt $currentVersion) {
                Write-Host "发现新版本: $latestVersion (当前版本: $currentVersion)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "当前已是最新版本 ($currentVersion)" -ForegroundColor Cyan
                return $false
            }
        } else {
            Write-Host "无法从最新脚本中提取版本号" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "检查更新时出错: $_" -ForegroundColor Red
        return $false
    }
}

# 更新脚本的函数
function Update-Script {
    param (
        [string]$scriptPath
    )
    
    try {
        Write-Host "正在下载最新版本..." -ForegroundColor Cyan
        
        $tempFile = Join-Path $env:TEMP "steamruku_temp.ps1"
        $success = $false
        
        # 尝试从各个镜像下载
        foreach ($mirror in $githubMirrors) {
            $mirrorUrl = $mirror + "https://github.com/huanggua666/ruku/blob/main/%E4%BE%BF%E6%8D%B7%E5%85%A5%E5%BA%93.ps1"
            try {
                # 使用-Encoding UTF8参数确保正确保存
                Invoke-WebRequest -Uri $mirrorUrl -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
                
                # 验证下载的文件
                if (Test-Path $tempFile -PathType Leaf) {
                    # 强制以UTF-8编码读取文件
                    $content = Get-Content $tempFile -Raw -Encoding UTF8
                    if ($content -match '\$currentVersion\s*=\s*"([\d\.]+)"') {
                        $success = $true
                        break
                    }
                }
            }
            catch {
                Write-Host "镜像 $mirror 下载失败: $_" -ForegroundColor Yellow
                continue
            }
        }

        if (-not $success) {
            Write-Host "无法从任何镜像下载最新版本" -ForegroundColor Red
            return $false
        }

        # 不再创建备份文件
        # 直接替换为最新版本，确保使用UTF-8编码
        $content = Get-Content $tempFile -Raw -Encoding UTF8
        $content | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
        
        Write-Host "脚本已成功更新到最新版本!" -ForegroundColor Green
        
        # 删除临时文件
        Remove-Item $tempFile -Force
        
        return $true
    }
    catch {
        Write-Host "更新脚本时出错: $_" -ForegroundColor Red
        return $false
    }
}

# 在显示主菜单前检查更新
$scriptPath = $MyInvocation.MyCommand.Path
if (Check-Update) {
    $updateChoice = Read-Host "发现新版本，是否立即更新？(y/n)"
    if ($updateChoice -eq 'y' -or $updateChoice -eq 'Y') {
        if (Update-Script -scriptPath $scriptPath) {
            Write-Host "更新完成，请重新运行脚本" -ForegroundColor Green
            Start-Sleep 3
            exit
        }
    }
}

# 保存配置函数
function Save-Config {
    param (
        [string]$steamPath
    )
    
    $config = @"
SteamPath=$steamPath
"@
    
    $config | Out-File -FilePath $configFile -Force -Encoding UTF8
    Write-Host "Steam路径已保存到配置文件: $configFile"
}

# 加载配置函数
function Load-Config {
    if (Test-Path $configFile) {
        try {
            $content = Get-Content $configFile -Raw
            # 确保配置文件格式正确
            if ($content -match "SteamPath=(.*)") {
                $steamPath = $matches[1].Trim()
                if (Test-Path $steamPath) {
                    return $steamPath
                }
            }
        }
        catch {
            Write-Host "配置文件格式错误，将重新创建" -ForegroundColor Yellow
        }
    }
    return $null
}

# 快速检测 Steam 路径
function Find-SteamPath {
    $possiblePaths = @(
        "C:\Program Files (x86)\Steam",
        "C:\Program Files\Steam",
        "$env:ProgramFiles\Steam",
        "$env:ProgramFiles(x86)\Steam",
        "$env:LOCALAPPDATA\Steam",
        "D:\Steam", "E:\Steam", "F:\Steam"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $steamExe = Join-Path $path "steam.exe"
            if (Test-Path $steamExe) {
                return $path
            }
        }
    }

    try {
        $regPath = "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam"
        if (Test-Path $regPath) {
            $installPath = (Get-ItemProperty -Path $regPath -Name "InstallPath").InstallPath
            if ($installPath -and (Test-Path $installPath)) {
                return $installPath
            }
        }
    }
    catch {
        Write-Host "无法从注册表读取 Steam 路径: $_" -ForegroundColor Yellow
    }

    return $null
}

# 尝试从配置文件或自动检测获取 Steam 路径
$steamPath = Load-Config

if (-not $steamPath) {
    Write-Host "正在自动检测 Steam 路径..." -ForegroundColor Cyan
    $steamPath = Find-SteamPath

    if (-not $steamPath) {
        Write-Host "未找到 Steam 路径，请手动设置！" -ForegroundColor Red
        do {
            $steamPath = Read-Host "请输入 Steam 安装路径（例如：C:\Program Files (x86)\Steam）"
            if (-not (Test-Path $steamPath)) {
                Write-Host "路径无效，请重新输入！" -ForegroundColor Red
            }
        } while (-not (Test-Path $steamPath))
    }

    Save-Config -steamPath $steamPath
}

# 设置子目录路径
$luaDestination = Join-Path $steamPath "config\stplug-in"
$manifestDestination = Join-Path $steamPath "config\depotcache"

# 创建必要的目录
if (-not (Test-Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
}
if (-not (Test-Path $luaDestination)) {
    New-Item -ItemType Directory -Path $luaDestination -Force | Out-Null
}
if (-not (Test-Path $manifestDestination)) {
    New-Item -ItemType Directory -Path $manifestDestination -Force | Out-Null
}

function Download-File {
    param (
        [string]$url,
        [string]$outputFile,
        [int]$retryCount = 3,
        [int]$timeoutSec = 30
    )

    # 强制使用 TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $success = $false
    $attempt = 0
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

    # 确保输出目录存在
    $outputDir = Split-Path $outputFile -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    do {
        $attempt++
        try {
            Write-Host "正在尝试下载 (第 $attempt 次尝试)..." -ForegroundColor Cyan
            Write-Host "URL: $url"
            Write-Host "保存到: $outputFile"

            # 方法1：使用WebClient
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", $userAgent)
            $webClient.DownloadFile($url, $outputFile)
            
            # 验证下载的文件
            if (Test-Path $outputFile) {
                $fileSize = (Get-Item $outputFile).Length
                Write-Host "下载成功！文件大小: $([math]::Round($fileSize/1KB,2)) KB" -ForegroundColor Green
                $success = $true
            } else {
                throw "文件未正确保存"
            }
        }
        catch {
            Write-Host "下载失败 (尝试 $attempt): $($_.Exception.Message)" -ForegroundColor Red
            if (Test-Path $outputFile) { Remove-Item $outputFile -Force }
            
            # 最后一次尝试前增加等待时间
            if ($attempt -lt $retryCount) {
                Start-Sleep -Seconds 2
            }
        }
    } while (-not $success -and $attempt -lt $retryCount)

    return $success
}


function Initialize-HidDll {
    $hidDllPath = Join-Path $steamPath "hid.dll"
    $correctSize = 591272  # 正确的文件大小（字节）

    # 检查文件是否存在且大小正确
    if (Test-Path $hidDllPath) {
        $currentSize = (Get-Item $hidDllPath).Length
        if ($currentSize -eq $correctSize) {
            Write-Host "hid.dll 已存在且大小正确（$currentSize 字节），跳过下载" -ForegroundColor Green
            return $true
        } else {
            Write-Host "检测到异常 hid.dll（当前大小: $currentSize 字节，应有: $correctSize 字节）" -ForegroundColor Red
            Remove-Item $hidDllPath -Force
            Write-Host "已删除无效文件，将重新下载..." -ForegroundColor Yellow
        }
    }

    # 使用可靠的下载源（直接GitHub原始链接）
    $url = "https://gh.catmak.name/https://github.com/huanggua666/ruku/blob/main/hid.dll"
    
    Write-Host "正在从 GitHub 下载 hid.dll..." -ForegroundColor Cyan
    
    if (Download-File -url $url -outputFile $hidDllPath) {
        # 最终验证
        if ((Test-Path $hidDllPath) -and ((Get-Item $hidDllPath).Length -eq $correctSize)) {
            Write-Host "hid.dll 下载验证通过！" -ForegroundColor Green
            return $true
        } else {
            Write-Host "下载的文件大小不正确" -ForegroundColor Red
            Remove-Item $hidDllPath -Force
        }
    }

    # 所有方法都失败
    Write-Host "`n无法自动下载 hid.dll，请手动操作：" -ForegroundColor Red
    Write-Host "1. 从这里下载: https://cdn.jsdelivr.net/gh/huanggua666/ruku/hid.dll"
    Write-Host "2. 复制到: $steamPath"
    Write-Host "3. 按任意键继续..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $false
}


# 确保BITS服务已启动
try {
    Start-Service -Name BITS -ErrorAction SilentlyContinue
}
catch {
    Write-Host "无法启动BITS服务，将使用备用下载方法" -ForegroundColor Yellow
}

# 保存配置函数
function Save-Config {
    param (
        [string]$steamPath
    )
    
    $config = @"
SteamPath=$steamPath
"@
    
    $config | Out-File -FilePath $configFile -Force
    Write-Host "Steam路径已保存到配置文件: $configFile"
}

# 获取游戏DLC列表的函数
function Get-DlcList {
    param (
        [string]$appId
    )
    
    try {
        $url = "https://store.steampowered.com/api/appdetails?appids=$appId"
        $response = Invoke-RestMethod -Uri $url -Method Get
        
        # 检查响应是否成功
        if ($response.$appId.success -eq $true) {
            $dlcList = $response.$appId.data.dlc
            if ($dlcList -and $dlcList.Count -gt 0) {
                return $dlcList
            } else {
                Write-Host "该游戏没有DLC或DLC列表不可用"
                return $null
            }
        } else {
            Write-Host "无法获取游戏信息，请检查游戏ID是否正确"
            return $null
        }
    }
    catch {
        Write-Host "获取DLC列表时出错: $_"
        return $null
    }
}

# 添加DLC到lua文件的函数
function Add-DlcToLua {
    param (
        [string]$appId,
        [array]$dlcList
    )
    
    $luaFile = Join-Path $luaDestination "$appId.lua"
    
    # 如果文件不存在，创建新文件
    if (-not (Test-Path $luaFile)) {
        $content = @"
-- 自动生成的DLC入库配置
-- 游戏ID: $appId
-- 生成时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
        $content | Out-File -FilePath $luaFile -Encoding UTF8
    }
    
    # 读取现有内容
    $existingContent = Get-Content $luaFile -Raw
    
    # 添加DLC条目
    foreach ($dlcId in $dlcList) {
        $dlcEntry = "addappid($dlcId, 1)`r`n"  # 这里添加了回车换行
        if (-not $existingContent.Contains("addappid($dlcId, 1)")) {
            Add-Content -Path $luaFile -Value $dlcEntry -Encoding UTF8
            Write-Host "已添加DLC: $dlcId"
        } else {
            Write-Host "DLC $dlcId 已存在，跳过添加"
        }
    }
    
    # 确保文件末尾有空行
    $finalContent = Get-Content $luaFile -Raw
    if (-not $finalContent.EndsWith("`r`n")) {
        Add-Content -Path $luaFile -Value "" -Encoding UTF8
    }
    
    Write-Host "DLC配置已更新到文件: $luaFile"
}



# 在显示菜单前调用初始化函数
Initialize-HidDll

# 显示菜单
function Show-Menu {
    Clear-Host
    Write-Host -NoNewline "                                                                                                                               `r"
    Write-Host -NoNewline "                                                        %@@@@@@@@@@@@                                                          `r"
    Write-Host -NoNewline "                                                   @@@@@@@@@@@@@@@@@@@@@@@@@@                                                     `r"
    Write-Host -NoNewline "                                                %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                  `r"
    Write-Host -NoNewline "                                              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                               `r"
    Write-Host -NoNewline "                                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                                             `r"
    Write-Host -NoNewline "                                          %@@@@@@@@@@@@@@@@@@@@@@@@:        %@@@@@@                                            `r"
    Write-Host -NoNewline "                                         @@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@  @@@@@                                           `r"
    Write-Host -NoNewline "                                        @@@@@@@@@@@@@@@@@@@@@@@     @        @  :@@@@                                         `r"
    Write-Host -NoNewline "                                       @@@@@@@@@@@@@@@@@@@@@@@     @         :@   @@@@                                        `r"
    Write-Host -NoNewline "                                      @@@@@@@@@@@@@@@@@@@@@@@     @           -@   @@@@@                                        `r"
    Write-Host -NoNewline "                                    @@@@@@@@@@@@@@@@@@@@@@@@     @             @   @@@@@@                                      `r"
    Write-Host -NoNewline "                                    @@@@@@@@@@@@@@@@@@@@@@        @           @    @@@@@@@                                     `r"
    Write-Host -NoNewline "                                    *@@@@@@@@@@@@@@@@@@@@.         @         @    @@@@@@@@                                     `r"
    Write-Host -NoNewline "                                        *@@@@@@@@@@@@@@@            @@@@@@@@@    @@@@@@@@@                                     `r"
    Write-Host -NoNewline "                                            +@@@@@@@@@@                         @@@@@@@@@@                                     `r"
    Write-Host -NoNewline "                                                +@@                           @@@@@@@@@@@@                                     `r"
    Write-Host -NoNewline "                                                     @@@@@                 @@@@@@@@@@@@@@@                                     `r"
    Write-Host -NoNewline "                                                          @           @@@@@@@@@@@@@@@@@@@                                      `r"
    Write-Host -NoNewline "                                      @@@                  @   @@@@@@@@@@@@@@@@@@@@@@@%                                       `r"
    Write-Host -NoNewline "                                       @@@@@@    @        @   -@@@@@@@@@@@@@@@@@@@@@@@@                                        `r"
    Write-Host -NoNewline "                                       .@@@@@@    @      @    @@@@@@@@@@@@@@@@@@@@@@@@                                         `r"
    Write-Host -NoNewline "                                         @@@@@@-   @@@@@@    @@@@@@@@@@@@@@@@@@@@@@@%                                          `r"
    Write-Host -NoNewline "                                          @@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@                                            `r"
    Write-Host -NoNewline "                                            @@@@@@@@:    @@@@@@@@@@@@@@@@@@@@@@@@@                                             `r"
    Write-Host -NoNewline "                                             *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                               `r"
    Write-Host -NoNewline "                                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                  `r"
    Write-Host -NoNewline "                                                   @@@@@@@@@@@@@@@@@@@@@@@%                                                    `r"
    Write-Host -NoNewline "                                                       @@@@@@@@@@@@@@@+                                                        `r"
    Write-Host -NoNewline "          _____                _____                    _____                    _____                    _____          `r"
    Write-Host -NoNewline "         /\    \              /\    \                  /\    \                  /\    \                  /\    \         `r"
    Write-Host -NoNewline "        /::\    \            /::\    \                /::\    \                /::\    \                /::\____\        `r"
    Write-Host -NoNewline "       /::::\    \           \:::\    \              /::::\    \              /::::\    \              /::::|   |        `r"
    Write-Host -NoNewline "      /::::::\    \           \:::\    \            /::::::\    \            /::::::\    \            /:::::|   |        `r"
    Write-Host -NoNewline "     /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/\:::\    \          /::::::|   |        `r"
    Write-Host -NoNewline "    /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \        /:::/|::|   |        `r"
    Write-Host -NoNewline "    \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \      /:::/ |::|   |        `r"
    Write-Host -NoNewline "  ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/  |::|___|______  `r"
    Write-Host -NoNewline " /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/   |::::::::\    \ `r"
    Write-Host -NoNewline "/::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/  \:::\   \:::\____\/:::/    |:::::::::\____\`r"
    Write-Host -NoNewline "\:::\   \:::\   \::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /\::/    / ~~~~~/:::/    /`r"
    Write-Host -NoNewline " \:::\   \:::\   \/____/   /:::/    / \/____/  \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /  \/____/      /:::/    / `r"
    Write-Host -NoNewline "  \:::\   \:::\    \      /:::/    /            \:::\   \:::\    \               \::::::/    /               /:::/    /  `r"
    Write-Host -NoNewline "   \:::\   \:::\____\    /:::/    /              \:::\   \:::\____\               \::::/    /               /:::/    /   `r"
    Write-Host -NoNewline "    \:::\  /:::/    /    \::/    /                \:::\   \::/    /               /:::/    /               /:::/    /    `r"
    Write-Host -NoNewline "     \:::\/:::/    /      \/____/                  \:::\   \/____/               /:::/    /               /:::/    /     `r"
    Write-Host -NoNewline "      \::::::/    /                                 \:::\    \                  /:::/    /               /:::/    /      `r"
    Write-Host -NoNewline "       \::::/    /                                   \:::\____\                /:::/    /               /:::/    /       `r"
    Write-Host -NoNewline "        \::/    /                                     \::/    /                \::/    /                \::/    /        `r"
    Write-Host -NoNewline "         \/____/                                       \/____/                  \/____/                  \/____/         `r"
    Write-Host
    Write-Host
    Write-Host
    Write-Host "==================== Steam 工具 ===================="
    Write-Host "==================== 作者BY黄瓜 ===================="
    Write-Host "当前Steam路径: $steamPath"
    Write-Host "当前Tools版本:$currentVersion"
    Write-Host
    Write-Host
    Write-Host
    
    # 饭要一口一口吃
    Write-Host @"
    ( ( ( 
     ) ) )
   ........
  | 饭要 |__
  | 一口 |  |
  | 一口 |  |
  | 吃   |__|
   \______/
"@
    Write-Host
    Write-Host
    Write-Host

    # 路要一步一步走
    Write-Host @"
       /\
      /  \
     /____\
       ||    路要
       ||    一步
       ||    一步
       ||    走
      /||\
     / || \
    /__||__\
"@

    Write-Host
    Write-Host
    Write-Host
    # 屎山代码要一点一点拉
    Write-Host @"
     _____
   .'     '.
  /  O   O  \
 |     ∆     |  屎山代码
  \  '---'  /  要一点
   '._____.'   一点拉
     |  |
     |  |
    _|  |_
   '======'
"@
    Write-Host
    Write-Host
    Write-Host
    Write-Host "1: 打开 Steam 游戏库(复制appid)"
    Write-Host "2: 输入 ID 下载并处理文件"
    Write-Host "3: 自动添加游戏DLC到入库文件"
    Write-Host "4: 删除入库游戏"
    Write-Host "5: 设置 Steam 路径 (当前: $steamPath)"
    Write-Host "6: 检查更新"
    Write-Host "7: 重启Steam"
    Write-Host "8: 使用教程"
    Write-Host "Q: 退出"
    Write-Host "===================================================="
}

do {
    Show-Menu
    $selection = Read-Host "请选择操作"
    
    switch ($selection) {
        '1' {
            # 打开Steam游戏库
            Start-Process "https://www.steamui.com/"
        }

        '2' {
            # 获取用户输入的多个ID（空格分隔）
            $inputIds = Read-Host "请输入ID（可批量，用空格分隔）"
            
            # 分割输入为数组
            $idList = $inputIds -split '\s+' | Where-Object { $_ -match '^\d+$' }
            
            if ($idList.Count -eq 0) {
                Write-Host "未输入有效ID！"
                Pause
                continue
            }

            # 使用foreach循环处理每个ID
            foreach ($id in $idList) {
                Write-Host "`n正在处理ID: $id"
                
                # 构建下载URL
                $url = "https://gh.catmak.name/https://github.com/SteamAutoCracks/ManifestHub/archive/refs/heads/$id"
                $zipFile = Join-Path $downloadPath "$id"
                
                if (-not (Download-File -url $url -outputFile $zipFile -isGithubUrl)) {
                    Write-Host "所有镜像下载失败，请检查网络连接或稍后再试"
                    continue
                }
                
                try {
                    Write-Host "下载完成，正在解压..."
                    
                    # 解压文件
                    Expand-Archive -Path $zipFile -DestinationPath $downloadPath -Force
                    
                    # 删除zip文件
                    Remove-Item $zipFile -Force
                    
                    # 查找解压后的文件夹
                    $extractedFolder = Get-ChildItem -Path $downloadPath -Directory | 
                        Where-Object { $_.Name -like "ManifestHub-*" } | 
                        Select-Object -First 1
                    
                    if ($extractedFolder) {
                        # 移动.lua文件
                        Get-ChildItem -Path $extractedFolder.FullName -Filter "*.lua" -Recurse | 
                            ForEach-Object {
                                Move-Item -Path $_.FullName -Destination $luaDestination -Force
                                Write-Host "已移动 $($_.Name) 到 $luaDestination"
                            }
                        
                        # 移动.manifest文件
                        Get-ChildItem -Path $extractedFolder.FullName -Filter "*.manifest" -Recurse | 
                            ForEach-Object {
                                Move-Item -Path $_.FullName -Destination $manifestDestination -Force
                                Write-Host "已移动 $($_.Name) 到 $manifestDestination"
                            }
                        
                        # 删除解压的文件夹
                        Remove-Item $extractedFolder.FullName -Recurse -Force
                        Write-Host "ID $id 处理完成！"
                    } else {
                        Write-Host "未找到解压后的文件夹"
                    }
                }
                catch {
                    Write-Host "处理ID $id 时出错: $_"
                }
            }
            
            # 所有ID处理完成后询问是否重启Steam
            $restartChoice = Read-Host "`n所有ID处理完成，是否要重启Steam以应用更改？(y/n)"
            if ($restartChoice -eq 'y' -or $restartChoice -eq 'Y') {
                try {
                    # 结束Steam进程
                    Get-Process -Name "steam" -ErrorAction SilentlyContinue | Stop-Process -Force
                    Write-Host "已关闭Steam进程..."
                    
                    # 等待一段时间确保进程完全关闭
                    Start-Sleep -Seconds 3
                    
                    # 重新启动Steam
                    $steamExe = Join-Path $steamPath "steam.exe"
                    if (Test-Path $steamExe) {
                        Start-Process -FilePath $steamExe
                        Write-Host "Steam已重新启动"
                    } else {
                        Write-Host "未找到Steam.exe，请检查路径是否正确"
                    }
                }
                catch {
                    Write-Host "重启Steam时出错: $_"
                }
            } else {
                Write-Host "未重启Steam，请记得手动重启以使更改生效"
            }
            
            Pause
        }
        
        '3' {
            # 自动添加游戏DLC到入库文件（先执行功能2再执行功能3）
            $appId = Read-Host "请输入游戏ID(挂梯子)"
            
            if (-not ($appId -match '^\d+$')) {
                Write-Host "无效的游戏ID，请输入数字"
                Pause
                continue
            }
            
            # 先执行功能2的操作（下载并处理文件）
            Write-Host "`n下载并处理文件..."
            $url = "https://gh.catmak.name/https://github.com/SteamAutoCracks/ManifestHub/archive/refs/heads/$appId"
            $zipFile = Join-Path $downloadPath "$appId"
            
            if (-not (Download-File -url $url -outputFile $zipFile -isGithubUrl)) {
                Write-Host "所有镜像下载失败，请检查网络连接或稍后再试"
                continue
            }
            
            try {
                Write-Host "下载完成，正在解压..."
                
                # 解压文件
                Expand-Archive -Path $zipFile -DestinationPath $downloadPath -Force
                
                # 删除zip文件
                Remove-Item $zipFile -Force
                
                # 查找解压后的文件夹
                $extractedFolder = Get-ChildItem -Path $downloadPath -Directory | 
                    Where-Object { $_.Name -like "ManifestHub-*" } | 
                    Select-Object -First 1
                
                if ($extractedFolder) {
                    # 移动.lua文件
                    Get-ChildItem -Path $extractedFolder.FullName -Filter "*.lua" -Recurse | 
                        ForEach-Object {
                            Move-Item -Path $_.FullName -Destination $luaDestination -Force
                            Write-Host "已移动 $($_.Name) 到 $luaDestination"
                        }
                    
                    # 移动.manifest文件
                    Get-ChildItem -Path $extractedFolder.FullName -Filter "*.manifest" -Recurse | 
                        ForEach-Object {
                            Move-Item -Path $_.FullName -Destination $manifestDestination -Force
                            Write-Host "已移动 $($_.Name) 到 $manifestDestination"
                        }
                    
                    # 删除解压的文件夹
                    Remove-Item $extractedFolder.FullName -Recurse -Force
                    Write-Host "ID $appId 文件处理完成！"
                } else {
                    Write-Host "未找到解压后的文件夹"
                }
            }
            catch {
                Write-Host "处理ID $appId 时出错: $_"
            }
            
            # 然后执行功能3的操作（获取并添加DLC）
            Write-Host "`n获取并添加DLC..."
            $dlcList = Get-DlcList -appId $appId
            
            if ($dlcList -and $dlcList.Count -gt 0) {
                Write-Host "找到以下DLC: $($dlcList -join ', ')"
                
                # 添加到lua文件
                Add-DlcToLua -appId $appId -dlcList $dlcList
                
                # 询问是否重启Steam
                $restartChoice = Read-Host "`n所有操作完成，是否要重启Steam以应用更改？(y/n)"
                if ($restartChoice -eq 'y' -or $restartChoice -eq 'Y') {
                    try {
                        # 结束Steam进程
                        Get-Process -Name "steam" -ErrorAction SilentlyContinue | Stop-Process -Force
                        Write-Host "已关闭Steam进程..."
                        
                        # 等待一段时间确保进程完全关闭
                        Start-Sleep -Seconds 3
                        
                        # 重新启动Steam
                        $steamExe = Join-Path $steamPath "steam.exe"
                        if (Test-Path $steamExe) {
                            Start-Process -FilePath $steamExe
                            Write-Host "Steam已重新启动"
                        } else {
                            Write-Host "未找到Steam.exe，请检查路径是否正确"
                        }
                    }
                    catch {
                        Write-Host "重启Steam时出错: $_"
                    }
                } else {
                    Write-Host "未重启Steam，请记得手动重启以使更改生效"
                }
            } else {
                Write-Host "未找到DLC或DLC列表不可用，仅完成了文件下载和处理"
            }
            
            Pause
        }

'4' {
    # 批量删除入库游戏功能
    $luaFiles = Get-ChildItem -Path $luaDestination -Filter "*.lua" -File

    if ($luaFiles.Count -eq 0) {
        Write-Host "没有找到任何入库游戏配置"
        Pause
        continue
    }

    # 询问用户是否要挂梯子获取游戏名称
    $fetchNames = $false
    $choice = Read-Host "`n是否要获取游戏名称(部分网络要挂梯)？(y/n, 默认n)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        $fetchNames = $true
    }

    # 存储游戏ID和名称的映射
    $gameInfo = @{}

    if ($fetchNames) {
        Write-Host "`n正在从Steam API获取游戏名称，请稍候...(游戏越多时间越长)" -ForegroundColor Cyan
        Write-Host "总共有 $($luaFiles.Count) 个游戏需要获取名称" -ForegroundColor Cyan

        # 设置超时时间为5秒
        $timeout = 5
        $startTime = Get-Date
        $processedCount = 0
        $totalCount = $luaFiles.Count

        foreach ($file in $luaFiles) {
            $processedCount++
            $appId = $file.BaseName
            
            # 检查是否超时
            if (((Get-Date) - $startTime).TotalSeconds -gt $timeout) {
                # 显示进度
                Write-Host "`n已获取 $($processedCount - 1)/$totalCount 个游戏名称" -ForegroundColor Yellow
                Write-Host "当前获取速度: ~$([math]::Round(($processedCount - 1)/((Get-Date) - $startTime).TotalSeconds,1)) 个/秒" -ForegroundColor Yellow
                
                # 询问是否继续
                $continue = Read-Host "获取名称耗时较长，预计还需要 ~$([math]::Round(($totalCount - $processedCount + 1)/(($processedCount - 1)/((Get-Date) - $startTime).TotalSeconds),1)) 秒。是否继续获取？(y=继续/n=停止获取名称, 默认y)"
                if ($continue -eq 'n' -or $continue -eq 'N') {
                    # 用户选择不继续，回退到只显示ID
                    $gameInfo = @{}
                    foreach ($f in $luaFiles) {
                        $appId = $f.BaseName
                        $gameInfo[$appId] = "ID: $appId"
                    }
                    Write-Host "已停止获取名称，将只显示游戏ID" -ForegroundColor Yellow
                    break
                }
                $startTime = Get-Date  # 重置计时器
            }
            
            try {
                # 从Steam API获取游戏信息
                $url = "https://store.steampowered.com/api/appdetails?appids=$appId"
                $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $timeout -ErrorAction Stop
                
                if ($response.$appId.success -eq $true) {
                    $gameName = $response.$appId.data.name
                    $gameInfo[$appId] = "$gameName (ID: $appId)"
                    Write-Progress -Activity "获取游戏名称" -Status "$gameName (ID: $appId)" -PercentComplete ($processedCount/$totalCount*100)
                } else {
                    $gameInfo[$appId] = "未知游戏 (ID: $appId)"
                }
            }
            catch {
                $gameInfo[$appId] = "获取失败 (ID: $appId)"
                # 显示进度
                Write-Host "`n已获取 $processedCount/$totalCount 个游戏名称" -ForegroundColor Yellow
                Write-Host "当前获取速度: ~$([math]::Round($processedCount/((Get-Date) - $startTime).TotalSeconds,1)) 个/秒" -ForegroundColor Yellow
                
                # 询问是否继续
                $continue = Read-Host "获取游戏名称时出错(你没挂梯子)，是否继续？(y继续/n停止获取名称, 默认y)"
                if ($continue -eq 'n' -or $continue -eq 'N') {
                    # 用户选择不继续，回退到只显示ID
                    $gameInfo = @{}
                    foreach ($f in $luaFiles) {
                        $appId = $f.BaseName
                        $gameInfo[$appId] = "ID: $appId"
                    }
                    Write-Host "已停止获取名称，将只显示游戏ID" -ForegroundColor Yellow
                    break
                }
            }
        }
        Write-Progress -Activity "获取游戏名称" -Completed
    } else {
        # 不挂梯子，只显示ID
        foreach ($file in $luaFiles) {
            $appId = $file.BaseName
            $gameInfo[$appId] = "ID: $appId"
        }
    }

    # 显示游戏列表
    Write-Host "`n当前已入库的游戏列表:"
    $index = 1
    foreach ($file in $luaFiles) {
        $appId = $file.BaseName
        Write-Host "$($index): $($gameInfo[$appId])"
        $index++
    }

    $choice = Read-Host "`n请输入要删除的游戏编号 (用空格分隔多个编号，输入0返回)"

    if ($choice -eq "0") {
        continue
    }

    # 分割输入为数组并去除空值
    $choices = $choice -split '\s+' | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $luaFiles.Count }

    if ($choices.Count -eq 0) {
        Write-Host "没有输入有效的编号"
        Pause
        continue
    }

    # 显示将要删除的游戏
    Write-Host "`n将要删除以下游戏:"
    $choices | ForEach-Object {
        $index = [int]$_ - 1
        $appId = $luaFiles[$index].BaseName
        Write-Host "- $($gameInfo[$appId])"
    }

    $confirm = Read-Host "`n确定要删除以上 $($choices.Count) 个游戏的入库配置吗？(y/n)"

    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        $successCount = 0
        $choices | ForEach-Object {
            $index = [int]$_ - 1
            $selectedFile = $luaFiles[$index]
            $appId = $selectedFile.BaseName
            
            try {
                # 删除lua文件
                Remove-Item -Path $selectedFile.FullName -Force -ErrorAction Stop
                
                # 尝试删除对应的manifest文件
                $manifestFile = Join-Path $manifestDestination "$appId.manifest"
                if (Test-Path $manifestFile) {
                    Remove-Item -Path $manifestFile -Force -ErrorAction SilentlyContinue
                }
                
                Write-Host "已删除: $($gameInfo[$appId])"
                $successCount++
            }
            catch {
                Write-Host "删除 $($gameInfo[$appId]) 时出错: $_" -ForegroundColor Red
            }
        }
        
        Write-Host "`n成功删除了 $successCount/$($choices.Count) 个游戏"
        
        # 询问是否重启Steam
        if ($successCount -gt 0) {
            $restartChoice = Read-Host "是否要重启Steam以应用更改？(y/n)"
            if ($restartChoice -eq 'y' -or $restartChoice -eq 'Y') {
                try {
                    # 结束Steam进程
                    Get-Process -Name "steam" -ErrorAction SilentlyContinue | Stop-Process -Force
                    Write-Host "已关闭Steam进程..."
                    
                    # 等待一段时间确保进程完全关闭
                    Start-Sleep -Seconds 3
                    
                    # 重新启动Steam
                    $steamExe = Join-Path $steamPath "steam.exe"
                    if (Test-Path $steamExe) {
                        Start-Process -FilePath $steamExe
                        Write-Host "Steam已重新启动"
                    } else {
                        Write-Host "未找到Steam.exe，请检查路径是否正确"
                    }
                }
                catch {
                    Write-Host "重启Steam时出错: $_"
                }
            }
        }
    }

    Pause
}
        
        '5' {
            # 设置Steam路径
            Write-Host "当前Steam路径: $steamPath"
            $newPath = Read-Host "请输入新的Steam路径 (留空保持当前路径)"
            
            if (-not [string]::IsNullOrWhiteSpace($newPath)) {
                if (Test-Path $newPath) {
                    $steamPath = $newPath
                    $luaDestination = Join-Path $steamPath "config\stplug-in"
                    $manifestDestination = Join-Path $steamPath "config\depotcache"
                    
                    # 创建必要的目录
                    if (-not (Test-Path $luaDestination)) {
                        New-Item -ItemType Directory -Path $luaDestination -Force | Out-Null
                    }
                    if (-not (Test-Path $manifestDestination)) {
                        New-Item -ItemType Directory -Path $manifestDestination -Force | Out-Null
                    }
                    
                    # 保存配置
                    Save-Config -steamPath $steamPath
                    Write-Host "Steam路径已更新为: $steamPath"
                } else {
                    Write-Host "指定的路径不存在，请检查路径是否正确"
                }
            }
            
            Pause
        }

        '6' {
        # 手动检查更新
        if (Check-Update) {
            $updateChoice = Read-Host "发现新版本，是否立即更新？(y/n)"
            if ($updateChoice -eq 'y' -or $updateChoice -eq 'Y') {
                if (Update-Script -scriptPath $scriptPath) {
                    Write-Host "更新完成，请重新运行脚本" -ForegroundColor Green
                    Start-Sleep 3
                    exit
                }
            }
        }
        Pause
    }

    '7' {
    # 手动重启Steam功能
    Write-Host "`n正在尝试重启Steam..."
    
    try {
        # 结束Steam进程
        $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
        if ($steamProcess) {
            $steamProcess | Stop-Process -Force
            Write-Host "已关闭Steam进程..."
            
            # 等待一段时间确保进程完全关闭
            Start-Sleep -Seconds 3
        } else {
            Write-Host "未找到正在运行的Steam进程" -ForegroundColor Yellow
        }
        
        # 重新启动Steam
        $steamExe = Join-Path $steamPath "steam.exe"
        if (Test-Path $steamExe) {
            Start-Process -FilePath $steamExe
            Write-Host "Steam已重新启动" -ForegroundColor Green
        } else {
            Write-Host "未找到Steam.exe，请检查路径是否正确" -ForegroundColor Red
            Write-Host "当前Steam路径: $steamPath"
        }
    }
    catch {
        Write-Host "重启Steam时出错: $_" -ForegroundColor Red
    }
    
    Pause
}

'8' {
    # 使用教程功能
    Clear-Host
    Write-Host @"
==================== Steam入库工具使用教程 ====================

1. 基本准备：
   - 确保Steam客户端已安装并关闭
   - 工具会自动检测Steam路径，若检测失败需手动设置(选项4)
   - 首次使用会自动下载必要的hid.dll文件

2. 核心功能说明：

   [选项1] 打开Steam游戏库
   - 访问steamui.com查询游戏
   - 在游戏商店页面中找到游戏封面右上角的数字ID点击复制

   [选项2] 单个/批量入库游戏
   - 输入游戏ID(可多个，空格分隔)
   - 示例: 输入"123456 789012"可同时入库两个游戏
   - 完成后重启Steam生效(选项7)

   [选项3] 自动添加DLC
   - 先确保主游戏已入库(通过选项2)
   - 输入游戏ID自动获取所有DLC(部分网络可能需要梯子)

   [选项6] 删除已入库游戏
   - 显示所有已入库游戏列表
   - 输入编号(可多个，空格分隔)进行批量删除
   - 示例: 输入"1 3 5"删除第1、3、5个游戏

3. 常见问题：
   Q: 入库后游戏显示"需要购买"？
   A: 重启本工具并重启steam

   Q: 下载文件失败？
   A: 尝试以下方法：
      1. 检查网络连接
      2. 使用梯子(部分资源需要)
      3. github的国内镜像崩了,等本脚本更新

   Q: 游戏无法启动？
   A: D加密游戏或有盗版验证,或者你的系统不支持该游戏

4. 文件结构说明：
   - Steam目录
     ├─config
     │  ├─stplug-in       # 存放.lua入库配置
     │  └─depotcache      # 存放.manifest清单文件
     └─hid.dll            # 核心验证文件(勿删)

5. 注意事项：
   - 使用前备份Steam账户重要数据
   - 部分游戏可能需要额外补丁
   - 频繁操作可能导致Steam客户端异常

6. 本脚本入库实现原理：
   - 将steamtools的入库原理导入到了本脚本，本脚本更多的只是提供清单文件
============================================================
"@
    Write-Host "按任意键返回主菜单..." -ForegroundColor Yellow
      # 兼容性更好的按键等待方法
    try {
        # 方法1：尝试标准控制台读取
        [Console]::ReadKey($true) | Out-Null
    }
    catch {
        # 方法2：如果失败则使用备用方法
        Write-Host "`n(如果界面卡住，请直接按Enter键)" -ForegroundColor Yellow
        $null = Read-Host
    }
}


        'Q' {
            return
        }
        default {
            Write-Host "无效的选择，请重新输入"
            Start-Sleep -Seconds 1
        }
    }
} while ($true)





