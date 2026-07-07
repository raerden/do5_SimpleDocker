# Part 6. Docker composer

## docker-compose.yaml

**src/docker-compose.yaml**
```docker
services:

  app:
    build: 
      context: .
      dockerfile: Dockerfile
    image: my-server:clean
    #порты с хоста не мапим. Сервер слушает только 81 порт внутри образа.
    networks:
      - app-network
    restart: unless-stopped

  
  proxy:
    image: nginx:latest
    ports:
      #мапим 80й порт в контейнер nginx на 8080
      - "80:8080"
    volumes:
      #в конфиге стоит проксирование listen 8080 на proxy_pass http://app:81 в контейнер app
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
    networks:
      - app-network
    restart: unless-stopped


networks:
  app-network:
    driver: bridge
```



**Собрать контейнеры по инструкции yaml** \
`docker compose build`

![docker compose build](./images/part6/1.png)


**Запустить контейнеры в фоне** \
`docker compose up -d`

![docker compose up -d](./images/part6/2.png)
запуск контейнеров и проверка localhost

## Полезные команды

**Остановить и удалить все контейнеры** \
`docker compose down`

**Просмотреть журналы сервисов** \
`docker compose logs -f [service name]`

**Просмотерть список контейнеров** \
`docker compose ps`

**Выполнить команду в контейнере** \
`docker compose exec [service name] [command]`

**Вывести список образов** 
`docker compose images`

