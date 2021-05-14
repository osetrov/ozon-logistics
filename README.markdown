# Ozon-logistics

API wrapper для Ozon.Logistics [API](https://api-stg.ozonru.me/principal-integration-api/swagger/index.html).

## Установка Ruby

    $ gem install ozon-logistics

## Установка Rails

добавьте в Gemfile:

    gem 'ozon-logistics'

и запустите `bundle install`.

Затем:

    rails g ozon_logistics:install

## Требования

Необходимо запросить CLIENT_ID и CLIENT_SECRET для production

## Использование Rails

В файл `config/ozon_logistics.yml` вставьте ваши данные

## Использование Ruby

Сначала cгенерируйте access_token
Затем создайте экземпляр объекта `OzonLogistics::Request`:

```ruby
access_token = OzonLogistics.generate_access_token('ApiTest_11111111-1111-1111-1111-111111111111', 'SRYksX3PBPUYj73A6cNqbQYRSaYNpjSodIMeWoSCQ8U=', 'client_credentials')
delivery = OzonLogistics::Request.new(access_token: access_token)
```

Вы можете изменять `access_token`, `timeout`, `open_timeout`, `faraday_adapter`, `proxy`, `symbolize_keys`, `logger`, и `debug`:

```ruby
OzonLogistics::Request.access_token = "your_access_token"
OzonLogistics::Request.timeout = 15
OzonLogistics::Request.open_timeout = 15
OzonLogistics::Request.symbolize_keys = true
OzonLogistics::Request.debug = false
```

Либо в файле `config/initializers/ozon_logistics.rb` для Rails.

## Debug Logging

Pass `debug: true` to enable debug logging to STDOUT.

```ruby
delivery = OzonLogistics::Request.new(access_token: "your_access_token", debug: true)
```

### Custom logger

Ruby `Logger.new` is used by default, but it can be overrided using:

```ruby
delivery = OzonLogistics::Request.new(access_token: "your_access_token", debug: true, logger: MyLogger.new)
```

Logger can be also set by globally:

```ruby
OzonLogistics::Request.logger = MyLogger.new
```

## Примеры (для версии от 26.04.2021)

### Delivery

#### Получение списка городов доставки 

```ruby
response = OzonLogistics::Request.delivery.cities.retrieve
cities = response.body[:data]
```

#### Получение информации о способе доставки по адресу

```ruby

body = {
  deliveryType: 'Courier',
  address: 'Санкт-Петербург, ул. Профессора Попова, д. 37Щ',
  radius: 5,
  packages: [{
    count: 1,
    dimensions: {length: 1, height: 1, width: 1, weight: 1},
    price: 999
  }]
}

response = OzonLogistics::Request.delivery.variants.byaddress.create(body: body)
variants = response.body[:data]
```

#### Получение ИД способа доставки по адресу 

```ruby
body = {
  "deliveryTypes": [
    "Courier"
  ],
  address: 'Санкт-Петербург, ул. Профессора Попова, д. 37Щ',
  radius: 5,
  packages: [{
    count: 1,
    dimensions: {length: 1, height: 1, width: 1, weight: 1},
    price: 999
  }]
}

response = OzonLogistics::Request.delivery.variants.byaddress.short.create(body: body)
delivery_variant_ids = response.body[:deliveryVariantIds]
```

#### Получение списка способов доставки
```ruby
params = {
  cityName: 'Санкт-Петербург',
  payloadIncludes: {
    includeWorkingHours: true,
    includePostalCode: true
  },
  pagination: {
    size: 100,
    token: 0
  }
}
response = OzonLogistics::Request.delivery.variants.retrieve(params: params)
variants = response.body[:data]
first_variant_id = variants.first[:id]
```

#### Список складов передачи отправлений (OZON)
```ruby
response = OzonLogistics::Request.delivery.from_places.retrieve
places = response.body[:data]
first_place_id = places.first[:id]
```
#### Расчёт стоимости доставки
```ruby
params = {
  deliveryVariantId: first_variant_id,
  weight: 1,
  fromPlaceId: first_place_id
}
response = OzonLogistics::Request.delivery.calculate.retrieve(params: params)
amount = response.body[:amount]
```

### Order
#### Метод загрузки многокоробочных отправлений
```ruby
body = {
  orderNumber: '1',
  buyer: {
    name: 'Павел',
    phone: '+71234567890',
    email: 'test@test.ru',
    type: 'NaturalPerson'
  },
  recipient: {
    name: 'Павел',
    phone: '+71234567890',
    email: 'test@test.ru',
    type: 'NaturalPerson'
  },
  deliveryInformation: {
    deliveryVariantId: first_variant_id,
    address: 'Санкт-Петербург, ул. Профессора Попова, д. 37Щ'
  },
  payment: {
    type: 'FullPrepayment',
    prepaymentAmount: 777,
    recipientPaymentAmount: 0,
    deliveryPrice: 0
  },
  packages: [
    {
      packageNumber: 1,
      dimensions: {length: 1, height: 1, width: 1, weight: 1},
      barCode: '76384576384756'
    }
  ],
  orderLines: [
    lineNumber: 1,
    articleNumber: '11398',
    name: 'Сетевое зарядное устройство USB-C + USB A, PD 3.0, QC 3.0, 20Вт',
    weight: 1,
    sellingPrice: 1190,
    estimatedPrice: 1190,
    quantity: 1,
    resideInPackages: ['1']
  ]
}
response = OzonLogistics::Request.order.create(body: body)
order = response[:data]
```
### Tariff
#### Получение списка тарифов 
```ruby
response = OzonLogistics::Request.tariff.list.retrieve
tariff = response.body[:items]
```

### Manifest
#### Получение списка отправлений
```ruby
params = {
  pagination: {
    size: 100,
    token: 0
  }
}
response = OzonLogistics::Request.manifest.unprocessed.retrieve(params: params)
tracks = response.body[:data]
track_id = tracks.first[:posting][:id]
```

### Posting
#### Получение этикетки отправления
```ruby
params = {
  postingId: track_id
}
response = OzonLogistics::Request.posting.ticket.retrieve(params: params)
barcode = response.body[:barcode]
```

### Document
#### Создание электронных документов
```ruby
body = {
  postingIds: [track_id]
}
response = OzonLogistics::Request.document.create?.create(body: body)
document = response.body
document_number = document[:documentId]
```
#### Получение списка созданных документов
```ruby
params = {
  pagination: {
    size: 100,
    token: 0
  },
  number: document_number,
  dateFrom: DateTime.now - 7.days,
  dateTo: DateTime.now
}
response = OzonLogistics::Request.document.list.retrieve(params: params)
list = response.body[:data]
```
#### Запрос печатной формы документа (Base64)
```ruby
params = {
  id: document_number,
  type: 'T12Sales',
  format: 'PDF'
}
response = OzonLogistics::Request.document.retrieve(params: params)
document = response.body[:data]
```

### Tracking
#### Трекинг по номеру отправления
```ruby
params = {
  postingNumber: 1
}
response = OzonLogistics::Request.tracking.bypostingnumber.retrieve(params: params)
bypostingnumber = response.body
```
#### Трекинг по штрихкоду отправления
```ruby
params = {
  postingBarcode: '76384576384756'
}
response = OzonLogistics::Request.tracking.bybarcode.retrieve(params: params)
bybarcode = response.body
```
#### Трекинг группы отправлений
```ruby
body = {
  articles: [
    "1"
  ]
}
response = OzonLogistics::Request.tracking.list.create(body: body)
list = response.body
```

#### Получение детальной информации по отправлению
```ruby
params = {
  postingBarcode: '76384576384756'
}
response = OzonLogistics::Request.tracking.article.retrieve(params: params)
article = response.body
```

### DropOff

#### Метод создания завки на отгрузк
```ruby
body = {
  "orderIds": [
    0
  ]
}
response = OzonLogistics::Request.dropoff.create(body: body).body
drop_off_id = response[:id]
```

#### Метод для для получения акта по ID заявки на отгрузку
```ruby
response = OzonLogistics::Request.dropoff(drop_off_id).act
p response.body
```