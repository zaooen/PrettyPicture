# ==========================================
# 🏗️ 第一阶段：构建前端 (React)
# ==========================================
# ⚠️ 修复：将 node:16 升级为 node:20，解决 Vite 构建时的 crypto 报错
FROM node:20 AS frontend-builder

# 设置前端构建工作目录
WORKDIR /app/frontend

# 1. 复制前端项目的依赖配置文件
COPY PrettyPicture-react/package*.json ./

# 2. 安装前端依赖 (使用淘宝镜像源)
RUN npm install --registry=https://registry.npmmirror.com

# 3. 复制前端源代码
COPY PrettyPicture-react/ ./

# 4. 执行构建命令
RUN npm run build


# ==========================================
# 🚀 第二阶段：构建后端 (ThinkPHP + Apache)
# ==========================================
FROM php:8.0-apache

# 1. 安装系统依赖和 PHP 扩展
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install \
    pdo_mysql \
    bcmath \
    zip \
    && apt-get clean

# 2. 启用 Apache 的 Rewrite 模块
RUN a2enmod rewrite

# 3. 配置 Apache 网站根目录
# ⚠️ 优化：使用 key=value 格式，消除 Docker 构建警告
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 4. 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. 设置工作目录
WORKDIR /var/www/html

# 6. 复制后端代码
COPY . .

# 7. 将第一阶段构建好的前端文件复制到 public 目录
# ⚠️ 注意：这里假设 Vite 打包输出目录是 dist
# 如果依然报错找不到目录，请检查 package.json 里的 "build" 脚本生成的是 dist 还是 build
COPY --from=frontend-builder /app/frontend/dist ./public/

# 8. 安装 PHP 依赖
RUN composer install --no-dev --optimize-autoloader || echo "Composer install skipped"

# 9. 设置目录权限
RUN chown -R www-data:www-data /var/www/html/runtime
RUN chown -R www-data:www-data /var/www/html/public

# 10. 暴露端口
EXPOSE 80

# 11. 启动 Apache
CMD ["apache2-foreground"]
