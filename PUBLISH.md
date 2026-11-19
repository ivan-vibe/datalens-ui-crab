# Публикация репозитория

Состояние на 2026-11-20: репозиторий **создан и запушен** —
[`ivan-vibe/datalens-ui-crab`](https://github.com/ivan-vibe/datalens-ui-crab), ветка `main`.
Staging-дерево: `/Users/ivan/datalens2026/publish/ui-theme-fork`. Ниже — что вошло в
первый публичный коммит и что ещё предстоит закрыть перед объявлением репозитория
production-ready.

## 1. Статус исходников — это distribution, не source

Исходники форка **не входят** в этот репозиторий.

- Локальный снапшот существует: `/Users/ivan/datalens2026/research/datalens-ui-src`.
- Но это не отдельный git-репозиторий с историей upstream: `git rev-parse` из него
  разрешается в монорепо `/Users/ivan/datalens2026`; remote отсутствует, а файлы
  форка (`src/ui/units/service-settings/components/ThemeSettings/*`,
  `src/server/controllers/themes.ts`) не отслеживаются (`git ls-files` пуст).
- Готового патч-сета (`*.patch` / `git format-patch`) в workspace нет.
- В `research/datalens-ui-src` есть `dist/` и `node_modules/`, то есть это рабочая
  копия, а не чистый upstream + патчи.

Следствие: **публиковать этот репозиторий можно только как distribution собранного
UI**, с явной пометкой «source not included» (она уже есть в README и NOTICE).
Публикация только `dist` возможна, но выдавать её за исходники нельзя.

Чтобы опубликовать именно source, до публикации нужно:

1. Взять чистый upstream `datalens-tech/datalens-ui` на ревизию из OCI-лейбла
   базового образа: `7c06cd198a47ca3b2b18159ca790d6c0e3e0c14e`
   (лейбл `org.opencontainers.image.revision`).
2. Перенести только файлы форка (Theme Studio, `themes.ts`, `routes.ts`,
   `dl-main.tsx`, `AppearanceSettings`, `UsersList`, i18n, стили) и изменения
   streaming-клиента.
3. Сгенерировать патч:
   ```bash
   git clone https://github.com/datalens-tech/datalens-ui.git /tmp/dl-ui-upstream
   git -C /tmp/dl-ui-upstream checkout 7c06cd198a47ca3b2b18159ca790d6c0e3e0c14e
   # overlaying fork files into /tmp/dl-ui-upstream ...
   git -C /tmp/dl-ui-upstream add -A
   git -C /tmp/dl-ui-upstream diff --cached --binary > theme-fork.patch
   ```
4. Проверить, что в патч не попали изменения монорепо (Rust, nginx, deploy).
5. Добавить в этот репозиторий `patches/theme-fork.patch` и инструкцию сборки,
   после чего можно снять формулировку «distribution only».

## 2. Имена репозитория

| Имя | Почему |
| --- | --- |
| **`datalens-ui-crab`** (выбрано) | Кратко, совпадает с именем образа; «crab» — отсылка к Rust-стеку, для которого собран форк; `datalens-ui-*` однозначно говорит, что это UI |
| `datalens-theme-studio` | Фича на первом плане, короче; но не видно, что это форк именно UI и какая база |
| `datalens-ui-extended` | Шире по смыслу (темы + streaming), но размыто и легче воспринимается как официальное расширение |

Владелец — `ivan-vibe` (личный аккаунт, где лежит остальной стек), видимость — public. В README/NOTICE уже есть дисклеймер «independent fork,
not an official DataLens distribution».

## 3. Описание для GitHub

> An independent Apache-2.0 fork of the DataLens UI (base image 0.3831.0) that adds
> a Theme Studio with service-wide and per-user themes, high-contrast-aware theming,
> dashboard radius controls, and a batch/NDJSON streaming chart client for the Rust
> DataLens monolith. Ships as a Docker Compose service on port 8094 next to the
> official UI, with nginx routing /api/run* to the backend.

Короткая версия для поля Description (до 350 символов):

> Apache-2.0 DataLens UI fork: Theme Studio, per-user themes and a batch/NDJSON
> streaming chart client for the Rust monolith. Runs on :8094 via Docker Compose.

## 4. Topics

`datalens`, `datalens-ui`, `gravity-ui`, `theme-studio`, `theme-editor`, `theming`,
`high-contrast`, `data-visualization`, `business-intelligence`, `react`, `typescript`,
`docker`, `docker-compose`, `nginx`, `ndjson`, `streaming`, `rust`, `fork`

## 5. Видимость

- **До прохождения чек-листа — private.** Причины: не подтверждён способ публикации
  исходников, не проверены сторонние лицензии в собранной статике, не выбран owner.
- **После чек-листа — public.** Apache-2.0 разрешает распространение производной
  работы при сохранении `LICENSE`/`NOTICE`; секретов и пользовательских данных в
  дереве нет.
- Видимость пакета GHCR настраивается отдельно от репозитория. Для публичного
  репозитория сделайте пакет public, иначе `docker compose` у пользователей не
  сможет его скачать без токена. До этого собирайте локально:
  `docker compose up -d --build`.

## 6. Команды создания и пуша

> Ниже — команды на будущее. В рамках подготовки они **не выполнялись**.

```bash
cd /Users/ivan/datalens2026/publish/ui-theme-fork

# 0. Проверить, что gh авторизован и смотрит в нужный аккаунт
gh auth status

# 1. Создать репозиторий и (опционально) сразу запушить.
#    ivan-vibe замените на свой логин/организацию.
gh repo create ivan-vibe/datalens-ui-crab \
  --public \
  --description "Apache-2.0 DataLens UI fork: Theme Studio, per-user themes and a batch/NDJSON streaming chart client for the Rust monolith." \
  --source=. \
  --remote=origin

# 2. Первый пуш (ветка уже main, коммит сделан)
git push -u origin main
```

Либо без `--source`, вручную:

```bash
git remote add origin git@github.com:ivan-vibe/datalens-ui-crab.git
git branch -M main
git push -u origin main
```

Если репозиторий создаётся на github.com через UI, не инициализируйте его README:
локальный репозиторий уже содержит коммит, иначе получится расходящаяся история.

## 7. Публикация артефактов

```bash
# 7.1. dist как release asset (по умолчанию без source maps)
export REPO_SLUG=ivan-vibe/datalens-ui-crab
./scripts/release-dist.sh /path/to/theme-fork-dist 0.3831.0-themes.1
# создаст release v0.3831.0-themes.1 с
# datalens-ui-crab-0.3831.0-themes.1-dist.tar.gz + SHA256SUMS

# 7.2. OCI-образ (thin runtime; dist монтируется или запекается через DIST_URL)
docker build \
  --build-arg DIST_URL=https://github.com/ivan-vibe/datalens-ui-crab/releases/download/v0.3831.0-themes.1/datalens-ui-crab-0.3831.0-themes.1-dist.tar.gz \
  --build-arg DIST_SHA256=<sha256> \
  -t ghcr.io/ivan-vibe/datalens-ui-crab:0.3831.0-themes.1 .
docker push ghcr.io/ivan-vibe/datalens-ui-crab:0.3831.0-themes.1
```

Альтернатива — GitHub Actions: `.github/workflows/release-image.yml`
(`workflow_dispatch`, версия + опциональный `DIST_URL`).

## 8. Чек-лист перед публикацией

| # | Проверка | Статус |
| --- | --- | --- |
| 1 | Лицензия upstream | ✅ Проверена: `LICENSE` = Apache-2.0, `Copyright 2023 YANDEX LLC`; `package.json` = `Apache-2.0`; OCI-лейбл базового образа = `Apache-2.0` |
| 2 | Digest базового образа | ✅ `sha256:5c720832463cc54c43307a9aeafb8f881fb54facc548edac35efb8ccfe327b0f` (локальный `docker image inspect`); перепроверить перед пушем |
| 3 | Исходники форка в репозитории | ❌ Нет. Решение: оставить distribution-лейбл **или** экспортировать патч-сет (см. §1) |
| 4 | `dist/` не в git | ✅ `.gitignore`, в коммите только `dist/.gitkeep` |
| 5 | Секреты не в git | ✅ `.env` игнорируется, `.env.example` — только placeholders; проверить `git grep` |
| 6 | Source maps в релизе | ⚠️ По умолчанию вырезаются `release-dist.sh`; решить, не нужен ли `-sources`-вариант отдельным ассетом |
| 7 | Сторонние лицензии в собранной статике | ⚠️ Проверить React/Gravity UI/Monaco и др.; Highcharts не входит в `dist` (грузится с `HC_ENDPOINT`), но его лицензия отдельная |
| 8 | Товарный знак «DataLens» | ⚠️ Дисклеймер «independent fork» уже в README/NOTICE; подтвердить формулировку |
| 9 | Owner, имя репозитория, видимость GHCR | ✅ `ivan-vibe/datalens-ui-crab`, public; GHCR-пакет пока private — сделать public после первого релиза образа |
| 10 | Чистая проверка сборки | ⚠️ `git clone` во временный каталог → `fetch-dist` → `docker compose up -d --build` на машине без старого образа |
| 11 | Скриншоты/пользовательские данные | ✅ В репозиторий не включены |
| 12 | Тег и релиз | ⚠️ Создаются `release-dist.sh`; проверить, что тег указывает на коммит с `NOTICE`/`LICENSE` |

## 9. Что блокирует публикацию

1. **Исходники не включены.** Либо публикуем как distribution (текущий вариант),
   либо экспортируем патч-сет — это отдельная работа, без неё нельзя называть
   репозиторий source-репозиторием.
2. **Юридическая проверка производной работы.** Apache-2.0 это позволяет, но нужно
   подтвердить атрибуцию и сторонние лицензии в собранных ассетах; особенно если
   публиковать образ с `dist` внутри.
3. **GHCR-пакет.** Репозиторий публичный, но пакет образа по умолчанию private:
   `docker compose` у пользователя не скачает его без токена, пока пакет не станет
   public (Settings → Packages) или пока образ не собран локально (`--build`).
4. **Source maps.** Если их не вырезать, релизный ассет де-факто раскрывает
   исходный код форка и весит 102 MB вместо ~29 MB распакованного (или ~8 MB
   сжатого `.tar.gz` без maps).

Репозиторий опубликован. Осталось закрыть пункты 1–2 (source/патч-сет и юридическая
проверка сторонней статики) и пункт 3 по GHCR, если планируется раздача готового образа.
