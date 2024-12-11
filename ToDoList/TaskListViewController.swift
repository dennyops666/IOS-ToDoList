import UIKit
import CoreData

class TaskListViewController: UIViewController {
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private var selectedCategory: Category?
    
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
        loadTasks()
        applyFilter()
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
    
    private func loadTasks() {
        if let category = selectedCategory {
            // 获取特定分类的任务
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "dueDate", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            do {
                tasks = try CoreDataManager.shared.context.fetch(fetchRequest)
            } catch {
                print("Error fetching tasks: \(error)")
                tasks = []
            }
        } else {
            // 获取所有任务
            tasks = CoreDataManager.shared.fetchTasks()
        }
        tableView.reloadData()
        
        // 更新标题
        title = selectedCategory?.name ?? "所有任务"
    }
    
    @objc private func addTaskButtonTapped() {
        let taskDetailVC = TaskDetailViewController()
        taskDetailVC.delegate = self
        
        // 创建导航控制器并将taskDetailVC嵌入其中
        let navigationController = UINavigationController(rootViewController: taskDetailVC)
        navigationController.modalPresentationStyle = .fullScreen  // 或者 .formSheet
        
        present(navigationController, animated: true)
    }
    
    @objc private func categoryButtonTapped() {
        let actionSheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加"所有任务"选项
        actionSheet.addAction(UIAlertAction(title: "所有任务", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.loadTasks()
        })
        
        // 添加现有分类
        let categories = CoreDataManager.shared.fetchCategories()
        for category in categories {
            actionSheet.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
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
    
    private func applyTheme() {
        let colors = ThemeManager.shared.color(for: traitCollection.userInterfaceStyle)
        view.backgroundColor = colors.background
        tableView.backgroundColor = colors.background
    }
    
    @objc private func filterChanged() {
        applyFilter()
    }
    
    private func applyFilter() {
        switch filterSegmentedControl.selectedSegmentIndex {
        case 1:
            // 筛选已完成任务
            filteredTasks = tasks.filter { $0.isCompleted }
        case 2:
            // 筛选未完成任务
            filteredTasks = tasks.filter { !$0.isCompleted }
        default:
            // 显示所有任务
            filteredTasks = tasks
        }
        
        // 刷新任务列表
        tableView.reloadData()
    }
}

// MARK: - TaskDetailViewControllerDelegate
extension TaskListViewController: TaskDetailViewControllerDelegate {
    func taskDetailViewController(_ controller: TaskDetailViewController, didSaveTask task: Task) {
        loadTasks()
        applyFilter()
    }
}

// MARK: - UITableView DataSource
extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = filteredTasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        
        return cell
    }
}

// MARK: - UITableView Delegate
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
}

// MARK: - Trait Collection Handling
extension TaskListViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            applyTheme()
        }
    }
}
