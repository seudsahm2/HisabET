# Tells Telegram where your bot's server is (the "setWebhook" step).
# Run once after deploying to Netlify:
#
#     powershell -ExecutionPolicy Bypass -File functions\scripts\connect-telegram.ps1
#
# It asks three questions, connects the bot, and checks that it worked.
# Nothing is saved to disk.

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "Connect your Telegram bot to your Netlify site" -ForegroundColor Cyan
Write-Host "-----------------------------------------------"

$token  = (Read-Host "1) Bot token from @BotFather (looks like 7123456789:AAH...)").Trim()
$secret = (Read-Host "2) TELEGRAM_WEBHOOK_SECRET - the exact value you put in Netlify").Trim()
$site   = (Read-Host "3) Your Netlify site address (e.g. hisabet-backend.netlify.app)").Trim()

# Accept "https://x.netlify.app/" or "x.netlify.app".
$site = $site -replace '^https?://', '' -replace '/.*$', ''
$url  = "https://$site/telegram-webhook"

Write-Host ""
Write-Host "Connecting the bot to $url ..."

try {
  $body = @{
    url                  = $url
    secret_token         = $secret
    allowed_updates      = @('message')
    drop_pending_updates = $true
  } | ConvertTo-Json
  $result = Invoke-RestMethod "https://api.telegram.org/bot$token/setWebhook" -Method Post -ContentType 'application/json' -Body $body
} catch {
  Write-Host "Telegram refused the request. Check the bot token and try again." -ForegroundColor Red
  exit 1
}

if (-not $result.ok) {
  Write-Host "Telegram said: $($result.description)" -ForegroundColor Red
  exit 1
}

Start-Sleep -Seconds 2
$info = (Invoke-RestMethod "https://api.telegram.org/bot$token/getWebhookInfo").result

Write-Host ""
if ($info.last_error_message) {
  Write-Host "Connected, but Telegram reports an error reaching your site:" -ForegroundColor Yellow
  Write-Host "  $($info.last_error_message)" -ForegroundColor Yellow
  Write-Host "  401 = the secret differs from Netlify's.  404 = wrong address or deploy not finished."
  Write-Host "  500 = check Netlify -> Logs -> Functions."
} else {
  Write-Host "Done. Telegram now sends your bot's messages to $url" -ForegroundColor Green
  Write-Host "Test it: open your bot in Telegram and send 'hello' - it should reply."
}
