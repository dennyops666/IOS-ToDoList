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
    private let manager = Database.shared
    
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
            picker.preferredDatePickerStyle = .compact
        }
        picker.isUserInteractionEnabled = true
        return picker
    }()
    
    private let dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .compact
        }
        picker.isUserInteractionEnabled = true
        return picker
    }()
    
    private let reminderToggle: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        return toggleSwitch
    }()
    
    private let reminderLabel: UILabel = {
        let label = UILabel()
        label.text = "开启提醒"
        label.translatesAutoresizingMaskIntoConstraints = false
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
        view.isUserInteractionEnabled = true
        
        // 设置导航栏按钮
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
        
        reminderToggle.addTarget(self, 
                               action: #selector(reminderToggleChanged), 
                               for: .valueChanged)
        
        // 确保视图层级的交互性
        //view.isUserInteractionEnabled = true
        //scrollView.isUserInteractionEnabled = true
        //contentView.isUserInteractionEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 不再需要设置 contentSize，因为已经移除了 scrollView
        // 如果需要，可以在这里添加其他布局相关的代码
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = task == nil ? "新建任务" : "编辑任务"
        
        // 添加控件到主视图
        view.addSubview(titleTextField)
        view.addSubview(notesTextView)
        view.addSubview(categoryButton)
        
        // 创建日期选择器的stack views
        let startDateStack = createLabeledDatePicker(label: "开始时间:", picker: startDatePicker)
        let dueDateStack = createLabeledDatePicker(label: "截止时间:", picker: dueDatePicker)
        
        view.addSubview(startDateStack)
        view.addSubview(dueDateStack)
        
        // 创建提醒控制的stack view
        let reminderStack = UIStackView()
        reminderStack.translatesAutoresizingMaskIntoConstraints = false
        reminderStack.axis = .horizontal
        reminderStack.spacing = 8
        reminderStack.isUserInteractionEnabled = true
        
        reminderLabel.text = "开启提醒"
        reminderLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        reminderStack.addArrangedSubview(reminderLabel)
        reminderStack.addArrangedSubview(reminderToggle)
        
        view.addSubview(reminderStack)
        
        // 确保所有控件都启用了用户交互
        titleTextField.isUserInteractionEnabled = true
        notesTextView.isUserInteractionEnabled = true
        categoryButton.isUserInteractionEnabled = true
        startDatePicker.isUserInteractionEnabled = true
        dueDatePicker.isUserInteractionEnabled = true
        reminderToggle.isUserInteractionEnabled = true
    }
    
    private func createLabeledDatePicker(label text: String, picker: UIDatePicker) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 8
        stack.isUserInteractionEnabled = true
        
        let label = UILabel()
        label.text = text
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        picker.isUserInteractionEnabled = true
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(picker)
        
        return stack
    }
    
    private func setupConstraints() {
        guard let startDateStack = view.subviews.first(where: { $0 is UIStackView && ($0 as? UIStackView)?.arrangedSubviews.contains(startDatePicker) ?? false }) as? UIStackView,
              let dueDateStack = view.subviews.first(where: { $0 is UIStackView && ($0 as? UIStackView)?.arrangedSubviews.contains(dueDatePicker) ?? false }) as? UIStackView,
              let reminderStack = view.subviews.first(where: { $0 is UIStackView && ($0 as? UIStackView)?.arrangedSubviews.contains(reminderToggle) ?? false }) as? UIStackView
        else {
            return
        }
        
        NSLayoutConstraint.activate([
            // 标题和备注约束
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            categoryButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // 日期选择器和提醒栈视图约束
            startDateStack.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 16),
            startDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dueDateStack.topAnchor.constraint(equalTo: startDateStack.bottomAnchor, constant: 16),
            dueDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dueDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            reminderStack.topAnchor.constraint(equalTo: dueDateStack.bottomAnchor, constant: 16),
            reminderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            reminderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        
        startDatePicker.addTarget(self, 
                                action: #selector(datePickerValueChanged(_:)), 
                                for: .valueChanged)
        
        dueDatePicker.addTarget(self, 
                               action: #selector(datePickerValueChanged(_:)), 
                               for: .valueChanged)
        
        reminderToggle.addTarget(self, 
                               action: #selector(reminderToggleChanged(_:)),
                                 for: .touchUpInside)
    }
    
    @objc private func categoryButtonTapped() {
        let actionSheet = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加"无分类"选项
        actionSheet.addAction(UIAlertAction(title: "无分类", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.categoryButton.setTitle("无分类", for: .normal)
        })
        
        // 添加现有分类
        let categories = Database.shared.fetchCategories()
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
            if Database.shared.isCategoryNameExists(name) {
                let errorAlert = UIAlertController(
                    title: "错误",
                    message: "已存在相同名称的分类",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }
            
            let category = Database.shared.createCategory(name)
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
        if Database.shared.isTaskNameExists(title) && (task?.title != title) {
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
            Database.shared.updateTask(existingTask)
            delegate?.taskDetailViewController(self, didSaveTask: existingTask)
        } else {
            // 创建新任务
            let newTask = Database.shared.createTask(
                title: title,
                notes: notes,
                dueDate: dueDatePicker.date,
                category: selectedCategory
            )
            delegate?.taskDetailViewController(self, didSaveTask: newTask)
        }
        
        // 处理提醒
        if reminderToggle.isOn {
            scheduleNotification(for: title, at: startDatePicker.date)
        } else {
            // 如果关闭提醒,删除现有提醒
            if let task = task {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: [task.objectID.uriRepresentation().absoluteString]
                )
            }
        }
        
        dismiss(animated: true)
    }
    
    private func scheduleNotification(for taskTitle: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = "任务 '\(taskTitle)' 开始时间到了"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = task?.objectID.uriRepresentation().absoluteString ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("设置提醒失败: \(error)")
            }
        }
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        // 处理日期选择器值变化
        if sender == startDatePicker {
            print("开始时间已更改: \(sender.date)")
        } else if sender == dueDatePicker {
            print("截止时间已更改: \(sender.date)")
        }
    }
    
    @objc private func reminderToggleChanged(_ sender: UISwitch) {
        if sender.isOn {
            let alert = UIAlertController(
                title: "提醒已开启",
                message: "将在任务开始时间提醒您",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func setupDatePicker() {
        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.minimumDate = Date() // 设置最小日期为当前时间
        dueDatePicker.addTarget(self, 
                              action: #selector(datePickerValueChanged(_:)),  // 修正参数
                              for: .valueChanged)
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
