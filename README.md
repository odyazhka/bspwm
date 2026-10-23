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
sudo xbps-install -S terminus-font nerd-fonts-symbols-ttf bspwm polybar rofi feh dbus xlockmore maim xdotool xclip jq pulseaudio pavucontrol feh numlockx btop pavucontrol-qt
yay -S ttf-terminus-nerd
```

#### 2. Скачать дотфайлы из репозитория к себе в .config

```
git clone https://github.com/odyazhka/bspwm.git ~/bspwm
cp -r ~/bspwm/{bspwm,polybar,rofi,sxhkd} ~/.config/
sudo cp -r ~/bspwm/00-keyboard.conf /etc/X11/xorg.conf.d/
```

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


#### 5. Для безпарольного выключения, перезагрузки, гибернации и прочих действий редактируйте visudo:

``` sudo EDITOR=nano visudo ```

Он должен выглядеть примерно вот так:
<img width="653" height="126" alt="изображение" src="https://github.com/user-attachments/assets/54e24de2-e1cf-41bf-884c-f3de2bfa47d4" />
(вместо iwa ваше имя пользователя)

Сохраняем и выходим: контрл+o, контрл+x

#### 6. Поставить обои:

```
feh --bg-scale ~/oboi.png
```

#### 7. Панель интегрирована с odjk-wifi

Скачать можно тут:

https://github.com/odyazhka/odjk-wifi


Просто скачайте бинарники и положите его в /usr/local/bin/

### Сочетания клавиш:

##### Окна и фокус

super + Tab — список открытых окон (rofi), выбор переключает на окно.
super + o / super + i — переход к предыдущему / следующему окну по истории фокуса.
super + c — закрыть текущее окно штатно (bspc node -c).
super + k — принудительно убить текущее окно.
alt + F4 — принудительно убить текущее окно (то же, что super + k).
super + g — поменять текущее окно местами с самым большим окном.
super + y — переместить самое новое помеченное окно на предвыбранное место.
super + r — повернуть родительский контейнер на 90°.
super + z — переключить раскладку рабочего стола: мозаика / монокль (одно окно на весь экран).
alt + ЛКМ (зажать) — разделение окна. Зажмите Alt и ЛКМ на окне, а потом перетащите курсор на другое окно: скрипт alt.sh предпросматривает направление разделения (запад/восток/север/юг по форме и положению курсора) и ставит текущее окно рядом с целевым. Отпускание кнопки завершает операцию.

##### Скрытие и режимы просмотра

super + x — zen mode: скрыть все окна рабочего стола, кроме текущего. Повторное нажатие возвращает их.
super + d — скрыть все видимые окна рабочего стола. Повторное нажатие возвращает их.

##### Рабочие столы и мониторы

super + 1…9, 0 — перейти на рабочий стол 1–10.
alt + 1…9, 0 — отправить текущее окно на рабочий стол 1–10 (окно остаётся без переключения).
super + m — применить раскладку мониторов (monitors.sh): встроенный экран и внешние, после чего bspwm перезапускается.

##### Запуск программ и системные действия

super + Return — терминал xterm.
super + space — меню запуска приложений (rofi drun).
super + p — запуск/перезапуск панели polybar.
super + v — менеджер сервисов (odjk-sv).
super + n — менеджер сетей (odjk-ip).
super + l — блокировка экрана (xlock.sh).
ctrl + alt + Delete — меню питания (rofi-power).
super + Escape — перечитать конфиг sxhkd (pkill -USR1 sxhkd).
super + alt + q — выйти из bspwm.
super + alt + r — перезапустить bspwm.

##### Скриншоты и буфер обмена

F1 — выделить область мышью, скриншот в буфер обмена.
super + F1 — то же, но с задержкой 5 секунд.
shift + F1 — скриншот всего текущего монитора в буфер обмена.

##### Текст

ctrl + shift + v — вставка в терминале (отправляет средний клик мыши).
