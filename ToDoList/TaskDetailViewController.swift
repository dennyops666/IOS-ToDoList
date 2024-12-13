import UIKit
import CoreData

protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetailViewController(_ controller: TaskDetailViewController, didSaveTask task: Task)
    func taskDetailViewController(_ controller: TaskDetailViewController, didDeleteTask task: Task)
}

class TaskDetailViewController: UIViewController {
    
    // MARK: - Properties
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var titleTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "任务标题"
        textField.borderStyle = .roundedRect
        textField.delegate = self
        return textField
    }()
    
    private lazy var prioritySegmentControl: UISegmentedControl = {
        let items = ["低", "中", "高"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1 // 默认中优先级
        return control
    }()
    
    private lazy var startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        return picker
    }()
    
    private lazy var dueDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: #selector(dueDateChanged), for: .valueChanged)
        return picker
    }()
    
    private lazy var reminderSwitch: UISwitch = {
        let reminderSwitch = UISwitch()
        reminderSwitch.addTarget(self, action: #selector(reminderSwitchChanged), for: .valueChanged)
        return reminderSwitch
    }()
    
    private lazy var notesTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 5
        textView.font = .systemFont(ofSize: 16)
        return textView
    }()
    
    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("选择分类", for: .normal)
        button.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var task: Task?
    var selectedCategory: Category?
    weak var delegate: TaskDetailViewControllerDelegate?
    var coreDataManager: CoreDataManager!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureWithTask()
    }
    
    // MARK: - Setup
    
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
        
        if task != nil {
            let deleteButton = UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(deleteButtonTapped)
            )
            deleteButton.tintColor = .systemRed
            navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, deleteButton]
        }
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // 添加标题输入框
        let titleStack = createLabeledStack(label: "标题:", view: titleTextField)
        contentStackView.addArrangedSubview(titleStack)
        
        // 添加优先级选择
        let priorityStack = createLabeledStack(label: "优先级:", view: prioritySegmentControl)
        contentStackView.addArrangedSubview(priorityStack)
        
        // 添加开始时间选择器
        let startDateStack = createLabeledStack(label: "开始时间:", view: startDatePicker)
        contentStackView.addArrangedSubview(startDateStack)
        
        // 添加截止时间选择器
        let dueDateStack = createLabeledStack(label: "截止时间:", view: dueDatePicker)
        contentStackView.addArrangedSubview(dueDateStack)
        
        // 添加提醒开关
        let reminderStack = createLabeledStack(label: "开启提醒:", view: reminderSwitch)
        contentStackView.addArrangedSubview(reminderStack)
        
        // 添加分类选择按钮
        let categoryStack = createLabeledStack(label: "分类:", view: categoryButton)
        contentStackView.addArrangedSubview(categoryStack)
        
        // 添加备注输入区域
        let notesLabel = UILabel()
        notesLabel.text = "备注:"
        contentStackView.addArrangedSubview(notesLabel)
        contentStackView.addArrangedSubview(notesTextView)
        notesTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func configureWithTask() {
        guard let task = task else {
            // 设置默认值
            startDatePicker.date = Date()
            dueDatePicker.date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            return
        }
        
        titleTextField.text = task.title
        notesTextView.text = task.notes
        prioritySegmentControl.selectedSegmentIndex = Int(task.priority)
        
        if let startDate = task.createdAt {
            startDatePicker.date = startDate
        }
        
        if let dueDate = task.dueDate {
            dueDatePicker.date = dueDate
        }
        
        reminderSwitch.isOn = task.hasReminder
        updateCategoryButtonTitle()
    }
    
    private func createLabeledStack(label text: String, view: UIView) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        
        let label = UILabel()
        label.text = text
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(view)
        
        return stack
    }
    
    private func updateCategoryButtonTitle() {
        if let category = selectedCategory ?? task?.category {
            categoryButton.setTitle(category.name, for: .normal)
        } else {
            categoryButton.setTitle("选择分类", for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func startDateChanged() {
        validateDateRange()
    }
    
    @objc private func dueDateChanged() {
        validateDateRange()
    }
    
    @objc private func reminderSwitchChanged() {
        if reminderSwitch.isOn {
            requestNotificationPermission()
        }
    }
    
    private func validateDateRange() {
        if dueDatePicker.date < startDatePicker.date {
            showAlert(message: "截止时间不能早于开始时间")
            dueDatePicker.date = Calendar.current.date(byAdding: .hour, value: 1, to: startDatePicker.date) ?? startDatePicker.date
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    self.reminderSwitch.isOn = false
                    self.showAlert(message: "需要通知权限来设置提醒")
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            showAlert(message: "请输入任务标题")
            return
        }
        
        let currentTask = task ?? Task(context: coreDataManager.context)
        currentTask.title = title
        currentTask.notes = notesTextView.text
        currentTask.priority = Int16(prioritySegmentControl.selectedSegmentIndex)
        currentTask.createdAt = startDatePicker.date
        currentTask.dueDate = dueDatePicker.date
        currentTask.hasReminder = reminderSwitch.isOn
        currentTask.category = selectedCategory ?? task?.category
        
        if reminderSwitch.isOn {
            scheduleReminder(for: currentTask)
        }
        
        coreDataManager.saveContext()
        delegate?.taskDetailViewController(self, didSaveTask: currentTask)
        dismiss(animated: true)
    }
    
    private func scheduleReminder(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = task.title ?? ""
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate ?? Date())
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = task.reminderIdentifier ?? UUID().uuidString
        task.reminderIdentifier = identifier
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc private func deleteButtonTapped() {
        guard let task = task else { return }
        
        let alert = UIAlertController(
            title: "删除任务",
            message: "确定要删除这个任务吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // 如果有提醒，删除提醒
            if let identifier = task.reminderIdentifier {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            }
            
            self.coreDataManager.deleteTask(task)
            self.delegate?.taskDetailViewController(self, didDeleteTask: task)
            self.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func categoryButtonTapped() {
        let alert = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        
        // 添加现有分类
        let categories = coreDataManager.fetchCategories()
        for category in categories {
            alert.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.updateCategoryButtonTitle()
            })
        }
        
        // 添加创建新分类的选项
        alert.addAction(UIAlertAction(title: "新建分类", style: .default) { [weak self] _ in
            self?.showNewCategoryAlert()
        })
        
        // 添加取消选项
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 对于iPad，需要设置弹出位置
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryButton
            popover.sourceRect = categoryButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showNewCategoryAlert() {
        let alert = UIAlertController(
            title: "新建分类",
            message: "请输入分类名称",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "分类名称"
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let categoryName = textField.text,
                  !categoryName.isEmpty else { return }
            
            if !self.coreDataManager.isCategoryNameExists(categoryName) {
                let newCategory = self.coreDataManager.createCategory(name: categoryName)
                self.selectedCategory = newCategory
                self.updateCategoryButtonTitle()
            } else {
                self.showAlert(message: "分类名称已存在")
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "提示",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension TaskDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
