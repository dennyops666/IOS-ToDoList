import UIKit

class TaskListViewController: UITableViewController {
    
    // 临时数据用于测试显示
    private var tasks: [Task] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTasks()
    }
    
    private func setupUI() {
        title = "待办事项"
        
        // 配置导航栏
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTaskButtonTapped)
        )
        
        // 注册cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
    }
    
    private func loadTasks() {
        tasks = CoreDataManager.shared.fetchTasks()
        tableView.reloadData()
    }
    
    @objc private func addTaskButtonTapped() {
        let alert = UIAlertController(title: "新增任务", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "任务名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let title = alert.textFields?.first?.text, !title.isEmpty else { return }
            
            let task = CoreDataManager.shared.createTask(title: title)
            self?.tasks.insert(task, at: 0)
            self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        cell.accessoryType = task.isCompleted ? .checkmark : .none
        
        // 设置accessibility value，安全地处理可选值
        if let title = task.title {
            cell.accessibilityValue = task.isCompleted ? "\(title), 已完成" : title
        }
        
        return cell
    }
}

// MARK: - UITableView Delegate
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let task = tasks[indexPath.row]
        let detailVC = TaskDetailViewController(task: task)
        detailVC.delegate = self
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // 左滑操作
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completion) in
            self?.deleteTask(at: indexPath)
            completion(true)
        }
        
        // 完成操作
        let task = tasks[indexPath.row]
        let completeTitle = task.isCompleted ? "未完成" : "完成"
        let completeAction = UIContextualAction(style: .normal, title: completeTitle) { [weak self] (_, _, completion) in
            self?.toggleTaskCompletion(at: indexPath)
            completion(true)
        }
        completeAction.backgroundColor = task.isCompleted ? .systemOrange : .systemGreen
        
        return UISwipeActionsConfiguration(actions: [deleteAction, completeAction])
    }
    
    private func deleteTask(at indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        CoreDataManager.shared.deleteTask(task)
        tasks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    private func toggleTaskCompletion(at indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        task.isCompleted.toggle()
        CoreDataManager.shared.updateTask(task)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - TaskDetailViewControllerDelegate
extension TaskListViewController: TaskDetailViewControllerDelegate {
    func taskDetailViewController(_ controller: TaskDetailViewController, didUpdateTask task: Task) {
        if let index = tasks.firstIndex(of: task) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
}
