import UIKit
import CoreData

class CategoryListViewController: UIViewController {
    private let db = Database.shared
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        return table
    }()
    
    private var categories: [Category] = []
    weak var delegate: CategorySelectionDelegate?
    
    // 添加加载状态指示
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // 添加空状态视图
    private let emptyStateView: UIView = {
        let view = UIView()
        // 配置空状态视图
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCategories()
    }
    
    private func setupUI() {
        title = "选择分类"
        view.backgroundColor = .systemBackground
        
        // 添加导航栏按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 设置tableView
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            categories = try db.viewContext.fetch(request)
            tableView.reloadData()
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    @objc private func addButtonTapped() {
        let alert = UIAlertController(title: "新建分类", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "分类名称"
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let saveAction = UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.isEmpty else { return }
            
            // 检查分类名称是否已存在
            if self.db.isCategoryNameExists(name) {
                let errorAlert = UIAlertController(
                    title: "错误",
                    message: "已存在相同名称的分类",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(errorAlert, animated: true)
                return
            }
            
            // 创建新分类
            let category = self.db.createCategory(name)
            self.loadCategories()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true)
    }
    
    // 优化数据加载流程
    private func loadData() {
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 在后台线程加载数据
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                // 更新 UI
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension CategoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categories[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = category.name
        cell.contentConfiguration = content
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        delegate?.didSelectCategory(category)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = categories[indexPath.row]
            db.viewContext.delete(category)
            db.save()
            
            categories.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - CategorySelectionDelegate
protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: Category)
} 
