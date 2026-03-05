# 第五章：REST API 设计 —— 前后端怎么对话

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
> - "什么是 REST API？"
> - "GET / POST / PUT / DELETE 有什么区别？"
> - "HTTP 状态码 200、404、500 是什么意思？"
> - "前端怎么调你的 API？"

---

## 📖 Part 1：从你懂的 Java 出发

### 什么叫"前后端分离"？

```
你以前写的 Java 程序：
  输入 → 控制台打印结果
  用户界面和业务逻辑混在一起

现在的做法：
  前端（浏览器/App）←→ HTTP 请求/响应 ←→ 后端（你的 Spring Boot）
  两个独立的程序，通过"约定好的规则"通信
  
这个"约定好的规则" = REST API
```

### REST 就是用 URL + HTTP 动词描述操作

```
传统 URL（不 REST）：
  /getUser?id=123           ← 动词在 URL 里
  /createUser               ← 动词在 URL 里
  /deleteUser?id=123        ← 动词在 URL 里

REST 风格 URL：
  GET    /users/123         ← 获取用户（HTTP 动词说明操作）
  POST   /users             ← 创建用户
  PUT    /users/123         ← 更新用户
  DELETE /users/123         ← 删除用户
  
资源（users）是名词，操作用 HTTP 动词表达。
```

---

## 💻 Part 2：在这个项目里怎么用？

### HTTP 动词对照表

| HTTP 动词 | 含义 | 项目例子 | 对应数据库操作 |
|-----------|------|----------|---------------|
| GET | 查询 | `GET /api/v1/payments/order123` | SELECT |
| POST | 创建 | `POST /api/v1/orders` | INSERT |
| PUT | 更新 | `PUT /api/v1/payments/refund/pay123` | UPDATE |
| DELETE | 删除 | `DELETE /api/v1/products/prod123` | DELETE |

### 看真实的 Controller 代码

```java
// 路径：order-service/.../controller/OrderController.java

@RestController                   // REST 控制器
@RequestMapping("/api/v1/orders") // 基础路径
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    // ===== 创建订单 =====
    // 前端发 POST 请求到 /api/v1/orders
    // 请求体是 JSON 格式的订单数据
    @PostMapping
    public ResponseEntity<?> placeOrder(
            @RequestBody OrderDTO orderDTO,       // 从请求体取 JSON
            @RequestHeader("Authorization") String token  // 从请求头取 JWT
    ) {
        orderService.placeOrder(orderDTO);
        return ResponseEntity
            .status(HttpStatus.CREATED)   // HTTP 201：创建成功
            .body("Order placed successfully");
    }

    // ===== 查询订单 =====
    // 前端发 GET 请求到 /api/v1/orders/abc123
    @GetMapping("/{orderId}")
    public ResponseEntity<?> getOrder(
            @PathVariable String orderId   // 从 URL 路径取值
    ) {
        return ResponseEntity.ok(          // HTTP 200：成功
            orderService.checkOrderStatusByOrderId(orderId)
        );
    }

    // ===== 更新订单状态 =====
    // 前端发 PUT 请求到 /api/v1/orders/abc123/status/2
    @PutMapping("/{orderId}/status/{status}")
    public ResponseEntity<?> updateOrderStatus(
            @PathVariable String orderId,
            @PathVariable int status
    ) {
        return ResponseEntity.ok(
            orderService.updateOrderStatus(orderId, status)
        );
    }
}
```

---

### 请求和响应长什么样？

```
前端发出的 POST 请求：
┌────────────────────────────────────────────┐
│ POST /api/v1/orders HTTP/1.1              │ ← 请求行
│ Host: localhost:9191                       │ ← 请求头
│ Content-Type: application/json            │
│ Authorization: Bearer eyJhbGciOiJ...      │ ← JWT Token
│                                            │
│ {                                          │ ← 请求体（JSON）
│   "userId": "user123",                    │
│   "orderItems": [                         │
│     {                                      │
│       "productId": "prod-001",            │
│       "variantId": 5,                     │
│       "quantity": 2,                      │
│       "price": 29.99                      │
│     }                                      │
│   ]                                        │
│ }                                          │
└────────────────────────────────────────────┘

后端返回的响应：
┌────────────────────────────────────────────┐
│ HTTP/1.1 201 Created                       │ ← 状态码
│ Content-Type: application/json            │
│                                            │
│ {                                          │ ← 响应体（JSON）
│   "orderId": "abc123",                    │
│   "status": "PENDING",                    │
│   "message": "Order placed successfully"  │
│ }                                          │
└────────────────────────────────────────────┘
```

