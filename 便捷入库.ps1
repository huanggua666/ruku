# 定义默认路径
$downloadPath = "C:\Users\Administrator\Downloads\steamruku"
$configFile = Join-Path $env:APPDATA "SteamToolConfig.ini"

# 尝试从配置文件加载Steam路径
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-StringData
    $steamPath = $config.SteamPath
    $luaDestination = Join-Path $steamPath "config\stplug-in"
    $manifestDestination = Join-Path $steamPath "config\depotcache"
} else {
    # 默认路径
    $steamPath = "C:\Program Files (x86)\Steam"
    $luaDestination = Join-Path $steamPath "config\stplug-in"
    $manifestDestination = Join-Path $steamPath "config\depotcache"
}

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

# 优化的下载函数
function Download-File {
    param (
        [string]$url,
        [string]$outputFile,
        [int]$retryCount = 3,
        [int]$timeoutSeconds = 30
    )
    
    $success = $false
    $attempt = 0
    
    do {
        $attempt++
        try {
            Write-Host "尝试下载 (尝试 $attempt/$retryCount)..."
            
            # 使用WebClient下载（比Invoke-WebRequest更快）
            $webClient = New-Object System.Net.WebClient
            $webClient.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
            $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
            
            # 设置超时（毫秒）
            $webClient.DownloadFile($url, $outputFile)
            
            $success = $true
            Write-Host "下载完成！"
        }
        catch {
            Write-Host "下载失败: $_"
            if ($attempt -lt $retryCount) {
                Start-Sleep -Seconds 2
            }
        }
        finally {
            if ($webClient -ne $null) {
                $webClient.Dispose()
            }
        }
    } while (-not $success -and $attempt -lt $retryCount)
    
    return $success
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

# 显示菜单
function Show-Menu {
    Clear-Host
Write-Host -NoNewline "                                                                                                                               `r"
Write-Host -NoNewline "                                                        %@@@@@@@@@@@@                                                          `r"
Write-Host -NoNewline "                                                   @@@@@@@@@@@@@@@@@@@@@@                                                     `r"
Write-Host -NoNewline "                                                %@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                  `r"
Write-Host -NoNewline "                                              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                               `r"
Write-Host -NoNewline "                                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                                             `r"
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
    Write-Host "4: 设置 Steam 路径 (当前: $steamPath)"
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
                $url = "https://tvv.tw//https://github.com/SteamAutoCracks/ManifestHub/archive/refs/heads/$id.zip"
                
                try {
                    # 下载文件
                    $zipFile = Join-Path $downloadPath "$id.zip"
                    
                    # 使用优化的下载函数
                    if (Download-File -url $url -outputFile $zipFile) {
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
                    } else {
                        Write-Host "ID $id 下载失败，请检查ID是否正确或网络连接是否正常或DLC不支持清单！"
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
    $url = "http://tvv.tw/https://github.com/SteamAutoCracks/ManifestHub/archive/refs/heads/$appId.zip"
    
    try {
        # 下载文件
        $zipFile = Join-Path $downloadPath "$appId.zip"
        
        # 使用优化的下载函数
        if (Download-File -url $url -outputFile $zipFile) {
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
        } else {
            Write-Host "ID $appId 下载失败，请检查ID是否正确或网络连接是否正常或DLC不支持清单！"
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

        'Q' {
            return
        }
        default {
            Write-Host "无效的选择，请重新输入"
            Start-Sleep -Seconds 1
        }
    }
} while ($true)