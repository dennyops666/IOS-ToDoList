import UIKit
import CoreData

class TaskListViewController: UIViewController {
    
    // MARK: - Properties
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        return tableView
    }()
    
    private lazy var taskCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    var tasks: [Task] = []
    var coreDataManager: CoreDataManager!
    
    private let themeManager = ThemeManager.shared
    private var selectedCategory: Category?
    
    // 添加主题切换按钮
    private lazy var themeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "circle.lefthalf.filled"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(toggleTheme))
        return button
    }()
    
    // 添加分类筛选按钮
    private lazy var categoryFilterButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "全部分类",
                                   style: .plain,
                                   target: self,
                                   action: #selector(showCategoryFilter))
        return button
    }()
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        // 添加主题切换按钮和分类筛选按钮到导航栏
        navigationItem.leftBarButtonItem = themeButton
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped)), categoryFilterButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
        updateTaskCount()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "任务列表"
        
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(taskCountLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: taskCountLabel.topAnchor),
            
            taskCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            taskCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            taskCountLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            taskCountLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Data Management
    
    private func loadTasks() {
        tasks = coreDataManager.fetchTasks(category: selectedCategory)
        tableView.reloadData()
    }
    
    private func updateTaskCount() {
        var title = "任务列表"
        if let category = selectedCategory {
            let totalTasks = tasks.count
            let completedTasks = tasks.filter { $0.isCompleted }.count
            title += " [\(category.name ?? ""): \(completedTasks)/\(totalTasks)]"
        } else {
            // 计算所有任务的统计信息
            let allTasks = coreDataManager.fetchTasks()
            let totalTasks = allTasks.count
            let completedTasks = allTasks.filter { $0.isCompleted }.count
            title += " [全部任务: \(completedTasks)/\(totalTasks)]"
        }
        navigationItem.title = title
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        let taskDetailVC = TaskDetailViewController()
        taskDetailVC.coreDataManager = coreDataManager
        taskDetailVC.delegate = self
        let navigationController = UINavigationController(rootViewController: taskDetailVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    @objc private func toggleTheme() {
        let alert = UIAlertController(title: "选择主题",
                                    message: nil,
                                    preferredStyle: .actionSheet)
        
        let lightAction = UIAlertAction(title: "浅色", style: .default) { [weak self] _ in
            self?.themeManager.currentTheme = .light
        }
        
        let darkAction = UIAlertAction(title: "深色", style: .default) { [weak self] _ in
            self?.themeManager.currentTheme = .dark
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alert.addAction(lightAction)
        alert.addAction(darkAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func showCategoryFilter() {
        let alert = UIAlertController(title: "选择分类",
                                    message: nil,
                                    preferredStyle: .actionSheet)
        
        // 添加"全部分类"选项
        let allCategoriesAction = UIAlertAction(title: "全部分类", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.categoryFilterButton.title = "全部分类"
            self?.loadTasks()
            self?.updateTaskCount()
        }
        alert.addAction(allCategoriesAction)
        
        // 添加现有分类
        let categories = coreDataManager.fetchCategories()
        for category in categories {
            let action = UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.categoryFilterButton.title = category.name
                self?.loadTasks()
                self?.updateTaskCount()
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // 获取优先级显示文本和颜色
    private func getPriorityDisplay(for priority: Int16) -> (text: String, color: UIColor) {
        switch priority {
        case 0:
            return ("低", .systemGray)
        case 1:
            return ("中", .systemOrange)
        case 2:
            return ("高", .systemRed)
        default:
            return ("低", .systemGray)
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        
        // 获取优先级显示
        let priorityDisplay = getPriorityDisplay(for: task.priority)
        content.text = "[\(priorityDisplay.text)] \(task.title ?? "")"
        
        // 设置标题颜色
        if task.isCompleted {
            content.textProperties.color = .systemGray3
        } else {
            content.textProperties.color = priorityDisplay.color
        }
        
        // 构建副标题
        var subtitleComponents: [String] = []
        if let category = task.category?.name {
            subtitleComponents.append("[\(category)]")
        }
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy a h:mm"
            formatter.amSymbol = "上午"
            formatter.pmSymbol = "下午"
            formatter.locale = Locale(identifier: "zh_CN")
            subtitleComponents.append("截止: \(formatter.string(from: dueDate))")
        }
        
        // 添加状态标记
        var statusMarks: [String] = []
        if task.isCompleted {
            statusMarks.append("已完成")
        }
        if task.hasReminder {
            statusMarks.append("已设置提醒")
        }
        if !statusMarks.isEmpty {
            subtitleComponents.append("| \(statusMarks.joined(separator: " | "))")
        }
        
        content.secondaryText = subtitleComponents.joined(separator: " ")
        content.secondaryTextProperties.color = .systemGray
        
        cell.contentConfiguration = content
        
        // 设置已完成任务的标记
        cell.accessoryType = task.isCompleted ? .checkmark : .none
        
        // 设置过期任务的背景色
        if let dueDate = task.dueDate, dueDate < Date() {
            cell.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        } else {
            cell.backgroundColor = .systemBackground
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = tasks[indexPath.row]
        
        let taskDetailVC = TaskDetailViewController()
        taskDetailVC.task = task
        taskDetailVC.coreDataManager = coreDataManager
        taskDetailVC.delegate = self
        let navigationController = UINavigationController(rootViewController: taskDetailVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = tasks[indexPath.row]
        
        // 删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            self.coreDataManager.deleteTask(task)
            self.tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.updateTaskCount()
            completion(true)
        }
        
        // 完成/取消完成操作
        let completionTitle = task.isCompleted ? "取消完成" : "完成"
        let completionAction = UIContextualAction(style: .normal, title: completionTitle) { [weak self] (_, _, completion) in
            guard let self = self else { return }
            task.isCompleted.toggle()
            self.coreDataManager.saveContext()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            self.updateTaskCount()
            completion(true)
        }
        completionAction.backgroundColor = task.isCompleted ? .systemOrange : .systemGreen
        
        return UISwipeActionsConfiguration(actions: [deleteAction, completionAction])
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let task = tasks[indexPath.row]
            coreDataManager.deleteTask(task)
            tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateTaskCount()
        }
    }
}

// MARK: - TaskDetailViewControllerDelegate
extension TaskListViewController: TaskDetailViewControllerDelegate {
    func taskDetailViewController(_ controller: TaskDetailViewController, didSaveTask task: Task) {
        loadTasks()
        updateTaskCount()
    }
    
    func taskDetailViewController(_ controller: TaskDetailViewController, didDeleteTask task: Task) {
        if let index = tasks.firstIndex(where: { $0 === task }) {
            tasks.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            updateTaskCount()
        }
    }
}
