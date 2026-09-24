# iPad 设置整理：首轮源码改动

日期：2026-09-24。目标：iPadOS 16.5 / 多巴胺隐根 / 抖音 32.6。

**当前状态：已修改 Windows 源码并完成回读和静态检查；尚未完整编译，尚无新 DEB，尚未实机验证。长按菜单在 iPad 上的入口问题未宣称解决。**

## 基线与备份

- 源码目录：`Aweme-color-settings`；修改前工作树干净。
- 分支：`wip/ipad-color-settings`；修改前 HEAD：`5547392`（Add DYYY settings search）。用户已授权提交、推送和CI编译，待实际构建结果。
- 安装包参考基线：`DEB/com.xiaopan.dyyy_2.2-8_iphoneos-arm64e.deb`，SHA-256 `c7f32ea2b5d82deb35b1959712d124544dce219a378e916f9cd3f6697c77f805`。原包未覆盖；源码和二进制精确构建关系未独立证明。
- 5 个已修改文件各有同目录 `原文件名.20260924-ipad1.bak`，备份与修改前 SHA-256 一致，保留原 CRLF/文件结尾。
- 获授权后将 `control` 设置为独立测试版 `2.2-8+ipad1`；原control有 `.20260924-before-ci.bak`。Makefile、工作流、下载器、颜色模块、搜索隐藏、AI和睡眠代码未改。

## 已落实到源码

| 文件 | 改动 |
|---|---|
| DYYY.xm | 双指双击手势；窗口初始化及 makeKeyAndVisible 防重复安装；防止重复打开设置；从当前窗口可见控制器展示，并只关闭本次设置页 |
| DYYYSettingViewController.m | 分组互斥折叠；刷新新旧两组；点击已展开组可收起；搜索模式不折叠；折叠前结束文本编辑，不改功能开关值 |
| DYYYSettingViewController.m / DYYYSettings.xm | 两套设置入口均移除进度时长样式、隐藏视频进度、推荐视频时限 |
| DYYY.xm / DYYYSettingsHelper.m | 移除上述三个 key 的运行时读取、对应过滤分支和依赖；保留进度显示、纵向偏移及其他过滤 |
| DYYY.xm | 两个 modernLongPressPanelStyleMode 补齐返回路径；仅开玻璃或仅开深色时先回退原实现，避免未定义返回，不猜私有枚举 |
| README.md | 更新双指双击、手风琴说明；标注尚待编译与实机验证 |

进度标签固定为原默认形式：左侧已播放时间、右侧总时长。显示进度时长仍可关闭。旧的三个偏好值没有从用户磁盘强制擦除，但代码已不再读取，导入旧设置也不应使这三项重新生效；保留旧值便于回滚。

原快捷设置列表 243 项（含悬浮按钮组）只删除指定 3 项，剩余 240 项；本轮检测范围排除悬浮按钮后从 230 项变成 227 项。未删其他设置项。

## 验证结果与边界

1. MCP `apply_patch` 带原版本号应用成功，5 文件完整回读与准备版本逐行一致。
2. 新增 `tests/test_ipad_settings_stage1.py`：8 项源码约束检查通过（本地保留备份时含“只删3项”的比较）。这些不是 UIKit 单元测试。
3. 对回读的 DYYY.xm、DYYYSettings.xm 使用 Theos Logos（internal generator）预处理：均 exit 0，stderr 为空。此步骤不包含 Apple SDK 编译、链接或打包。
4. 既有 `test_awemex_palette.c` 主机 C 测试通过：端点、128级RGB、渐变节点数与100000次HSB取样。
5. `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check` 通过。默认 Git 检查把保留的 CRLF 中 CR 当作行尾空白；未为消除该提示整份转换原文件换行，也未更改仓库配置。
6. 无设备测试，无新安装包；不能把这轮源码调整说成“iPad功能均已生效”。

相关 API 已核对 Apple 文档：
- https://developer.apple.com/documentation/uikit/uitapgesturerecognizer/numberoftouchesrequired
- https://developer.apple.com/documentation/uikit/uigesturerecognizer/cancelstouchesinview

## 待编译后进行的设备验收

- [ ] 双指双击打开设置；旧双指长按不再打开；普通单指点击、滑动及双击点赞不受影响。
- [ ] 同一页面重复操作不叠加设置页；已有弹窗、横竖屏、分屏/多场景下安全展示与关闭。
- [ ] 原“禁用设置手势”偏好仍有效，文案为双指双击；更改后依原逻辑重启应用生效。
- [ ] 展开A再展开B只显示B；再次点B可全部收起；开关值不会因折叠改变。
- [ ] 搜索跨组结果正常，清空搜索恢复之前的折叠状态；文本输入完成后再折叠不会丢值。
- [ ] 两套设置页都没有三个指定项；旧偏好/导入旧配置不再触发它们。
- [ ] 显示进度时长仍可开关，左已播放/右总时长、进度条显示和拖动、纵轴位置正常。
- [ ] 作者/关键词/拍同款/HDR等其他过滤保持原行为；已通过的搜索隐藏、颜色功能回归。
- [ ] 长按玻璃/深色四组合均不出现未定义返回；单开功能是否符合预期仍需私有样式枚举验证。

## 下一步：长按菜单独立诊断

本轮没有改 DYYYLongPressPanel.xm，更没有把抖音图层二进制直接移植进来。
需在32.6设备上确认实际长按控制器与 dataArray 是否命中，再区分：面板开关无效、菜单项缺失、菜单项存在但动作/确认弹窗失效。优先保留已有下载器，避免为UI入口重写整个下载链。
设置源文件已完成首轮，可先沿已有 GitHub Actions 编译验证。触发前须明确提交/推送授权，不执行无说明的外部推送。
提交时只选择源码、README、新测试和本说明，不把同目录 `.bak` 当作源码提交（不要直接 git add .）。新编译产物保存在独立测试位置，不覆盖 DEB 基线。
睡眠与36.4 AI隐藏继续暂缓。

## 构建授权补充
用户已明确选择“允许提交、推送并编译”。仅提交6个修改文件（含control）、本说明和源码测试，不提交.bak。版本2.2-8+ipad1用于识别测试产物，不覆盖任何原包。本文的静态检查结论不是CI成功证明，最终构建与设备结果见工程外AI工作记录。