---

### HTTP 状态码（必背！）

```
2xx 成功：
  200 OK              → 一切正常
  201 Created         → 创建资源成功（POST 用）
  204 No Content      → 成功但没有返回内容（DELETE 用）

4xx 客户端错误（前端搞错了）：
  400 Bad Request     → 请求格式不对（缺字段、类型错）
  401 Unauthorized    → 没登录 / Token 无效
  403 Forbidden       → 登录了但没权限
  404 Not Found       → 找不到资源

5xx 服务端错误（你的代码出 bug 了）：
  500 Internal Error  → 服务器内部错误
  503 Service Unavailable → 服务暂不可用
```

---

### @RequestBody vs @PathVariable vs @RequestParam

```java
// ① @PathVariable — 从 URL 路径中取值
@GetMapping("/orders/{orderId}")
public Order getOrder(@PathVariable String orderId) { ... }
// 请求：GET /orders/abc123 → orderId = "abc123"

// ② @RequestBody — 从请求体取 JSON 对象
@PostMapping("/orders")
public Order createOrder(@RequestBody OrderDTO orderDTO) { ... }
// 请求：POST /orders，body: {"userId": "u1", "items": [...]}
// Spring 自动把 JSON → Java 对象（用 Jackson 库）

// ③ @RequestParam — 从 URL 查询参数取值
@GetMapping("/orders")
public List<Order> search(@RequestParam String status) { ... }
// 请求：GET /orders?status=PAID → status = "PAID"
```

---

### ResponseEntity：控制 HTTP 响应

```java
// 成功返回数据
return ResponseEntity.ok(payment);              // 200 + 数据

// 创建成功
return ResponseEntity.status(HttpStatus.CREATED) // 201
    .body(newOrder);

// 找不到
return ResponseEntity.notFound().build();        // 404

// 自定义
return ResponseEntity
    .status(HttpStatus.BAD_REQUEST)              // 400
    .body("Order ID is required");
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: 你的项目 API 是怎么设计的？**

> 🗣️ "我们采用 RESTful 风格，URL 使用名词表示资源，
> HTTP 动词表示操作。比如商品用 `/api/v1/products`，
> GET 查询、POST 创建、PUT 更新、DELETE 删除。
> 所有请求通过 API Gateway 统一入口，
> 网关按路径前缀转发到对应微服务。"

---

**Q: @RestController 和 @Controller 什么区别？**

> 🗣️ "@Controller 返回视图名称（HTML 页面），
> 需要配合模板引擎使用。
> @RestController 等于 @Controller + @ResponseBody，
> 每个方法的返回值自动序列化为 JSON 响应体。
> 在前后端分离的项目里用 @RestController。"

---

**Q: POST 和 PUT 有什么区别？**

> 🗣️ "POST 用来创建新资源，是非幂等的，
> 调 10 次可能创建 10 个订单。
> PUT 用来更新已有资源，是幂等的，
> 调 10 次效果和调 1 次一样。
> 在我的项目里，创建订单用 POST，更新订单状态用 PUT。"

---

## ✅ 第五章检查清单

- [ ] 能解释 REST API 的核心思想
- [ ] 知道 GET/POST/PUT/DELETE 各自的用途
- [ ] 认识 @PathVariable、@RequestBody、@RequestParam
- [ ] 知道常见 HTTP 状态码的含义
- [ ] 能看懂 Controller 代码并说出它做了什么

✅ 全部搞定 → 去看第六章（微服务）！



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
