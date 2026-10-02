workspace "Маркетплейс" "C4 Container: целевая архитектура маркетплейса" {
    model {
        buyer = person "Покупатель" "Смотрит ленту, оформляет и оплачивает заказ"
        seller = person "Продавец" "Публикует и редактирует собственные товары"

        marketplace = softwareSystem "Маркетплейс" "Площадка для продажи товаров" {
            gateway = container "API Gateway" "Единая точка входа; сейчас реализован только GET /health" "nginx"
            identity = container "Identity Service" "Аккаунты, роли и аутентификация" "Планируемый сервис"
            catalog = container "Catalog Service" "Карточки, цены и публикация товаров" "Планируемый сервис"
            inventory = container "Inventory Service" "Остатки и временные резервы SKU" "Планируемый сервис"
            feed = container "Feed Service" "Проекция каталога и персонализированная выдача" "Планируемый сервис"
            orders = container "Order Service" "Заказы и оркестрация оформления" "Планируемый сервис"
            payments = container "Payment Service" "Платежные попытки, учет и возвраты" "Планируемый сервис"
            notifications = container "Notification Service" "Шаблоны, доставка и повторы уведомлений" "Планируемый сервис"

            identityDb = container "Identity DB" "Аккаунты, роли, сессии" "PostgreSQL" "Database"
            catalogDb = container "Catalog DB" "Карточки, цены, публикации" "PostgreSQL" "Database"
            inventoryDb = container "Inventory DB" "Остатки и резервы" "PostgreSQL" "Database"
            feedDb = container "Feed DB" "Проекция, предпочтения и ранги" "PostgreSQL" "Database"
            orderDb = container "Order DB" "Заказы и снимки цен" "PostgreSQL" "Database"
            paymentDb = container "Payment DB" "Операции и журнал учета" "PostgreSQL" "Database"
            notificationDb = container "Notification DB" "Задания и попытки доставки" "PostgreSQL" "Database"
            broker = container "Event Broker" "Доставка предметных событий как минимум один раз" "RabbitMQ"
        }

        psp = softwareSystem "Платежный провайдер" "Внешняя оплата, возврат и webhook"
        delivery = softwareSystem "Провайдер сообщений" "Внешняя доставка email и SMS"

        buyer -> gateway "Просмотр ленты и товаров, заказы, вход" "HTTPS/JSON"
        seller -> gateway "Вход и управление карточками" "HTTPS/JSON"
        gateway -> identity "Маршрутизация аккаунта и входа" "HTTPS/JSON"
        gateway -> catalog "Маршрутизация карточек и товаров" "HTTPS/JSON"
        gateway -> feed "Маршрутизация ленты" "HTTPS/JSON"
        gateway -> orders "Маршрутизация заказов" "HTTPS/JSON"
        gateway -> payments "Маршрутизация webhook провайдера" "HTTPS/JSON"

        identity -> identityDb "Читает и изменяет свои данные" "SQL"
        catalog -> catalogDb "Читает и изменяет свои данные, outbox" "SQL"
        inventory -> inventoryDb "Атомарно меняет остатки и резервы" "SQL"
        feed -> feedDb "Читает и обновляет свою проекцию" "SQL"
        orders -> orderDb "Читает и изменяет заказ, outbox" "SQL"
        payments -> paymentDb "Пишет попытки, учет и outbox" "SQL"
        notifications -> notificationDb "Пишет задания, попытки и дедупликацию" "SQL"

        orders -> catalog "Получает актуальные карточки и цены" "HTTPS/JSON, синхронно"
        orders -> inventory "Создает, подтверждает и освобождает резерв" "HTTPS/JSON, синхронно"
        orders -> payments "Создает идемпотентную платежную попытку и возврат" "HTTPS/JSON, синхронно"
        feed -> catalog "Загружает полный снимок для восстановления проекции" "HTTPS/JSON, синхронно"
        payments -> psp "Создает операцию, проверяет статус и делает возврат" "HTTPS/JSON, синхронно"
        psp -> gateway "Отправляет подписанный платежный webhook" "HTTPS/JSON, синхронно"
        notifications -> delivery "Отправляет сообщение" "HTTPS/JSON, синхронно"

        identity -> broker "Публикует AccountDisabled, ContactChanged через outbox" "AMQP, асинхронно"
        catalog -> broker "Публикует ProductPublished/Changed/Unpublished через outbox" "AMQP, асинхронно"
        inventory -> broker "Публикует AvailabilityChanged через outbox" "AMQP, асинхронно"
        orders -> broker "Публикует OrderCreated/Paid/Cancelled через outbox" "AMQP, асинхронно"
        payments -> broker "Публикует PaymentSucceeded/Failed, RefundSucceeded через outbox" "AMQP, асинхронно"
        broker -> feed "Доставляет изменения товаров, доступности и аккаунта" "AMQP, асинхронно"
        broker -> orders "Доставляет результаты платежей" "AMQP, асинхронно"
        broker -> notifications "Доставляет статусы заказа и обновления контакта" "AMQP, асинхронно"
    }

    views {
        container marketplace "marketplace-container" "C4 Container — маркетплейс и его зависимости" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #2f6f9f
                color #ffffff
            }
        }
    }
}
