# Services Deploy

一个用于多服务一键部署的代码库，基于 Docker Compose，兼容 `arm64` 与 `amd64`。

## 目录结构

```
services-deploy/
├── docker-compose.yml          # 总编排（include 各子服务）
├── docker-compose.test.yml     # 测试环境覆盖
├── .env-demo                   # 全局环境变量示例（部署前复制为 .env）
├── services/
│   ├── caddy/                  # 对外统一入口/反向代理/自动 HTTPS
│   ├── casdoor/                # 统一登录 (SSO/OAuth2)
│   ├── umami/                  # 网站统计
│   ├── sub2api/                # 订阅转换/代理中转
│   ├── happyImage/             # Agent 服务（含源码）
│   └── mihomo/                 # 出站代理（可拆卸）
├── scripts/
│   ├── bootstrap.sh            # 初始化 .env / 创建网络
│   ├── up.sh                   # 启动（可选服务/环境）
│   ├── down.sh                 # 停止
│   └── pull.sh                 # 更新镜像
└── test/
    └── README.md
```

## 设计原则

- **统一入口**：所有外部流量经 `caddy`，按子域名分发；域名形如 `*.${ROOT_DOMAIN}`（如 `auth.xxx.cn`、`stats.xxx.cn`）。
- **统一登录**：由 `casdoor` 提供 OAuth2/OIDC，其他服务作为客户端接入。
- **隐私优先**：所有敏感信息只放在 `.env`，仓库内只保留 `.env-demo`。`.env` 已加入 `.gitignore`。
- **多架构**：所有镜像优先选用同时发布 `linux/amd64` 与 `linux/arm64` 的官方镜像；自构建镜像使用 `docker buildx` 多平台构建。
- **可拆卸**：`mihomo` 通过 Compose `profiles` 控制，按需启用。
- **可扩展**：新增服务只需在 `services/<name>/` 下放 `compose.yml` 与 `.env-demo`，并在根 `docker-compose.yml` 的 `include` 中追加。

## 快速开始

```bash
# 1. 复制环境变量模板（递归生成所有 .env）
./scripts/bootstrap.sh

# 2. 编辑根 .env 与各子服务 .env，至少修改：
#    ROOT_DOMAIN=xxx.cn
#    ACME_EMAIL=you@xxx.cn
#    各服务密码 / OAuth 凭据

# 3. 启动生产环境（默认不含 mihomo）
./scripts/up.sh

# 4. 启用 mihomo（出站代理）
./scripts/up.sh --with-mihomo

# 5. 测试环境
./scripts/up.sh --env test
```

## 子域名规划

| 服务        | 默认子域名             | 说明                |
| ----------- | ---------------------- | ------------------- |
| caddy       | —（充当入口）          | 80/443 暴露         |
| casdoor     | `auth.${ROOT_DOMAIN}`  | 统一登录            |
| umami       | `stats.${ROOT_DOMAIN}` | 统计后台            |
| sub2api     | `sub.${ROOT_DOMAIN}`   | 代理中转            |
| happyImage  | `img.${ROOT_DOMAIN}`   | Agent 服务          |
| mihomo      | 内部 `mihomo:7890`     | 仅集群内出站代理    |

## 多架构构建

```bash
docker buildx create --use --name multi || true
docker buildx build --platform linux/amd64,linux/arm64 \
  -t your-registry/happy-image:latest \
  services/happyImage --push
```
