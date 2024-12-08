import UIKit
import CoreData

protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetailViewController(_ controller: TaskDetailViewController, didUpdateTask task: Task)
}

class TaskDetailViewController: UIViewController {
    
    weak var delegate: TaskDetailViewControllerDelegate?
    private let task: Task
    
    private lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "任务标题"
        textField.borderStyle = .roundedRect
        textField.text = task.title
        textField.accessibilityIdentifier = "taskTitleTextField"
        return textField
    }()
    
    private lazy var notesTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = task.notes
        textView.font = .systemFont(ofSize: 16)
        return textView
    }()
    
    private lazy var dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        if let dueDate = task.dueDate {
            picker.date = dueDate
        }
        return picker
    }()
    
    private lazy var prioritySegmentedControl: UISegmentedControl = {
        let items = ["低", "中", "高"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = Int(task.priority)
        return control
    }()
    
    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(task.category?.name ?? "选择分类", for: .normal)
        button.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    init(task: Task) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "编辑任务"
        
        // 导航栏按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        // 布局视图
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        // 添加子视图
        stackView.addArrangedSubview(titleTextField)
        
        let categoryLabel = UILabel()
        categoryLabel.text = "分类"
        stackView.addArrangedSubview(categoryLabel)
        stackView.addArrangedSubview(categoryButton)
        
        let notesLabel = UILabel()
        notesLabel.text = "备注"
        stackView.addArrangedSubview(notesLabel)
        stackView.addArrangedSubview(notesTextView)
        
        let dueDateLabel = UILabel()
        dueDateLabel.text = "截止日期"
        stackView.addArrangedSubview(dueDateLabel)
        stackView.addArrangedSubview(dueDatePicker)
        
        let priorityLabel = UILabel()
        priorityLabel.text = "优先级"
        stackView.addArrangedSubview(priorityLabel)
        stackView.addArrangedSubview(prioritySegmentedControl)
        
        // 设置约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            notesTextView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    @objc private func categoryButtonTapped() {
        let actionSheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加"无分类"选项
        actionSheet.addAction(UIAlertAction(title: "无分类", style: .default) { [weak self] _ in
            self?.task.category = nil
            self?.categoryButton.setTitle("选择分类", for: .normal)
        })
        
        // 添加现有分类
        let categories = CoreDataManager.shared.fetchCategories()
        for category in categories {
            actionSheet.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.task.category = category
                self?.categoryButton.setTitle(category.name, for: .normal)
            })
        }
        
        // 添加新建分类选项
        actionSheet.addAction(UIAlertAction(title: "新建分类...", style: .default) { [weak self] _ in
            self?.showCreateCategoryAlert()
        })
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 对于iPad，需要设置弹出位置
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = categoryButton
            popoverController.sourceRect = categoryButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func showCreateCategoryAlert() {
        let alert = UIAlertController(title: "新建分类", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "分类名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            
            let category = CoreDataManager.shared.createCategory(name: name)
            self?.task.category = category
            self?.categoryButton.setTitle(category.name, for: .normal)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        // 更新任务
        task.title = titleTextField.text ?? ""
        task.notes = notesTextView.text
        task.dueDate = dueDatePicker.date
        task.priority = Int16(prioritySegmentedControl.selectedSegmentIndex)
        
        // 保存更改
        CoreDataManager.shared.updateTask(task)
        
        // 通知代理
        delegate?.taskDetailViewController(self, didUpdateTask: task)
        
        // 返回上一页
        navigationController?.popViewController(animated: true)
    }
} 