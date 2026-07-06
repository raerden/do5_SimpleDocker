# Part 5. Dockle

## Этап 1: Проверка образа

**Проверка образа**
`dockle my-server:latest`

![Dockle](./images/part5/1.png)

![Dockle](./images/part5/2.png)


1. *FATAL - CIS-DI-0010: Do not store credential in environment variables/files
Suspicious ENV key found : NGINX_GPGKEYS* \
Dockle ругается на официальный образ nginx:latest.

2. *CIS-DI-0001: Create a user for the container* \
Не использовать root для запуска процессов

3. *DKL-DI-0006: Avoid latest tag* \
Не использовать тег latest. Писать номер версии

4. *CIS-DI-0006: Add HEALTHCHECK instruction to the container image* \
Не используется регулярная проверка работоспособности контейнера

## Этап 2: Новая сборка образа с учетом dockle report


**src/Dockerfile**
```docker
# ======================
# BUILD
# ======================
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    gcc \
    libfcgi-dev \
 && rm -rf /var/lib/apt/lists/*

COPY server/server.c /app/server.c

RUN gcc /app/server.c -o /app/server -lfcgi

```

*FROM ubuntu:22.04 AS builder* \
Указыват базовый образ Ubuntu как builder

*RUN apt-get update && ...* \
Каждая команда RUN создает новый слой образа (слепок), поэтому обьединяем несколько команд в одну чтобы не увеличивать размер

*COPY server/server.c /app/server.c* \
скопировать server.c в контейнер

*RUN gcc /app/server.c -o /app/server -lfcgi* \
Скомпилировать ./server в контейнере

Созданный на первом этапе контейнер необходим только для компиляции итоговгоо бинарного файла "server". 

## Этап 2: Финальный образ. Без nginx образа, раз он такой ошибочный. 

дописываем в файл сборки src/Dockerfile второй этап
```docker
# ======================
# RUNTIME
# ======================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    libfcgi0ldbl \
    curl \
 && rm -rf /var/lib/apt/lists/*

# non-root user
RUN useradd -r -u 1001 -s /usr/sbin/nologin appuser

COPY --from=builder /app/server /app/server

COPY server/nginx/nginx.conf /etc/nginx/nginx.conf

# start script (no spawn-fcgi!)
RUN printf '#!/bin/sh\n\
set -e\n\
/app/server &\n\
nginx -g "daemon off;"\n' > /start.sh \
 && chmod +x /start.sh

HEALTHCHECK --interval=30s --timeout=3s \
 CMD curl -fs http://localhost/ || exit 1

USER appuser

CMD ["/start.sh"]
```

*FROM ubuntu:22.04*
Соберем nginx сервер самостоятельно с базовой Ubuntu

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