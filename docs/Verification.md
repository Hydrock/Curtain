# Проверка — 8 ноября 2026

macOS 27.0.1, Apple Silicon, Swift 6.4; целевая система macOS 14+.

- `build.sh`: успешная сборка без предупреждений.
- `test.sh`: все пять наборов тестов прошли в графической сессии macOS.
- Физика: открытие обеих штор, передача деформации соседям, отпускание,
  затухание, изменение размера, экстремальные координаты захвата.
- AppKit: видимость демо без фокуса, порядок окон, свободный заголовок,
  hit testing ткани, свободная середина, следование за перемещением и размером,
  обработчики захвата/перетаскивания/отпускания и двойного щелчка, снятие штор.
- Подпись: `codesign --verify --deep --strict` проходит.
- Визуально: просмотрены приветствие, демо и отрисованные шторы.

Автоматизация UI не смогла надёжно доставить жест в прозрачную панель;
обработчики жестов проверены отдельно интеграционными тестами AppKit.
Пользователь выдал системное разрешение и подтвердил работу штор на настоящих
окнах сторонних приложений. Прозрачность и звук также проверены пользователем.
Автотесты дополнительно проверяют ползунки, сохранение настроек и декодирование WAV.
Полноэкранный режим, несколько мониторов и Stage Manager не проверены.

## Window tracking and release pipeline

- Added immediate AX move/resize/focus notifications and 60 Hz fallback polling.
- Batched geometry conversion rejects malformed values; regression tests pass.
- Same-size layout preserves cloth momentum; the regression test fails against
  the prior unconditional resize, and passes with the fix.
- Full GUI and headless test suites pass locally.
- Universal arm64 + x86_64 app builds and verifies after ZIP extraction.
- Release archive checksum verified with `shasum -a 256 -c SHA256SUMS.txt`.
- Native AppKit documentation rendering and animation generated using Tools/Demo.
- Release builds remain ad hoc signed, not notarized.

## v1.1.0 localization

- English defaults independently of the macOS language. English and Russian are persisted.
- Language switches live from the welcome picker and menu; existing windows refresh.
- All five test groups and the headless CI subset passed, including default language,
  invalid preference fallback, notifications, persistence and translated slider labels.
- Live UI inspection confirmed English → Russian → English without restart and correct layout.
- PNG, GIF and MP4 were regenerated in English from the native AppKit views.

## v1.2.0 wind

- Full GUI suite and headless CI suite passed (six test groups).
- New wind tests cover persistence, limits, still air, increased sway with force,
  subtle maximum displacement, pinned top rings, dragging, opening/release,
  smooth settling after switch-off and no unwanted sound events.
- Integration tests cover the wind slider callback and English/Russian labels.
- Wind defaults to off; enabled strength starts at 35%.

## v1.2.1 stronger maximum wind

- Nonlinear strength curve keeps low settings gentle, with broad gusts at 100%.
- Added faster flutter only as strength increases.
- 800×500 simulation measured 1.8pt hem range at 20% and 88.9pt at 100%.
- All six test groups and headless subset pass, including bounded maximum force,
  pinned rings, hand control, release and settling after disabling wind.
