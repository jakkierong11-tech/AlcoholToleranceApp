param($p)
$K=$env:ARK_API_KEY
if(!$K){Write-Host "Error: Set ARK_API_KEY first";exit 1}

# 保存图片到 C:\OPENCLAW_FILE
$SAVE_DIR="C:\OPENCLAW_FILE"
if(!(Test-Path $SAVE_DIR)){New-Item -Type Directory $SAVE_DIR|Out-Null}

$H=@{"Content-Type"="application/json";"Authorization"="Bearer $K"}
$B=@{model="doubao-seedream-5-0-260128";prompt=$p;size="2K";output_format="png";watermark=$false}|ConvertTo-Json -Compress

Write-Host "Generating..." -ForegroundColor Cyan

$R=Invoke-RestMethod "https://ark.cn-beijing.volces.com/api/v3/images/generations" -Method Post -Headers $H -Body $B

if($R.data[0].url){
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$F="$SAVE_DIR\img_"+(Get-Date -Format "yyyyMMdd_HHmmss")+".png"
Invoke-WebRequest $R.data[0].url -OutFile $F -UseBasicParsing
Write-Host "============ SUCCESS ============" -ForegroundColor Green
Write-Host "Saved: $F"
Write-Host "Direct link: $($R.data[0].url)"
Write-Host "Size: $($R.data[0].size)"
Start-Process explorer.exe "/select,$F"
}else{
Write-Host "Failed"
Write-Host ($R|ConvertTo-Json)
}
