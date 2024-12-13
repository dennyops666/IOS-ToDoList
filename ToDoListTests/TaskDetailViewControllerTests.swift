import XCTest
@testable import ToDoList

class TaskDetailViewControllerTests: XCTestCase {
    
    var sut: TaskDetailViewController!
    var mockManager: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        mockManager = CoreDataStack(modelName: "ToDoList", inMemory: true)
        sut = TaskDetailViewController()
    }
    
    override func tearDown() {
        sut = nil
        mockManager = nil
        super.tearDown()
    }
    
    // MARK: - 实时视觉反馈测试
    
    func testInvalidTimeSelection() {
        // 设置开始时间和结束时间
        let currentDate = Date()
        let invalidEndDate = currentDate.addingTimeInterval(-3600) // 结束时间比开始时间早1小时
        
        // 触发时间验证
        sut.loadViewIfNeeded()
        sut.startDatePicker.date = currentDate
        sut.dueDatePicker.date = invalidEndDate
        sut.datePickerValueChanged()
        
        // 验证视觉反馈
        XCTAssertEqual(sut.startDatePicker.tintColor, .systemRed)
        XCTAssertEqual(sut.dueDatePicker.tintColor, .systemRed)
        XCTAssertEqual(sut.timeValidationLabel.textColor, .systemRed)
        XCTAssertEqual(sut.timeValidationLabel.text, "⚠️ 开始时间必须早于截止时间")
        XCTAssertEqual(sut.timeValidationLabel.alpha, 1.0)
        
        // 等待3秒验证标签消失
        let expectation = XCTestExpectation(description: "Wait for validation label to fade")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            XCTAssertEqual(self.sut.timeValidationLabel.alpha, 0.0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testValidTimeSelection() {
        // 设置有效的时间范围
        let currentDate = Date()
        let validEndDate = currentDate.addingTimeInterval(3600) // 结束时间比开始时间晚1小时
        
        // 触发时间验证
        sut.loadViewIfNeeded()
        sut.startDatePicker.date = currentDate
        sut.dueDatePicker.date = validEndDate
        sut.datePickerValueChanged()
        
        // 验证视觉反馈
        XCTAssertEqual(sut.startDatePicker.tintColor, .systemGreen)
        XCTAssertEqual(sut.dueDatePicker.tintColor, .systemGreen)
        XCTAssertEqual(sut.timeValidationLabel.textColor, .systemGreen)
        XCTAssertEqual(sut.timeValidationLabel.text, "✓ 时间设置有效")
        XCTAssertEqual(sut.timeValidationLabel.alpha, 1.0)
    }
    
    func testTimeConflictDetection() {
        // 创建一个已存在的任务
        let existingTask = Task(context: mockManager.context)
        existingTask.title = "已存在的任务"
        existingTask.createdAt = Date()
        existingTask.dueDate = Date().addingTimeInterval(3600)
        try? mockManager.context.save()
        
        // 设置与已存在任务时间冲突的新任务
        let conflictStartDate = existingTask.createdAt!.addingTimeInterval(1800) // 开始时间在已存在任务的中间
        let conflictEndDate = existingTask.dueDate!.addingTimeInterval(1800) // 结束时间超过已存在任务
        
        // 触发时间验证
        sut.loadViewIfNeeded()
        sut.startDatePicker.date = conflictStartDate
        sut.dueDatePicker.date = conflictEndDate
        sut.datePickerValueChanged()
        
        // 验证冲突提示
        XCTAssertTrue(sut.hasTimeConflict)
        XCTAssertEqual(sut.conflictingTasks.count, 1)
        XCTAssertEqual(sut.conflictLabel.alpha, 1.0)
        XCTAssertEqual(sut.conflictOptionsStackView.alpha, 1.0)
    }
    
    func testAutoAdjustTime() {
        // 创建一个已存在的任务
        let existingTask = Task(context: mockManager.context)
        existingTask.title = "已存在的任务"
        existingTask.createdAt = Date()
        existingTask.dueDate = Date().addingTimeInterval(3600)
        try? mockManager.context.save()
        
        // 设置冲突时间
        let conflictStartDate = existingTask.createdAt!.addingTimeInterval(1800)
        let conflictEndDate = existingTask.dueDate!.addingTimeInterval(1800)
        
        // 触发时间验证
        sut.loadViewIfNeeded()
        sut.startDatePicker.date = conflictStartDate
        sut.dueDatePicker.date = conflictEndDate
        sut.datePickerValueChanged()
        
        // 执行自动调整
        sut.autoAdjustTime()
        
        // 验证新时间
        XCTAssertGreaterThan(sut.startDatePicker.date, existingTask.dueDate!)
        XCTAssertFalse(sut.hasTimeConflict)
    }
    
    func testTaskSaving() {
        // 设置任务数据
        sut.loadViewIfNeeded()
        sut.titleTextField.text = "测试任务"
        sut.notesTextView.text = "测试备注"
        sut.startDatePicker.date = Date()
        sut.dueDatePicker.date = Date().addingTimeInterval(3600)
        
        // 创建分类
        let category = Category(context: mockManager.context)
        category.name = "测试分类"
        try? mockManager.context.save()
        
        // 设置分类
        sut.selectedCategory = category
        
        // 保存任务
        sut.saveButtonTapped()
        
        // 验证任务是否保存成功
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try? mockManager.context.fetch(request)
        
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.title, "测试任务")
        XCTAssertEqual(tasks?.first?.notes, "测试备注")
        XCTAssertEqual(tasks?.first?.category, category)
    }
    
    func testReminderSetting() {
        // 设置任务数据
        sut.loadViewIfNeeded()
        sut.titleTextField.text = "提醒测试"
        sut.startDatePicker.date = Date().addingTimeInterval(3600) // 1小时后
        sut.dueDatePicker.date = Date().addingTimeInterval(7200) // 2小时后
        sut.reminderSwitch.isOn = true
        
        // 保存任务
        sut.saveButtonTapped()
        
        // 验证提醒是否设置
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try? mockManager.context.fetch(request)
        let savedTask = tasks?.first
        
        XCTAssertNotNil(savedTask)
        XCTAssertTrue(savedTask?.hasReminder ?? false)
        XCTAssertNotNil(savedTask?.reminderIdentifier)
    }
}
