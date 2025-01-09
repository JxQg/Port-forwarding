# RealmOneKey 脚本

这个脚本旨在简化部署、管理和更新 Realm 转发服务的过程。它允许你轻松设置 Realm，添加和删除转发规则，启动和停止服务，并更新到最新版本。此外，它支持设置 GitHub 加速地址以加速下载。

## 功能

- 部署 Realm 转发服务
- 添加和删除转发规则
- 启动和停止 Realm 服务
- 更新到最新版本的 Realm
- 设置 GitHub 加速地址
- 自动处理从旧安装路径 `/root/realm` 到新路径 `/opt/realm` 的迁移

## 前提条件

- 基于 Linux 的操作系统
- root 或 sudo 权限

## 安装

要下载、使脚本可执行并运行它，请使用以下命令：

```sh
wget https://raw.githubusercontent.com/Jaydooooooo/Port-forwarding/main/RealmOneKey.sh && chmod +x RealmOneKey.sh && ./RealmOneKey.sh
```

## 使用方法

运行脚本后，你会看到以下选项的菜单：

1. **部署环境**：安装 Realm 到指定目录。
2. **添加转发规则**：添加新的转发规则。
3. **删除转发规则**：删除现有的转发规则。
4. **启动服务**：启动 Realm 服务。
5. **停止服务**：停止 Realm 服务。
6. **卸载 Realm**：完全删除 Realm 及其相关文件。
7. **更新 Realm**：检查并安装最新版本的 Realm。
8. **设置 GitHub 加速地址**：设置自定义的 GitHub 加速地址。
9. **退出脚本**：退出脚本。

### 详细步骤

1. **部署环境**：
   - 此选项将下载最新版本的 Realm 并安装到默认目录 `/opt/realm`。如果在 `/root/realm` 检测到旧安装，你将被提示迁移到新路径。

2. **添加转发规则**：
   - 通过指定 IP 和端口来添加新的转发规则。

3. **删除转发规则**：
   - 列出所有现有的转发规则，并允许你选择一个进行删除。

4. **启动服务**：
   - 使用 `systemctl` 启动 Realm 服务。

5. **停止服务**：
   - 使用 `systemctl` 停止 Realm 服务。

6. **卸载 Realm**：
   - 停止 Realm 服务，并删除所有相关文件和配置。

7. **更新 Realm**：
   - 检查当前安装的版本并与 GitHub 上的最新版本进行比较。如果有更新版本，将下载并安装它。

8. **设置 GitHub 加速地址**：
   - 允许你设置自定义的 GitHub 加速地址以加速下载。

9. **退出脚本**：
   - 退出脚本。

## 注意事项

- 确保以 root 或 sudo 权限运行脚本，以允许其对系统进行必要的更改。
- 如果你是从旧安装路径升级，脚本会自动处理配置文件的迁移。

## 许可证

本项目根据 MIT 许可证授权。详情请参阅 [LICENSE](LICENSE) 文件。

## 鸣谢

此脚本来源 [NodeSeek](https://www.nodeseek.com/post-77509-1) 帖子。

## 联系

如有任何问题或疑虑，请随时在 [GitHub 仓库](https://github.com/Jaydooooooo/Port-forwarding) 上提出 issue。
