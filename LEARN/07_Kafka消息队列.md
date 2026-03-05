# 第七章：Apache Kafka 消息队列 —— 服务之间怎么传消息

---

## 📚 全部章节导航

- [00_从零开始学Spring Boot](./00_从零开始学Spring Boot.md)
- [01_Spring_Boot是什么](./01_Spring_Boot是什么.md)
- [02_三层架构_MVC](./02_三层架构_MVC.md)
- [03_依赖注入_IOC](./03_依赖注入_IOC.md)
- [04_数据库_JPA_MySQL](./04_数据库_JPA_MySQL.md)
- [05_REST_API设计](./05_REST_API设计.md)
- [06_微服务是什么](./06_微服务是什么.md)
- [07_Kafka消息队列](./07_Kafka消息队列.md)
- [08_JWT身份认证](./08_JWT身份认证.md)
- [09_Docker容器化](./09_Docker容器化.md)
- [10_面试模拟_项目讲解话术](./10_面试模拟_项目讲解话术.md)

---



> 读完这章，你能回答：
> - "为什么不直接 HTTP 调用，要用消息队列？"
> - "Kafka 的 Topic、Producer、Consumer 是什么？"
> - "消息丢了怎么办？重复消费怎么办？"
>
> ⚠️ JD 用 Kafka 是标配，这是重点考察区域！

---

## 📖 Part 1：从你懂的 Java 出发

### 先理解一个问题：下单之后要做什么？

```
用户在京东下了一个订单：
  
  ① 创建订单记录        → order-service 负责
  ② 扣减库存            → product-service 负责
  ③ 创建支付记录        → payment-service 负责
  ④ 发确认邮件          → email-service 负责
```

### 方案一：全部同步调用（依次等待）

```java
// order-service 里这样做：
public void createOrder(OrderDTO orderDTO) {
    orderRepo.save(order);                    // 存订单，10ms
    productClient.reduceStock(items);         // 等 product-service 扣库存，50ms
    paymentClient.createPayment(order);       // 等 payment-service 创建支付，80ms
    emailClient.sendConfirmation(email);      // 等 email-service 发邮件，2000ms
    //                                         总共：2140ms 用户一直在等！
}
```

**问题：**
- 🔴 用户要等 2 秒多才看到结果！（发邮件很慢）
- 🔴 如果 email-service 挂了 → 整个下单失败（但其实邮件可以之后再发）
- 🔴 所有服务紧耦合（任何一个挂了都得全挂）

---

### 方案二：用消息队列（异步通知）

```java
// order-service 里这样做：
public void createOrder(OrderDTO orderDTO) {
    orderRepo.save(order);                    // 存订单，10ms
    kafkaProducer.send(orderEvent);           // 发一条消息到 Kafka，3ms
    //                                         总共：13ms！用户秒回！
}

// 然后 Kafka 在后台把消息分发给各个服务：
// payment-service 收到消息 → 自己慢慢处理支付
// product-service 收到消息 → 自己慢慢扣库存
// email-service 收到消息   → 自己慢慢发邮件
```

**好处：**
- ✅ 用户只等 13ms
- ✅ email-service 挂了？消息在 Kafka 排队等着，恢复后继续处理
- ✅ 服务之间解耦：order-service 不需要知道有哪些服务在消费消息

---

### 消息队列 = 快递柜

```
没有快递柜（同步调用）：
  快递员必须等你开门 → 你不在家 → 快递员一直等 → 其他快递送不了
  
有了快递柜（消息队列）：
  快递员把包裹放进快递柜 → 走了 → 你什么时候有空什么时候取
  快递员（Producer）不用等你（Consumer）
  快递柜（Kafka）暂时存着这个包裹（Message）
```

---

## 💻 Part 2：在这个项目里怎么用？

### Kafka 核心概念

```
Producer（生产者）  →  Topic（主题）  →  Consumer（消费者）

Producer = 发消息的人（order-service）
Topic    = 消息分类（order-created, payment-result 等）
Consumer = 收消息的人（payment-service, email-service）

一个 Topic 可以有多个 Consumer：
  order-created-topic
    ├── Consumer 1: payment-service（处理支付）
    ├── Consumer 2: product-service（扣库存）
    └── Consumer 3: email-service（发邮件）

三个服务各自独立消费，互不影响！
```

