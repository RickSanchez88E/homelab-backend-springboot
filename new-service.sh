#!/bin/bash
# ============================================================
# 🛠️ Spring Boot 微服务脚手架生成器
# 用法: ./new-service.sh <服务名> <端口> <数据库端口>
# 例如: ./new-service.sh review 8086 3312
# ============================================================

set -e

SERVICE_NAME=${1:?"❌ 用法: ./new-service.sh <服务名> <端口> <数据库端口>\n例如: ./new-service.sh review 8086 3312"}
PORT=${2:?"❌ 请指定服务端口，如 8086"}
DB_PORT=${3:?"❌ 请指定数据库端口，如 3312"}

# 自动生成各种名称格式
SERVICE_LOWER=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]')
SERVICE_UPPER=$(echo "$SERVICE_NAME" | tr '[:lower:]' '[:upper:]')
SERVICE_PASCAL=$(echo "$SERVICE_NAME" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
SERVICE_DIR="${SERVICE_LOWER}-service"
PACKAGE_NAME="${SERVICE_LOWER}_service"
DB_NAME="${SERVICE_LOWER}_db"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="${PROJECT_ROOT}/${SERVICE_DIR}"
JAVA_DIR="${BASE_DIR}/src/main/java/net/javaguides/${PACKAGE_NAME}"
RES_DIR="${BASE_DIR}/src/main/resources"
TEST_DIR="${BASE_DIR}/src/test/java/net/javaguides/${PACKAGE_NAME}"

echo "🚀 创建微服务: ${SERVICE_DIR}"
echo "   端口: ${PORT}"
echo "   数据库: ${DB_NAME} (端口 ${DB_PORT})"
echo ""

# ============================================================
# 创建目录结构
# ============================================================
mkdir -p "${JAVA_DIR}/controller"
mkdir -p "${JAVA_DIR}/service/impl"
mkdir -p "${JAVA_DIR}/repository"
mkdir -p "${JAVA_DIR}/entity"
mkdir -p "${JAVA_DIR}/dto"
mkdir -p "${JAVA_DIR}/config"
mkdir -p "${RES_DIR}"
mkdir -p "${TEST_DIR}"

echo "📁 目录结构已创建"

# ============================================================
# pom.xml
# ============================================================
cat > "${BASE_DIR}/pom.xml" << 'POMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.3</version>
        <relativePath/>
    </parent>

    <groupId>net.javaguides</groupId>
POMEOF

cat >> "${BASE_DIR}/pom.xml" << EOF
    <artifactId>${SERVICE_DIR}</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>${SERVICE_DIR}</name>
    <description>${SERVICE_PASCAL} Service</description>
EOF

cat >> "${BASE_DIR}/pom.xml" << 'POMEOF'

    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.3</spring-cloud.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>1.18.38</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
POMEOF

echo "📦 pom.xml 已创建"

# ============================================================
# Application.java
# ============================================================
cat > "${JAVA_DIR}/${SERVICE_PASCAL}ServiceApplication.java" << EOF
package net.javaguides.${PACKAGE_NAME};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class ${SERVICE_PASCAL}ServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(${SERVICE_PASCAL}ServiceApplication.class, args);
    }
}
EOF

echo "🚀 ${SERVICE_PASCAL}ServiceApplication.java 已创建"

# ============================================================
# Entity
# ============================================================
cat > "${JAVA_DIR}/entity/${SERVICE_PASCAL}.java" << EOF
package net.javaguides.${PACKAGE_NAME}.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "${SERVICE_LOWER}s")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ${SERVICE_PASCAL} {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    // TODO: 添加你的业务字段
    @Column(nullable = false)
    private String name;

    private String description;

    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}
EOF

echo "🗄️  ${SERVICE_PASCAL}.java (Entity) 已创建"

# ============================================================
# Repository
# ============================================================
cat > "${JAVA_DIR}/repository/${SERVICE_PASCAL}Repository.java" << EOF
package net.javaguides.${PACKAGE_NAME}.repository;

import net.javaguides.${PACKAGE_NAME}.entity.${SERVICE_PASCAL};
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ${SERVICE_PASCAL}Repository extends JpaRepository<${SERVICE_PASCAL}, String> {

    // TODO: 添加自定义查询方法
    // 例: List<${SERVICE_PASCAL}> findByName(String name);
}
EOF

echo "📊 ${SERVICE_PASCAL}Repository.java 已创建"

# ============================================================
# DTO
# ============================================================
cat > "${JAVA_DIR}/dto/${SERVICE_PASCAL}Request.java" << EOF
package net.javaguides.${PACKAGE_NAME}.dto;

import lombok.Data;

@Data
public class ${SERVICE_PASCAL}Request {
    // TODO: 添加前端传入的字段（不包含 id 和 createdAt）
    private String name;
    private String description;
}
EOF

echo "📝 ${SERVICE_PASCAL}Request.java (DTO) 已创建"

# ============================================================
# Service Interface
# ============================================================
cat > "${JAVA_DIR}/service/${SERVICE_PASCAL}Service.java" << EOF
package net.javaguides.${PACKAGE_NAME}.service;

import net.javaguides.${PACKAGE_NAME}.dto.${SERVICE_PASCAL}Request;
import net.javaguides.${PACKAGE_NAME}.entity.${SERVICE_PASCAL};
import java.util.List;

public interface ${SERVICE_PASCAL}Service {
    ${SERVICE_PASCAL} create(${SERVICE_PASCAL}Request request);
    ${SERVICE_PASCAL} getById(String id);
    List<${SERVICE_PASCAL}> getAll();
    void deleteById(String id);
}
EOF

