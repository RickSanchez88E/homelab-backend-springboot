#!/bin/bash
# ============================================================
# 🏭 数据填充脚本 — 模拟真实电商数据
# 用法: ./scripts/seed-data.sh [数据量级]
#   small  → 每个表 1,000 条     (开发调试)
#   medium → 每个表 100,000 条   (性能测试)
#   large  → 每个表 1,000,000 条 (压力测试)
# ============================================================

set -e

LEVEL=${1:-"small"}

case $LEVEL in
    small)  PRODUCTS=1000;   REVIEWS=5000 ;;
    medium) PRODUCTS=100000; REVIEWS=500000 ;;
    large)  PRODUCTS=1000000;REVIEWS=5000000 ;;
    *) echo "用法: ./scripts/seed-data.sh [small|medium|large]"; exit 1 ;;
esac

echo "🏭 数据填充: $LEVEL 级别"
echo "  Products: $PRODUCTS"
echo "  Reviews:  $REVIEWS"
echo ""

# ============================================================
# 生成批量 INSERT SQL 文件（最快的方式）
# ============================================================

BATCH=1000  # 每条 INSERT 1000 行

# --- Products ---
echo "📦 生成商品数据 SQL ($PRODUCTS 条)..."
TMPFILE="/tmp/seed_products.sql"
echo "SET autocommit=0;" > "$TMPFILE"

i=0
while [ $i -lt $PRODUCTS ]; do
    echo -n "INSERT INTO products (id, name, description, price, quantity) VALUES " >> "$TMPFILE"
    j=0
    while [ $j -lt $BATCH ] && [ $((i+j)) -lt $PRODUCTS ]; do
        IDX=$((i+j))
        PRICE=$(awk "BEGIN{printf \"%.2f\", 10 + rand()*990}")
        QTY=$((RANDOM % 10000 + 1))
        [ $j -gt 0 ] && echo -n "," >> "$TMPFILE"
        echo -n "(UUID(),'Product-$(printf '%07d' $IDX)','High quality item #$IDX',$PRICE,$QTY)" >> "$TMPFILE"
        j=$((j+1))
    done
    echo ";" >> "$TMPFILE"
    echo "COMMIT;" >> "$TMPFILE"
    i=$((i+BATCH))
done

echo "  📄 SQL 已生成，导入中..."
docker cp "$TMPFILE" mysql-product-service:/tmp/seed.sql
docker exec mysql-product-service mysql -uroot -proot product_db -e "source /tmp/seed.sql" 2>/dev/null
PRODUCT_COUNT=$(docker exec mysql-product-service mysql -uroot -proot -N -e "SELECT COUNT(*) FROM product_db.products;" 2>/dev/null)
echo "  ✅ 商品: $PRODUCT_COUNT 条"

# --- Reviews ---
echo "⭐ 生成评价数据 SQL ($REVIEWS 条)..."
TMPFILE="/tmp/seed_reviews.sql"
echo "SET autocommit=0;" > "$TMPFILE"

COMMENTS=("非常好用强烈推荐" "质量不错物流很快" "一般般还行吧" "性价比很高会回购" "包装精美送人很合适" "京东自营品质有保障" "比实体店便宜很多" "客服态度很好" "已经回购第三次了" "朋友推荐的确实不错")

i=0
while [ $i -lt $REVIEWS ]; do
    echo -n "INSERT INTO reviews (id, name, description, created_at) VALUES " >> "$TMPFILE"
    j=0
    while [ $j -lt $BATCH ] && [ $((i+j)) -lt $REVIEWS ]; do
        IDX=$((i+j))
        CIDX=$((RANDOM % 10))
        DAYS=$((RANDOM % 365))
        [ $j -gt 0 ] && echo -n "," >> "$TMPFILE"
        echo -n "(UUID(),'Review-$(printf '%07d' $IDX)','${COMMENTS[$CIDX]}',DATE_SUB(NOW(),INTERVAL $DAYS DAY))" >> "$TMPFILE"
        j=$((j+1))
    done
    echo ";" >> "$TMPFILE"
    echo "COMMIT;" >> "$TMPFILE"
    i=$((i+BATCH))
done

echo "  📄 SQL 已生成，导入中..."
docker cp "$TMPFILE" mysql-product-service:/tmp/seed_reviews.sql
docker exec mysql-product-service mysql -uroot -proot review_db -e "source /tmp/seed_reviews.sql" 2>/dev/null
REVIEW_COUNT=$(docker exec mysql-product-service mysql -uroot -proot -N -e "SELECT COUNT(*) FROM review_db.reviews;" 2>/dev/null)
echo "  ✅ 评价: $REVIEW_COUNT 条"

echo ""
echo "============================================"
echo "✅ 数据填充完成！"
echo "============================================"
echo ""
echo "验证："
echo "  curl http://localhost:8086/api/v1/reviews | python3 -m json.tool | head"
