import UIKit

class CategoryListViewController: UITableViewController {
    
    private var categories: [Category] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCategories()
    }
    
    private func setupUI() {
        title = "分类管理"
        
        // 配置导航栏
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 注册cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
    }
    
    private func loadCategories() {
        categories = CoreDataManager.shared.fetchCategories()
        tableView.reloadData()
    }
    
    @objc private func addButtonTapped() {
        let alert = UIAlertController(title: "新建分类", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "分类名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            
            // 检查分类名称是否已存在
            if CoreDataManager.shared.isCategoryNameExists(name) {
                let errorAlert = UIAlertController(
                    title: "错误",
                    message: "已存在相同名称的分类",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }
            
            let category = CoreDataManager.shared.createCategory(name: name)
            self?.categories.append(category)
            self?.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource
extension CategoryListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categories[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = category.name
        cell.contentConfiguration = content
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = categories[indexPath.row]
            CoreDataManager.shared.deleteCategory(category)
            categories.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
} 