echo "🔌 ${SERVICE_PASCAL}Service.java (接口) 已创建"

# ============================================================
# Service Implementation
# ============================================================
cat > "${JAVA_DIR}/service/impl/${SERVICE_PASCAL}ServiceImpl.java" << EOF
package net.javaguides.${PACKAGE_NAME}.service.impl;

import lombok.RequiredArgsConstructor;
import net.javaguides.${PACKAGE_NAME}.dto.${SERVICE_PASCAL}Request;
import net.javaguides.${PACKAGE_NAME}.entity.${SERVICE_PASCAL};
import net.javaguides.${PACKAGE_NAME}.repository.${SERVICE_PASCAL}Repository;
import net.javaguides.${PACKAGE_NAME}.service.${SERVICE_PASCAL}Service;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ${SERVICE_PASCAL}ServiceImpl implements ${SERVICE_PASCAL}Service {

    private final ${SERVICE_PASCAL}Repository ${SERVICE_LOWER}Repository;

    @Override
    public ${SERVICE_PASCAL} create(${SERVICE_PASCAL}Request request) {
        ${SERVICE_PASCAL} entity = new ${SERVICE_PASCAL}();
        entity.setName(request.getName());
        entity.setDescription(request.getDescription());
        // TODO: 设置其他字段
        return ${SERVICE_LOWER}Repository.save(entity);
    }

    @Override
    public ${SERVICE_PASCAL} getById(String id) {
        return ${SERVICE_LOWER}Repository.findById(id)
                .orElseThrow(() -> new RuntimeException("${SERVICE_PASCAL} not found: " + id));
    }

    @Override
    public List<${SERVICE_PASCAL}> getAll() {
        return ${SERVICE_LOWER}Repository.findAll();
    }

    @Override
    public void deleteById(String id) {
        ${SERVICE_LOWER}Repository.deleteById(id);
    }
}
EOF

echo "⚙️  ${SERVICE_PASCAL}ServiceImpl.java (实现) 已创建"

# ============================================================
# Controller
# ============================================================
cat > "${JAVA_DIR}/controller/${SERVICE_PASCAL}Controller.java" << EOF
package net.javaguides.${PACKAGE_NAME}.controller;

import lombok.RequiredArgsConstructor;
import net.javaguides.${PACKAGE_NAME}.dto.${SERVICE_PASCAL}Request;
import net.javaguides.${PACKAGE_NAME}.entity.${SERVICE_PASCAL};
import net.javaguides.${PACKAGE_NAME}.service.${SERVICE_PASCAL}Service;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/${SERVICE_LOWER}s")
@RequiredArgsConstructor
public class ${SERVICE_PASCAL}Controller {

    private final ${SERVICE_PASCAL}Service ${SERVICE_LOWER}Service;

    @PostMapping
    public ResponseEntity<${SERVICE_PASCAL}> create(@RequestBody ${SERVICE_PASCAL}Request request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(${SERVICE_LOWER}Service.create(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<${SERVICE_PASCAL}> getById(@PathVariable String id) {
        return ResponseEntity.ok(${SERVICE_LOWER}Service.getById(id));
    }

    @GetMapping
    public ResponseEntity<List<${SERVICE_PASCAL}>> getAll() {
        return ResponseEntity.ok(${SERVICE_LOWER}Service.getAll());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<String> delete(@PathVariable String id) {
        ${SERVICE_LOWER}Service.deleteById(id);
        return ResponseEntity.ok("Deleted successfully");
    }
}
EOF

echo "🌐 ${SERVICE_PASCAL}Controller.java 已创建"

# ============================================================
# application.yml
# ============================================================
cat > "${RES_DIR}/application.yml" << EOF
server:
  port: ${PORT}

spring:
  application:
    name: ${SERVICE_UPPER}-SERVICE

  datasource:
    url: jdbc:mysql://localhost:${DB_PORT}/${DB_NAME}
    username: root
    password: root
    driver-class-name: com.mysql.cj.jdbc.Driver

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
EOF

echo "📋 application.yml 已创建"

# ============================================================
# Dockerfile
# ============================================================
cat > "${BASE_DIR}/Dockerfile" << EOF
FROM eclipse-temurin:17-jre-alpine
COPY target/${SERVICE_DIR}-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

echo "🐳 Dockerfile 已创建"

# ============================================================
# 完成！
# ============================================================
echo ""
echo "============================================"
echo "✅ ${SERVICE_DIR} 创建完成！"
echo "============================================"
echo ""
echo "📂 结构:"
find "${BASE_DIR}" -type f | sed "s|${PROJECT_ROOT}/||" | sort | head -20
echo ""
echo "📌 接下来你要做的:"
echo "  1. 修改 Entity 字段（entity/${SERVICE_PASCAL}.java）"
echo "  2. 修改 DTO 字段（dto/${SERVICE_PASCAL}Request.java）"
echo "  3. 修改 Service 业务逻辑"
echo "  4. 在 api-gateway/application.yml 加路由:"
echo ""
echo "     - id: ${SERVICE_DIR}"
echo "       uri: lb://${SERVICE_UPPER}-SERVICE"
echo "       predicates:"
echo "         - Path=/api/v1/${SERVICE_LOWER}s/**"
echo ""
echo "  5. 构建: cd ${SERVICE_DIR} && mvn clean package -DskipTests"
echo "  6. 运行: mvn spring-boot:run"
echo ""
