import UIKit

class TaskListViewController: UITableViewController {
    
    // 临时数据用于测试显示
    private var tasks: [(title: String, isCompleted: Bool)] = [
        ("完成iOS课程作业", false),
        ("准备周会演示", true),
        ("健身1小时", false),
        ("看书学习", false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    
    @objc private func addTaskButtonTapped() {
        // 暂时只显示一个提示
        let alert = UIAlertController(
            title: "新增任务",
            message: "此功能正在开发中",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
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
        
        // 配置cell
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        cell.accessoryType = task.isCompleted ? .checkmark : .none
        
        return cell
    }
}

// MARK: - UITableView Delegate
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 切换任务完成状态
        tasks[indexPath.row].isCompleted.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
