import UIKit
import CoreData
import UserNotifications

protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetailViewController(_ controller: TaskDetailViewController, didSaveTask task: Task)
}

class TaskDetailViewController: UIViewController {
    
    weak var delegate: TaskDetailViewControllerDelegate?
    private var task: Task?
    private var selectedCategory: Category?
    private var isEditingMode: Bool = false
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "任务名称"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let notesTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.font = .systemFont(ofSize: 16)
        return textView
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("选择分类", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return button
    }()
    
    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
           // picker.preferredDatePickerStyle = .compact  //使用完成日历样式
            picker.preferredDatePickerStyle = .automatic  //根据当前平台和日期选择器模式选择具体风格
        }
        return picker
    }()
    
    private let dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .compact
        }
        return picker
    }()
    
    private let reminderDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .compact
        }
        return picker
    }()
    
    private let reminderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "提醒时间:"
        label.textColor = .label
        return label
    }()
    
    init(task: Task? = nil) {
        self.task = task
        self.isEditingMode = task != nil
        self.selectedCategory = task?.category
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        
        if isEditingMode, let task = task {
            // 填充现有任务数据
            titleTextField.text = task.title
            notesTextView.text = task.notes
            notesTextView.textColor = .label
            categoryButton.setTitle(task.category?.name ?? "无分类", for: .normal)
            if let dueDate = task.dueDate {
                dueDatePicker.date = dueDate
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = task == nil ? "新建任务" : "编辑任务"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleTextField)
        contentView.addSubview(notesTextView)
        contentView.addSubview(categoryButton)
        
        // 创建日期选择器的stack views
        let startDateStack = createLabeledDatePicker(label: "开始时间:", picker: startDatePicker)
        let dueDateStack = createLabeledDatePicker(label: "截止时间:", picker: dueDatePicker)
        
        contentView.addSubview(startDateStack)
        contentView.addSubview(dueDateStack)
        
        notesTextView.text = "添加备注..."
        notesTextView.textColor = .placeholderText
        notesTextView.delegate = self
        
        // 添加提醒时间标签
        contentView.addSubview(reminderLabel)
        NSLayoutConstraint.activate([
            reminderLabel.topAnchor.constraint(equalTo: dueDatePicker.bottomAnchor, constant: 20),
            reminderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
        
        // 添加提醒时间选择器
        contentView.addSubview(reminderDatePicker)
        NSLayoutConstraint.activate([
            reminderDatePicker.centerYAnchor.constraint(equalTo: reminderLabel.centerYAnchor),
            reminderDatePicker.leadingAnchor.constraint(equalTo: reminderLabel.trailingAnchor, constant: 10),
            reminderDatePicker.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func createLabeledDatePicker(label text: String, picker: UIDatePicker) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        
        let label = UILabel()
        label.text = text
        label.setContentHuggingPriority(.required, for: .horizontal)
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(picker)
        
        return stack
    }
    
    private func setupConstraints() {
        // 获取已经在setupUI中创建的stack views
        guard let startDateStack = contentView.subviews.first(where: { $0 is UIStackView && ($0 as? UIStackView)?.arrangedSubviews.contains(startDatePicker) ?? false }) as? UIStackView,
              let dueDateStack = contentView.subviews.first(where: { $0 is UIStackView && ($0 as? UIStackView)?.arrangedSubviews.contains(dueDatePicker) ?? false }) as? UIStackView
        else {
            return
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            notesTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            categoryButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            startDateStack.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 16),
            startDateStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            startDateStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            dueDateStack.topAnchor.constraint(equalTo: startDateStack.bottomAnchor, constant: 16),
            dueDateStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dueDateStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dueDateStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            reminderLabel.topAnchor.constraint(equalTo: dueDatePicker.bottomAnchor, constant: 20),
            reminderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            reminderDatePicker.centerYAnchor.constraint(equalTo: reminderLabel.centerYAnchor),
            reminderDatePicker.leadingAnchor.constraint(equalTo: reminderLabel.trailingAnchor, constant: 10),
            reminderDatePicker.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
    }
    
    @objc private func categoryButtonTapped() {
        let actionSheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加"无分类"选项
        actionSheet.addAction(UIAlertAction(title: "无分类", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.categoryButton.setTitle("无分类", for: .normal)
        })
        
        // 添加现有分类
        let categories = CoreDataManager.shared.fetchCategories()
        for category in categories {
            actionSheet.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.selectedCategory = category
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
            self?.selectedCategory = category
            self?.categoryButton.setTitle(category.name, for: .normal)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            // 显示错误提示
            let alert = UIAlertController(
                title: "错误",
                message: "请输入任务名称",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 检查任务名称是否重复
        if CoreDataManager.shared.isTaskNameExists(title) && (task?.title != title) {
            let alert = UIAlertController(
                title: "错误",
                message: "已存在相同名称的任务",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        
        let notes = notesTextView.text == "添加备注..." ? nil : notesTextView.text
        
        if isEditingMode, let existingTask = task {
            // 更新现有任务
            existingTask.title = title
            existingTask.notes = notes
            existingTask.dueDate = dueDatePicker.date
            existingTask.category = selectedCategory
            CoreDataManager.shared.updateTask(existingTask)
            delegate?.taskDetailViewController(self, didSaveTask: existingTask)
        } else {
            // 创建新任务
            let newTask = CoreDataManager.shared.createTask(
                title: title,
                notes: notes,
                dueDate: dueDatePicker.date,
                category: selectedCategory
            )
            delegate?.taskDetailViewController(self, didSaveTask: newTask)
        }
        
        // 设置任务提醒
        let reminderDate = reminderDatePicker.date
        if reminderDate > Date() {
            scheduleNotification(for: title, at: reminderDate)
        }
        
        dismiss(animated: true)
    }
    
    private func scheduleNotification(for taskTitle: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = "任务 '\(taskTitle)' 即将到期"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("调度通知失败: \(error)")
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension TaskDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "添加备注..."
            textView.textColor = .placeholderText
        }
    }
} 