---

### 1. Producer（发消息的人）

```java
// 路径：order-service/.../kafka/OrderProducer.java

@Service
@RequiredArgsConstructor
public class OrderProducer {

    // KafkaTemplate = Spring 提供的 Kafka 工具类
    // <String, OrderEvent> = 消息的 key 和 value 类型
    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;

    @Value("${spring.kafka.create-order-topic.name}")
    private String orderTopic;  // Topic 名字，从配置文件读

    public void sendOrderEvent(OrderEvent orderEvent) {
        // 就这一行！把消息发到 Kafka
        kafkaTemplate.send(orderTopic, orderEvent);
        // 参数1: Topic 名字（比如 "order-created"）
        // 参数2: 消息内容（OrderEvent 对象，自动转成 JSON）
    }
}
```

**在 Service 层调用：**
```java
// 路径：order-service/.../service/impl/OrderServiceImpl.java

public void placeOrder(OrderDTO orderDTO) {
    // 1. 保存订单到数据库
    Order order = orderRepo.save(createOrder(orderDTO));
    
    // 2. 构建 Kafka 消息
    OrderEvent orderEvent = new OrderEvent();
    orderEvent.setStatus("PENDING");
    orderEvent.setMessage("Order created");
    orderEvent.setOrderDTO(orderDTO);
    
    // 3. 发送到 Kafka → 马上返回，不等消费者处理
    orderProducer.sendOrderEvent(orderEvent);
    
    // 用户此时已经收到了"下单成功"的响应
    // payment-service 在后台慢慢处理支付
}
```

---

### 2. Consumer（收消息的人）

```java
// 路径：payment-service/.../kafka/OrderConsumer.java

@Component
@RequiredArgsConstructor
public class OrderConsumer {

    private final PaymentService paymentService;

    @KafkaListener(
        topics = "${spring.kafka.create-order-topic.name}",  // 监听哪个 Topic
        groupId = "${spring.kafka.consumer.group-id}"        // 消费者组
    )
    // ↑ 这个注解的意思是：
    //   "一直监听 order-created 这个 Topic，有新消息就调用这个方法"
    
    public void consume(OrderEvent orderEvent) {
        // Kafka 收到新消息时，自动调用这个方法
        // orderEvent 是 Kafka 消息里的内容，自动从 JSON 转成 Java 对象
        
        log.info("Received order event: {}", orderEvent);
        paymentService.createPayment(orderEvent);
        // 创建支付记录，完全异步，不影响用户的订单操作
    }
}
```

```java
// 路径：product-service/.../kafka/consumer/OrderConsumer.java

@Component
@RequiredArgsConstructor
public class OrderConsumer {

    private final ProductVariantService productVariantService;

    @KafkaListener(
        topics = "${spring.kafka.create-order-topic.name}",
        groupId = "${spring.kafka.consumer.group-id}"  // 注意：group-id 不同！
    )
    @Transactional
    public void consume(OrderEvent orderEvent) {
        // 同一个消息，product-service 也收到了
        // 但它做的事不同：扣减库存
        OrderDTO orderDTO = orderEvent.getOrderDTO();
        for (OrderItemDTO item : orderDTO.getOrderItems()) {
            Long variantId = item.getVariantId();
            int quantity = item.getQuantity();
            // 从库存中扣减
            productVariantService.reduceStock(variantId, quantity);
        }
    }
}
```

---

### 3. Consumer Group（消费者组）—— 面试高频

```
概念：同一个 Consumer Group 中的 Consumer，
     每条消息只会被其中一个消费。

场景：假设 order-created-topic 有一条新消息

payment-service（group: "payment-group"）
  payment-instance-1  ← 收到消息（同组只有一个收到）
  payment-instance-2  ← 没有收到

product-service（group: "product-group"）
  product-instance-1  ← 收到消息（另一个组也收到了）

email-service（group: "email-group"）
  email-instance-1    ← 收到消息（又一个组也收到了）

结论：
  不同 Group → 都能收到（广播效果）
  同一 Group → 只有一个实例收到（负载均衡效果）
```

