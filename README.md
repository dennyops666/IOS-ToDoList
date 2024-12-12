# ToDoList iOS App

一个功能完整的iOS待办事项管理应用，帮助用户高效管理日常任务。

## 功能特点

### 任务管理
- 创建、编辑、删除任务
- 设置任务优先级（低/中/高）
- 添加开始时间和截止时间
- 任务备注支持
- 任务完成状态追踪

### 分类管理
- 创建和管理任务分类
- 为任务分配分类
- 按分类查看和筛选任务
- 实时统计各分类任务数量

### 智能筛选
- 查看所有/已完成/未完成任务
- 分类筛选
- 左滑快速完成任务
- 右滑快速删除任务

### 提醒功能
- 任务到期本地通知提醒
- 灵活设置提醒时间
- 提醒状态管理

### 界面优化
- 深色/浅色主题支持
- 主题设置自动保存
- 任务状态颜色区分
- 优先级视觉标识
- 表格视图性能优化

## 技术特性

- 基于 Swift 和 UIKit 开发
- 使用 CoreData 实现数据持久化
- UserNotifications 实现本地提醒
- 支持 iOS 14.0 及以上版本

## 安装要求

- iOS 14.0+
- Xcode 13.0+
- Swift 5.0+

## 开始使用

1. 克隆项目
```bash
git clone https://github.com/dennyops666/IOS-ToDoList.git
```

2. 打开项目
```bash
cd ToDoList
open ToDoList.xcodeproj
```

3. 运行项目
- 选择目标设备或模拟器
- 点击运行按钮或按 Cmd + R

## 项目结构

```
ToDoList/
├── Models/
│   ├── Task.swift              # 任务数据模型
│   ├── Category.swift          # 分类数据模型
│   ├── TaskPriority.swift      # 优先级枚举
│   └── ToDoList.xcdatamodeld  # CoreData 数据模型
│
├── ViewControllers/
│   ├── TaskListViewController.swift     # 任务列表视图控制器
│   ├── TaskDetailViewController.swift   # 任务详情视图控制器
│   └── CategoryListViewController.swift # 分类管理视图控制器
│
├── Managers/
│   ├── CoreDataManager.swift   # CoreData 管理器
│   ├── Database.swift          # 数据库操作封装
│   └── TaskDateValidator.swift # 任务日期验证器
│
├── Utils/
│   ├── IconGenerator.swift     # 应用图标生成工具
│   └── Extensions/
│       ├── UIColor+Theme.swift # 颜色主题扩展
│       └── Date+Format.swift   # 日期格式化扩展
│
├── Resources/
│   ├── Assets.xcassets/        # 图片资源
│   │   └── AppIcon.appiconset # 应用图标
│   └── Info.plist             # 应用配置文件
│
└── Supporting Files/
    ├── AppDelegate.swift      # 应用程序代理
    └── SceneDelegate.swift    # 场景代理
```

### 核心组件说明

#### Models
- `Task.swift`: 任务核心数据模型，包含任务的所有属性和方法
- `Category.swift`: 分类数据模型，管理任务分类
- `TaskPriority.swift`: 任务优先级枚举，定义优先级及其视觉属性
- `ToDoList.xcdatamodeld`: CoreData 数据模型定义文件

#### ViewControllers
- `TaskListViewController.swift`: 主界面，显示任务列表，处理任务筛选和操作
- `TaskDetailViewController.swift`: 任务创建和编辑界面
- `CategoryListViewController.swift`: 分类管理界面

#### Managers
- `CoreDataManager.swift`: CoreData 核心管理器，处理数据持久化
- `Database.swift`: 数据库操作的高级封装，提供 CRUD 接口
- `TaskDateValidator.swift`: 任务日期验证逻辑

#### Utils
- `IconGenerator.swift`: 动态生成应用图标的工具类
- `Extensions/`: 存放各种扩展方法
  - `UIColor+Theme.swift`: 主题相关的颜色扩展
  - `Date+Format.swift`: 日期格式化扩展方法

#### Resources
- `Assets.xcassets`: 图片资源管理
- `Info.plist`: 应用配置信息

#### Supporting Files
- `AppDelegate.swift`: 应用程序生命周期管理
- `SceneDelegate.swift`: UI场景生命周期管理

## 开发计划

### 即将推出
- 任务重复周期设置
- 子任务支持
- 标签系统
- 搜索功能
- iCloud 同步
- 数据导入导出

### 长期规划
- 团队协作功能
- 统计分析
- Widget 支持
- iPad 和 macOS 版本

## 贡献指南

欢迎提交 Issue 和 Pull Request。在贡献代码前，请确保：

1. 代码符合项目的编码规范
2. 添加必要的测试用例
3. 更新相关文档

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件
