# 第八章：JWT 身份认证 —— 怎么知道你是谁

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
> - "Session 和 JWT 有什么区别？"
> - "JWT Token 里面有什么？"
> - "你的项目怎么做身份认证的？"

---

## 📖 Part 1：从你懂的 Java 出发

### 为什么需要身份认证？

```
HTTP 是"无状态"的。什么意思？

请求1：GET /orders  ← 我是谁？服务器不知道！
请求2：GET /orders  ← 还是我！服务器还是不知道！

每次请求对服务器来说都是"陌生人"。
怎么让服务器知道"这个请求是已经登录过的用户发的"？
```

### 方案一：Session（传统方式）

```
1. 用户登录 → 服务器创建一个 Session（存在服务器内存里）
   Session = { userId: "u123", role: "USER" }
   生成 SessionID: "abc123"

2. 服务器把 SessionID 通过 Cookie 发给浏览器

3. 之后每次请求，浏览器自动带上 Cookie: sessionid=abc123
   服务器收到 → 去内存里查 abc123 → 找到了 → 知道你是 u123

问题：
  🔴 Session 存在服务器内存里 → 多个服务器怎么共享？
  🔴 微服务有 7 个服务 → 每个服务都要存 Session？
  🔴 用户量大了 → 服务器内存装不下！
```

### 方案二：JWT（本项目使用的方式）

```
1. 用户登录 → 服务器生成一个 Token（字符串），发给用户
   Token 里面包含了用户信息（加密过的），服务器不需要存！

2. 之后每次请求，用户在 Header 里带上  
   Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

3. 任何服务收到请求 → 解密 Token → 就知道用户是谁
   不需要查数据库！不需要共享 Session！

   identity-service 能验证 ✅
   order-service 也能验证 ✅
   每个服务自己解密就行！
```

---

## 💻 Part 2：在这个项目的代码里

### JWT Token 长什么样？

```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNzA5NzI2NDAwfQ.abc123signature

三段用 . 分隔：

第一段（Header）：加密算法
  {"alg": "HS256"}

第二段（Payload）：用户数据（Base64编码，不是加密！）
  {
    "sub": "test@example.com",       ← 用户标识
    "email": "test@example.com",
    "permissions": ["CUSTOMER"],     ← 权限
    "iat": 1709640000,               ← 签发时间
    "exp": 1709726400                ← 过期时间（24h后）
  }

第三段（Signature）：签名（防篡改）
  HMAC-SHA256(header + payload, 密钥)
  ← 改了 payload → 签名对不上 → 验证失败！
```

---

### 1. 登录流程（生成 Token）

```java
// 路径：identity-service/.../service/impl/JwtServiceImpl.java

@Service
public class JwtServiceImpl implements JwtService {

    @Value("${application.security.jwt.secret-key}")
    private String secretKey;  // 密钥（只有服务器知道！）

    @Value("${application.security.jwt.expiration}")
    private long jwtExpiration;  // 过期时间：86400000ms = 24小时

    public String generateToken(UserDetails userDetails) {
        CustomUserDetails user = (CustomUserDetails) userDetails;
        
        return Jwts.builder()
            .subject(user.getUsername())             // 设置用户名
            .claim("email", user.getEmail())         // 自定义字段
            .claim("permissions", user.getPermissions())  // 权限
            .issuedAt(new Date())                    // 签发时间
            .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
            .signWith(getSigningKey())               // 用密钥签名
            .compact();                              // 生成字符串
    }
    
    // 密钥
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(secretKey));
    }
}
```

---

### 2. 验证 Token（每个请求都要验证）

