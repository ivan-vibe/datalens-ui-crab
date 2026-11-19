# DataLens UI Crab — theme fork

Параллельный форк интерфейса DataLens с **Theme Studio** (редактор тем в духе
[Gravity UI Themes](https://gravity-ui.com/ru/themes)) и **клиентом пакетной/потоковой
загрузки чартов** для Rust-монолита.

Форк живёт рядом с официальным UI: оригинал остаётся на `:8091` и не изменяется,
форк открывается на **`:8094`**. Nginx форка проксирует `/api/run`, `/api/run/batch` и
`/api/run/batch/stream` на нативный монолит на хосте `:8099`, а всё остальное — в
node-сервер UI на `:3030`.

> Это **распространение (distribution) собранного UI**, а не полный исходный код
> DataLens. Исходники форка в репозиторий не входят — см.
> [PUBLISH.md](PUBLISH.md), раздел «Статус исходников».

## Что добавлено по сравнению с upstream

| Область | Изменение |
| --- | --- |
| Оформление | Раздел **Settings → Оформление → Темы**: 3 встроенные темы (DataLens, DataLens Original, Gravity Light), набор базовых тем, создание/редактирование/удаление своих тем |
| Редактор | Вкладки «Предпросмотр / Цвета / Шрифты / Скругления / Разное», режимы Basic/Advanced, живой предпросмотр, 17 SVG-иконок и загрузка своей |
| Импорт/экспорт | Импорт JSON/CSS из Темизатора Gravity UI (полная карта CSS-переменных, включая типографику и радиусы), экспорт в JSON/CSS |
| Пользователи | Персональная тема в **Настройки → Пользователи → Тема интерфейса**; приоритет: персональная → активная тема сервиса → штатное оформление |
| Контрастность | Кастомная тема генерирует 4 набора переменных, включая `light-hc`/`dark-hc`; штатный Contrast → High теперь работает вместе с темой |
| Дашборды | Радиус темы применяется к карточкам, контролам и полотну чартов, если у дашборда не задан собственный радиус |
| Хранение | Серверное JSON-хранилище тем (`themes.json`), API `/api/themes*`, атомарная запись, лимиты и валидация |
| Производительность | **Settings → Performance**: обычная или пакетная загрузка (`POST /api/run/batch`), при пакетной — потоковая NDJSON-загрузка (`/api/run/batch/stream`, zstd/gzip) с fallback |
| Prefetch | Предзагрузка JS-чанка и entry при наведении/фокусе на карточку дашборда или воркбука |
| Prewarm | Удалён полностью (endpoint, клиент, nginx-маршрут) |

Подробное описание фичи, замеры и скриншоты — в исходном документе проекта
`THEME-FORK.md` (в этот репозиторий не входит).

## Что внутри

```
.
├── README.md                  этот файл
├── LICENSE                    Apache License 2.0 (upstream)
├── NOTICE                     атрибуция upstream и список изменений
├── PUBLISH.md                 имена репозитория, команды публикации, чек-лист
├── Dockerfile                 runtime-образ: upstream 0.3831.0 + nginx + entrypoint
├── docker-compose.yml         запуск на :8094, dist/ + named volume для тем
├── docker-compose.tls.yml     опциональный TLS на :8092
├── .env.example               переменные окружения (без секретов)
├── nginx/nginx.conf           HTTP-конфиг форка (проксирование на :8099)
├── nginx/nginx-tls.conf       опциональный TLS server block
├── docker/entrypoint.sh       seed themes.json + проверка dist
├── theme-data.example/        стартовое состояние themes.json
├── theme-data/                локальный bind-каталог (опционально, см. ниже)
├── scripts/fetch-dist.sh      скачать релизный dist.tar.gz в dist/
├── scripts/release-dist.sh    собрать и опубликовать релизный артефакт
├── .github/workflows/         сборка OCI-образа в GHCR
└── dist/                      сюда распаковывается сборка (в git не попадает)
```

## Требования

- Docker Engine 24+ и Docker Compose v2.24+ (нужны `env_file.required` и `!override`).
- Собранный UI в `dist/` — скачивается из GitHub Release (см. ниже) или собирается
  из исходников.
- Запущенный бэкенд DataLens: Rust-монолит на хосте `:8099` и auth на `:8097`
  (или свои адреса в `.env`).
- Свободный порт `8094`.

## Быстрый старт

```bash
git clone https://github.com/ivan-vibe/datalens-ui-crab.git
cd datalens-ui-crab

cp .env.example .env
$EDITOR .env                  # endpoints, AUTH_* токены и ключи

./scripts/fetch-dist.sh v0.3831.0-themes.1

docker compose up -d --build
# UI: http://127.0.0.1:8094
```

Проверка:

```bash
docker compose ps
curl -I http://127.0.0.1:8094/
docker compose logs -f ui
```

Остановка:

```bash
docker compose down
```

### Переменные окружения

`docker-compose.yml` читает `.env` (файл в `.gitignore`). Минимально нужны:

- `US_ENDPOINT`, `BI_DATA_ENDPOINT`, `BI_API_ENDPOINT`, `META_MANAGER_ENDPOINT` —
  на текущем стенде все указывают на `http://host.docker.internal:8099`;
- `AUTH_ENDPOINT` — на стенде `http://host.docker.internal:8097`;
- `AUTH_MASTER_TOKEN`, `AUTH_TOKEN_PUBLIC_KEY`, `US_DYNAMIC_MASTER_TOKEN_PRIVATE_KEY` —
  значения берутся из вашего deployment-окружения, в репозитории их нет.

`host.docker.internal` добавляется через `extra_hosts: host-gateway`, поэтому схема
работает и на Linux, и на Docker Desktop.

### Хранилище тем

Активная тема, темы и персональные назначения лежат в
`/opt/app/theme-data/themes.json`. По умолчанию это **named volume**
`datalens-theme-fork-theme-data`: он наследует владельца `app` (uid 1001) от каталога
в образе, поэтому не требует `chown` на хосте. При первом запуске entrypoint
копирует туда `theme-data.example/themes.json`.

Бэкап и восстановление (volume принадлежит compose-проекту):

```bash
# backup
docker compose exec -T ui tar czf - -C /opt/app/theme-data . > themes-backup.tar.gz
# restore
docker compose exec -T ui tar xzf - -C /opt/app/theme-data < themes-backup.tar.gz
```

`docker compose down -v` удаляет volume вместе с темами; используйте `down` без `-v`,
если темы нужно сохранить.

Если нужен `themes.json` прямо на хосте (как в текущем деплое), используйте bind.
Создайте `docker-compose.bind.yml`:

```yaml
services:
  ui:
    volumes: !override
      - ./dist:/opt/app/dist:ro
      - ./theme-data:/opt/app/theme-data
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

и запускайте `docker compose -f docker-compose.yml -f docker-compose.bind.yml up -d`.
Каталог должен быть доступен uid `1001`:

```bash
sudo chown -R 1001:1001 theme-data
```

Один экземпляр UI — один писатель. Несколько реплик без общего Postgres/блокировки
дают last-write-wins.

### TLS (опционально)

```bash
mkdir -p certs
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout certs/localhost.key -out certs/localhost.crt \
  -subj "/CN=localhost"

docker compose -f docker-compose.yml -f docker-compose.tls.yml up -d
# https://127.0.0.1:8092
```

HTTP `:8094` при этом продолжает работать. В продакшене TLS обычно terminates
вышестоящий прокси, и этот override не нужен.

## Как это работает

```
браузер :8094
   │
   ▼
nginx (контейнер, :8080)
   ├── /api/run, /api/run/batch, /api/run/batch/stream ──► host.docker.internal:8099
   │                                                        (Rust-монолит)
   └── / ──► node dist/server (:3030)
                ├── /api/themes*  ──► /opt/app/theme-data/themes.json
                └── остальные API ──► US / auth / meta-manager
```

- `dist/public` — статика, `dist/server` — node-сервер UI;
- nginx-конфиг форка отличается от upstream только маршрутами `/api/run*` и
  вынесенным TLS-блоком;
- для потокового ответа отключены `proxy_buffering`/`proxy_cache` и включён
  `chunked_transfer_encoding`, иначе NDJSON не доходит до браузера построчно.

### API тем

| Метод | Путь | Назначение |
| --- | --- | --- |
| GET | `/api/themes` | `{themes, activeId, assignments}` |
| POST | `/api/themes` | создать/обновить тему |
| PUT | `/api/themes/:id` | обновить тему |
| DELETE | `/api/themes/:id` | удалить тему |
| POST | `/api/themes/active` | `{id}` — активная тема сервиса (`null` — сбросить) |
| POST | `/api/themes/assign` | `{userId, themeId}` — персональная тема |

Все методы требуют авторизации; мутации — роль `datalens.admin` (кроме `assign`,
где пользователь может менять только себя). Встроенные темы на сервере не хранятся:
сервер знает их id только для `activeId`.

## Отличия от upstream 0.3831.0

1. **Theme Studio** и серверное хранение тем — новая фича, в upstream её нет.
2. **Персональные темы** пользователей и приоритет применения.
3. **High contrast** работает с кастомными темами: генерируются 4 набора
   CSS-переменных, HC-вариант не смешивается с импортированными цветами.
4. **Радиус темы** применяется к дашбордам, если у дашборда не задан свой.
5. **Пакетная и потоковая загрузка чартов**: клиент коалесцирует запросы в
   `POST /api/run/batch` (окно 0 мс, до 64 запросов), при включённой пакетной
   загрузке доступен Streaming (`POST /api/run/batch/stream`, NDJSON, zstd/gzip,
   коалесценция резолвов 16 мс). При недоступности batch — fallback на одиночные
   `/api/run`. Streaming без батчинга не даёт выигрыша и не предлагается.
6. **Prefetch** entry и JS-чанка на карточках дашбордов/воркбуков и в навигации.
7. **Prewarm отсутствует**: экспериментальный endpoint форка удалён, в upstream
   его не было.
8. Сборка форка сделана из исходников **чуть старше** образа `0.3831.0`;
   чартовый фикс `3710` из оригинального образа в неё не входит. Это осознанное
   состояние текущего стенда, а не регрессия публикации.
9. Официальный UI на `:8091` и его образ не изменяются; форк — отдельный контейнер
   на том же хосте.

Ограничения:

- цвета, зашитые в JS-темы ChartKit, могут перекрашиваться не полностью;
- шрифты Merriweather/Titillium/Manrope/Roboto Mono грузятся с Google Fonts,
  без сети используется fallback;
- Highcharts **не входит** в `dist`: сервер отдаёт ссылку на внешний
  `HC_ENDPOINT` (по умолчанию `code.highcharts.com`), у Highcharts своя лицензия;
- иконка темы подменяет логотип через CSS-селекторы Gravity UI; при обновлении
  Gravity UI их нужно перепроверять.

## Сборка и воспроизведение

### Вариант A. Готовый dist из релиза (рекомендуется)

```bash
./scripts/fetch-dist.sh v0.3831.0-themes.1
docker compose up -d --build
```

`scripts/fetch-dist.sh` скачивает `datalens-ui-crab-<version>-dist.tar.gz`
из GitHub Release, проверяет `SHA256SUMS` и распаковывает содержимое в `dist/`.
Артефакт **не коммитится**: 102 MB статики (из них ~78 MB — source maps) не место
в git; без maps релизный `.tar.gz` занимает ~8 MB. Альтернативы и обоснование — в [PUBLISH.md](PUBLISH.md).

### Вариант B. Сборка образа с запечённым dist

```bash
docker build \
  --build-arg DIST_URL=https://github.com/ivan-vibe/datalens-ui-crab/releases/download/v0.3831.0-themes.1/datalens-ui-crab-0.3831.0-themes.1-dist.tar.gz \
  --build-arg DIST_SHA256=<sha256> \
  -t ghcr.io/ivan-vibe/datalens-ui-crab:0.3831.0-themes.1 .
```

Архив должен содержать **содержимое** `dist/` (`public/`, `server/`, `shared/`,
`ui/`, `i18n/`, `deploy-public/`, `run/`), а не вложенную папку `dist/`.

### Вариант C. Из исходников форка

Исходники в этот репозиторий не входят. Если у вас есть патч-сет форка
(см. [PUBLISH.md](PUBLISH.md)), сборка повторяет текущий стенд:

```bash
# Node 22, pnpm 10.17.1
cd /path/to/datalens-ui-src
pnpm install --frozen-lockfile
pnpm run build                 # i18n:prepare + app-builder build
rm -rf /path/to/ui-theme-fork/dist/*
cp -R dist/. /path/to/ui-theme-fork/dist/
```

Текущая сборка (эталон стенда): `public/build/js/dl-main.380f1b91.js`,
SHA-256 `ae845a8a6a2955ebbe4ab28bf885c6ff557b53b7f8ceded89b0ee39ae45ced76`.
Базовый образ: `ghcr.io/datalens-tech/datalens-ui:0.3831.0`, digest
`sha256:5c720832463cc54c43307a9aeafb8f881fb54facc548edac35efb8ccfe327b0f`.

### Релиз нового dist

```bash
./scripts/release-dist.sh /path/to/theme-fork-dist 0.3831.0-themes.2
```

Скрипт по умолчанию **удаляет `*.map`** (иначе релизный артефакт содержит
исходный код форка), собирает `dist.tar.gz`, считает SHA-256 и создаёт GitHub
Release через `gh`. Флаг `KEEP_MAPS=1` оставляет maps, если они нужны для отладки.

## Лицензия и атрибуция

- Upstream: [datalens-tech/datalens-ui](https://github.com/datalens-tech/datalens-ui),
  **Apache License 2.0**, `Copyright 2023 YANDEX LLC`. Полный текст — в
  [LICENSE](LICENSE); атрибуция и перечень изменений — в [NOTICE](NOTICE).
- Лицензия проверена локально по `LICENSE` и `package.json` upstream-снапшота,
  а также по OCI-лейблу базового образа (`org.opencontainers.image.licenses=Apache-2.0`).
- Собранная статика содержит сторонние open-source библиотеки (React, Gravity UI,
  Monaco и др.) под их собственными лицензиями. Highcharts в `dist` не входит и
  подключается внешне — на него распространяется лицензия Highcharts.
- Если вы публикуете образ или релизный артефакт, сохраняйте `LICENSE` и `NOTICE`
  рядом с артефактом и в OCI-лейблах.

Про публикацию, имена репозитория и обязательный чек-лист — [PUBLISH.md](PUBLISH.md).
