<h2>PrettyPicture - 企业/团队图床系统</h2>
☁ 使用thinkphp+react开发，前后端分离；本仓库为完整版程序，下载后根据安装教程安装即可使用；

##  程序功能
* 支持第三方云储存，本地、阿里云OSS、腾讯云COS、七牛云KODO、华为云OBS、AWS S3等等
* 支持多桶储存，可同时添加多个对象存储桶管理，适合团队多桶协作
* 多图上传、拖拽上传、粘贴上传、上传预览、全屏预览、一键复制图片外链
* 多用户管理、分组管理；不同分组用户控制不同的存储桶
* 完整的权限控制功能，不同用户组可分配不同的操作权限，控制其上传删除及查看
* 完整的可视化日志功能，记录用户所有操作，方便事件溯源
* 全局配置用户初始剩余储存空间、设置指定用户剩余储存空间
* 支持接口上传、接口删除
* React 和 HeroUI风格，高性能 / 精致 / 优雅 / 简洁而不简单


##  安装要求
* PHP 版本 &ge; 8.2
* Mysql版本 &ge; 5.6
* PDO 拓展
* fileinfo 拓展
* curl 拓展
* ZipArchive 支持

##  安装教程
1. 下载PrettyPicture，上传至 web 运行环境，解压。
2. 设置运行目录为 public。
3. 配置网站默认文档：
~~~
index.html
index.php
~~~

4. 配置 Rewrite 规则为：thinkphp
####  \[ Apache \]

~~~
<IfModule mod_rewrite.c>
  Options +FollowSymlinks -Multiviews
  RewriteEngine On

  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteRule ^(.*)$ index.php/$1 [QSA,PT,L]
</IfModule>
~~~
####  \[ Nginx\]

~~~
location / { 
   if (!-e $request_filename) {
   		rewrite  ^(.*)$  /index.php?s=/$1  last;
    }
}
~~~

5. 访问 域名/install，根据页面提示安装。
注：完成后若开启前台注册请登录管理员账号配置发信邮箱

##  联系我
- Email: 1742305143@qq.com

##  鸣谢
- ThinkPHP
- React
- HeroUI
