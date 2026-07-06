# Part 4. Свой докер

## Этап 1: Сборка C-сервера

**src/Dockerfile**
```docker
# Этап 1: Сборка C-сервера
FROM ubuntu:22.04 AS builder

# Устанавливаем компилятор и библиотеки
RUN apt-get update && apt-get install -y \
    gcc \
    libfcgi-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем исходник
COPY server.c /app/server.c

# Компилируем с линковкой библиотеки FastCGI
RUN gcc /app/server.c -o /app/server -lfcgi
```

*FROM ubuntu:22.04 AS builder* \
Указыват базовый образ Ubuntu как builder

*RUN apt-get update && ...* \
Каждая команда RUN создает новый слой образа (слепок), поэтому обьединяем несколько команд в одну чтобы не увеличивать размер

Созданный на первом этапе контейнер необходим только для компиляции итоговгоо бинарного файла "server". Для финального образа не нужно хранить лишнюю OS Ubuntu, gcc и тд

## Этап 2: Финальный образ

дописываем в файл сборки src/Dockerfile 
```docker
# Этап 2: Финальный образ
FROM nginx:latest

# Устанавливаем spawn-fcgi (нужен для запуска FastCGI-сервера)
RUN apt-get update && apt-get install -y \
    spawn-fcgi \
    libfcgi0ldbl \
    && rm -rf /var/lib/apt/lists/*

# Копируем скомпилированный сервер из этапа builder
COPY --from=builder /app/server /app/server

# Копируем конфиг nginx в контейнер
COPY server/nginx/nginx.conf /etc/nginx/nginx.conf

# Создаем скрипт для запуска обоих процессов
RUN printf '#!/bin/sh\n\
spawn-fcgi -p 8080 /app/server &\n\
exec nginx -g "daemon off;"\n' > /app/start.sh \
 && chmod +x /app/start.sh

# Запускаем скрипт
CMD ["/app/start.sh"]
```

*FROM nginx:latest*
Берем официальный образ nginx базу для финалього образа \
В нем уже есть nginx, все его зависимости, и он настроен на запуск

*RUN apt-get update && apt-get install -y spawn-fcgi* \
Устанавливаем spawn-fcgi — утилиту для запуска FastCGI-серверов \
Она нужна, чтобы запустить наш сервер на порту 8080

*COPY --from=builder /app/server /app/server* \
Копирует скомпилированный бинарник из этапа builder

*RUN printf '#!/bin/sh\n\ ..* \
Создаем скрипт запуска сервера в фоне и nginx на главном  /app/start.sh
```bash
#!/bin/sh
spawn-fcgi -p 8080 /app/server &
exec nginx -g "daemon off;"
```
spawn-fcgi -p 8080 /app/server & — запускает сервер на порту 8080 в фоне (&) \
nginx -g 'daemon off;' — запускает nginx на переднем плане \
-g 'daemon off;' — запрещает nginx уходить в фон (чтобы контейнер не умирал)

*chmod +x /app/start.sh* \
делаем скрипт исполняемым

*CMD ["/app/start.sh"]* \
Выполнить команду при старте контейнера


## Этап 3. Сборка образа и проверка

**docker build -t my-server:latest .** \
Запуск сборки по инструкциям Dockerfile в текущей директории

![docker build](./images/part4/1.png)

![docker build](./images/part4/2.png)


**docker run -d --name my-container -p 80:81 -v $(pwd)/server/nginx/nginx.conf:/etc/nginx/nginx.conf my-server:latest** \
Запуск контейнера с маппингом папки ./nginx внутрь контейнера

`docker run` - создание и запуск нового контейнера \
`-d` - Detach mode (фоновый режим) \
`--name my-container` - присвоить имя контейнеру \
`-p 80:81` - Port mapping (проброс портов). \
`-v ...` - Volume mount (монтирование тома / файла). \
`$(pwd)/server/nginx/nginx.conf` - Источник на хосте (Source).
`:/etc/nginx/nginx.conf` - Путь назначения в контейнере (Destination).
`my-server:latest` - Имя и тег образа для сборки контейнера

**Посмотреть какой процесс занимает 80й порт** \
`sudo ss -tlnp | grep :80`

**Остановить nginx на локальном хосте :80** \
`systemctl stop nginx`

**Перезапустить nginx в контейнере** 
`docker exec my-container nginx -s reload`

**Перезапустить контейнер** \
`docker restart my-container`