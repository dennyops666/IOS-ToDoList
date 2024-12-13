import UIKit
import CoreData

class CategoryListViewController: UIViewController {
    var coreDataManager: CoreDataManager!
    
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
        title = NSLocalizedString("Categories", comment: "")
        view.backgroundColor = .systemBackground
        
        // 设置导航栏按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 设置表格视图
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
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            categories = try coreDataManager.context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    @objc private func addButtonTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("Add Category", comment: ""),
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = NSLocalizedString("Category Name", comment: "")
        }
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .cancel
        )
        
        let saveAction = UIAlertAction(
            title: NSLocalizedString("Add", comment: ""),
            style: .default
        ) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.isEmpty else { return }
            
            // 检查分类名称是否已存在
            if self.coreDataManager.isCategoryNameExists(name) {
                let errorAlert = UIAlertController(
                    title: NSLocalizedString("Error", comment: ""),
                    message: NSLocalizedString("Category name already exists", comment: ""),
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                self.present(errorAlert, animated: true)
                return
            }
            
            // 创建新分类
            let category = Category(context: self.coreDataManager.context)
            category.name = name
            category.createdAt = Date()
            
            do {
                try self.coreDataManager.context.save()
                self.loadCategories()
            } catch {
                print("Error saving category: \(error)")
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true)
    }
}

extension CategoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCategory = categories[indexPath.row]
        delegate?.didSelectCategory(selectedCategory)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = categories[indexPath.row]
            
            // 检查分类是否有关联的任务
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            
            do {
                let tasks = try coreDataManager.context.fetch(fetchRequest)
                if !tasks.isEmpty {
                    // 显示警告
                    let alert = UIAlertController(
                        title: NSLocalizedString("Warning", comment: ""),
                        message: NSLocalizedString("This category has associated tasks. Deleting it will also delete all associated tasks.", comment: ""),
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel
                    ))
                    
                    alert.addAction(UIAlertAction(
                        title: NSLocalizedString("Delete", comment: ""),
                        style: .destructive
                    ) { [weak self] _ in
                        self?.deleteCategory(at: indexPath)
                    })
                    
                    present(alert, animated: true)
                } else {
                    // 直接删除
                    deleteCategory(at: indexPath)
                }
            } catch {
                print("Error fetching tasks: \(error)")
            }
        }
    }
    
    private func deleteCategory(at indexPath: IndexPath) {
        let category = categories[indexPath.row]
        coreDataManager.context.delete(category)
        
        do {
            try coreDataManager.context.save()
            categories.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } catch {
            print("Error deleting category: \(error)")
        }
    }
}

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

// MARK: - CategorySelectionDelegate
protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: Category)
}

// 添加观察者以在任务更新时刷新列表
extension CategoryListViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次视图出现时刷新数据
        loadCategories()
    }
}

// MARK: - Theme Support
extension CategoryListViewController {
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