---

### 4. 配置文件

```yaml
# order-service/application.yml（Producer 配置）
spring:
  kafka:
    bootstrap-servers: kafka:9092   # Kafka 的地址
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
      #                 ↑ 把 Java 对象序列化成 JSON 发出去
    create-order-topic:
      name: order-created           # Topic 名字

# payment-service/application.yml（Consumer 配置）
spring:
  kafka:
    bootstrap-servers: kafka:9092
    consumer:
      group-id: payment-group       # 消费者组名
      auto-offset-reset: earliest   # 从最早的消息开始消费
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: '*'  # 信任所有包（反序列化用）
```

---

### 5. 消息可靠性 —— 面试必问

**消息丢失问题：**
```
① Producer 发消息丢失：
   → 解决：acks=all，所有 Kafka 副本确认才算成功

② Kafka 自己丢消息：
   → 解决：replication.factor=3，消息存 3 份

③ Consumer 处理前崩溃：
   → 解决：关闭自动提交 offset，处理完才手动提交
```

**重复消费问题：**
```
场景：Consumer 处理完消息，还没提交 offset 就崩溃了
     → 重启后 Kafka 不知道已经处理过 → 再发一次 → 重复了！

解决：幂等性处理
  if (paymentRepo.existsByOrderId(orderId)) {
      return; // 已经处理过了，跳过
  }
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 为什么选 Kafka 而不是直接 HTTP 调用？**

> 🗣️ "三个原因：第一是解耦，下单服务不需要知道有哪些下游服务在消费；
> 第二是异步，发邮件这种慢操作不应该让用户等待；
> 第三是削峰，大促时订单量瞬间暴增，Kafka 可以缓存消息，
> 下游服务按自己的速度处理，不会被压垮。"

---

**Q: Kafka 怎么保证消息不丢失？**

> 🗣️ "三个层面：Producer 端设置 acks=all 确保所有副本确认；
> Broker 端设置 replication.factor 不低于3做多副本冗余；
> Consumer 端关闭自动提交 offset，业务处理成功后手动提交。"

---

**Q: Consumer Group 是什么？有什么用？**

> 🗣️ "同一个 Consumer Group 内的消费者分摊 Topic 的 Partition，
> 每条消息只被组内一个消费者处理，实现负载均衡。
> 不同 Group 各自独立消费，实现广播效果。
> 在我的项目里，payment-service 和 email-service 属于不同 Group，
> 所以下单事件两个服务都能收到，各自处理各自的逻辑。"

---

**Q: 怎么处理重复消费？**

> 🗣️ "通过幂等性设计。在消费者端，先查数据库看这条消息对应的
> 业务是否已经处理过。比如收到创建支付的消息时，
> 先查 existsByOrderId，如果已存在就跳过。
> 也可以用 Redis 记录已处理的消息 ID 来去重。"

---

## ✅ 第七章检查清单

- [ ] 能说清楚为什么要用消息队列（解耦、异步、削峰）
- [ ] 知道 Producer、Consumer、Topic、Consumer Group 的概念
- [ ] 能看懂项目里的 Kafka Producer 和 Consumer 代码
- [ ] 知道消息丢失和重复消费的解决方案

✅ 全部搞定 → 去看第八章（JWT 身份认证）！



---

## 📚 全部章节导航

- [00_从零开始学Spring Boot](./00_从零开始学Spring Boot.md)
- [01_Spring_Boot是什么](./01_Spring_Boot是什么.md)
- [02_三层架构_MVC](./02_三层架构_MVC.md)
- [03_依赖注入_IOC](./03_依赖注入_IOC.md)
- [04_数据库_JPA_MySQL](./04_数据库_JPA_MySQL.md)
- [05_REST_API设计](./05_REST_API设计.md)
- [06_微服务是什么](./06_微服务是什么.md)
- [07_Kafka消息队列](./07_Kafka消息队列.md)
- [08_JWT身份认证](./08_JWT身份认证.md)
- [09_Docker容器化](./09_Docker容器化.md)
- [10_面试模拟_项目讲解话术](./10_面试模拟_项目讲解话术.md)

---
