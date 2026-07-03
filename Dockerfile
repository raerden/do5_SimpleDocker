# Этап 1: Сборка C-сервера
FROM ubuntu:22.04 AS builder

# Устанавливаем компилятор и библиотеки
RUN apt-get update && apt-get install -y \
    gcc \
    libfcgi-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем исходник
COPY server/server.c /app/server.c

# Компилируем
RUN gcc /app/server.c -o /app/server -lfcgi


# Этап 2: Финальный образ
FROM nginx:latest

# Устанавливаем spawn-fcgi (нужен для запуска FastCGI-сервера)
RUN apt-get update && apt-get install -y \
    spawn-fcgi \
    libfcgi0ldbl \
    && rm -rf /var/lib/apt/lists/*

# Копируем скомпилированный сервер из этапа builder
COPY --from=builder /app/server /app/server

# Копируем конфиг nginx
COPY server/nginx/nginx.conf /etc/nginx/nginx.conf

# Создаем скрипт для запуска обоих процессов
RUN printf '#!/bin/sh\n\
spawn-fcgi -p 8080 /app/server &\n\
exec nginx -g "daemon off;"\n' > /app/start.sh \
 && chmod +x /app/start.sh

# Запускаем скрипт
CMD ["/app/start.sh"]