```java
// 路径：api-gateway/.../filter/JwtAuthenticationFilter.java

// API Gateway 的 JWT 过滤器
// 每个请求到达时，先经过这个过滤器
@Component
public class JwtAuthenticationFilter implements GlobalFilter {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        
        // 1. 有些路径不需要验证（登录、注册）
        String path = exchange.getRequest().getPath().toString();
        if (path.contains("/auth/token") || path.contains("/auth/register")) {
            return chain.filter(exchange);  // 直接放行
        }
        
        // 2. 从 Header 取出 Token
        String authHeader = exchange.getRequest()
            .getHeaders().getFirst("Authorization");
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            // 没有 Token → 401 未授权
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        
        String token = authHeader.substring(7);  // 去掉 "Bearer " 前缀
        
        // 3. 验证 Token
        if (jwtService.isTokenValid(token)) {
            // Token 有效 → 放行，继续转发给下游服务
            return chain.filter(exchange);
        } else {
            // Token 无效/过期 → 401
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }
}
```

---

### 3. 完整登录流程

```
用户注册：
  POST /api/v1/auth/register
  Body: {"name":"Rick", "email":"rick@jd.com", "password":"123456"}
  
  → identity-service 收到
  → 密码加密（BCrypt）存入数据库
  → 返回 "注册成功"

用户登录：
  POST /api/v1/auth/token
  Body: {"username":"Test User", "password":"password123"}
  ⚠️ 注意：端点是 /token 不是 /login，username 用注册时的 name 字段不是 email！
  
  → identity-service 收到
  → 查数据库找到用户
  → 验证密码（BCrypt 对比）
  → 生成 JWT Token
  → 返回 {"token": "eyJhbGciOi..."}

之后的请求：
  GET /api/v1/orders
  Header: Authorization: Bearer eyJhbGciOi...
  
  → API Gateway 收到
  → JwtAuthenticationFilter 验证 Token
  → Token 有效 → 转发给 order-service
  → order-service 处理请求并返回
```

---

### 4. 密码加密（BCrypt）

```java
// identity-service 里的密码处理

// 注册时：明文密码 → 加密后存储
String rawPassword = "123456";
String encrypted = passwordEncoder.encode(rawPassword);
// encrypted = "$2a$10$N9qo8uLOickgx2ZMRZoMye..."
// 每次加密结果不同（有随机盐值）！

// 登录时：用户输入密码 → 和数据库里的密文对比
boolean matches = passwordEncoder.matches("123456", encrypted);
// true → 密码正确

// 为什么不存明文？
// 如果数据库泄露 → 所有用户密码暴露！
// BCrypt 不可逆 → 拿到密文也推不出原文
```

---

## 🎤 Part 3：面试官会怎么问？

---

**Q: Session 和 JWT 有什么区别？**

> 🗣️ "Session 是服务端存储用户状态，用 SessionID 关联；
> JWT 是把用户信息编码在 Token 里，服务端不存储。
> Session 适合单体应用，JWT 适合微服务，
> 因为每个服务可以独立验证 Token，不需要共享 Session 存储。
> 我的项目用 JWT 就是因为有 7 个微服务，
> 在 API Gateway 层统一验证，下游服务不需要再验证。"

---

**Q: JWT 有什么缺点？**

> 🗣️ "主要两个：第一，Token 一旦签发在过期前无法主动吊销，
> 用户退出登录后 Token 仍然有效。
> 解决方案可以用黑名单（Redis 存已吊销的 Token）。
> 第二，Payload 是 Base64 编码不是加密，
> 所以不能放敏感信息。"

---

**Q: 你项目里的认证流程是怎样的？**

> 🗣️ "用户通过 identity-service 的 /auth/token 接口登录，
> 验证用户名密码后生成 JWT Token 返回。
> 之后的请求都在 Header 里携带 Token。
> API Gateway 有一个全局 JwtAuthenticationFilter，
> 每个请求先验证 Token 有效性，有效才转发到下游服务，
> 无效直接返回 401。"

---

## ✅ 第八章检查清单

- [ ] 能说清楚 Session vs JWT 的区别和选择
- [ ] 知道 JWT Token 的三段结构
- [ ] 能描述登录 → 生成Token → 验证Token 的完整流程
- [ ] 知道 BCrypt 密码加密的作用

✅ 全部搞定 → 去看第九章（Docker 容器化）！



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
