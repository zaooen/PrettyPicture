# ==========================================
# 第一阶段：构建前端 (React)
# ==========================================
FROM node:16 AS frontend-builder

# 设置前端构建目录
WORKDIR /app/frontend

# 1. 复制前端依赖配置 (注意路径匹配你的文件夹名 PrettyPicture-react)
COPY PrettyPicture-react/package*.json ./

# 2. 安装前端依赖 (使用淘宝源加速，防止卡顿)
RUN npm install --registry=https://registry.npmmirror.com

# 3. 复制前端所有源码
COPY PrettyPicture-react/ ./

# 4. 执行构建 (生成 dist 目录)
RUN npm run build


# ==========================================
# 第二阶段：构建后端 (ThinkPHP + Apache)
# ==========================================
FROM php:8.0-apache

# 1. 安装系统依赖和必要的 PHP 扩展
# (pdo_mysql 用于连接数据库, zip/git 用于 composer)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install \
    pdo_mysql \
    bcmath \
    zip \
    && apt-get clean

# 2. 启用 Apache 的 Rewrite 模块 (ThinkPHP 伪静态必须)
RUN a2enmod rewrite

# 3. 配置 Apache 网站根目录指向 public (ThinkPHP 安全规范)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 4. 安装 Composer (PHP 包管理器)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. 设置工作目录
WORKDIR /var/www/html

# 6. 复制后端代码 (当前目录下所有文件)
COPY . .

# 7. 从第一阶段复制构建好的前端文件到 public 目录
# (假设 React 打包输出在 dist，将其放入 ThinkPHP 的 public 目录下以便访问)
COPY --from=frontend-builder /app/frontend/dist ./public/admin

# 8. 安装 PHP 依赖 (忽略开发包)
# 如果因为网络问题安装失败，可以尝试删除这行，但建议保留
RUN composer install --no-dev --optimize-autoloader || echo "Composer install failed, skipping..."

# 9. 设置目录权限 (确保 ThinkPHP 能够写入日志和缓存)
RUN chown -R www-data:www-data /var/www/html/runtime
RUN chown -R www-data:www-data /var/www/html/public

# 10. 暴露 80 端口
EXPOSE 80

# 11. 启动 Apache
CMD ["apache2-foreground"]
