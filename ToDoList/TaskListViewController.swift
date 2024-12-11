import UIKit
import CoreData

class TaskListViewController: UIViewController {
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private var selectedCategory: Category?
    private let db = Database.shared
    
    private let filterSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["所有任务", "已完成", "未完成"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = .systemBackground
        return control
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadTasks()
        applyFilter()
        
        // 恢复保存的主题设置
        if let savedTheme = UserDefaults.standard.string(forKey: "AppTheme") {
            if let window = view.window {
                window.overrideUserInterfaceStyle = savedTheme == "dark" ? .dark : .light
                // 更新按钮图标
                let imageName = savedTheme == "dark" ? "sun.max.fill" : "moon.fill"
                navigationItem.rightBarButtonItems?[1].image = UIImage(systemName: imageName)
            }
        }
    }
    
    private func setupUI() {
        // 添加子视图
        view.addSubview(filterSegmentedControl)
        view.addSubview(tableView)
        
        // 设置代理
        tableView.delegate = self
        tableView.dataSource = self
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 筛选控件约束
            filterSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加筛选控件的事件处理
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }
    
    private func setupNavigationBar() {
        title = "所有任务"
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTaskButtonTapped)
        )
        
        // 添加主题切换按钮
        let themeButton = UIBarButtonItem(
            image: UIImage(systemName: "moon.fill"),
            style: .plain,
            target: self,
            action: #selector(themeButtonTapped)
        )
        
        // 设置右侧按钮组
        navigationItem.rightBarButtonItems = [addButton, themeButton]
        
        let categoryButton = UIBarButtonItem(
            title: "分类",
            style: .plain,
            target: self,
            action: #selector(categoryButtonTapped)
        )
        navigationItem.leftBarButtonItem = categoryButton
    }
    
    @objc private func addTaskButtonTapped() {
        let taskDetailVC = TaskDetailViewController()
        taskDetailVC.delegate = self
        
        let navigationController = UINavigationController(rootViewController: taskDetailVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        present(navigationController, animated: true)
    }
    
    private func loadTasks() {
        if let category = selectedCategory {
            // 获取特定分类的任务
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "dueDate", ascending: true)
            ]
            do {
                tasks = try db.viewContext.fetch(fetchRequest)
                // 安全解包分类名称
                let categoryName = category.name ?? "未命名分类"
                title = "\(categoryName)(\(tasks.count))"
            } catch {
                print("Error fetching tasks: \(error)")
                tasks = []
            }
        } else {
            // 获取所有任务
            tasks = db.fetchTasks()
            title = "所有任务(\(tasks.count))"
        }
        tableView.reloadData()
    }
    
    @objc private func categoryButtonTapped() {
        let actionSheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加"所有任务"选项
        let allTasksCount = db.fetchTasks().count
        actionSheet.addAction(UIAlertAction(title: "所有任务(\(allTasksCount))", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.loadTasks()
        })
        
        // 添加现有分类
        let categories = db.fetchCategories()
        for category in categories {
            // 获取每个分类的任务数量并安全解包分类名称
            let taskCount = db.getTaskCount(for: category)
            let categoryName = category.name ?? "未命名分类"  // 提供默认名称
            let title = "\(categoryName)(\(taskCount))"
            
            actionSheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.loadTasks()
            })
        }
        
        // 添加管理分类选项
        actionSheet.addAction(UIAlertAction(title: "管理分类...", style: .default) { [weak self] _ in
            let categoryVC = CategoryListViewController()
            self?.navigationController?.pushViewController(categoryVC, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 对于iPad，需要设置弹出位置
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.leftBarButtonItem
        }
        
        present(actionSheet, animated: true)
    }
    
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController(style: .insetGrouped)
        let navigationController = UINavigationController(rootViewController: settingsVC)
        present(navigationController, animated: true)
    }
    
    @objc private func filterChanged() {
        applyFilter()
    }
    
    private func applyFilter() {
        switch filterSegmentedControl.selectedSegmentIndex {
        case 1: // 已完成
            filteredTasks = tasks.filter { $0.isCompleted }
        case 2: // 未完成
            filteredTasks = tasks.filter { !$0.isCompleted }
        default: // 所有任务
            filteredTasks = tasks
        }
        tableView.reloadData()
    }
    
    // 添加批量更新支持
    private func reloadData() {
        tableView.performBatchUpdates({
            self.loadTasks()
            self.applyFilter()
        }, completion: nil)
    }
    
    // 优化表格视图性能
    private func configureTableView() {
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.prefetchDataSource = self
    }
    
    // 添加主题切换方法
    @objc private func themeButtonTapped() {
        if let window = view.window {
            // 切换主题并更新按钮图标
            if window.overrideUserInterfaceStyle == .dark {
                window.overrideUserInterfaceStyle = .light
                navigationItem.rightBarButtonItems?[1].image = UIImage(systemName: "moon.fill")
                UserDefaults.standard.set("light", forKey: "AppTheme")
            } else {
                window.overrideUserInterfaceStyle = .dark
                navigationItem.rightBarButtonItems?[1].image = UIImage(systemName: "sun.max.fill")
                UserDefaults.standard.set("dark", forKey: "AppTheme")
            }
        }
    }
}

