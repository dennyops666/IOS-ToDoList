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
    private let manager = CoreDataStack.shared
    private var hasTimeConflict = false
    private var conflictingTasks: [Task] = []
    
    // MARK: - UI Components
    
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
        return textView
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("选择分类", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 5
        return button
    }()
    
    private let priorityButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("设置优先级", for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 5
        return button
    }()
    
    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    
    private let dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        return picker
    }()
    
    private let reminderSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let timeValidationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()
    
    private let conflictLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.alpha = 0
        return label
    }()
    
    private let conflictOptionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.alpha = 0
        return stackView
    }()
    
    private let priorityStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let startDateStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        return stackView
    }()
    
    private let dueDateStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        return stackView
    }()
    
    private let reminderStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: - Initialization
    
    init(task: Task? = nil) {
        self.task = task
        self.isEditingMode = task != nil
        self.selectedCategory = task?.category
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        configureNavigationBar()
        loadTaskData()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = task == nil ? "新建任务" : "编辑任务"
        
        view.addSubview(titleTextField)
        view.addSubview(notesTextView)
        view.addSubview(categoryButton)
        view.addSubview(priorityStack)
        view.addSubview(startDateStack)
        view.addSubview(dueDateStack)
        view.addSubview(reminderStack)
        view.addSubview(timeValidationLabel)
        view.addSubview(conflictLabel)
        view.addSubview(conflictOptionsStackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            notesTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 100),
            
            categoryButton.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 16),
            categoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            priorityStack.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 16),
            priorityStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            priorityStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            startDateStack.topAnchor.constraint(equalTo: priorityStack.bottomAnchor, constant: 16),
            startDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dueDateStack.topAnchor.constraint(equalTo: startDateStack.bottomAnchor, constant: 16),
            dueDateStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dueDateStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            reminderStack.topAnchor.constraint(equalTo: dueDateStack.bottomAnchor, constant: 16),
            reminderStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            reminderStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            timeValidationLabel.topAnchor.constraint(equalTo: reminderStack.bottomAnchor, constant: 16),
            timeValidationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timeValidationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            conflictLabel.topAnchor.constraint(equalTo: timeValidationLabel.bottomAnchor, constant: 16),
            conflictLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            conflictLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            conflictOptionsStackView.topAnchor.constraint(equalTo: conflictLabel.bottomAnchor, constant: 8),
            conflictOptionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            conflictOptionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // 添加优先级按钮
        for priority in TaskPriority.allCases {
            let button = createPriorityButton(for: priority)
            priorityStack.addArrangedSubview(button)
        }
        
        // 设置日期选择器和标签
        let startDateLabel = UILabel()
        startDateLabel.text = "开始时间"
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateStack.addArrangedSubview(startDateLabel)
        startDateStack.addArrangedSubview(startDatePicker)
        
        let dueDateLabel = UILabel()
        dueDateLabel.text = "截止时间"
        dueDateLabel.translatesAutoresizingMaskIntoConstraints = false
        dueDateStack.addArrangedSubview(dueDateLabel)
        dueDateStack.addArrangedSubview(dueDatePicker)
        
        // 设置提醒开关和标签
        let reminderLabel = UILabel()
        reminderLabel.text = "开启提醒"
        reminderLabel.translatesAutoresizingMaskIntoConstraints = false
        reminderStack.addArrangedSubview(reminderLabel)
        reminderStack.addArrangedSubview(reminderSwitch)
        
        // 添加冲突处理按钮
        let continueButton = UIButton(type: .system)
        continueButton.setTitle("继续保存", for: .normal)
        continueButton.addTarget(self, action: #selector(continueWithConflict), for: .touchUpInside)
        
        let adjustButton = UIButton(type: .system)
        adjustButton.setTitle("自动调整时间", for: .normal)
        adjustButton.addTarget(self, action: #selector(autoAdjustTime), for: .touchUpInside)
        
        conflictOptionsStackView.addArrangedSubview(continueButton)
        conflictOptionsStackView.addArrangedSubview(adjustButton)
    }
    
    private func setupActions() {
        categoryButton.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        startDatePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        dueDatePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
    }
    
    private func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
    }
    
    private func loadTaskData() {
        guard let task = task else { return }
        
        titleTextField.text = task.title
        notesTextView.text = task.notes
        startDatePicker.date = task.createdAt ?? Date()
        dueDatePicker.date = task.dueDate ?? Date()
        reminderSwitch.isOn = task.hasReminder
        
        if let category = task.category {
            selectedCategory = category
            categoryButton.setTitle(category.name, for: .normal)
        }
        
        if let priority = TaskPriority(rawValue: task.priority) {
            updatePriorityButtons(with: priority)
        }
    }
    
    // MARK: - Action Methods
    
    @objc private func saveButtonTapped() {
        guard validateInput() else { return }
        
        let context = manager.context
        let taskToSave = task ?? Task(context: context)
        
        taskToSave.title = titleTextField.text
        taskToSave.notes = notesTextView.text
        taskToSave.createdAt = startDatePicker.date
        taskToSave.dueDate = dueDatePicker.date
        taskToSave.category = selectedCategory
        taskToSave.hasReminder = reminderSwitch.isOn
        
        // 设置默认优先级
        if taskToSave.priority == 0 {
            taskToSave.priority = TaskPriority.medium.rawValue
        }
        
        if reminderSwitch.isOn {
            scheduleReminder(for: taskToSave)
        }
        
        do {
            try context.save()
            delegate?.taskDetailViewController(self, didSaveTask: taskToSave)
            navigationController?.popViewController(animated: true)
        } catch {
            showAlert(title: "保存失败", message: error.localizedDescription)
        }
    }
    
    @objc private func categoryButtonTapped() {
        let categoryVC = CategoryViewController()
        categoryVC.delegate = self
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
    }
    
    @objc private func datePickerValueChanged() {
        validateTimeSelection()
    }
    
    @objc private func priorityButtonTapped(_ sender: UIButton) {
        guard let priority = TaskPriority(rawValue: Int16(sender.tag)) else { return }
        updatePriorityButtons(with: priority)
        task?.priority = priority.rawValue
    }
    
    // MARK: - Helper Methods
    
    private func createPriorityButton(for priority: TaskPriority) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(priority.title, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 5
        button.tag = Int(priority.rawValue)
        button.addTarget(self, action: #selector(priorityButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func updatePriorityButtons(with priority: TaskPriority) {
        for case let button as UIButton in priorityStack.arrangedSubviews {
            let buttonPriority = TaskPriority(rawValue: Int16(button.tag))
            button.backgroundColor = buttonPriority == priority ? priority.color : .systemGray6
            button.setTitleColor(buttonPriority == priority ? .white : .systemBlue, for: .normal)
        }
    }
    
    private func validateInput() -> Bool {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(title: "错误", message: "请输入任务名称")
            return false
        }
        
        guard startDatePicker.date < dueDatePicker.date else {
            showAlert(title: "错误", message: "开始时间必须早于截止时间")
            return false
        }
        
        return true
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Time Validation
    
    private func validateTimeSelection() {
        let startDate = startDatePicker.date
        let dueDate = dueDatePicker.date
        
        let isValid = startDate < dueDate
        
        startDatePicker.tintColor = isValid ? .systemGreen : .systemRed
        dueDatePicker.tintColor = isValid ? .systemGreen : .systemRed
        
        timeValidationLabel.text = isValid ? "✓ 时间设置有效" : "⚠️ 开始时间必须早于截止时间"
        timeValidationLabel.textColor = isValid ? .systemGreen : .systemRed
        
        UIView.animate(withDuration: 0.3) {
            self.timeValidationLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.3) {
                self.timeValidationLabel.alpha = 0.0
            }
        }
        
        if isValid {
            checkTimeConflicts()
        }
    }
    
    private func checkTimeConflicts() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        let startDate = startDatePicker.date
        let dueDate = dueDatePicker.date
        
        let predicate = NSPredicate(format: "(createdAt <= %@ AND dueDate >= %@) OR (createdAt <= %@ AND dueDate >= %@)",
                                  dueDate as NSDate,
                                  startDate as NSDate,
                                  startDate as NSDate,
                                  dueDate as NSDate)
        
        if let currentTask = task {
            let notCurrentTask = NSPredicate(format: "self != %@", currentTask)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, notCurrentTask])
        } else {
            fetchRequest.predicate = predicate
        }
        
        do {
            let allTasks = try manager.context.fetch(fetchRequest)
            conflictingTasks = allTasks
            hasTimeConflict = !allTasks.isEmpty
            
            if hasTimeConflict {
                showConflictWarning()
            } else {
                hideConflictWarning()
            }
        } catch {
            print("Error checking time conflicts: \(error)")
        }
    }
    
    private func showConflictWarning() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        var conflictMessages: [String] = []
        for task in conflictingTasks {
            let startTime = formatter.string(from: task.createdAt ?? Date())
            let endTime = formatter.string(from: task.dueDate ?? Date())
            conflictMessages.append("\(task.title ?? ""): \(startTime)-\(endTime)")
        }
        
        conflictLabel.text = "发现时间冲突：\n" + conflictMessages.joined(separator: "\n")
        
        UIView.animate(withDuration: 0.3) {
            self.conflictLabel.alpha = 1
            self.conflictOptionsStackView.alpha = 1
        }
    }
    
    private func hideConflictWarning() {
        UIView.animate(withDuration: 0.3) {
            self.conflictLabel.alpha = 0
            self.conflictOptionsStackView.alpha = 0
        }
    }
    
    @objc private func continueWithConflict() {
        hideConflictWarning()
    }
    
    @objc private func autoAdjustTime() {
        var newStartDate = startDatePicker.date
        let duration = dueDatePicker.date.timeIntervalSince(startDatePicker.date)
        
        let sortedTasks = conflictingTasks.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        
        for task in sortedTasks {
            if let taskDueDate = task.dueDate {
                newStartDate = taskDueDate.addingTimeInterval(60)
                let newDueDate = newStartDate.addingTimeInterval(duration)
                
                startDatePicker.date = newStartDate
                dueDatePicker.date = newDueDate
                
                validateTimeSelection()
                break
            }
        }
    }
    
    // MARK: - Reminder Methods
    
    private func scheduleReminder(for task: Task) {
        guard task.hasReminder else { return }
        
        if let identifier = task.reminderIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = task.title ?? "任务即将开始"
        content.sound = .default
        
        let triggerDate = task.createdAt ?? Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = UUID().uuidString
        task.reminderIdentifier = identifier
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// MARK: - CategoryViewControllerDelegate

extension TaskDetailViewController: CategoryViewControllerDelegate {
    func categoryViewController(_ controller: CategoryViewController, didSelectCategory category: Category) {
        selectedCategory = category
        categoryButton.setTitle(category.name, for: .normal)
        dismiss(animated: true)
    }
}
