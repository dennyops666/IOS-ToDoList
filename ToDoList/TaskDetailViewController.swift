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
    
    private let priorityButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("优先级：低", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return button
    }()
    
    private var selectedPriority: TaskPriority = .low
    
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
        setupActions()
        
        if isEditingMode, let task = task {
            loadTaskData()
        }
        
        reminderToggle.addTarget(self, 
                               action: #selector(reminderToggleChanged), 
                               for: .valueChanged)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 不再需要设置 contentSize，因为已经移除了 scrollView
        // 如果需要，可以在这里添加其他布局相关的代码
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = task == nil ? "新建任务" : "编辑任务"
        
        // 创建优先级选择器的 stack view
        let priorityLabel = UILabel()
        priorityLabel.text = "优先级"
        priorityLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        let priorityStack = UIStackView(arrangedSubviews: [priorityLabel, priorityButton])
        priorityStack.translatesAutoresizingMaskIntoConstraints = false
        priorityStack.axis = .horizontal
        priorityStack.spacing = 8
        priorityStack.distribution = .fill
        
        // 添加到视图层次结构
        view.addSubview(titleTextField)
        view.addSubview(notesTextView)
        view.addSubview(categoryButton)
        view.addSubview(priorityStack)
        
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
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 标题和备注约束
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // 分类按钮约束
            categoryButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 优先级栈视图约束
            priorityStack.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 16),
            priorityStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            priorityStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 日期选择器约束
            startDateStack.topAnchor.constraint(equalTo: priorityStack.bottomAnchor, constant: 16),
            startDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dueDateStack.topAnchor.constraint(equalTo: startDateStack.bottomAnchor, constant: 16),
            dueDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dueDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // 提醒栈视图约束
            reminderStack.topAnchor.constraint(equalTo: dueDateStack.bottomAnchor, constant: 16),
            reminderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            reminderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
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
        
        priorityButton.addTarget(self, action: #selector(priorityButtonTapped), for: .touchUpInside)
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
            existingTask.title = title
            existingTask.notes = notes
            existingTask.dueDate = dueDatePicker.date
            existingTask.priority = selectedPriority.rawValue
            Database.shared.updateTask(existingTask, category: selectedCategory)
            delegate?.taskDetailViewController(self, didSaveTask: existingTask)
        } else {
            let newTask = Database.shared.createTask(
                title: title,
                notes: notes,
                dueDate: dueDatePicker.date,
                category: selectedCategory,
                priority: selectedPriority
            )
            delegate?.taskDetailViewController(self, didSaveTask: newTask)
        }
        
        // 处理提醒
        if reminderToggle.isOn {
            // 先请求通知权限
            requestNotificationPermission { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.scheduleNotification(for: title, at: self.startDatePicker.date)
                }
            }
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
    
    // 添加请求通知权限的方法
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("通知权限请求失败: \(error)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
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
        
        // 添加处理通知请求的方法
        addNotificationRequest(request)
    }
    
    // 添加处理通知请求的方法
    private func addNotificationRequest(_ request: UNNotificationRequest) {
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
    
    // 添加内存警告处理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // 清理非必要资源
    }
    
    // 优化图片和资源加载
    private func loadResources() {
        if #available(iOS 15.0, *) {
            // 使用新的异步图片加载
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                // 异步加载资源
                DispatchQueue.main.async {
                    // 在主线程更新 UI
                }
            }
        } else {
            // 兼容旧版本
            // 使用传统的图片加载方式
        }
    }
    
    @objc private func priorityButtonTapped() {
        let actionSheet = UIAlertController(title: "选择优先级", message: nil, preferredStyle: .actionSheet)
        
        TaskPriority.allCases.forEach { priority in
            let action = UIAlertAction(title: priority.title, style: .default) { [weak self] _ in
                self?.selectedPriority = priority
                self?.updatePriorityButton()
            }
            actionSheet.addAction(action)
        }
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = priorityButton
            popoverController.sourceRect = priorityButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func updatePriorityButton() {
        priorityButton.setTitle("优先级：\(selectedPriority.title)", for: .normal)
        priorityButton.setTitleColor(selectedPriority.color, for: .normal)
    }
    
    // 添加加载任务数据的方法
    private func loadTaskData() {
        guard let task = task else { return }
        titleTextField.text = task.title
        notesTextView.text = task.notes
        notesTextView.textColor = .label
        categoryButton.setTitle(task.category?.name ?? "无分类", for: .normal)
        selectedPriority = TaskPriority(rawValue: task.priority) ?? .low
        updatePriorityButton()
        
        if let dueDate = task.dueDate {
            dueDatePicker.date = dueDate
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
