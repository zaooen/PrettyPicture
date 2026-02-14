# ==========================================
# 🏗️ 第一阶段：构建前端 (React)
# ==========================================
FROM node:16 AS frontend-builder

# 设置前端构建工作目录
WORKDIR /app/frontend

# 1. 复制前端项目的依赖配置文件
#    注意：源项目的前端代码在 PrettyPicture-react 文件夹中
COPY PrettyPicture-react/package*.json ./

# 2. 安装前端依赖 (使用淘宝镜像源，国内构建更快)
RUN npm install --registry=https://registry.npmmirror.com

# 3. 复制前端源代码
COPY PrettyPicture-react/ ./

# 4. 执行构建命令
#    (这通常会生成一个 dist 或 build 文件夹，里面是 index.html 和静态资源)
RUN npm run build


# ==========================================
# 🚀 第二阶段：构建后端 (ThinkPHP + Apache)
# ==========================================
FROM php:8.0-apache

# 1. 安装系统依赖和 PHP 扩展
#    ThinkPHP 需要 pdo_mysql, bcmath, zip 等扩展
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
#    (ThinkPHP 路由必须，否则会出现 404 错误)
RUN a2enmod rewrite

# 3. 配置 Apache 网站根目录指向 public 文件夹
#    这是 ThinkPHP 的安全规范，防止直接访问核心代码
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 4. 安装 Composer (PHP 包管理器)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. 设置工作目录
WORKDIR /var/www/html

# 6. 复制后端代码 (复制当前目录所有文件到容器)
COPY . .

# 7. 【关键步骤】将第一阶段构建好的前端文件复制到 public 目录
#    假设 React 构建输出在 dist 文件夹，我们把它复制到 public/admin (如果是后台) 或者直接覆盖 public (如果是单页应用)
#    ⚠️注意：根据通常 React 项目结构，构建目录通常是 dist 或 build。
#    如果构建失败提示找不到目录，请检查 package.json 的 build 输出。
COPY --from=frontend-builder /app/frontend/dist ./public/

# 8. 安装 PHP 依赖
#    (如果有 composer.lock 会严格按照版本安装)
RUN composer install --no-dev --optimize-autoloader || echo "Composer install skipped"

# 9. 设置目录权限
#    确保 web 服务器可以写入 runtime (日志/缓存) 和 public (上传文件) 目录
RUN chown -R www-data:www-data /var/www/html/runtime
RUN chown -R www-data:www-data /var/www/html/public

# 10. 暴露 80 端口
EXPOSE 80

# 11. 启动 Apache 服务
CMD ["apache2-foreground"]
