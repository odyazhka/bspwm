### дотфайлы со скриптами для sbpwm, polybar и rofi

### Скриншоты

<img width="1920" height="1080" alt="изображение" src="https://github.com/user-attachments/assets/559257f9-747f-44c4-9cbf-483a8b783449" />


Оригинал обоев взят отсюда: https://ru.pinterest.com/pin/882353752013603311/

Слева пришотофоплен вывод fastfetch в xterm, шрифт Terminus 28. Прикляпляю .Xresources для терминала

<img width="1920" height="1080" alt="изображение" src="https://github.com/user-attachments/assets/197771a7-3167-4386-b32e-214954d04dc0" />

<img width="1920" height="1080" alt="изображение" src="https://github.com/user-attachments/assets/6ee94ff6-e473-4346-a3b3-08a4717dad8a" />

<img width="1920" height="1080" alt="изображение" src="https://github.com/user-attachments/assets/2b94fcee-1cdf-47b6-a1b0-781fa47269b1" />

<img width="1920" height="1080" alt="изображение" src="https://github.com/user-attachments/assets/f962014c-b44a-4fe6-bf4b-70235da47c70" />



### Установка

#### 1. Установить пакеты:

```
sudo xbps-install -S terminus-font nerd-fonts-symbols-ttf bspwm polybar rofi feh dbus xlockmore maim xdotool xclip jq pulseaudio pavucontrol feh numlockx
```

#### 2. Переместить дотфайлы из репозитория к себе в .config

#### 3. Сделать исполняемыми файлы

```
chmod -R 755 ~/.config/bspwm
chmod -R 755 ~/.config/polybar
chmod -R 755 ~/.config/rofi
chmod -R 755 ~/.config/sxhkd
```

#### 4. Установить приложение для смены яркости на встроенных мониторах (если надо):

Cкачать и запустить устаногвочный скрипт отсюда: https://github.com/odyazhka/bg

В visudo прописать /usr/local/bin/brightness для смены яркости без пароля

#### 5. Для смены рскладки должен существовать файл 00-keyboard.conf в /etc/X11/xorg.conf.d

Переместите его куда если ещё нет и сделайте исполняемым

``` sudo chmod 777 /etc/X11/xorg.conf.d/00-keyboard.conf ```

#### 6. Для безпарольного выключения, перезагрузки, гибернации и прочих действий редактируйте visudo:

``` sudo EDITOR=nano visudo ```

Он должен выглядеть примерно вот так:
<img width="653" height="126" alt="изображение" src="https://github.com/user-attachments/assets/54e24de2-e1cf-41bf-884c-f3de2bfa47d4" />
(вместо iwa ваше имя пользователя)

Сохраняем и выходим: контрл+o, контрл+x

#### 7. Поставить обои:

```
feh --bg-scale ~/oboi.png
```

#### 8. Панель интегрирована с odjk-wifi

Скачать можно тут:

https://github.com/odyazhka/odjk-wifi


Просто скачайте бинарники и положите его в /usr/local/bin/


