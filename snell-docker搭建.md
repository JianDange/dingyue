<h1 id="docker搭建snell教程">docker搭建snell教程</h1>
<blockquote><p><strong>用docker compose方便多了，强烈建议！！！</strong></p></blockquote>
<h2 id="安装docker">安装docker</h2>
<p>依次输入以下命令</p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">apt-get</span> update <span class="token operator">&amp;&amp;</span> <span class="token function">apt-get</span> <span class="token parameter variable">-y</span> upgrade

<span class="token comment">#获取docker（国外）</span>
<span class="token function">curl</span> <span class="token parameter variable">-fsSL</span> https://get.docker.com <span class="token operator">|</span> <span class="token function">bash</span> <span class="token parameter variable">-s</span> <span class="token function">docker</span>

<span class="token comment">#如果之前没安装过docker，请忽略这里</span>
<span class="token comment">#如果之前安装了compose 2.0以下的版本的话，请先执行卸载指令：</span>
<span class="token function">sudo</span> <span class="token function">rm</span> /usr/local/bin/docker-compose
<span class="token comment">#如果之前安装了compose 2.0以上的版本的话，请先执行卸载指令：</span>
<span class="token function">rm</span> <span class="token parameter variable">-rf</span> .docker/cli-plugins/

<span class="token comment">#下载最新compose</span>
<span class="token function">apt-get</span> <span class="token function">install</span> docker-compose-plugin <span class="token parameter variable">-y</span></code></pre></div>
<p>然后输入以下命令来检测compose版本</p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">docker</span> compose version</code></pre></div>
<p>正常的话会出现一个版本号</p>
<p>好了，现在docker已经安装好了，</p>
<h2 id="搭建snell">搭建snell</h2>
<p>创建docker-compose.yml文件夹</p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">mkdir</span> <span class="token parameter variable">-p</span> /root/snelldocker/snell-conf</code></pre></div>
<blockquote><p>⚠️注意：我这里的snelldocker文件夹名可以自行更改，但接下来的命令也要记得对应更改，最好就是啥也不改，省事</p></blockquote>
<p>接着输入下面这一串，然后直接 <code>回车</code> 即可，注意区分自己是 <code>amd</code>还是 <code>arm</code></p>
<p><strong>amd</strong></p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">cat</span> <span class="token operator">&gt;</span> /root/snelldocker/docker-compose.yml <span class="token operator">&lt;&lt;</span> <span class="token string">EOF
version: "3.8" 
services:
  snell:
    image: accors/snell:latest
    container_name: snell
    restart: always
    network_mode: host
    volumes:
      - ./snell-conf/snell.conf:/etc/snell-server.conf
    environment:
      - SNELL_URL=https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
EOF</span></code></pre></div>
<p><strong>注意其他服务端文件请去</strong><a target="_blank" rel="noopener noreferrer nofollow" href="https://manual.nssurge.com/others/snell.html"><strong>此网站</strong></a><strong>查找</strong></p>
<p><strong>arm</strong></p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">cat</span> <span class="token operator">&gt;</span> /root/snelldocker/docker-compose.yml <span class="token operator">&lt;&lt;</span> <span class="token string">EOF
version: "3.8" 
services:
  snell:
    image: accors/snell:latest
    container_name: snell
    restart: always
    network_mode: host
    volumes:
      - ./snell-conf/snell.conf:/etc/snell-server.conf
    environment:
      - SNELL_URL=https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-aarch64.zip
EOF</span></code></pre></div>
<p><strong>注意其他服务端文件请去</strong><a target="_blank" rel="noopener noreferrer nofollow" href="https://manual.nssurge.com/others/snell.html"><strong>此网站</strong></a><strong>查找</strong></p>
<p>接下来再输入下面这一串命令，如需要可以自行更改，如果要开 <code>ipv6</code>的话，就把 <code>listen</code> 那一行的 <code>0.0.0.0</code> 改成 <code>::0</code> ，然后把下面的 <code>ipv6=false</code> 改成 <code>ipv6=true</code> 即可，接着 <code>回车</code></p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">cat</span> <span class="token operator">&gt;</span> /root/snelldocker/snell-conf/snell.conf <span class="token operator">&lt;&lt;</span> <span class="token string">EOF
[snell-server]
listen = 0.0.0.0:28261   # 这里28261是端口
psk = GLk1ff4wuQNCDSqr92WwsHwe8KBjy3S  # 这里是密钥，可以自行更改
ipv6 = false
EOF</span></code></pre></div>
<p>注意，这里我没有把obfs加入了，如果自己加入了<code>obfs=http</code>记得在surge的配置文件也加上，<strong>不建议</strong></p>
<p>现在所有的配置已经完成了！！！</p>
<p>依次输入以下命令即可</p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token builtin class-name">cd</span> /root/snelldocker

<span class="token function">docker</span> compose up <span class="token parameter variable">-d</span></code></pre></div>
<p>完成之后可以输入以下命令查看日志，来查看是否正常运行snell服务</p>
<div class="code-toolbar"><pre class="language-shell line-numbers" tabindex="0"><code class="hljs language-shell"><span class="token function">docker</span> logs <span class="token parameter variable">-f</span> snell</code></pre></div>
<p>按&nbsp;<code>ctrl</code>+&nbsp;<code>c</code>&nbsp;退出日志</p>
<p>那么现在就可以去surge填写配置了，就是这么简单，导入surge教程看上面<a target="_self" rel="noopener noreferrer nofollow" href="#surge上导入节点" data-pjax-state="">手搓示例，点击跳转</a></p>
docker snell更新教程
如果之后更新了就可以输入以下命令完成更新

cd /root/snelldocker && docker compose pull && docker compose up -d

如果之后老刘更新服务端文件的链接了，那就把docker-compose.yml的文件链接替换成新的

然后再输入以下命令

cd /root/snelldocker
 
docker stop snell && docker rm snell

docker compose pull

docker compose up -d