// MARK: - TaskDetailViewControllerDelegate
extension TaskListViewController: TaskDetailViewControllerDelegate {
    func taskDetailViewController(_ controller: TaskDetailViewController, didSaveTask task: Task) {
        loadTasks()
        applyFilter()
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = filteredTasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        
        // 构建状态、优先级和分类信息
        let statusText = task.isCompleted ? "已完成" : "未完成"
        let priority = TaskPriority(rawValue: task.priority) ?? .low
        let priorityText = "[\(priority.title)]"
        let categoryText = task.category?.name ?? "无分类"
        
        let statusColor = task.isCompleted ? UIColor.systemGreen : UIColor.systemRed
        
        let attributedString = NSMutableAttributedString()
        
        // 添加状态
        let statusString = NSAttributedString(
            string: statusText,
            attributes: [.foregroundColor: statusColor]
        )
        attributedString.append(statusString)
        
        // 添加分隔符
        attributedString.append(NSAttributedString(string: " • "))
        
        // 添加优先级
        let priorityString = NSAttributedString(
            string: priorityText,
            attributes: [.foregroundColor: priority.color]
        )
        attributedString.append(priorityString)
        attributedString.append(NSAttributedString(string: " • "))
        
        // 添加分类
        attributedString.append(NSAttributedString(string: categoryText))
        
        content.secondaryAttributedText = attributedString
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let taskToDelete = filteredTasks[indexPath.row]
            db.deleteTask(taskToDelete)
            loadTasks()
            applyFilter()
        }
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = filteredTasks[indexPath.row]
        let taskDetailVC = TaskDetailViewController(task: task)
        taskDetailVC.delegate = self
        
        let navigationController = UINavigationController(rootViewController: taskDetailVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        present(navigationController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let taskToDelete = self.filteredTasks[indexPath.row]
            self.db.deleteTask(taskToDelete)
            self.loadTasks()
            self.applyFilter()
            
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = filteredTasks[indexPath.row]
        let title = task.isCompleted ? "未完成" : "完成"
        let action = UIContextualAction(style: .normal, title: title) { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            task.isCompleted = !task.isCompleted
            self.db.updateTask(task, category: task.category)
            self.loadTasks()
            self.applyFilter()
            
            completionHandler(true)
        }
        
        action.backgroundColor = task.isCompleted ? UIColor.systemOrange : UIColor.systemGreen
        
        return UISwipeActionsConfiguration(actions: [action])
    }
}

// MARK: - Theme Support
extension TaskListViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            applyTheme()
        }
    }
    
    private func applyTheme() {
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground
    }
}

// 添加预加载支持
extension TaskListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // 预加载数据
    }
}
