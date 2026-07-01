#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcgi_stdio.h>

int main() {
    // Бесконечный цикл ожидания запросов
    while (FCGI_Accept() >= 0) {
        // Отправляем HTTP-заголовки
        printf("Content-type: text/html\r\n\r\n");
        // Отправляем тело ответа
        printf("Hello, World!\n");
    }
    return 0;
}